classdef MDF_CD < MDF_BaseClass
    %CCBLOCK
    %   Detailed explanation goes here
    
    properties
    end % testparameter
    
    methods
    end
    
    methods (Static)
        function cdBlock = read(fid, fPos)
            cdBlock = MDF_CD.empty; % return empty object
        end
    end
end

