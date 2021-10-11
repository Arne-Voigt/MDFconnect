classdef MDF_TX < MDF_BaseClass
    %CNBLOCK
    %   Detailed explanation goes here

    properties        
        text;
        size;
    end % testparameter
    
    methods
        function obj = MDF_TX(strText)
            if nargin == 0
                strText = '';
            end
            % limit text length
            obj.text = strText( 1 : min(2^16-1-(4+1),length(strText)));
            obj.size = length(obj.text) + 4 + 1; % 2bytes 'TX' + 2bytes size + 1byte stringTerminator  
        end
        
        function hTreeNode = getTreeNodeTX(this, pathToThisNode, string)
            iconPath = which('HDF_SDS.gif');
            hTreeNode = uitreenode('v0', pathToThisNode, ['TX_',string],  iconPath, true);
            %hTreeNode.UserData = this;
        end
        
        function print(obj,fid)
            obj.fPos = ftell(fid);
            fwrite(fid, 'TX',     'char*1');
            fwrite(fid, obj.size, 'uint16');
            fwrite(fid, obj.text, 'char*1');
            fwrite(fid, 0,        'char*1'); % string terminator
        end
    end % methods
    
    methods (Static)
        function txBlock = read(fid, fPos, parentBlock)
            txBlock = MDF_TX.empty; % default -> return empty object
            if (fPos == 0); return; end;
            
            fseek(fid, fPos ,'bof');
            first4Bytes = fread(fid, 4 , '*uint8');
            
            % check if this a text block
            if any(first4Bytes(1:2)' ~= uint8('TX')); return; end           
 
            % seems legit --> start reading
            txBlock        = MDF_TX;
            txBlock.fid    = fid;
            txBlock.fPos   = fPos;
            txBlock.parent = parentBlock;
            txBlock.size   = max(first4Bytes(3) + first4Bytes(4)*256 - 4, 4);
            %txBlock.text  = fread(fid,  txBlock.size-4, 'char');
            txBlock.text   = fread(fid, [1 txBlock.size-4], '*char');
        end
    end
end

