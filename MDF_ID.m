classdef MDF_ID < MDF_BaseClass
    %CNBLOCK
    %   Detailed explanation goes here
    
    properties
        id_kenn = uint8('MDF     ');  % no zero terminator
        id_vers = uint8('3.30    ');  % no zero terminator 
        id_prog = uint8('sim2mdf ');  % no zero terminator 
        id_order = uint16(0);
        id_float = uint16(0);
        id_ver   = uint16(330);
        id_res   = uint16(0);
        id_check = uint8(zeros(1,2));
        id_fill  = uint8(zeros(1,26));
        id_unfin_flags = uint16(0);
        id_custom_unfin_flags = uint16(0); 
        
       % internals: none mdf-structur related
        fid_my;
        
    end % testparameter
    
    methods %( Access = 'protected' )
        function this = print(this, fid)
            % save file position
            this.fPos = ftell(fid);
            % write ID-Block into file
            fwrite(fid, this.id_kenn, 'char*1');
            fwrite(fid, this.id_vers, 'char*1');
            fwrite(fid, this.id_prog, 'char*1');
            fwrite(fid, this.id_order, 'uint16');
            fwrite(fid, this.id_float, 'uint16');
            fwrite(fid, this.id_ver,   'uint16');
            fwrite(fid, this.id_res,   'uint16');
            fwrite(fid, this.id_check, 'uint8');
            fwrite(fid, this.id_fill,  'uint8');
            fwrite(fid, this.id_unfin_flags,        'uint16');
            fwrite(fid, this.id_custom_unfin_flags, 'uint16');
        end
        function fid = get_fid(this)
            fid = this.fid_;
        end
        function hTreeNode = getTreeNode(this, pathToThisNode)
            iconPath = which('HDF_pointfieldset.gif');   
            hTreeNode = uitreenode('v0', pathToThisNode, 'ID', iconPath, true);
        end
    end
    
    methods (Static)
        function idBlock = read(fid)
            fseek(fid, 0 ,'bof');
            % check if this a mdf file
            charPatternAtStart = fread(fid, [1 3] , 'char*1');
            if strcmp(char(charPatternAtStart), 'MDF')
            	idBlock = MDF_ID;
                idBlock.fid = fid;
                fseek(fid, 0 ,'bof');
                idBlock.fPos = 0;
                idBlock.id_kenn  = fread(fid, [1 8], 'uint8');
                idBlock.id_vers  = fread(fid, [1 8], 'uint8');
                idBlock.id_prog  = fread(fid, [1 8], 'uint8');
                idBlock.id_order = fread(fid, [1 1], 'uint16');
                idBlock.id_float = fread(fid, [1 1], 'uint16');
                idBlock.id_ver   = fread(fid, [1 1], 'uint16');
                idBlock.id_res   = fread(fid, [1 1], 'uint16');
                idBlock.id_check = fread(fid, [1 2], 'uint8');
                idBlock.id_fill  = fread(fid, [1 26],'uint8');
                idBlock.id_unfin_flags        = fread(fid, 1, 'uint16');
                idBlock.id_custom_unfin_flags = fread(fid, 1, 'uint16');
            else
                idBlock = MDF_ID.empty; % return empty object
            end
        end
    end
end

