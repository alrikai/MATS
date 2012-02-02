function h = location(fid, option, where)
%LOCATION Helper function to keep track of the variables.


[fn, per, format] = fopen(fid);
if isempty(fn)
    h = 'Called on invalid fid';
    warning(h)
    return
end

switch lower(option)
    case 'skip'
        h = ftell(fid);
        if 'w' ~= per(1)
            h = '''skip'' called on non-writable fid';
            warning(h);
            return
        end
        A = default('direntrysize');
        count = fwrite(fid, 0, A);
        if (1 ~= (count))
            error('what?')
        end
    case 'put'
        h = ftell(fid);
        if 'w' ~= per(1)
            h = '''put'' called on non-writable fid';
            warning(h);
            return
        end
        status = fseek(fid, where, 'bof');
        if (-1 == status)
            status = fseek(fid, 0, 'bof');
            status = fseek(fid, where, 'bof');
        end
            
        A = default('direntrysize');
        count = fwrite(fid, h, A);
        if (1 ~= (count))
            error('what?')
        end
        status = fseek(fid, h, 'bof');
    case 'read'
        h = ftell(fid);
        if 'r' ~= per(1)
            h = '''read'' called on non-readable fid';
            warning(h);
            return
        end
        status = fseek(fid, where, 'bof');
        
        A = default('direntrysize');
        [h, count] = fread(fid, 1, A);
        if (~isempty(h) && 1 ~= count)
            error('what?')
        end
    otherwise
        error('what?')
end