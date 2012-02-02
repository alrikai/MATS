function [hi_list, lo_list, fullpath] = gen_file_list(sd, frmt_index, pairs_only)
% Generates a cell array of strings representing the names of files to be
% used, from a source directory.
%
% sd = the source directory
% frmt_index = indicates the file format type:
%   1 - old .mat (e.g., Bravo)
%   2 - .mymat
%   3 - scrub .mat
%   4 - NSWC .mat
%   5 - HDF5 (.h5)
%   6 - NURC MUSCLE (.mat)
%   7 - CSDT (.csdt)
%   8 - POND (.mat)
%   9 - PC SWAT (.mat)
% pairs_only = if 1, prunes the lists of files to include only those with
%   all frequencies present

fullpath = '';

switch frmt_index
    case {1,4}  % Bravo||NSWC .mat: all data in one file; 'lo_list' is empty
        dir_struct = dir([sd,filesep,'*.mat']);
        hi_list = extract_names(dir_struct);
        lo_list = cell(length(hi_list),1);
    case 2  % .mymat
        % Get all filenames from HF folder
        dir_struct_hi = dir([sd,filesep,'HF',filesep,'*.mymat']);
        hi_list = extract_names(dir_struct_hi);
        % Get all filenames from LF folder
        dir_struct_lo = dir([sd,filesep,'LF',filesep,'*.mymat']);
        lo_list = extract_names(dir_struct_lo);
        
        hi_tokens = get_tokens(hi_list, '-(\d+)_(\d+)-');
        hi_list = mat_list_sort(hi_list, hi_tokens);
        
        lo_tokens = get_tokens(lo_list, '-(\d+)_(\d+)-');
        lo_list = mat_list_sort(lo_list, lo_tokens);
        
        if pairs_only
            % Make sure that the lists only contains complete pairs
            [hi_list, lo_list] = purge_unpaired(hi_list, lo_list, 'H', 'L');
        end
    case 3  % Scrub .mat
        % Get all filenames from HF folder
        dir_struct_hi = dir([sd,filesep,'Sensor2_EnvB_07Aug11',filesep,'Images',filesep,'*.mat']);
        hi_list = extract_names(dir_struct_hi);
        % Get all filenames from LF folder
        dir_struct_lo = dir([sd,filesep,'Sensor3_EnvB_07Aug11',filesep,'Images',filesep,'*.mat']);
        lo_list = extract_names(dir_struct_lo);
        
        % Extract image numbers to sort by from HF images
        hi_tokens = get_tokens(hi_list,'Image(\d*)_Sensor2.+');
        % Sort list of filenames in order of image number
        hi_list = mat_list_sort(hi_list, hi_tokens);
        
        % Extract image numbers to sort by from LF images
        lo_tokens = get_tokens(lo_list,'Image(\d*)_Sensor3.+'); 
        % Sort list of filenames in order of image number
        lo_list = mat_list_sort(lo_list, lo_tokens);
        
        if pairs_only
            % Make sure that the lists only contains complete pairs
            [hi_list, lo_list] = purge_unpaired(hi_list, lo_list,...
                'Sensor2', 'Sensor3');
        end
    case 5  % HDF5
        % Get all HDF5 filenames
%         dir_struct = dir([sd,filesep,'*.h5']);
%         file_list = extract_names(dir_struct);
        file_list = fuf([sd,filesep,'*.h5'],1,'detail');
        for ii = 1:size(file_list,1)
            tmp = find(file_list{ii} == filesep);
            fullpath{ii} = file_list{ii}(1:tmp(end)-1);
            file_list{ii} = file_list{ii}(tmp(end)+1:end);
        end
        
        % Get all HF filenames
        temp = regexp(file_list,'^.H.+','match');
        boolvec = cellfun(@(a) (~isempty(a)), temp);
        hi_list = file_list(boolvec);
        fullpath = fullpath(boolvec);
        % Sort list of filenames in order of image number
        hi_tokens = get_tokens(hi_list, '[-](\d*)[.]');
        hi_list = mat_list_sort(hi_list, hi_tokens);
        fullpath = mat_list_sort(fullpath, hi_tokens);
        
        % Get all LF filenames
        temp = regexp(file_list,'^.L.+','match');
        boolvec = cellfun(@(a) (~isempty(a)), temp);
        lo_list = file_list(boolvec);
        % Sort list of filenames in order of image number
        lo_tokens = get_tokens(lo_list, '[-](\d*)[.]');
        lo_list = mat_list_sort(lo_list, lo_tokens);
        
        if pairs_only
            % Make sure that the lists only contains complete pairs
            [hi_list, lo_list, mark_hi] = purge_unpaired(hi_list, lo_list, 'H', 'L');
            fullpath =  fullpath(mark_hi == 1);
        end
    case 6 %MUSCLE
%         dir_struct = dir([sd,filesep,'MUSCLE*.mat']);
        file_list = fuf([sd,filesep,'MUSCLE*.mat'],1,'detail');
        for ii = 1:size(file_list,1)
            tmp = find(file_list{ii} == filesep);
            fullpath{ii} = file_list{ii}(1:tmp(end)-1);
            file_list{ii} = file_list{ii}(tmp(end)+1:end);
        end
        hi_list = file_list;
        lo_list = cell(length(hi_list),1);
        hi_tokens = get_tokens(hi_list, '_[ps]_(\d+)_');
        hi_list = mat_list_sort(hi_list, hi_tokens); 
        fullpath = mat_list_sort(fullpath, hi_tokens); 
    case 7 %CSDT all data in one file
        dir_struct = dir([sd, filesep,'*.csdt']);
        hi_list = extract_names(dir_struct);
        lo_list = cell(length(hi_list),1);
    case 8 %POND data these are RAW DATA FILES
        dir_struct = dir([sd, filesep, '*.mat']);
        hi_list = extract_names(dir_struct);
        lo_list = cell(length(hi_list),1);
    case 9  %PC SWAT Imagery
        % Get all filenames from HF folder
        dir_struct_hi = dir([sd,filesep,'HF',filesep,'*HF*.mat']);
        hi_list = extract_names(dir_struct_hi);
        dir_struct_lo = dir([sd,filesep,'LF',filesep,'*LF*.mat']);
        lo_list = extract_names(dir_struct_lo);
    case 10 % MATS input structure
        dir_struct = dir([sd, filesep, '*.mat']);
        hi_list = extract_names(dir_struct);
        lo_list = cell(length(hi_list),1);
    otherwise
        error('Unrecognized file format in file list generator.');
end

end

function tokens = get_tokens(list, regex_str)
% Extract tokens from the list of strings and convert that data into a
% cell array of numbers (as opposed the convoluted nested cell arrays that
% result).
tokens = regexp(list, regex_str,'tokens','once');
for qq = 1:length(tokens)
    tokens{qq} = cell2mat(tokens{qq});
end
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

% Removes files from a list that do not have a counterpart in the other
% list.
function [hi_list, lo_list, mark_hi] = purge_unpaired(hi_list, lo_list,...
    reg_str_hi, reg_str_lo)
% Omits files that do not have a counterpart in the other frequency.
% 'reg_str_xx' is a string that contains the frequency-dependent part of
% the string (i.e., all high frequencies contain reg_str_hi).  The rest of
% the string will be used to determine if an entry has a valid counterpart
% in the other list.
mark_lo = zeros(size(lo_list)); cnt_lo = 1;
mark_hi = zeros(size(hi_list)); cnt_hi = 1;
while cnt_hi <= length(hi_list)
    if cnt_lo > length(lo_list)
        % hi is not in low list: inc. hi, reset lo
        cnt_lo = 1;
        cnt_hi = cnt_hi + 1;
        continue
    end
    rest_hi = cell2mat( regexp(hi_list{cnt_hi}, reg_str_hi,'split') );
    rest_lo = cell2mat( regexp(lo_list{cnt_lo}, reg_str_lo,'split') );
    if strcmp(rest_hi, rest_lo) == 1
        % hi matches lo entry: mark locations in lists, inc. hi,
        % and reset lo
        mark_hi(cnt_hi) = 1;
        mark_lo(cnt_lo) = 1;
        cnt_hi = cnt_hi + 1;
        cnt_lo = 1;
    else
        % hi does not match lo entry: try next lo entry
        cnt_lo = cnt_lo + 1;
    end
end
lo_list = lo_list(mark_lo == 1);
hi_list = hi_list(mark_hi == 1);
end

% Sort list of files by image number
function sorted_list = mat_list_sort(list, tokens)
% Purge list of empty cells
z = 1;
while z <= length(list)
    if isempty( list{z} )
        list(z) = [];
        tokens(z) = [];
    else
        z = z + 1;
    end
end
% Convert data extracted from the tokens into the image numbers
nums = zeros(size(tokens));
for tkn_cnt = 1:length(tokens)
    nums(tkn_cnt) = str2double(tokens{tkn_cnt});
end
% Sort the list based on these image numbers
[junk, num_index] = sort(nums); %#ok<*ASGLU>
sorted_list = list(num_index);
end