classdef MDF_PR < MDF_BaseClass
    % stump  for the program specific block
    % may never be implemented
    
    properties        
    end 
    
    methods
    end % methods
    
    methods (Static)
        function prBlock = read(fid, fPos)
            prBlock = MDF_PR.empty; % return empty object
        end
    end
end

