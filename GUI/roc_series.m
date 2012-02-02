function roc_series
% Reads in data from a directory and display the ROC curve from the data,
% one image at a time throughout a set of iamges
clear
% get directory from user
data_dir = uigetdir(pwd,'Select directory with ROC data');
if data_dir == 0, return, end
% data_dir = uigetdir('H:\TESTBED','Select directory with ROC data');
% load proper files in that directory into a file list
dir_struct_roc = dir([data_dir,filesep,'ROC*.mat']);

file_list_roc = cell( length(dir_struct_roc),1 );
for k = 1:length(file_list_roc)
    file_list_roc{k} = dir_struct_roc(k).name;
end
% get numbers from strings
temp = regexp(file_list_roc, '(\d+)', 'tokens');
sides = regexp(file_list_roc, '(PORT|STBD)', 'tokens');
if isempty(sides{1})
    sides = regexp(file_list_roc, '(port|stbd)', 'tokens');
end
    
a = length(temp); b = length(temp{1});
tag_nums = zeros(a,b);
for q1 = 1:a
    for q2 = 1:b
        tag_nums(q1,q2) = str2double( temp{q1}{q2}{1} );
    end
end
% choose the first chunk that differs among files
use_col = find( tag_nums(1,:) - tag_nums(end,:), 1, 'first');
if isempty(use_col)
    use_col = 1;
end
sort_tags = tag_nums(:,use_col);
for q1 = 1:a
    if strcmp('STBD', sides{q1}{1}{1})
        sort_tags(q1) = sort_tags(q1) + .5;
    end
end
% sort based on this number
[junk, indexes] = sort(sort_tags); %#ok<*ASGLU>
file_list_roc = file_list_roc(indexes);
data = cell(length(file_list_roc),4);

% data = cell(length(file_list_roc),4);

% step through list and process ROC curve for each file
%%% NEW METHOD
all_gts = []; all_classes = []; all_confs = [];
%%%
for k = 1:length(file_list_roc)
    % load next file
    file_name_roc = file_list_roc{k};

       
    load([data_dir,filesep,file_name_roc]);
    % variables 'classes', 'gts', 'confs', 'start_of_img', 'det_name', 
    %   'cls_name', and 'roc_version' are now in memory.
    
    det_str = det_name; cls_str = cls_name;
    
    assert( ~any(gts == -99), 'Error: Selected results do not have groundtruth');
    
    if exist('roc_version', 'var') == 0
        roc_version = 1;
    end
    
    if roc_version <= 1
        %%% NEW METHOD (for old files) - fields in ROC_*.mat contain
        %%% cumulative lists of contacts; must break out proper section to
        %%% handle sets composed of arbitrary images.
        all_classes = [all_classes, classes(start_of_img:end)]; %#ok<COLND>
        all_confs = [all_confs, confs(start_of_img:end)]; %#ok<COLND>
        all_gts = [all_gts, gts(start_of_img:end)]; %#ok<COLND>
        %%%
    else
        % in the future, just put in the contacts of the image -> add all
        % of them to the running lists
        all_classes = [all_classes, classes(1:end)]; %#ok<COLND>
        all_confs = [all_confs, confs(1:end)]; %#ok<COLND>
        all_gts = [all_gts, gts(1:end)]; %#ok<COLND>
    end
    
    skip = 0;
    try
        % calculate ROC data
        if isempty(gts)
            skip = 1;
        else
            
        %%% NEW METHOD
        [x,y,t,auc] = perfcurve(all_gts, all_confs, 1);

        end
    catch ME
        type = regexp(ME.identifier, '(?<=:)\w+$', 'match');
        if strcmp(type, 'NotEnoughClasses') == 1
            fprintf(1, 'Not enough classes @ k = %d...\n',k);
        else
            fprintf(1, '%-s\n', 'Error... ');
            keyboard
        end
        fprintf(1, 'skipping k = %d\n', k);
        skip = 1;
    end
    if skip == 0
        % store ROC data
        data{k,1} = x;
        data{k,2} = y;
        data{k,3} = t;
        data{k,4} = auc;
        ind = find(data_dir == filesep, 1, 'last');
    end
end

figure(102);
plot(x, y, 'linewidth', 2)
title(['ROC curve for ''',data_dir((ind+1):end),''' (',det_str,...
    '/',cls_str,'), images 1:',num2str(k),' (',...
    num2str(length(all_gts)),' contacts)'], 'Interpreter', 'none');
xlabel('False Alarm'); ylabel('Correct');
drawnow

end
    