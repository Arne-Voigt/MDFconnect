classdef MDF_DATA < MDF_BaseClass
    % stump  for the trigger block
    % may never be implemented
    
    properties        
    
        hDG_parent = MDF_DG.empty
        %timeData = [];
        signalData = [];
        %dataType;
        dataTypePattern;
        rawData;
    end % testparameter
    
    properties (Dependent)
        writeData;  % builds up data from associated channels  
        readData;   % reads 
    end
    
    methods
        function this_DATA = MDF_DATA(dataGroup)
            this_DATA.hDG_parent = dataGroup;
        end
        
        function data = get.writeData(this)

            if isempty(this.hDG_parent) ||...
               isempty(this.hDG_parent.hCG_1stChannelGroup)
               isempty(this.hDG_parent.hCG_1stChannelGroup.hCN_1stChannel)
                % assume no data
                data = [];
                this.dataTypePattern = {};                 
            else
                listOfAllChannels = this.hDG_parent.hCG_1stChannelGroup.hCN_1stChannel.listAllChannels();
                data = zeros(this.hDG_parent.hCG_1stChannelGroup.numberOfChannels,...
                             this.hDG_parent.hCG_1stChannelGroup.numberOfCycles);
                %this.dataTypePattern = {};
                for i =1:numel(listOfAllChannels)
                    % pattern for data-matrix must be:
                    %  t1    t2    t3   ... tn
                    %  a(t1) a(t2) a(3) ...a(tn)
                    %  b(t1) b(t2) b(3) ...b(tn)
                    channel = listOfAllChannels{i};
                    data(i,:) = channel.data;
%                     dataType = 'double';
%                     if isa( channel.data(1), 'single')
%                         dataType = 'single';
%                     end
%                     this.dataTypePattern{i} = dataType;
                    this.dataTypePattern{i} = channel.sigType.getFileWritePrecision();
                end
            end
        end
        
        function rawData = readRawData(this)
            listOfCg = this.parent.hCG_1stChannelGroup.listAllChannelGroups();
            % TODO :ther could be multiple CG in that list -- atm its assumed to be one
            numOfCycles =  listOfCg{1}.numberOfCycles;
            recordLength = listOfCg{1}.recordLength; 
            
            fseek(this.fid, this.fPos, 'bof');
            rawData = uint8(fread(this.fid, [recordLength, numOfCycles], 'uint8')');
            this.rawData = rawData;
        end
        
        
        function print(this, fid)
            data_ = this.writeData;
            if isempty(data_)
                this.fPos = 0;
            else
                this.fPos = ftell(fid);
                
                [numOfSignals, numOfSamples] = size(data_);
                for idxSample = 1:numOfSamples
                    for idxSignal = 1:numOfSignals
                        fwrite(fid, data_(idxSignal, idxSample),   this.dataTypePattern{idxSignal});
                    end
                end
            end
        end
        
        function hTreeNode = getTreeNode(this, pathToThisNode)
            hTreeNode = uitreenode('v0', pathToThisNode, 'Data', ['C:\Apps\MATLAB\R2016b\toolbox\matlab\icons\HDF_object02.gif'], true);
        end
    end % methods
    
    
    methods (Static)
        function dataBlock = read(fid, fPos, parentBlock)
            % default return empty object
            if (fPos == 0)
                dataBlock = MDF_DATA.empty;
                return; 
            end;
            
            dataBlock = MDF_DATA(parentBlock);
            dataBlock.fid = fid;
            dataBlock.fPos = fPos;
            dataBlock.parent = parentBlock;
        end
    end
end

