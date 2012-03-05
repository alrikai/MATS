function [cls_desc_params, TB_params] = update_all_cls_desc_params(TB_params, class_list)
% Refreshes all available classifiers' description data, and incorporates data
% from the selected classifier's description file into TB_params. 

if ischar(class_list)
    num_cls = 1;
    sel_index = 1;
else
    num_cls = length(class_list);
    sel_index = TB_params.CLASSIFIER;
end

% Make array of description data
for q = 1:num_cls

    if ischar(class_list)   % single string
        cls_name = class_list;
    else                    % classifier list
        cls_name = class_list{q};
    end

    df_path = fullfile(TB_params.TB_ROOT,'Classifiers',cls_name,'about.txt');

    assert(exist(df_path,'file') > 0,...
        'Description file ''%s'' does not exist for classifier ''%s''',...
        'about.txt', cls_name);
    cls_desc_params{q} = read_desc_file(df_path);
end

% Validity checks on selected module's data

% Module tag
assert(isfield(cls_desc_params{sel_index}, 'module_tag'),...
    'about.txt must contain ''module_tag'' string');

% Feedback flag
assert(isfield(cls_desc_params{sel_index}, 'uses_feedback'),...
    'about.txt must contain ''uses_feedback: (0 or 1)''');
TB_params.TB_FEEDBACK_ON = cls_desc_params{sel_index}.uses_feedback;

% Multiclass
assert(isfield(cls_desc_params{sel_index}, 'multiclass'),...
    'about.txt must contain ''multiclass: (0 or 1)''');
TB_params.MULTICLASS = cls_desc_params{sel_index}.multiclass;
end