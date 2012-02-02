function ok = retrain_prep(TB_params, varargin)
% Preparation for classifier retraining

% Determine classifier to be trained
list = cell(size(TB_params.CLS_HANDLES));
for q = 1:length(TB_params.CLS_HANDLES)
    temp = func2str(TB_params.CLS_HANDLES{q});
    list{q} = temp(5:end);
end
[sel,ok] = listdlg('ListString',list,'SelectionMode','single',...
    'PromptString','Choose a classifier to retrain:',...
    'OKString','Retrain','ListSize',[150,300]);
assert(ok == 1, 'Invalid classifier selection.');

c_params = update_cls_desc_params(TB_params, list{sel});
retrain_folder = [TB_params.TB_ROOT,filesep,'Classifiers',filesep,...
    list{sel}];
retrain_fname = ['trn_',list{sel},'.m'];
assert( exist([retrain_folder,filesep,retrain_fname],'file') == 2,...
    'Training function not found.');
% Determine training data to be used
train_dir = uigetdir(TB_params.TB_ROOT,...
    'Choose folder containing training data:');
assert(~isnumeric(train_dir),'Invalid training folder selection.');

if isempty(varargin)
    % ASSEMBLE FEATURES AND GT INFO FROM FOLDER OF I/O FILES

    % Determine list of files to be used in the training folder
    dir_struct_io = dir([train_dir,filesep,'IO*.mat']);
    file_list_io = cell( length(dir_struct_io),1 );
    for k = 1:length(file_list_io)
        file_list_io{k} = dir_struct_io(k).name;
    end

    % Gather the label and feature data from the I/O files
    labels = []; features = [];
    hand = waitbar(0,'Loading Features...');
    skip_file=0;done=0;
    tic
    for k = 1:length(file_list_io)
        file_name_io = file_list_io{k};
        
        try
        load([train_dir,filesep,file_name_io]);
        catch
            display(['Skipping: ', file_name_io]);
            skip_file = 1;
        end
        toc
        if skip_file == 1
        else            
            labels = [labels, arrayfun(@(a) (a.gt),contacts)];
            features = [features, cell2mat(arrayfun(@(a) ({a.features}),contacts))];
        end
        skip_file = 0;
        waitbar(k/length(file_list_io),hand,'Loading Features ... ');
        
        if k >=1 && size(contacts,2) ~=0 && done == 0;
            done=1;
            feature_tag = contacts(1).featureset;
        end
    end
    delete(hand);
    
else
    % FEATURES AND GT INFO ALREADY KNOWN
    %%% ADD INTEGRITY CHECKING
    labels = varargin{1};
    assert(numel(labels) == length(labels), 'labels must be a vector.');
    assert( sum(labels ~= 1 & labels ~= 0), 'labels must be 0 or 1.');
    labels = labels(:)';
    features = varargin{2};
    assert(length(size(features)) == 2, 'features must be a matrix.');
    assert(size(features,2) == length(labels),...
        'length mismatch between labels and features.');
    % Generate feature tag
    list = cell(size(TB_params.FEAT_HANDLES));
    for q = 1:length(TB_params.FEAT_HANDLES)
        temp = func2str(TB_params.FEAT_HANDLES{q});
        list{q} = temp(6:end);
    end
    [sel,ok] = listdlg('ListString',list,'SelectionMode','single',...
        'PromptString','Which feature set is being used?',...
        'OKString','Continue','ListSize',[150,300]);
    assert(ok == 1, 'Invalid feature set selection.');

    f_params = update_feat_desc_params(TB_params, list{sel});
    feature_tag = f_params.module_tag;
    if strcmpi(f_params.feat_mode,'append')
        % also need info from detector...
        list = cell(size(TB_params.DET_HANDLES));
        for q = 1:length(TB_params.DET_HANDLES)
            temp = func2str(TB_params.DET_HANDLES{q});
            list{q} = temp(5:end);
        end
        [sel,ok] = listdlg('ListString',list,'SelectionMode','single',...
            'PromptString','Which detector was used?',...
            'OKString','Continue','ListSize',[150,300]);
        assert(ok == 1, 'Invalid detector selection.');
        d_params = update_det_desc_params(TB_params, list{sel});
        feature_tag = [d_params.module_tag,'+',feature_tag];
    end
end


% Create save filename
save_prefix = ['data_',c_params.module_tag,'_',feature_tag,'_'];
save_ext = '.mat';
[data_fname,path] = uiputfile(...
    {[save_prefix,'*.mat'], ['Training data file (',save_prefix,'*.mat)']},...
    'Save training data as...', [retrain_folder,filesep,save_prefix,'newtrain.mat']);
if length(data_fname) < length([save_prefix,'X',save_ext]) ||...
        ~strcmpi(data_fname(1:length(save_prefix)), save_prefix)
    data_fname = [save_prefix, data_fname];
end
data_fname = [path, data_fname];



% Run training function for the chosen classifier
[junk,temp] = fileparts(retrain_fname); %#ok<*ASGLU>
retrain_handle = str2func(temp);
if ~isdeployed
    trn_path = genpath(retrain_folder);
    addpath(trn_path);
end
ok = retrain_handle(labels, features, data_fname);
if ~isdeployed
    rmpath(trn_path);
end
end