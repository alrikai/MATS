function write_flag(filename, msg_on)
% Writes a tiny, empty file.  The flag's sole purpose is merely to exist.
% filename = name of the file to be created.
[fid, msg] = fopen(filename, 'w');
if fid == -1
    fprintf(1, 'Error writing flag to ''%s'': %s\n',filename, msg);
else
%     fprintf(1, 'Flag ''%s'' written\n',filename);
end
fclose(fid);
there = exist(filename, 'file') > 0;
if there && msg_on
    disp([filename,' exists!']);
end
end