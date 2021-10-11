classdef MDF_DG < MDF_BaseClass
    %CNBLOCK
    %   Detailed explaination goes here

    properties        
        
        % matlab handle to associated mdf blocks
        hDG_nxtDataGroup    = MDF_DG.empty;     % next data group
        hCG_1stChannelGroup = MDF_CG.empty;     % 1st channel in this data group
        hTR                 = MDF_TR.empty;     % trigger block -> TODO
        hData               = MDF_DATA.empty;   % data block     
        
        % block internals
        recordIdLength      = 0;
        
        % non mdf properties
        numberOfThisDG;
        %dg_dataType = 0; % all channels in this data group have the same datatype        
    end % testparameter
    
    
    properties (Dependent)
        numberOfChannelGroups;
        % non mdf properties
        
    end
    
    methods   
        function this_DG = MDF_DG()
            this_DG.hData = MDF_DATA(this_DG);
        end
               
        function numberOfChannelGroups = get.numberOfChannelGroups(obj)
            if isempty(obj.hCG_1stChannelGroup)
                numberOfChannelGroups = 0;
            else
                list = obj.hCG_1stChannelGroup.listAllChannelGroups();
                numberOfChannelGroups = numel(list);
            end
        end
        
        function list = listAllDataGroups(this_DG)
            if this_DG.hDG_nxtDataGroup.isvalid()
                list = this_DG.hDG_nxtDataGroup.listAllDataGroups();
                list{end+1} = this_DG;
            else
                list = {this_DG};
            end
        end   
        
        function list = listAllChannelGroups(this_DG)
            if this_DG.hCG_1stChannelGroup.valid()
                list = this_DG.hCG_1stChannelGroup.listAllChannelGroups();
            else
                list = {};
            end
        end
   
        function retTsBucket = getDataAsTsBucket(this)
            retTsBucket = tsBucket; % empty bucket
            
            % no channel groups -> return with empty
            if ~this.hCG_1stChannelGroup.isvalid(); return; end
            
            cgList = this.hCG_1stChannelGroup.listAllChannelGroups();
            for channelGroup = cgList
                retTsBucket.add( channelGroup{:}.getDataAsTsBucket() );
            end
        end
        
        function hTreeNodes = getTreeNodes(this, pathToThisNode, hTreeNodes)
            isLeaf = isempty(this.hDG_nxtDataGroup) && ...
                     isempty(this.hCG_1stChannelGroup) && ...
                     isempty(this.hTR) && ...
                     isempty(this.hData);
                 
            dg_cnt = num2str(numel(hTreeNodes)+1);    
            iconPath = which('HDF_gridfieldset.gif');
            hTreeNode = uitreenode('v0', pathToThisNode, ['DG_', dg_cnt], iconPath, isLeaf);     
            if ~isempty(this.hData)
                hTreeNode.add(this.hData.getTreeNode( [pathToThisNode, '.hData'] ));
            end
            if ~isempty(this.hTR)
                hTreeNode.add(this.hTR.getTreeNode( [pathToThisNode, '.hTR'] ));
            end
            if ~isempty(this.hCG_1stChannelGroup)
                nodes = this.hCG_1stChannelGroup.getTreeNodes( [pathToThisNode, '.hCG_1stChannelGroup'], {});
                for node = nodes
                    hTreeNode.add(node{:});
                end
            end


            hTreeNodes{end+1} = hTreeNode;
            
            if ~isempty(this.hDG_nxtDataGroup)
                hTreeNodes = this.hDG_nxtDataGroup.getTreeNodes([pathToThisNode, '.hDG_nxtDataGroup'], hTreeNodes);
            end            
        end
        
        function print(obj,fid)
            %% print associated blocks
            blocks = {obj.hDG_nxtDataGroup obj.hCG_1stChannelGroup obj.hTR obj.hData};
            for i = 1:numel(blocks)
                 if blocks{i}.valid()
                     blocks{i}.print(fid);
                 end
            end
            %% save this block file-location
            obj.fPos = ftell(fid);
            %% print this channelGroup block
            fwrite(fid, 'DG', 'char*1');                    % block ID
            fwrite(fid, 28,   'uint16');                    % block size (constant)
            % write file pointer to other mdf locks (if they exist)
            blocks = {obj.hDG_nxtDataGroup obj.hCG_1stChannelGroup obj.hTR}; 
            for i = 1:numel(blocks)
                if blocks{i}.valid()
                    fwrite(fid, blocks{i}.fPos, 'uint32');
                else
                    fwrite(fid, 0,          'uint32');
                end
            end
            fwrite(fid, obj.hData.fPos,            'uint32');  % address of data
            %fwrite(fid, 0,            'uint32');  % address of data
            
            fwrite(fid, obj.numberOfChannelGroups, 'uint16');  % number of channel groups
            fwrite(fid, obj.recordIdLength,        'uint16');  % length of record ID
            fwrite(fid, 0,                         'uint32');  % reserved
        end % print

        function newDataGroup = addDataGroup(this, parent, counter )
            if this.hDG_nxtDataGroup.valid()
                newDataGroup = this.hDG_nxtDataGroup.addDataGroup(this, counter +1);
                return;
            end
            this.hDG_nxtDataGroup = MDF_DG();
            newDataGroup = this.hDG_nxtDataGroup;
            newDataGroup.parent = parent;
            newDataGroup.numberOfThisDG = counter;
        end
    end
    
    methods (Static)
        function dgBlock = read(fid, fPos, parentBlock, counterDG)
            dgBlock = MDF_DG.empty; % default -> return empty object
            if (fPos == 0); return; end;
             
            fseek(fid, fPos ,'bof');
            first4Bytes = fread(fid, 4 , '*uint8');
            
            % check if this a datagroup
            if any(first4Bytes(1:2)' ~= uint8('DG')); return; end
            
            dgBlock = MDF_DG;
            dgBlock.fid = fid;
            dgBlock.fPos = fPos;
            dgBlock.parent = parentBlock;
            dgBlock.numberOfThisDG = counterDG;
            
            blocks_1st = fread(fid, [1 4], '*uint32');
            blocks_2nd = fread(fid, [1 2], '*uint16');    
                
            % numberOfChannelGroups = blocks_2nd(1); % dont care -> dependent
            dgBlock.recordIdLength  = blocks_2nd(2);

            dgBlock.hDG_nxtDataGroup =    MDF_DG.read(fid, blocks_1st(1), parentBlock, counterDG+1);
            dgBlock.hCG_1stChannelGroup = MDF_CG.read(fid, blocks_1st(2), dgBlock);
            dgBlock.hTR =                 MDF_PR.read(fid, blocks_1st(3));
            dgBlock.hData =               MDF_DATA.read(fid, blocks_1st(4), dgBlock);
            if ~isempty(dgBlock.hData)
                dgBlock.hData.readRawData();
            end
        end
    end

end

