classdef MDF_HD < MDF_BaseClass
    % header block
    
    properties
        ident      = 'HD';
        size       = 208;
        hDG_1stDataGroup = MDF_DG.empty;    % default value (must be writen once the DGblock is written --> location known)%532; %  532 -> 0x233 (pointer to: first data group)
        hTX_comment      = MDF_TX.empty;    % default value (must be writen once the TXblock is written --> location known)272; % 272 -> 0x110 (pointer to: comment text block)
        hPR              = MDF_PR.empty;
        %numberOfDG -> dependent property
        date      = datestr(now, 'dd:mm:yyyy');
        time      = datestr(now, 'HH:MM:SS');
        author    = 'Arne Voigt                      ';
        division  = 'IAV                             ';
        project   = 'export simulink to mdf          ';
        misc      = '                                ';
        timestamp = 0;
        utcTimeOffset = 1; % GMT + 1 hour (berlin time)
        timeQualClass = 0; %local pc-timer
        timerIdent = 'pc local time                   ';
        
        %% internals: none mdf-structur related
        filepos = 0;
    end % testparameter
    
    properties (Dependent)
        numberOfDataGroups
    end
    
    methods  
        function obj = MDF_HD(parent)
            date = java.util.Date();
            obj.utcTimeOffset = -date.getTimezoneOffset()/60;
            obj.parent = parent;
        end
        
        function number = get.numberOfDataGroups(this)
            if isempty(this.hDG_1stDataGroup)
                number = 0;
            else
                list = this.hDG_1stDataGroup.listAllDataGroups();
                number = numel(list);
            end
        end
        
        function newDataGroup = addDataGroup(this)
            %obj.numberOfDG = obj.numberOfDG +1;
            
            if this.hDG_1stDataGroup.valid()
                newDataGroup = this.hDG_1stDataGroup.addDataGroup(this, 2);
                return
            end
            this.hDG_1stDataGroup = MDF_DG;
            newDataGroup = this.hDG_1stDataGroup;
            newDataGroup.parent = this;
            newDataGroup.numberOfThisDG = 1;
        end
        
        function retTsBucket = getDataAsTsBucket(this)
            retTsBucket = tsBucket; % empty bucket
            
            % no data groups -> return with empty
            if ~this.hDG_1stDataGroup.isvalid(); return; end
            
            dgList = this.hDG_1stDataGroup.listAllDataGroups();
            for dataGroup = dgList
                retTsBucket.add(dataGroup{:}.getDataAsTsBucket());
            end
        end
        
        function retContainerCN = getContainerOfAllCNsRegEx(this_HD, regExpStr)
            retContainerCN = containers.Map; % empty container
            
            for dg = this_HD.listAllDataGroups()  
                for cg = dg{:}.listAllChannelGroups()
                    for cn = cg{:}.listAllChannels()
                        if cn{:}.type == CN_Types.TIME; continue; end;
                        sigName = cn{:}.shortName;
                        sigName = deblank(sigName); % remove trailing whitespaces 
                        if ~isempty( regexp(sigName, regExpStr, 'ONCE'))
                            retContainerCN(sigName) = cn{:};
                        end
                    end
                end
            end
            %remove
%             hDG_1stDataGroup.isvalid(); return; end
%             
%             dgList = this.hDG_1stDataGroup.listAllDataGroups();
%             for dataGroup = dgList
%                 for channelGroup = dataGroup{:}.listAllChannelGroups());
%                 %%dataGroup
%             end
        end
        
        function list = listAllDataGroups(this_HD)
            if this_HD.hDG_1stDataGroup.isvalid()
                list = this_HD.hDG_1stDataGroup.listAllDataGroups();
            else
                list = {};
            end
        end   
        
        
        function hTreeNode = getTreeNode(this, pathToThisNode)
            isLeaf = isempty(this.hDG_1stDataGroup) && ...
                     isempty(this.hTX_comment) && ...
                     isempty(this.hPR);
                 
            iconPath = which('HDF_pointfieldset.gif');     
            hTreeNode = uitreenode('v0', pathToThisNode, 'HD', iconPath, isLeaf);     
            
            if ~isempty(this.hDG_1stDataGroup)
                nodes = this.hDG_1stDataGroup.getTreeNodes([pathToThisNode, '.hDG_1stDataGroup'], {});
                for node = nodes
                    hTreeNode.add(node{:});
                end
            end
            if ~isempty(this.hTX_comment)
                hTreeNode.add(this.hTX_comment.getTreeNode( [pathToThisNode, '.hTX_comment'] ));
            end
            if ~isempty(this.hPR)
                hTreeNode.add(this.hPR.getTreeNode( [pathToThisNode, '.hPR'] ));
            end
        end    

        
        function print(obj, fid)
            fid = obj.fid;
            % save file position
            obj.filepos = ftell(fid);
            % write ID-Block into file
            fwrite(fid, obj.ident,      'char*1');
            fwrite(fid, obj.size,       'uint16');
            loc_filePos = ftell(fid);
            fwrite(fid, 0,              'uint32');  % file address of: 1st data group -> cant be set yet
            fwrite(fid, 0,              'uint32');  % file address of: comment text -> cant be set yet
            fwrite(fid, 0,              'uint32');  % file address of: programm block -> cant be set yet
            fwrite(fid, obj.numberOfDataGroups, 'uint16');
            fwrite(fid, obj.date,       'char*1');
            fwrite(fid, obj.time,       'char*1');
            fwrite(fid, obj.author,     'char*1');
            fwrite(fid, obj.division,   'char*1');
            fwrite(fid, obj.project,    'char*1');
            fwrite(fid, obj.misc,       'char*1');
            fwrite(fid, obj.timestamp,  'uint64');
            fwrite(fid, obj.utcTimeOffset, 'int16');
            fwrite(fid, obj.timeQualClass, 'uint16');
            fwrite(fid, obj.timerIdent,    'char*1');
            %% print associated blocks
            blocksToWrite = {obj.hTX_comment obj.hPR obj.hDG_1stDataGroup};
            for block = blocksToWrite
                 if block{:}.valid()
                     block{:}.print(fid);
                 end
            end
            
            %% update file addresses for associated block
            fseek(fid, loc_filePos, 'bof');
            if obj.hDG_1stDataGroup.valid
                fwrite(fid, obj.hDG_1stDataGroup.fPos, 'uint32');
            end
            if obj.hTX_comment.valid
                fwrite(fid, obj.hTX_comment.fPos, 'uint32');
            end
            if obj.hPR.valid
                fwrite(fid, obj.hPR.fPos, 'uint32');
            end
        end
        
    end
    
    methods (Static)
        function hdBlock = read(fid,parent)
            fseek(fid, 64 ,'bof');
            % check if this a mdf file
            charPatternAtStart = fread(fid, [1 2] , 'char*1');
            sizeOfBlock = fread(fid, [1 1] , 'uint16');
            if strcmp(char(charPatternAtStart), 'HD')% && ...
                    %(sizeOfBlock == 208)
            	hdBlock = MDF_HD(parent);
                hdBlock.fid = fid;
                hdBlock.fPos  = 64;
                hdBlock.ident = 'HD';
                hdBlock.size  = sizeOfBlock;
                fPos_1stDataGroup = fread(fid, [1 1], 'uint32');
                fPos_comment      = fread(fid, [1 1], 'uint32');
                fPos_PR           = fread(fid, [1 1], 'uint32');
                %hdBlock.hDG_1stDataGroup = MDF_DG.read(fid, fread(fid, [1 1], 'uint32'));
                
                fread(fid, size(hdBlock.numberOfDataGroups), 'uint16'); % numberOfDataGroups --> dependent var
                
                hdBlock.date          = fread(fid,  [1 8],        '*char');
                hdBlock.time          = fread(fid,  [1 8],        '*char');
                hdBlock.author        = fread(fid,  [1 32],       '*char');
                hdBlock.division      = fread(fid,  [1 32],       '*char');
                hdBlock.project       = fread(fid,  [1 32],       '*char');
                hdBlock.misc          = fread(fid,  size(hdBlock.misc),          '*char');
                hdBlock.timestamp     = fread(fid,  size(hdBlock.timestamp),     'uint64');
                hdBlock.utcTimeOffset = fread(fid,  size(hdBlock.utcTimeOffset), 'int16');
                hdBlock.timeQualClass = fread(fid,  size(hdBlock.timeQualClass), 'uint16');
                hdBlock.timerIdent    = fread(fid,  size(hdBlock.timerIdent),    'char*1');
                
                hdBlock.hDG_1stDataGroup = MDF_DG.read(fid, fPos_1stDataGroup, hdBlock, 1);
                hdBlock.hTX_comment = MDF_TX.read(fid, fPos_comment, hdBlock);
                hdBlock.hTX_comment = MDF_PR.read(fid, fPos_PR);

            else
                hdBlock = MDF_HD.empty; % return empty object
            end
    end
        
        
        
    end
    
    
end

