classdef MDF_BaseClass < handle
    
properties ( GetAccess = 'public', SetAccess = 'private' )
    id
end

properties ( GetAccess = 'private', SetAccess = 'private' )
    verbose;
end

properties
    fPos;
    parent=[];
end

properties %(Dependent)
    fid;
end
 
methods ( Access = 'protected' )
    function obj = MDF_BaseClass()
        obj.id = MDF_BaseClass.increment();
        obj.verbose = false;
        obj.fPos = {};
    end
    
end

methods ( Static, Access = 'private' )
    function result = increment()
        persistent stamp;
        if isempty( stamp )
            stamp = 0;
        end
        stamp = stamp + uint32(1);
        result = stamp;
    end
end

methods
    function result = valid(obj)
        result = obj.isvalid;
        if isempty(result) % catch empty object
            result = false;
        end
    end
    function hTreeNode = getTreeNode(this, pathToThisNode)
        hTreeNode = uitreenode('v0', pathToThisNode, 'default', [], true);
    end

%     function fid = get_fid(this)
%         if this.parent.isvalid()
%             fid = this.parent.get_fid();
%         else
%             fid = {};
%         end
%     end
end

methods (Static)
    function result = isVerbose(value)
        persistent verboseVal
        if isempty(verboseVal)
            verboseVal = false; 
        end
        if nargin<1
            result = verboseVal;
        else
            verboseVal = value;
        end
    end

end

end % classdef

