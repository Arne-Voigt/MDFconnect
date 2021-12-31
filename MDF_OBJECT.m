classdef MDF_OBJECT < MDF_BaseClass
    % header block
    
    properties
        hID = MDF_ID.empty;    % ident-block of the mdf
        hHD = MDF_HD.empty;    % header-block of the mdf
        fileName = '';
        hSignalNameParserFcn;
    end 
    
    methods 
        
        %function this = MDF_OBJECT(signalNameParserFcn, rrr)
        function this = MDF_OBJECT(signalNameParserFcn)
           this.hID = MDF_ID();
           this.hHD = MDF_HD(this);
           if exist('signalNameParserFcn', 'var')
               this.hSignalNameParserFcn = signalNameParserFcn;
           else
               this.hSignalNameParserFcn = @MDF_OBJECT.defaultSignalNameParser;
           end
        end
        
        
        function print(this, fileName)
            this.fileName = fileName;
            fid=fopen(this.fileName,'wb'); % open as binary file
            
            this.hID.fid = fid;
            this.hHD.fid = fid;
            
            this.fPos = ftell(fid); % save file position -> dont think this is needed
            this.hID.print(fid); 
            this.hHD.print(fid);
            
            fclose(fid);
        end
        
        function read(this, fileName)
            this.fileName = fileName;
            fid=fopen(this.fileName,'rb'); % open as binary file
            this.hID = MDF_ID.read(fid);
            this.hHD = MDF_HD.read(fid, this);
            fclose(fid);
        end
        
        function importTsBucket(this, bucket)
            assert (isa(bucket, 'tsBucket'), 'input must be a tsBucket-object');
            for idxOfBucketItems = 1:numel(bucket.get)
                itemToInsert = bucket.get{idxOfBucketItems};
                if isa(itemToInsert, 'timeseries') 
                    dg = this.hHD.addDataGroup();
                    dg.hCG_1stChannelGroup = MDF_CG();
                    cg=dg.hCG_1stChannelGroup;
                    itemToInsertList = this.splitTs(itemToInsert);         % for array/vector data -> splits the ts into multiple "scalar" ts
                    cg.addChannel(itemToInsertList{1}, CN_Types.TIME);     % time channel
                    for i = 1:numel(itemToInsertList)
                        cg.addChannel(itemToInsertList{i}, CN_Types.VALUE);    % value channel
                    end
                    % [TODO] what if the data is not a sclar but a vector
                    % -> for mdf3.0 add "[x]-name indexing"
                end
                if isa(itemToInsert, 'tscollection')
                    dg = this.hHD.addDataGroup();
                    dg.hCG_1stChannelGroup = MDF_CG();
                    cg=dg.hCG_1stChannelGroup;
                    % add the time channel
                    cg.addChannel(itemToInsert, CN_Types.TIME); % time channel
                    % for each entry in the tscelloection generate a
                    % channel in the same channelGroup
                    for collectionItemName = itemToInsert.gettimeseriesnames
                        itemFromCollection = itemToInsert.get(collectionItemName{:});
                        itemToInsertList = this.splitTs(itemFromCollection);         % for array/vector data -> splits the ts into multiple "scalar" ts
                        for i = 1:numel(itemToInsertList)
                            cg.addChannel(itemToInsertList{i}, CN_Types.VALUE);    % value channel
                        end
                        %cg.addChannel(itemFromCollection, CN_Types.VALUE);  % yet another value channel
                    end
                end
                
                if isa(itemToInsert, 'tsRogue')
                    dg = this.hHD.addDataGroup();
                    dg.hCG_1stChannelGroup = MDF_CG();
                    cg=dg.hCG_1stChannelGroup;
                    cg.addChannel(itemToInsert, CN_Types.TIME);     % time channel
                    cg.addChannel(itemToInsert, CN_Types.VALUE);    % value channel
                    % [TODO] what if the data is not a sclar but a vector
                    % -> for mdf3.0 add "[x]-name indexing"
                end
            end
        end
        
        function appendTsBucket(this, bucket)
            assert (isa(bucket, 'tsBucket'), 'input must be a tsBucket-object');
            for idxOfBucketItems = 1:numel(bucket.get)
                itemToInsert = bucket.get{idxOfBucketItems};
                
                if isa(itemToInsert, 'tsRogue')
                    dg = this.hHD.addDataGroup();
                    dg.hCG_1stChannelGroup = MDF_CG();
                    cg=dg.hCG_1stChannelGroup;
                    cg.addChannel(itemToInsert, CN_Types.TIME);     % time channel
                    cg.addChannel(itemToInsert, CN_Types.VALUE);    % value channel
                    % [TODO] what if the data is not a sclar but a vector
                    % -> for mdf3.0 add "[x]-name indexing"
                    fid=fopen(this.fileName,'r+'); % open as binary file
                    fseek(fid, 0 , 'eof');
                    dg.print(fid);
                    % set DG list links
                    listAllDGs = this.hHD.hDG_1stDataGroup.listAllDataGroups();
                    oldLastDG = listAllDGs{2};
                    fseek(fid, oldLastDG.fPos + 4, 'bof');
                    fwrite(fid, dg.fPos, 'uint32');
                    % increase HD DG counter
                    fseek(fid, 80, 'bof');
                    counter = fread(fid, [1 1], 'uint16');
                    fseek(fid, 80, 'bof');
                    fwrite(fid, counter+1, 'uint16');
                    %done
                    fclose(fid);
                end
                
            end
        
        end
        
        
        function listCN = findCN(this, pattern)
            listCN = MDF_CN.empty; % empty array of CN type -- just an empty list ala [] will not work
            if ~this.hHD.isvalid(); return; end
            if ~this.hHD.hDG_1stDataGroup.isvalid(); return; end
            for DG = this.hHD.hDG_1stDataGroup.listAllDataGroups
                if ~DG{1}.hCG_1stChannelGroup.isvalid; continue; end
                for CG = DG{1}.hCG_1stChannelGroup.listAllChannelGroups
                    if ~CG{1}.hCN_1stChannel.isvalid; continue; end
                    for CN = CG{1}.hCN_1stChannel.listAllChannels
                        if contains(CN{1}.shortName, 'VeTMMR_M_Clch1TorqEst')
                            disp(33)
                        end
                        
                        % check from long name tx-block -- if exists
                        if CN{1}.hTX_longName.isvalid
                            if contains(CN{1}.hTX_longName.text, pattern)
                                listCN(end+1) = CN{1};
                                continue;
                            end 
                        end
                        % check via name in cn-block
                        if contains(CN{1}.shortName, pattern)
                            listCN(end+1) = CN{1};
                        end
                    end    
                end
            end
            
        
        end
        
        function clearCN(this, cnToClear)
            fid=fopen(this.fileName,'r+'); % open as binary file

            
            cnList = cnToClear.parent.hCN_1stChannel.listAllChannels;
             % find cn in list
             cnPrev = MDF_CN.empty;
             cnNext = MDF_CN.empty;
             for idx = 1:numel(cnList)
                chToCheck = cnList{idx};
                if chToCheck == cnToClear
                    if idx > 1 
                        cnPrev = cnList{idx-1};
                    end
                    if idx < numel(cnList)
                        cnNext = cnList{idx+1};
                    end
                    break;
                end
             end
             if cnPrev.isvalid()    % previous CN exist
                fseek(fid, cnPrev.fPos + 4, 'bof');
                if cnNext.isvalid() % next CN exist
                    fwrite(fid, cnNext.fPos, 'uint32');
                    cnPrev.hCN_nxtChannel = cnNext;
                else                % next CN doesn't exist
                    fwrite(fid,           0, 'uint32'); 
                    cnPrev.hCN_nxtChannel = MDF_CN.empty;
                end
             else                   % previous CN doesn't exist --> override in CG
                 fseek(fid, cnToClear.parent.fPos + 8, 'bof');
                 if cnNext.isvalid()
                    fwrite(fid, cnNext.fPos, 'uint32');
                    cnToClear.parent.hCN_1stChannel = cnNext;
                 else
                    fwrite(fid,           0, 'uint32'); 
                    cnToClear.parent.hCN_1stChannel = MDF_CN.empty;
                 end                
             end
             
             % rewrite CG channel-counter
             fseek(fid, cnToClear.parent.fPos + 18, 'bof');
             cnCounter = fread(fid, [1 1], 'uint16');
             fseek(fid, cnToClear.parent.fPos + 18, 'bof');
             fwrite(fid, max(cnCounter-1, 0), 'uint16');
             fclose(fid);
             
             
        
        end
        function hTreeNode = getTreeNode(this)
            isLeaf = isempty(this.hID) && ...
                     isempty(this.hHD);
            
            pathToThisNode = inputname(1);
            iconPath = which('file_open.png'); 
            hTreeNode = uitreenode('v0', pathToThisNode, ['mdf  {', this.fileName, '}'], iconPath, isLeaf);     
            
            if ~isempty(this.hID)
                hTreeNode.add(this.hID.getTreeNode( [pathToThisNode, '.hID'] ));
            end
            if ~isempty(this.hHD)
                hTreeNode.add(this.hHD.getTreeNode( [pathToThisNode, '.hHD'] ));
            end
        end    

    end
      
    methods (Access = 'private')
        
        function [ tsList ] = splitTs(this, tsToSplit )
            % nothing to split -> return unchanged ts
            if all(tsToSplit.getdatasamplesize() == 1)
                tsList = {tsToSplit};
                return;
            end
            
            cntFinal = tsToSplit.getdatasamplesize();
            cntInc = cntFinal./cntFinal;
            tsList = {};
            % run thru all indices
            while any(cntInc ~= cntFinal) % technically a do-while loop would be better
                % fprintf('%s\n', mat2str(cntInc))
                tsList{end+1} = this.getSubTs(tsToSplit, cntInc); % create sub-ts
                cntInc(1) = cntInc(1) + 1;
                for i = 1:numel(cntFinal)
                    if cntInc(i) > cntFinal(i)
                        cntInc(i) = 1;
                        cntInc(i+1) = cntInc(i+1) + 1;
                    else
                        break
                    end
                end
            end
            tsList{end+1} = this.getSubTs(tsToSplit, cntInc); % create one last sub-ts
        end %splitTs()
        
        function retTs = getSubTs(this, ts, idx)
            retTs = ts;
            
            % set name
            retTs.Name = [ts.Name, '__'];
            for i=1:numel(idx)
                retTs.Name = [retTs.Name, mat2str(idx(i)-1)];
                if i < numel(idx)
                    retTs.Name = [retTs.Name, '_'];
                end
            end
            
            % extract sub-Ts
            idxStr = '( ';
            for i=1:numel(idx)
                idxStr = [idxStr, mat2str(idx(i)), ', '];
            end
            idxStr = [idxStr, ': )'];
            eval(['retTs.Data = retTs.Data' idxStr ';']);
        end %getSubTs()
    end
    
    methods (Static)
        function nameReformat = defaultSignalNameParser(nameRaw)
            % remove everthing that is not a-z or A-Z or 0-9 or '_'
            nameReformat = regexprep(nameRaw,'\W', '');
            % for 1st character: only allow a-z (no underscores, no numbers)
            nameReformat = regexprep(nameReformat,'^[^a-zA-Z]', '');
        end
    end
    
end

