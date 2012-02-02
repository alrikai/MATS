function confusion_series
% Reads in data from a directory and display a confusion matrix from the data,
clear
% get directory from user
data_dir = uigetdir(pwd,'Select directory with ROC data');
if data_dir == 0, return, end
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

% step through list and collect data for confusion matrix
all_gts = []; all_classes = [];
hand = waitbar(0,'Loading Contacts...');
for k = 1:length(file_list_roc)
    % load next file
    file_name_roc = file_list_roc{k};
    
    try
    load([data_dir,filesep,file_name_roc]);
    catch
        display(['Skipped: ', file_name_roc])
        clear roc_version
        gts = [];
        classes = [];
    end
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
        all_classes = [all_classes, classes(start_of_img:end)]; 
        all_gts = [all_gts, gts(start_of_img:end)]; 
        %%%
    else
        % in the future, just put in the contacts of the image -> add all
        % of them to the running lists
        all_classes = [all_classes, classes(1:end)]; 
        all_gts = [all_gts, gts(1:end)]; 
    end
    waitbar(k/length(file_list_roc),hand,'Loading Contacts ... ');
    
end
delete(hand);

C = confusionmat(all_gts,all_classes,'order',[1 0]);
sprintf('\n\n')
disp('--------------------------------------------')
disp(['- Diagnostic Table ', det_str,'/',cls_str  ' - '])
disp(data_dir);
disp(['- Column Sums are Targets and Non-Targets - '])
disp('--------------------------------------------')
labels{1} = 'Mine';
labels{2} = 'Non-Mine';
disptable(C',labels,labels)

end

function disptable(M, col_strings, row_strings, fmt, spaces)
%DISPTABLE Displays a matrix with per-column or per-row labels.
%   DISPTABLE(M, COL_STRINGS, ROW_STRINGS)
%   Displays matrix or vector M with per-column or per-row labels,
%   specified in COL_STRINGS and ROW_STRINGS, respectively. These can be
%   cell arrays of strings, or strings delimited by the pipe character (|).
%   Either COL_STRINGS or ROW_STRINGS can be ommitted or empty.
%   
%   DISPTABLE(M, COL_STRINGS, ROW_STRINGS, FMT, SPACES)
%   FMT is an optional format string or number of significant digits, as
%   used in NUM2STR. It can also be the string 'int', as a shorthand to
%   specify that the values should be displayed as integers.
%   SPACES is an optional number of spaces to separate columns, which
%   defaults to 1.
%   
%   Example:
%     disptable(magic(3)*10-30, 'A|B|C', 'a|b|c')
%   
%   Outputs:
%        A   B   C
%     a 50 -20  30
%     b  0  20  40
%     c 10  60 -10
%   
%   Author: Jo?o F. Henriques, April 2010


	%parse and validate inputs

	if nargin < 2, col_strings = []; end
	if nargin < 3, row_strings = []; end
	if nargin < 4, fmt = 4; end
	if nargin < 5, spaces = 1; end
	
	if strcmp(fmt, 'int'), fmt = '%.0f'; end  %shorthand for displaying integer values
	
	assert(ndims(M) <= 2, 'Can only display a vector or two-dimensional matrix.')
	
	num_rows = size(M,1);
	num_cols = size(M,2);

	use_col_strings = true;
	if ischar(col_strings),  %convert "|"-delimited string to cell array of strings
		col_strings = textscan(col_strings, '%s', 'delimiter','|');
		col_strings = col_strings{1};
		
	elseif isempty(col_strings),  %empty input; have one empty string per column for consistency
		col_strings = cell(num_cols,1);
		use_col_strings = false;
	end

	use_row_strings = true;
	if ischar(row_strings),  %convert "|"-delimited string to cell array of strings
		row_strings = textscan(row_strings, '%s', 'delimiter','|');
		row_strings = row_strings{1};
		
	elseif isempty(row_strings),  %empty input; have one empty string per row for consistency
		row_strings = cell(num_rows,1);
		use_row_strings = false;
	end
	
	assert(~use_col_strings || numel(col_strings) == num_cols, ...
		'COL_STRINGS must have one string per column of M, or be empty.')
	
	assert(~use_row_strings || numel(row_strings) == num_rows, ...
		'ROW_STRINGS must have one string per column of M, or be empty.')
	
	assert(isscalar(fmt) || (isvector(fmt) && ischar(fmt)), ...
		'Format must be a format string or the number of significant digits (as in NUM2STR).')
	
	
	
	%format the table for display
	
	col_text = cell(num_cols,1);  %the text of each column
	
	%spaces to separate columns
	if use_col_strings,
		blank_column = repmat(' ', num_rows + 1, spaces);
	else
		blank_column = repmat(' ', num_rows, spaces);
	end
	
	for col = 1:num_cols,
		%convert this column of the matrix to its string representation
		str = num2str(M(:,col), fmt);
		
		%add the column header on top and automatically pad, returning a
		%character array
		if use_col_strings,
			str = char(col_strings{col}, str);
		end
		
		%right-justify and add blanks to separate from previous column
		col_text{col} = [blank_column, strjust(str, 'right')];
	end
	
	%turn the row labels into a character array, with a blank line on top
	if use_col_strings,
		left_text = char('', row_strings{:});
	else
		left_text = char(row_strings{:});
	end
	
	%concatenate horizontally the character arrays and display
	disp([left_text, col_text{:}])
	
end
    