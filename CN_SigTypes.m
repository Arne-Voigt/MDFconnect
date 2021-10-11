classdef CN_SigTypes < double
    %CNTYPE_ENUM Summary of this class goes here
    %   Detailed explanation goes here
    

   
   enumeration
      UINT_8       (0)
      UINT_16      (1)
      UINT_32      (2)
      UINT_64      (3)
      INT_8        (4)
      INT_16       (5)
      INT_32       (6)
      INT_64       (7)
      FLOAT        (8)      % 4 bytes (single)
      DOUBLE       (9)      % 8 bytes
      STRING       (10)
      BOOLEAN      (11)
   end
 
   
   enumeration
        VALUE (0)
        TIME  (1)
    end
   
   methods
       
       function bitCount = getBitCountFromDataType(this)
            switch this
                case {CN_SigTypes.BOOLEAN}
                    bitCount = 1;
                case {CN_SigTypes.UINT_8,  CN_SigTypes.INT_8}
                    bitCount = 8;
                case {CN_SigTypes.UINT_16, CN_SigTypes.INT_16}
                    bitCount = 16;
                case {CN_SigTypes.UINT_32, CN_SigTypes.INT_32, CN_SigTypes.FLOAT}
                    bitCount = 32;
                case {CN_SigTypes.UINT_64, CN_SigTypes.INT_64, CN_SigTypes.DOUBLE}
                    bitCount = 64;
                otherwise
                    bitCount = 64;
            end
       end
       
       function sigDataType = getSignalDataType(this)
            switch this
                case {CN_SigTypes.UINT_8, CN_SigTypes.UINT_16, CN_SigTypes.UINT_32, CN_SigTypes.UINT_64, CN_SigTypes.BOOLEAN}
                    sigDataType = uint16(0);    % unsigned integer
                case {CN_SigTypes.INT_8,  CN_SigTypes.INT_16,  CN_SigTypes.INT_32,  CN_SigTypes.INT_64}
                    sigDataType = uint16(1);    % signed integer
                case {CN_SigTypes.FLOAT}
                    sigDataType = uint16(2);
                case {CN_SigTypes.DOUBLE}
                    sigDataType = uint16(3);
                otherwise
                    sigDataType = uint16(99);
            end
       end
       
       
       function precision = getFileWritePrecision(this)
           switch this
               case {CN_SigTypes.UINT_8, CN_SigTypes.BOOLEAN}
                   precision = 'uint8';
               case {CN_SigTypes.UINT_16}
                   precision = 'uint16';
               case {CN_SigTypes.UINT_32}
                   precision = 'uint32';
               case {CN_SigTypes.UINT_64}
                   precision = 'uint64';
               case {CN_SigTypes.INT_8}
                   precision = 'int8';
               case {CN_SigTypes.INT_16}
                   precision = 'int16';
               case {CN_SigTypes.INT_32}
                   precision = 'int32';
               case {CN_SigTypes.INT_64}
                   precision = 'int64';
               case {CN_SigTypes.FLOAT}
                   precision = 'single';
               case {CN_SigTypes.DOUBLE}
                   precision = 'double';                   
               otherwise
                   precision = 'error';
%                    
%            if this == CN_SigTypes.DOUBLE
%                precision = 'double';
%            elseif this == CN_SigTypes.FLOAT
%                precision = 'single';
%            else
%                precision = 'double';
            end
       end
   end
   
   
   
   
   
   methods (Static)
        function type = getTypeFromRead(sigType, bitNumber)
            if sigType == 0 % unsigned int
                if bitNumber <= 8
                    type = CN_SigTypes.UINT_8;
                elseif bitNumber <= 16
                    type = CN_SigTypes.UINT_16;
                elseif bitNumber <= 32
                    type = CN_SigTypes.UINT_32;
                else 
                    type = CN_SigTypes.UINT_64;
                end
            elseif sigType == 1 % signed int
                if bitNumber <= 8
                    type = CN_SigTypes.INT_8;
                elseif bitNumber <= 16
                    type = CN_SigTypes.INT_16;
                elseif bitNumber <= 32
                    type = CN_SigTypes.INT_32;
                else
                    type = CN_SigTypes.INT_64;
                end
            elseif sigType == 2 % single
                    type = CN_SigTypes.FLOAT;
            elseif sigType == 3 % double
                type = CN_SigTypes.DOUBLE;
            elseif sigType == 7 % string
                type = CN_SigTypes.STRING;
            else
                %assert(0==1, 'why why why: string and array not yet implemented!')
                type = CN_SigTypes.DOUBLE;
            end
        end
   end % Static
end

