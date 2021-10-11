function cb_pb( ObjectH, EventData )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
vars = evalin('base', 'whos');

matches = strcmp({vars.class}, 'MDF_OBJECT');
mdfObjects = {vars(matches).name};

hdd = evalin('base', 'hdd');
set(hdd, 'String', mdfObjects);

end

