function [feat_desc_params, TB_params] = update_feat_desc_params(TB_params, feat_list)
% Incorporates data from a feature module's description file into TB_params

if ischar(feat_list)    % single string
    feat_name = feat_list;
else                    % feature set list
    feat_name = feat_list{TB_params.FEATURES};
end

df_path = fullfile(TB_params.TB_ROOT,'Features',feat_name,'about.txt');
    
assert(exist(df_path,'file') > 0,...
    'Description file ''%s'' does not exist for feature set ''%s''',...
    'about.txt', feat_name);
feat_desc_params = read_desc_file(df_path);

% Module tag
assert(isfield(feat_desc_params, 'module_tag'),...
    'about.txt must contain ''module_tag'' string');

% Inverse imaging flag
assert(isfield(feat_desc_params, 'reqs_inv_img'),...
    'about.txt must contain ''reqs_inv_img: (0 or 1)''.');
TB_params.INV_IMG_ON = feat_desc_params.reqs_inv_img;

if TB_params.INV_IMG_ON == 1
    assert(isfield(feat_desc_params, 'inv_img_modes'),...
        'about.txt must contain ''inv_img_mode'' strings.');
    TB_params.INV_IMG_MODES = regexp(feat_desc_params.inv_img_modes, '(hf|HF|bb|BB|lf1|LF1)', 'match');
end

% Background snippet
assert(isfield(feat_desc_params, 'reqs_bg_snippet'),...
    'about.txt must contain ''reqs_bg_snippet: (0 or 1)''.');
TB_params.BG_SNIPPET_ON = feat_desc_params.reqs_bg_snippet;
end