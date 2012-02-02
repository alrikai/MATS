function [hi_list, lo_list] = gen_proc_file_list(sd)
% Generates a cell array of strings representing the names of files to be
% used, from a source directory.
%
% sd = the source directory
% frmt_index = indicates the file format type:
%   1 - old .mat (e.g., Bravo)
%   2 - .mymat
%   3 - scrub .mat
%   4 - NSWC .mat
% pairs_only = if 1, prunes the lists of files to include only those with
%   all frequencies present

dir_struct = dir([sd,filesep,'IO*.mat']);
hi_list = extract_names(dir_struct);
lo_list = cell(length(hi_list),1);

end

% Get list of names from dir struct
function list = extract_names(dir_struct)
% Extracts the names from the structure that results from using the 'dir'
% function and puts them into a cell array.
list = cell( length(dir_struct),1 );
for k = 1:length(list)
    list{k} = dir_struct(k).name;
end
end