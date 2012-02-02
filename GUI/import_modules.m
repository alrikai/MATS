function [labels, fcn_handles] = import_modules(tbr,str)
% Imports module data based on the initial tag 'str'.
switch str
    case 'cls'
        cls_dir = [tbr,filesep,'Classifiers'];
    case 'det'
        cls_dir = [tbr,filesep,'Detectors'];
    case 'cor'
        cls_dir = [tbr,filesep,'Contact Correlation'];
    case 'feat'
        cls_dir = [tbr,filesep,'Features'];
    case 'perf'
        cls_dir = [tbr,filesep,'Performance Estimation'];
    otherwise
        error('Unexpected string type')
end

% Get subdirectories
dir_cell = struct2cell( dir(cls_dir) );
subdirs = dir_cell(1,:);
q = 1;
while q <= length(subdirs)
    if sum( subdirs{q}=='.' > 0 )
        subdirs(q) = [];
    else
        q = q + 1;
    end
end

labels = {};
fcn_handles = {};
% Find function names
for q = 1:length(subdirs)
    subdir_cell = struct2cell( dir([cls_dir, filesep, subdirs{q}]) );
    files = subdir_cell(1, :);
    % find files that start with 'str' and are followed by an underscore,
    % the subdirectory name, with a .m or .p extension
    matches = regexp(files, ['^',str,'_',subdirs{q},'\.(m|p)'],'match');
    matches_bool = ~cellfun('isempty',matches);
    file = files(matches_bool);
    if ~isempty(file)
        % add file to list
        labels = [labels; subdirs{q}];
        fcn_handles = [fcn_handles; {str2func( file{1}(1:end-2) )}];
    else
        % no match found; look for HF/BB variants
        [matches,tkns] = regexp(files, ['^',str,'_',subdirs{q},'\_(HF|BB).(m|p)'],...
            'match','tokens','once');
        matches_bool = ~cellfun('isempty',matches);
        files = files(matches_bool);
        tkns = tkns(matches_bool);
        for w = 1:length(files)
            labels = [labels; [subdirs{q},' (',tkns{w}{1},')']];
            fcn_handles = [fcn_handles; {str2func( files{w}(1:end-2) )}];
        end
    end
end
end