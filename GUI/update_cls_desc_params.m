function [cls_desc_params, TB_params] = update_cls_desc_params(TB_params, class_list)
% Incorporates data from a classifier's description file into TB_params 

if ischar(class_list)   % single string
    cls_name = class_list;
else                    % classifier list
    cls_name = class_list{TB_params.CLASSIFIER};
end

df_path = fullfile(TB_params.TB_ROOT,'Classifiers',cls_name,'about.txt');

assert(exist(df_path,'file') > 0,...
    'Description file ''%s'' does not exist for classifier ''%s''',...
    'about.txt', cls_name);
cls_desc_params = read_desc_file(df_path);

% Module tag
assert(isfield(cls_desc_params, 'module_tag'),...
    'about.txt must contain ''module_tag'' string');

% Feedback flag
assert(isfield(cls_desc_params, 'uses_feedback'),...
    'about.txt must contain ''uses_feedback: (0 or 1)''');
TB_params.TB_FEEDBACK_ON = cls_desc_params.uses_feedback;
end