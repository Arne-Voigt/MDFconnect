classdef MDF_CN < MDF_BaseClass
    %CNBLOCK
    %   Detailed explanation goes here

    properties        
    
        % matlab handle to associated mdf blocks
        hCN_nxtChannel = MDF_CN.empty;  % next channel block
        hCC = MDF_CC.empty;  % conversion formula
        hCE = MDF_CE.empty;  % source depending extension 
        hCD = MDF_CD.empty;  % dependency block
        hTX_comment = MDF_TX.empty;  % comment
        hTX_longName = MDF_TX.empty;    % tx-block to the signals name if its longer then 31 character
        hTX_longDispName = MDF_TX.empty;
        
        % private links
        %hCG_parent = MDF_CG.empty;
        
        % block internals
        type = CN_Types.TIME;           % time or data
        shortName =  char(zeros(1,32));
        signalDescr =  char(zeros(1,128));
        startBitOffset = uint16(0);
        numberOfBits = uint16(0);
        sigType = CN_SigTypes.DOUBLE; %uint16(0);         % double, single, int, ...
        valueRngValid = false;
        %valueMin = double(-inf); -> dependent property
        %valueMax = double(inf);  -> dependent property
        sampleRate = double(0);
        startBitOffsetAddon = uint16(0);
        
        data = [];
        
    end % testparameter
    
    
    properties (Dependent)
        valueMin;
        valueMax;       
    end
    
    methods
        % MDF_CN(name, timeOrData, dataType, channelgroup, previousChannel)
        % MDF_CN() -> whne called from static read-function
        %function obj = MDF_CN(name, type, sigType, data, cg, ch_prev)
%         function obj = MDF_CN(varargin)
%             if nargin ~= 1
%                 warning ('MDF_CN instantiation without the correct number of parameter');
%                 return;
%             end
%             name = varargin{1};
%             type = varargin{2};
%             sigType = varargin{3};
%             data = vargin{4};
%             cg = varargin{5};
%             ch_prev = varargin{6};
%             
%             obj.shortName = name;
%             obj.type = type;
%             obj.sigType = sigType;
%             obj.numberOfBits = sigType.getBitCountFromDataType(); 
%             obj.parent = varargin{4};
%             if ch_prev.valid()
%                 ch_prev.hCN_nxtChannel = obj;
%             else
%                 cg.hCN_1stChannel = obj;
%             end
%             obj.startBitOffset = ceil(cg.getBitOffset(obj)/8) * 8;
%             %obj.parent.numberOfCycles = 
%         end
  
        function set.shortName(obj, name)
            % limit obj.shortName to 31 character + \0, fill empty space with \0 
            obj.shortName = [ name( 1 : min(31,length(name))) zeros(1, 32-min(31,length(name))) ];
            obj.setLongName(name);
        end
        
        function valueMin = get.valueMin(this_CN)
            if ~this_CN.valueRngValid || isempty(this_CN.data)
                valueMin = 0;
            else
                valueMin = min(this_CN.data);
            end
        end
        
        function valueMax = get.valueMax(this_CN)
            if ~this_CN.valueRngValid || isempty(this_CN.data)
                valueMax = 0;
            else
                valueMax = max(this_CN.data);
            end
        end
       
        function setLongName(obj, name)
            if length (name) > 31
                obj.hTX_longName = MDF_TX(name);
            end
        end
        
        function bits = listBitOffsets(obj, objCaller)
            % end of daisy chain reached
            if obj == objCaller ||...
                    isempty(obj.hCN_nxtChannel) 
                bits = 0;
                return;
            end
            bits = obj.hCN_nxtChannel.listBitOffsets(objCaller);
            bits = bits + obj.numberOfBits;
        end
        
        function lastChannel = getLastChannel(this_CN)
            % get the last channel in the current channelGroup
            if isempty(this_CN.hCN_nxtChannel)
                lastChannel = this_CN;
                return;
            end
            lastChannel = this_CN.hCN_nxtChannel.getLastChannel();
        end
        
        
        function timeChannel = getTimeChannel(this_CN)
            % this is the time channel -> return this channel
            if this_CN.type == CN_Types.TIME
                timeChannel = this_CN;
                return;
            end
            % this is the last channel -> looks like a time channel could not be found -> return an empty channel object 
            if ~this_CN.hCN_nxtChannel.isvalid()
                timeChannel = MDF_CN.empty;
                return;
            end
            % try the next channel
            timeChannel = this_CN.hCN_nxtChannel.getTimeChannel();
        end
        
        function this_CN = set.data(this_CN, dataToSet)
            this_CN.data = dataToSet;
            % add conversion block for enum-members
            if isenum(dataToSet)
                this_CN.hCC = MDF_CC(dataToSet);
                
            end
        end
        
        function data = getData(this_CN)
            data = [];
            
            if isempty( this_CN.parent.parent.hData)
                return
            end
            
            % ignore if data is of string type
            if this_CN.sigType == CN_SigTypes.STRING; return; end
            
            % byte offset, data length
            byteOffset  = floor(double(this_CN.startBitOffset) / 8);
            byteNumbers =  ceil(double(this_CN.numberOfBits)   / 8);
            
            dataRaw = this_CN.parent.parent.hData.rawData(:, byteOffset+1:byteOffset+byteNumbers);
            dataRs  = reshape(dataRaw', [], 1);
            
            % typecast from array of uint8 to (single|double|int16|...)
            data = typecast(dataRs,this_CN.sigType.getFileWritePrecision());
            
            % apply conversion (offset, gain, function-conversion)
            if this_CN.hCC.isvalid()
                data = this_CN.hCC.applyConversion(data);
            end
        end
        
        function tsData = getDataAsTimeseries(this_CN)
            tsData = {};    % default return value
            
            cnTime = this_CN.parent.getTimeChannel();
            signalTime = cnTime.getData();
            signalData = this_CN.getData();
            
            % data is valid
            if isempty(signalTime) || isempty(signalData)
                return      % return empty cell
            end
           
            % get signal name
            if this_CN.hTX_longName.isvalid()
                nameRaw = this_CN.hTX_longName.text;
            else
                nameRaw = this_CN.shortName;
            end
            
            % get name string parser from MDF_OBJECT
            nameParserFcn = this_CN.parent.parent.parent.parent.hSignalNameParserFcn;
            signalName = nameParserFcn(nameRaw);
            
            % check if name is valid worksspace name
            if ~isvarname(signalName)
                fprintf(2, 'rawSigName: %s\t  parsed to: %s is not vaild -> signal not imported\n', nameRaw, signalName);
                return
            end
            
            tsData = timeseries(signalData, signalTime, 'Name', signalName);
        end
        
        
        
        function list = listAllChannels(this_CN)
            if this_CN.hCN_nxtChannel.isvalid()
                list = this_CN.hCN_nxtChannel.listAllChannels();
                list = [{this_CN} list];    
            else
                list = {this_CN};
            end
        end
        %%
        function hTreeNodes = getTreeNodes(this, pathToThisNode, hTreeNodes)
            isLeaf = isempty(this.hCC) && ...
                     isempty(this.hCE) && ...       % source depending extension
                     isempty(this.hCD) && ...
                     isempty(this.hTX_comment) && ...
                     isempty(this.hTX_longName) && ...
                     isempty(this.hTX_longDispName);
                 
            dg_cnt = num2str(numel(hTreeNodes)+1);    
            iconPath = which('greenarrowicon.gif');
            hTreeNode = uitreenode('v0', pathToThisNode, ['CN_', dg_cnt,'__',this.shortName], iconPath, isLeaf);     
            if ~isempty(this.hCC)
                hTreeNode.add(this.hCC.getTreeNode([pathToThisNode, '.hCC']));
            end
            if ~isempty(this.hCE)
                hTreeNode.add(this.hCE.getTreeNode([pathToThisNode, '.hCE']));
            end
            if ~isempty(this.hCD)
                hTreeNode.add(this.hCD.getTreeNode([pathToThisNode, '.hCD']));
            end            
            if ~isempty(this.hTX_comment)
                hTreeNode.add(this.hTX_comment.getTreeNodeTX([pathToThisNode, '.hTX_comment'], 'comment'));
            end             
            if ~isempty(this.hTX_longName)
                hTreeNode.add(this.hTX_longName.getTreeNodeTX([pathToThisNode, '.hTX_longName'], 'longName'));
            end              
            if ~isempty(this.hTX_longDispName)
                hTreeNode.add(this.hTX_longName.getTreeNodeTX([pathToThisNode, '.hTX_longDispName'], 'dispName'));
            end  
            
            
            hTreeNodes{end+1} = hTreeNode;
            
            if ~isempty(this.hCN_nxtChannel)
                hTreeNodes = this.hCN_nxtChannel.getTreeNodes([pathToThisNode, '.hCN_nxtChannel'], hTreeNodes);
            end            
        end 
        %%
        
        function print(this_CN,fid)
            %% print associated blocks
            blocks = {this_CN.hCN_nxtChannel this_CN.hCC this_CN.hCE this_CN.hCD this_CN.hTX_comment this_CN.hTX_longName this_CN.hTX_longDispName};
            for i = 1:numel(blocks)
                if blocks{i}.valid
                    blocks{i}.print(fid);
                end
            end
            %% save this block file-location
            this_CN.fPos = ftell(fid);
            %% print this channel block
            fwrite(fid, 'CN', 'char*1');
            fwrite(fid, 228,  'uint16');    % block size (constant)
            % write file pointer to other mdf locks (if they exist)
            blocks = {this_CN.hCN_nxtChannel this_CN.hCC this_CN.hCE this_CN.hCD this_CN.hTX_comment};
            for i = 1:numel(blocks)
                if blocks{i}.valid()
                    fwrite(fid, blocks{i}.fPos, 'uint32');
                else
                    fwrite(fid, 0,          'uint32');
                end
            end
            fwrite(fid, uint16(this_CN.type),    'uint16');
            fwrite(fid, this_CN.shortName,       'char*1');
            fwrite(fid, this_CN.signalDescr,     'char*1');
            fwrite(fid, this_CN.startBitOffset,  'uint16');
            fwrite(fid, this_CN.numberOfBits,    'uint16');
            fwrite(fid, this_CN.sigType.getSignalDataType(), 'uint16');
            fwrite(fid, this_CN.valueRngValid,   'uint16');
            fwrite(fid, this_CN.valueMin,        'double');
            fwrite(fid, this_CN.valueMax,        'double');
            fwrite(fid, this_CN.sampleRate,      'double');
            blocks = {this_CN.hTX_longName this_CN.hTX_longDispName};
            for i = 1:numel(blocks)
                if blocks{i}.valid()
                    fwrite(fid, blocks{i}.fPos, 'uint32');
                else
                    fwrite(fid, 0,          'uint32');
                end
            end
            fwrite(fid, this_CN.startBitOffsetAddon, 'uint16');
            
        end
    end % methods
    
    methods %( Access = 'private' )
        function newChannel = addChannel(this_CN, parent_CG)
            % this is not the last channel -> send 'new channel request'
            % further down the pipe
            if this_CN.hCN_nxtChannel.valid()
                newChannel = this_CN.hCN_nxtChannel.addChannel(parent_CG);
            else
                this_CN.hCN_nxtChannel = MDF_CN();
                newChannel = this_CN.hCN_nxtChannel;
                newChannel.startBitOffset = this_CN.startBitOffset + ...
                                           ceil(this_CN.sigType.getBitCountFromDataType()/8)*8; 
            end
        end       
 
    end
    
    methods (Static)
        function cnBlock = read(fid, fPos, parentBlock)
            cnBlock = MDF_CN.empty; % default -> return empty object
            if (fPos == 0); return; end;
            
            
            fseek(fid, fPos ,'bof');
            first4Bytes = fread(fid, 4 , '*uint8');
            
            % check if this a channel
            if any(first4Bytes(1:2)' ~= uint8('CN')); return; end
            
            cnBlock = MDF_CN;
            cnBlock.fid = fid;
            cnBlock.fPos = fPos;
            cnBlock.parent = parentBlock;
            
            %%%%%%%%%%% NEW %%%%%%%%%%%
%             blockLength = typecast(first4Bytes(3:4), 'uint16');
%             cnDataDump = fread(fid, [1 blockLength-4], '*uint8');            
% 
%             cnBlock.hCN_nxtChannel   = MDF_CN.read(fid, typecast(cnDataDump( 1: 4), 'uint32'));
%             cnBlock.hCC              = MDF_CC.read(fid, typecast(cnDataDump( 5: 8), 'uint32'));
%             cnBlock.hCE              = MDF_CE.read(fid, typecast(cnDataDump( 9:12), 'uint32'));
%             cnBlock.hCD              = MDF_CD.read(fid, typecast(cnDataDump(13:16), 'uint32'));
%             cnBlock.hTX_comment      = MDF_TX.read(fid, typecast(cnDataDump(17:20), 'uint32'));
% 
%             if 1 == typecast(cnDataDump(21:22), 'uint16')
%                 cnBlock.type = CN_Types.TIME;
%             else
%                 cnBlock.type = CN_Types.VALUE;
%             end
% 
%             cnBlock.shortName       = char(cnDataDump( 23: 54) );
%             cnBlock.signalDescr     = char(cnDataDump( 55:182) );
%             cnBlock.startBitOffset = typecast(cnDataDump(183:184), 'uint16');
%             cnBlock.numberOfBits = typecast(cnDataDump(185:186), 'uint16');
%             cnBlock.sigType = typecast(cnDataDump(187:188), 'uint16');
%             cnBlock.sigType = CN_SigTypes.getTypeFromRead( cnBlock.sigType, cnBlock.numberOfBits);
%             cnBlock.valueRngValid  = typecast(cnDataDump(189:190), 'uint16');
%             % ignore variable: valueMin ...191:198
%             % ignore variable: valueMax ...199:206
%             cnBlock.sampleRate  = typecast(cnDataDump(207:214), 'double');
%             cnBlock.hTX_longName     = MDF_TX.read(fid, typecast(cnDataDump(215:218), 'uint32'));
%             cnBlock.hTX_longDispName = MDF_TX.read(fid, typecast(cnDataDump(219:222), 'uint32')); 

            
            %%%%%%%%%%% OLD %%%%%%%%%%%
            
            
            blocks_1st = fread(fid, [1 5], '*uint32');
            %                 fPos_nxtChannel   = fread(fid, [1 1], 'uint32');
            %                 fPos_convFormula  = fread(fid, [1 1], 'uint32');
            %                 fPos_dependExt    = fread(fid, [1 1], 'uint32');
            %                 fPos_dependBlock  = fread(fid, [1 1], 'uint32');
            %                 fPos_comment      = fread(fid, [1 1], 'uint32');
            
            cnBlock.type           = fread(fid, [1 1],    '*uint16');
            if cnBlock.type == 1
                cnBlock.type = CN_Types.TIME;
            else
                cnBlock.type = CN_Types.VALUE;
            end
            cnBlock.shortName      = fread(fid, [1 32],       '*char');
            cnBlock.signalDescr    = fread(fid, [1 128],     '*char');
            
            blocks_2nd = fread(fid, [1 4],  '*uint16');
            
            cnBlock.startBitOffset = blocks_2nd(1);
            cnBlock.numberOfBits   = blocks_2nd(2);
            cnBlock.sigType        = CN_SigTypes.getTypeFromRead(blocks_2nd(3), cnBlock.numberOfBits);
            cnBlock.valueRngValid  = blocks_2nd(4);
            
            %                 cnBlock.startBitOffset = fread(fid, [1 1],  'uint16');
            %                 cnBlock.numberOfBits   = fread(fid, [1 1],    'uint16');
            %                 cnBlock.sigType        = CN_SigTypes.getTypeFromRead(fread(fid, [1 1], 'uint16'), cnBlock.numberOfBits);
            %                 cnBlock.valueRngValid  = fread(fid, [1 1],   'uint16');
            %                 fseek(fid, 4 ,'cof'); % ignore variable: valueMin
            %                 fseek(fid, 4 ,'cof'); % ignore variable: valueMax
            fseek(fid, 16 ,'cof'); % ignore variable: valueMin and valueMax
            cnBlock.sampleRate     = fread(fid, [1 1],      'double');
            
            blocks_3rd = fread(fid, [1 2],  '*uint32');
            
            %                 fPos_longName     = fread(fid, [1 1], 'uint32');
            %                 fPos_longDispName = fread(fid, [1 1], 'uint32');
            
            cnBlock.hCN_nxtChannel   = MDF_CN.read(fid, blocks_1st(1), parentBlock);
            cnBlock.hCC              = MDF_CC.read(fid, blocks_1st(2));
            cnBlock.hCE              = MDF_CE.read(fid, blocks_1st(3));
            cnBlock.hCD              = MDF_CD.read(fid, blocks_1st(4));
            cnBlock.hTX_comment      = MDF_TX.read(fid, blocks_1st(5), cnBlock);
            cnBlock.hTX_longName     = MDF_TX.read(fid, blocks_3rd(1), cnBlock);
            cnBlock.hTX_longDispName = MDF_TX.read(fid, blocks_3rd(2), cnBlock);
            
            
            

        
            
        end
    end
    
end

