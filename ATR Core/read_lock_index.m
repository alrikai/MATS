function lock_ind = read_lock_index(filename, show_details)
% Reads the index of the last locked contact, which is stored at the very
% beginning of the file given by the input parameter.
%
% Derek Kolacinski, NSWC PC (derek.kolacinski@navy.mil)
% Last update: 25 May 2010


fid = fopen(filename,'r');
if fid == -1
    % error reading file... assume it does not exist
    lock_ind = 0;
else
    % okay file
    lock_ind = fread(fid, 1, 'uint16');
    fclose(fid);
end
if show_details == 1
    fprintf(1, ' Last locked contact index %d stored.\n',lock_ind);
end
end