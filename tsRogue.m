classdef tsRogue < handle
    %TSBUCKET Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Data;
        Time;
        Name;
    end
    
    methods
        function plot(this)
            plot (this.Time, this.Data);
        end
    end
    
    
end

