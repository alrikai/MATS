function [det_desc_params, TB_params] = update_all_det_desc_params(TB_params, det_list)
% Incorporates data from a detector's description file into TB_params

if ischar(det_list)
    num_det = 1;
    sel_index = 1;
else
    num_det = length(det_list);
    sel_index = TB_params.DETECTOR;
end

% Make array of description data
for q = 1:num_det
    
    if ischar(det_list)   % single string
        det_name = det_list;
    else                    % classifier list
%         det_name = ;
        det_name = regexp(det_list{q},'[ ]*\([^)]*\)','split');
        det_name = det_name{1};
    end
    afn = get_aboutfname(TB_params, q);
    df_path = fullfile(TB_params.TB_ROOT,'Detectors',det_name,afn);

    assert(exist(df_path,'file') > 0,...
        'Description file ''%s'' does not exist for detector ''%s''',...
        afn, det_name);
    det_desc_params{q} = read_desc_file(df_path);
end

% Validity checks on selected module's data

% Module tag
assert(isfield(det_desc_params{sel_index}, 'module_tag'),...
    'about.txt must contain ''module_tag'' string');

% Incremental learning flag
assert(isfield(det_desc_params{sel_index}, 'has_learning'),...
    'about.txt must contain ''has_learning: (0 or 1)''');
TB_params.INCR_DETECTOR = det_desc_params{sel_index}.has_learning;
end
