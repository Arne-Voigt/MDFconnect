classdef MDF_CG < MDF_BaseClass
    %CGBLOCK
    %   Detailed explanation goes here

    properties        
        
        % matlab handle to associated mdf blocks
        hCG_nxtChannelGroup = MDF_CG.empty; % next channel block
        hCN_1stChannel =      MDF_CN.empty; % 1st channel of this channel group
        hTX_comment =         MDF_TX.empty; %  
        
        % block internals
        recordID =         0;       % only needed for unsorted mdf
        %numberOfChannels = 0;
        recordLength =     0;
        numberOfCycles;    % number of recorded sampleTimes
        
        % private links
        %hDG_parent = MDF_DG.empty;
        
    end % testparameter
    
    properties (Dependent)
        numberOfChannels;
        %recordLength;
    end
    
    methods
        

        function count = get.numberOfChannels(this_CG)
            if isempty(this_CG.hCN_1stChannel)
                count = 0;
            else
                list = this_CG.hCN_1stChannel.listAllChannels();
                count = numel(list);
            end
        end
        
        function length = getRecordLength(this_CG)
            if isempty(this_CG.hCN_1stChannel)
                length = 0;
            else
                last_CN = this_CG.hCN_1stChannel.getLastChannel();
                length = last_CN.startBitOffset + last_CN.numberOfBits;
                length = ceil(double(length)/8); % bits -> bytes
            end
        end
        
        function bitOffset = getBitOffset(obj, objCaller)
            if isempty(obj.hCN_1stChannel)  % should never happen
                bitOffset = 0;
                return;
            end
            bitOffset = obj.hCN_1stChannel.listBitOffsets(objCaller);
        end
        
        function timeChannel = getTimeChannel(this_CG)
            
            timeChannel = MDF_CN.empty; % empty channel as default
            
            if ~this_CG.hCN_1stChannel.isvalid(); return; end % no valid channels in this channelGroup
            
            timeChannel = this_CG.hCN_1stChannel.getTimeChannel();

        end
      
        function newChannel = addChannel(this, ts, type)
            % get info from the timeseries
            if type == CN_Types.TIME
                data = ts.Time;
                name = 'time';
            else
                data= ts.Data;
                name = ts.Name;
            end
            switch class(data)
                case {'logical'}
                    sigType = CN_SigTypes.BOOLEAN;
                case {'uint8'}
                    sigType = CN_SigTypes.UINT_8;
                case {'uint16'}
                    sigType = CN_SigTypes.UINT_16;
                case {'uint32'}
                    sigType = CN_SigTypes.UINT_32;
                case {'uint64'}
                    sigType = CN_SigTypes.UINT_64;
                case {'int8'}
                    sigType = CN_SigTypes.INT_8;
                case {'int16'}
                    sigType = CN_SigTypes.INT_16;
                case {'int32'}
                    sigType = CN_SigTypes.INT_32;
                case {'single'}
                    sigType = CN_SigTypes.FLOAT;
                otherwise
                    if isenum(data)
                        sigType = CN_SigTypes.INT_32;
                    else
                        sigType = CN_SigTypes.DOUBLE;
                    end
            end

            if this.hCN_1stChannel.valid()
                % one channel is already associated with the channelGroup,
                % hence add new channel in the channel tree
%                 newChannel = obj.hCN_1stChannel.addChannel(name, type, sigType, obj);
                newChannel = this.hCN_1stChannel.addChannel(this);
                %newChannel.data = data;
            else
                % 1st channel in this ChannelGroup
%                 newChannel = MDF_CN(name, type, sigType, data, obj, MDF_CN.empty);
                newChannel = MDF_CN();
                this.hCN_1stChannel = newChannel;
                %newChannel.data = data;
            end
            
            newChannel.shortName = name;
            newChannel.data = data;
            newChannel.type = type;         % time or data
            newChannel.sigType = sigType;
            newChannel.numberOfBits = sigType.getBitCountFromDataType();
            newChannel.parent = this;
            
            this.numberOfCycles = numel(data);
            %bitsInRecord = newChannel.startBitOffset + newChannel.numberOfBits;
            %obj.recordLength = ceil(bitsInRecord/8); % conversion from bits to bytes
        end
       
        function list = listAllChannelGroups(this_CG)
            if this_CG.hCG_nxtChannelGroup.isvalid()
                list = this_CG.hCG_nxtChannelGroup.listAllChannelGroups();
                list{end+1} = this_CG;
            else
                list = {this_CG};
            end
        end
        
        function list = listAllChannels(this_CG)
            if this_CG.hCN_1stChannel.valid()
                list = this_CG.hCN_1stChannel.listAllChannels();
            else
                list = {};
            end
        end
        
        function retTsBucket = getDataAsTsBucket(this)
            retTsBucket = tsBucket; % empty bucket
            
            % reads this CG data into timeseries objects
            if ~this.hCN_1stChannel.isvalid(); return; end
            % no timeseries data in this CG, [TODO] make some verbose output 
            if this.numberOfCycles <= 1; return; end;
            % no Data block attached to this ChannelGroup
            if isempty(this.parent.hData); return; end;
            
            rawData = this.parent.hData.rawData;
            
            % try finding the time-channel
            cn_loc = this.hCN_1stChannel;
            while ~isempty(cn_loc)
                if ( cn_loc.type == CN_Types.TIME ); break; end
                cn_loc = cn_loc.hCN_nxtChannel;
            end
            % no time channel found -- return empty bucket 
            if ( isempty(cn_loc) );                 return; end 
            if ( cn_loc.type ~= CN_Types.TIME );    return; end
            
            % read time info
            byteOffset = floor(cn_loc.startBitOffset / 8);
            byteNumbers = ceil(cn_loc.numberOfBits   / 8);
            try
                timeRaw    = rawData(:, byteOffset+1:byteOffset+byteNumbers);
                timeRs  = reshape(timeRaw', [], 1);
                time = typecast(timeRs,cn_loc.sigType.getFileWritePrecision());
            catch
                fprintf('can''t read time signal\n');
                return;
            end
            
            % get name string parser from MDF_OBJECT 
            nameParserFcn = this.parent.parent.parent.hSignalNameParserFcn;
            % read data channels
            cnList = this.hCN_1stChannel.listAllChannels; % TODO: there could be multiple channels groups
            for channelCell = cnList
                channel = channelCell{:};
                % ignore if thats the time-channel 
                if channel.type == CN_Types.TIME; continue; end
                % ignore if data is of string type
                if channel.sigType == CN_SigTypes.STRING; continue; end
                byteOffset  = floor(double(channel.startBitOffset) / 8);
                byteNumbers =  ceil(double(channel.numberOfBits)   / 8);
                dataRaw    = rawData(:, byteOffset+1:byteOffset+byteNumbers);
                dataRs  = reshape(dataRaw', [], 1);
                try
%                     if strncmp('$CalibrationLog\XETK:1#RAMCal', char(channel.shortName(1:29)), length('$CalibrationLog\XETK:1#RAMCal'))
%                         disp aaa
%                     end
                    
                    data = typecast(dataRs,channel.sigType.getFileWritePrecision());
                    if channel.hCC.isvalid()
                        data = channel.hCC.applyConversion(data);
                    end
                    if channel.hTX_longName.isvalid()
                        nameRaw = channel.hTX_longName.text;
                    else
                        nameRaw = channel.shortName;
                    end
                    
                    % rewrite name to align with matlab
                    % variable-name-convention (func handle store in HD-Block) 
                    nameReformat = nameParserFcn(nameRaw);

%                     name = deblank(nameRaw);
%                     
%                     nameReformat = strtok(name,'\');
%                     nameReformat = strtok(nameReformat,'/');
%                     nameReformat = strrep(nameReformat,':','_');
%                     nameReformat = strrep(nameReformat,'.','_');
%                     nameReformat = strrep(nameReformat,'[','_');
%                     nameReformat = strrep(nameReformat,']','_');
                    
                    % check if name is valid worksspace name
                    if ~isvarname(nameReformat); continue; end
                    retTsBucket.add(timeseries(data, time, 'Name', nameReformat));
                catch
                    name = char(channel.shortName);
                    fprintf ('typecast failure for signal: %s\n', name);
                end
                % assemble time series object, add to return object

            end
        end
        
        function hTreeNodes = getTreeNodes(this, pathToThisNode, hTreeNodes)
            isLeaf = isempty(this.hTX_comment) && ...
                     isempty(this.hCN_1stChannel) && ...
                     isempty(this.hCG_nxtChannelGroup);
                     
            dg_cnt = num2str(numel(hTreeNodes)+1);   
            iconPath = which('HDF_grid.gif');
            hTreeNode = uitreenode('v0', pathToThisNode, ['CG_', dg_cnt], iconPath, isLeaf);     
            if ~isempty(this.hTX_comment)
                hTreeNode.add(this.hTX_comment.getTreeNodeTX([pathToThisNode, '.hTX_comment'], 'comment'));
            end            
            if ~isempty(this.hCN_1stChannel)
                nodes = (this.hCN_1stChannel.getTreeNodes( [pathToThisNode, '.hCN_1stChannel'], {}));
                for node = nodes
                    hTreeNode.add(node{:});
                end
            end

            hTreeNodes{end+1} = hTreeNode;
            
            if ~isempty(this.hCG_nxtChannelGroup)
                hTreeNodes = this.hCG_nxtChannelGroup.getTreeNodes(hTreeNodes);
            end            
        end
        
        
        function print(obj,fid)
            %% print associated blocks
            blocks = {obj.hCG_nxtChannelGroup obj.hCN_1stChannel obj.hTX_comment};
            for i = 1:numel(blocks)
                if blocks{i}.valid
                    blocks{i}.print(fid);
                end
            end
            %% save this block file-location
            obj.fPos = ftell(fid);
            %% print this channelGroup block
            fwrite(fid, 'CG', 'char*1');
            fwrite(fid, 26,  'uint16');    % block size (constant)
            % write file pointer to other mdf blocks (if they exist)
            blocks = {obj.hCG_nxtChannelGroup obj.hCN_1stChannel obj.hTX_comment};
            for i = 1:numel(blocks)
                if blocks{i}.valid()
                    fwrite(fid, blocks{i}.fPos, 'uint32');
                else
                    fwrite(fid, 0,          'uint32');
                end
            end
            fwrite(fid, obj.recordID,         'uint16');
            fwrite(fid, obj.numberOfChannels, 'uint16');
            fwrite(fid, obj.getRecordLength(),     'uint16');
            fwrite(fid, obj.numberOfCycles,   'uint32');
        end % print
        
        
    end % methods
    
    methods (Static)
        function cgBlock = read(fid, fPos, parentBlock)
            % default -> return empty object
            cgBlock = MDF_CG.empty; 
            if (fPos == 0); return; end;
            
            fseek(fid, fPos ,'bof');
            first4Bytes = fread(fid, 4 , '*uint8');
            % check if this a channelGroup
            if any(first4Bytes(1:2)' ~= uint8('CG')); return; end
      
            cgBlock = MDF_CG;
            cgBlock.fid = fid;
            cgBlock.fPos = fPos;
            cgBlock.parent = parentBlock;
    
            blocks_1st = fread(fid, [1 3], '*uint32');
            blocks_2nd = fread(fid, [1 5], '*uint16');
            cgBlock.recordID       = blocks_2nd(1);
            % numberOfChannels -> dependent variable
            cgBlock.recordLength   = blocks_2nd(3);
            cgBlock.numberOfCycles = typecast(blocks_2nd(4:5), 'uint32');
            
            cgBlock.hCG_nxtChannelGroup = MDF_CG.read(fid, blocks_1st(1));
            cgBlock.hCN_1stChannel      = MDF_CN.read(fid, blocks_1st(2), cgBlock);
            cgBlock.hTX_comment         = MDF_TX.read(fid, blocks_1st(3), cgBlock);


        end
    end

end

