classdef MDF_TR < MDF_BaseClass
    % stump  for the trigger block
    % may never be implemented
    
    properties        
    end % testparameter
    
    methods
    end % methods
    
    methods (Static)
        function trBlock = read(fid, fPos)
            trBlock = MDF_TR.empty; % return empty object
        end
    end
end

