function desc_params = read_desc_file(fname)
% Reads a module description file (about.txt)

fid = fopen(fname);
desc_params = struct;

line = fgetl(fid); % first line of file
while ischar(line)
    % Parse data from line
    temp = regexp(line, '(?<param>\w+):[ ]*(?<val>.+)', 'names');
    
    if strcmpi(temp.val,'no') == 1 || str2double(temp.val) == 0
        % Boolean 0
        desc_params.(temp.param) = 0;
    elseif strcmpi(temp.val,'yes') == 1 || str2double(temp.val) == 1
        % Boolean 1
        desc_params.(temp.param) = 1;
    else
        % These are the strings...
        desc_params.(temp.param) = temp.val;
    end
    
    % Read next line from file
    line = fgetl(fid);
end
fclose(fid);
