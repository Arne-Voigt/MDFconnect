classdef MDF_CE < MDF_BaseClass
    %CCBLOCK
    %   Detailed explanation goes here
    
    properties
    end % testparameter
    
    methods
    end
    
    methods (Static)
        function ceBlock = read(fid, fPos)
            ceBlock = MDF_CE.empty; % return empty object
        end
    end
end

