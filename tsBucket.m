classdef tsBucket < handle
    %TSBUCKET Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = 'protected')
    listOfTs = {};
    
    end
    
    properties (Dependent)
        numberOfTs
    end
    
    methods
        
        function add(this, ts)
            switch class(ts)
                case {'timeseries','tscollection','tsRogue'}
                    this.listOfTs{end+1} = ts;
                case {'tsBucket'}
                    for entry = ts.get
                        this.listOfTs{end+1} = entry{:};
                    end
                case {'Simulink.SimulationData.Dataset', 'Simulink.sdi.Dataset'}
                    for i = 1:ts.numElements
                        this.listOfTs{end+1} = ts.getElement(i).Values;
                    end
                otherwise
                    error('unexpected data type ->\n\tinput was:   %s \n\tallowed are: timeseries, tscollection, tsBucket, tsRouge and DataSet (logsout, dsmout, streamout)', class(ts));
            end
        end
        
        function count = get.numberOfTs(this)
            count = numel(this.listOfTs);
        end
        
        function listOfTs = get(this)
            listOfTs = this.listOfTs;
        end
        
        function pack(this)
            packedList = {};
            for cellToInsert = this.listOfTs
                itemToInsert = cellToInsert{1}; % de-cell
                %itemToInsert
                % 1st entry goes unchecked into the new list 
                if isempty(packedList); packedList{1} = itemToInsert; continue; end
                % ignore rogue timerseries
                if isa(itemToInsert, 'tsRogue'); continue; end
                % [TODO] some better sort algo then this bubble-sort lookalike 
                itemMatchFound = false;
                for idxPackedList = 1:numel(packedList)
                    itemToCompare = packedList{idxPackedList};
                    
                    % check if time vector size is the same --> it not try next
                    if ~all(size(itemToInsert.Time) == size(itemToCompare.Time))
                        continue;
                    end
                    
                    % check if time vector has same values --> if not try next
                    if ~all(itemToInsert.Time == itemToCompare.Time)
                        continue;
                    end
                    
                    % [TODO] implement more 'not equal' checks
                    
                    % two timeseries -> merge into tscollection
                    if isa(itemToInsert, 'timeseries') && isa(itemToCompare, 'timeseries')
                        newCollection = tscollection({itemToInsert, itemToCompare});
                        % replace itemToCompare with the new collection
                        packedList{idxPackedList} = newCollection;
                        itemMatchFound = true;
                        break;
                    end
                    
                    % compare is a tscollection -> add the insert item to
                    % the tscollection
                    if isa(itemToInsert, 'timeseries') && isa(itemToCompare, 'tscollection')
                        packedList{idxPackedList} = itemToCompare.addts(itemToInsert);
                        itemMatchFound = true;
                        break;
                    end
                    
                    % compare is a timeseries and insert a tscollection ->
                    % add compare to the collection an overwirite the list 
                    if isa(itemToInsert, 'tscollection') && isa(itemToCompare, 'timeseries')
                        packedList{idxPackedList} = itemToInsert.addts(itemToCompare);
                        itemMatchFound = true;
                        break;
                    end
                    
                    % compare and inser are tscollection ->
                    % merge into one tscollection 
                    if isa(itemToInsert, 'tscollection') && isa(itemToCompare, 'tscollection')
                        for itemName = itemToInsert.gettimeseriesnames
                            ts = itemToInsert.get(itemName);
                            itemToCompare.addts(ts);
                        end
                        packedList{idxPackedList} = itemToCompare;
                        itemMatchFound = true;
                        break;
                    end
                    
                    fprintf('\n\nyou should not have reached this part of the code\n');
                    dbstack;
                end
                if ~itemMatchFound
                    packedList{end+1} = itemToInsert;
                end
                
            end
            this.listOfTs = packedList;
        end % pack
        
        function unpack(this)
            unpackedList = {};
            for idxToUnpack = 1:numel(this.listOfTs)
                itemToUnpack = this.listOfTs{idxToUnpack};
                if isa(itemToUnpack, 'timeseries')
                    unpackedList{end+1} = itemToUnpack;
                    continue;
                end
                if isa(itemToUnpack, 'tscollection')
                    %disassemble tscollection
                    for itemName = itemToUnpack.gettimeseriesnames
                        unpackedList{end+1} = itemToUnpack.get(itemName{:});
                    end
                    continue;
                end
                if isa(itemToUnpack, 'tsRogue')
                    unpackedList{end+1} = itemToUnpack;
                    continue;
                end
                fprintf('\n\nyou should not have reached this part of the code\n');
                dbstack;
            end
            this.listOfTs = unpackedList;
        end % unpack
        
        function extractAll(this)
            for idxToExtract = 1:numel(this.listOfTs)
                itemToExtract = this.listOfTs{idxToExtract};
                if isa(itemToExtract, 'timeseries')
                    try
                        assignin('base', itemToExtract.Name, itemToExtract);
                        continue;
                    catch
                        disp (itemToExtract.Name) 
                        continue;
                    end
                end
                if isa(itemToExtract, 'tscollection')
                    %disassemble tscollection
                    for itemName = itemToExtract.gettimeseriesnames
                        tsToExtract =  itemToExtract.get(itemName);
                        assignin('base', tsToExtract.name{:}, tsToExtract);
                    end
                    continue;
                end
                
                fprintf('\n\nyou should not have reached this part of the code\n');
                dbstack;
            end
        end % extract
        
        function extractByName(this, nameCellArray)
            for idxToExtract = 1:numel(this.listOfTs)
                itemToExtract = this.listOfTs{idxToExtract};
                if isa(itemToExtract, 'timeseries')
                    if ~any( strcmp(itemToExtract.name, nameCellArray)); continue; end
                    
                    try
                        assignin('base', itemToExtract.Name, itemToExtract);
                        continue;
                    catch
                        disp (itemToExtract.Name) 
                        continue;
                    end
                end
                if isa(itemToExtract, 'tscollection')
                    %disassemble tscollection
                    for itemName = itemToExtract.gettimeseriesnames
                        tsToExtract =  itemToExtract.get(itemName);
                        if ~any( strcmp(itemToExtract.name, nameCellArray)); continue; end 
                        assignin('base', tsToExtract.name{:}, tsToExtract);
                    end
                    continue;
                end
                
                fprintf('\n\nyou should not have reached this part of the code\n');
                dbstack;
            end
        end % extract
    end
    
end

