function [det_desc_params, TB_params] = update_det_desc_params(TB_params, det_list)
% Incorporates data from a detector's description file into TB_params

if ischar(det_list)   % single string
    det_name = det_list;
else                    % classifier list
    det_name = det_list{TB_params.DETECTOR};
end

df_path = fullfile(TB_params.TB_ROOT,'Detectors',det_name,'about.txt');

assert(exist(df_path,'file') > 0,...
    'Description file ''%s'' does not exist for detector ''%s''',...
    'about.txt', det_name);
det_desc_params = read_desc_file(df_path);

% Module tag
assert(isfield(det_desc_params, 'module_tag'),...
    'about.txt must contain ''module_tag'' string');
end