classdef MDF_CC < MDF_BaseClass
    %CCBLOCK
    %   Detailed explanation goes here
    
    properties
        validPhyRange = 0;
        minPhyRange = 0;
        maxPhyRange = 0;
        phyUnit = char(zeros(1,20));
        formulaId;
        numberFormulaParameter = 0;
        parameterArray = {};
    end % testparameter
    
    methods
        
        function this_CC = MDF_CC(data)
            if isenum(data)
                this_CC.formulaId = 11;
                [m,s] = enumeration(data);
                this_CC.numberFormulaParameter = numel(m);
                for i = 1:numel(m)
                    enumName = s{i};
                    enumName = enumName( 1 : min(31,length(enumName)) ); % limit to maximal 31 characters
                    enumName = char([enumName zeros(1, 32-length(enumName))]); % fill up remaining (to 32 char) with Null-characters
                    this_CC.parameterArray{end+1} = {int32(m(i))    enumName};
                end
            end
                
        end
        
        
        function convData = applyConversion(this, data)
            switch this.formulaId
                case {0}
                    convData = this.linearConv(data);
                case {1}
                    convData = this.tableInterpol(data); 
                case {2}
                    convData = this.table(data);                    
                otherwise
                    % [TODO]
                    %fprintf('CC conversion version not implemented');
                    convData = data;
            end
        end
        
        function convData = linearConv(this, data)
            convData = data * this.parameterArray{2} + this.parameterArray{1};
        end
        
        function convData = tableInterpol(this, data)
            xVector = this.parameterArray{1:2:end-1};
            yVector = this.parameterArray{2:2:end};
            % limit data to xVector range
            dataMinMax = max(data,       xVector(1));
            dataMinMax = min(dataMinMax, xVector(end));
            % interpolate - linear
            convData = interp1(xVector, yVector, dataMinMax, 'linear');   
        end
        
        function convData = table(this, data)
            xVector = this.parameterArray{1:2:end-1};
            yVector = this.parameterArray{2:2:end};
            % limit data to xVector range
            dataMinMax = max(data,       xVector(1));
            dataMinMax = min(dataMinMax, xVector(end));
            % interpolate - linear
            convData = interp1(xVector, yVector, dataMinMax, 'previous');   
        end
        
        function hTreeNode = getTreeNode(this, pathToThisNode)
            iconPath = which('help_fx.png');
            hTreeNode = uitreenode('v0', pathToThisNode, ['CC_conversion'],  iconPath, true);
            %hTreeNode.UserData = this;
        end
        
        function blockLength = getBlockLength(this_CC)
            blockLength = 46; % base byte count till (and including) info of this_CC.numberFormulaParameter 
            switch this_CC.formulaId
                case{0}
                    blockLength = blockLength + this_CC.numberFormulaParameter * 8;
                case{1,2}
                    blockLength = blockLength + this_CC.numberFormulaParameter * 2 *8; % pair of parameter, hence ' * 2'
                case{11}
                    blockLength = blockLength + this_CC.numberFormulaParameter * (8 + 32);
                otherwise
                    % no otherwise
            end
        end
        
        
        function print(this_CC,fid)
            %% save this block file-location
            this_CC.fPos = ftell(fid);
            %% print this channel block
            fwrite(fid, 'CC', 'char*1');
            fwrite(fid, this_CC.getBlockLength(), 'uint16');
            fwrite(fid, this_CC.validPhyRange,    'uint16');
            fwrite(fid, this_CC.minPhyRange,      'double');
            fwrite(fid, this_CC.maxPhyRange,      'double');
            fwrite(fid, this_CC.phyUnit,          'char*1');
            fwrite(fid, this_CC.formulaId,        'uint16');
            fwrite(fid, this_CC.numberFormulaParameter, 'uint16');
            switch this_CC.formulaId
                case{0}
                    fwrite(fid, this_CC.parameterArray{1}, 'double');
                    fwrite(fid, this_CC.parameterArray{2}, 'double');
                case{1,2}
                    for i = 1:this_CC.numberFormulaParameter
                        fwrite(fid, this_CC.parameterArray{(i-1)*2 + 1}, 'double');
                        fwrite(fid, this_CC.parameterArray{(i-1)*2 + 2}, 'double');
                    end
                case{11}
                    for i = 1:this_CC.numberFormulaParameter
                        fwrite(fid, this_CC.parameterArray{i}{1}, 'double');
                        fwrite(fid, this_CC.parameterArray{i}{2}, 'char*1');
                    end
                otherwise
                    % no otherwise
            end
        end
            
         
    end
    
    methods (Static)
        function ccBlock = read(fid, fPos)
            % default return empty object
            ccBlock = MDF_CC.empty;
            %return;
            if (fPos == 0); return; end;
            
            fseek(fid, fPos ,'bof');
            % check if this a conversion block --> return if not
            first6Bytes = fread(fid, 6 , '*uint8');
            if any(first6Bytes(1:2)' ~= uint8('CC')); return; end
            
            % ok, this has to be a valid CC --> start reading
            ccBlock = MDF_CC([]);
            ccBlock.fid = fid;
            ccBlock.fPos = fPos;
            

            ccBlock.validPhyRange  = first6Bytes(5) + first6Bytes(6)*2^16;
            
            blocks_1st = fread(fid, [1 2],  'double');
            
            ccBlock.minPhyRange    = blocks_1st(1);
            ccBlock.maxPhyRange    = blocks_1st(2);
            ccBlock.phyUnit        = fread(fid, [1 20], '*char');
            blocks_2nd = fread(fid, [1 2],  '*int16');
            
            ccBlock.formulaId      = blocks_2nd(1);
            ccBlock.numberFormulaParameter = blocks_2nd(2);
%             if ccBlock.numberFormulaParameter > 10
%                 disp what??
%             end
            % parameters - length can be dynamic
            ccBlock.parameterArray = num2cell(fread(fid, [1 ccBlock.numberFormulaParameter],  'double'));
        end
    end
end

