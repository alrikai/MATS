function [perf_out, contacts] = atr_testbed_altfb(input_struct,...
    prev_contacts, varargin)
% Processes ATR for one hf/bb image pair of data
%
% INPUTS:
% input_struct  = input structure containing the images and other data
% prev_contacts = contact list of all previous contacts
%
% OUTPUTS:
% perf_out = output structure containing estimated performance information
% contacts = array of contact structures representing potential targets in
% this image
%
% Fields of structs are further specified in documentation.
%
% Derek Kolacinski, NSWC PC (derek.kolacinski@navy.mil)
% Last update: 20 Dec 2011

% Get testbed parameters (Default set will be used if optional
% configuration struct not present.)
if isempty(input_struct)    % reclassification
    [TB_params, TBp_ok, tim_dir] = get_params(varargin, '');
else
    [TB_params, TBp_ok, tim_dir] = get_params(varargin, input_struct);
end
if TBp_ok == 1
    disp('Using manual initial configuration...');
end

% Add subdirectories to path (not needed when compiled b/c everything is
% already included.)
% if ~isdeployed
%     tic
%     addpath(TB_params.TB_ROOT);
%     addpath(genpath([TB_params.TB_ROOT,filesep,'ATR Core']));
%     toc
%     display('AGAIN')
% end
% keyboard
tic; timings = 0;               % Initialize timing data
perf_out = []; contacts = [];   % Initialize outputs

%%%%%%%%%%%%%%%%%%%%%%%%%% BEGIN ATR PROCESSING %%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(input_struct) == 0   % if there is an image to process...
    %%% 1.) LAUNCH PERFORMANCE ESTIMATION (Through-the-sensor model)
    if TB_params.SKIP_PERF_EST == 1 || input_struct.mode == 'A'
        fprintf(1,'Performance estimation bypassed.\n');
    else
        fprintf(1,'Estimating expected performance...\n');
        hperf = TB_params.PERF_HANDLES{TB_params.PERFORMANCE};
        temp = func2str(hperf);
        if ~isdeployed
            perf_paths = genpath([TB_params.TB_ROOT,filesep,...
                'Performance Estimation',filesep,temp(6:end)]);
            addpath(perf_paths);
        end
        perf_out = hperf(input_struct);
        if ~isdeployed
            rmpath(perf_paths);
        end
    end
    % Timing info
    timings = timing_sub(timings);

    % Skip ATR switch (run performance estimation only)
    if input_struct.mode == 'P', return, end;
    
    %%% 2.) LAUNCH DETECTOR
    if TB_params.SKIP_DETECTOR == 1
        % Skip running detector and use precalculated results instead.
        addpath(TB_params.PRE_DET_RESULTS); % run even if deployed
        [junk, iofile] = fileparts(input_struct.fn);         %#ok<*ASGLU>
        pdr_fname = ['IO_',iofile,'_',upper(input_struct.side)];
        [new_contacts, new_ecdata] = load_old_results(pdr_fname);
    else % Run detector as planned...
        % get detector function handle
        hdet = TB_params.DET_HANDLES{TB_params.DETECTOR};
        if ~isdeployed
            % add necessary folders to path
            det_paths = get_detpaths(TB_params);
            addpath(det_paths);
        end
        % run detector
        fprintf(1,'Launching detector (%s)...\n',func2str(hdet));
        [new_contacts, new_ecdata] = hdet(input_struct);
        if ~isdeployed
            % remove folders from path (to prevent overload conflicts)
            rmpath(det_paths);
        end

    end
    % Timing info
    timings = timing_sub(timings);
else                    % input_struct is empty...
    new_contacts = struct([]);
    new_ecdata = struct([]);
    perf_out = struct([]);
end

if TB_params.TB_HEAVY_TEXT == 1
    fprintf(1, ' Size of new_contacts: %d\n', size(new_contacts));
end

%%% 3.) OPTIONAL MODULES
new_ofdata = struct([]); % optional field data
%%% 3a.) LAUNCH INVERSE IMAGING
if TB_params.INV_IMG_ON == 1
    if ~isdeployed
        ii_paths = genpath([TB_params.TB_ROOT,filesep,'AC Prep']);
        addpath(ii_paths);
    end
    if ~isempty(new_contacts)
        if strcmp(input_struct.sensor,'MUSCLE')
            TB_params.INV_IMG_MODES = {'hf'};
        end;
    end;
    for q = 1:length(TB_params.INV_IMG_MODES)
        fprintf(1, 'Launching inverse imaging module (%s)...\n',...
            TB_params.INV_IMG_MODES{q});
        new_ofdata = acprep(new_contacts, new_ecdata, new_ofdata, TB_params.INV_IMG_MODES{q});
    end
    if ~isdeployed
        rmpath(ii_paths);
    end
    % Timing info
    timings = timing_sub(timings);
end

%%% 3b.) GET BACKGROUND SNIPPETS
if TB_params.BG_SNIPPET_ON == 1
    for q = 1:length(new_contacts)
        [new_ofdata(q).bg_snippet, new_ofdata(q).bg_offset] = ...
            make_bg_snippet(new_contacts(q).x, new_contacts(q).y, ...
            401, 401, input_struct.hf, new_contacts);
    end
    % Timing info
    timings = timing_sub(timings);
end

%%% 4.) LAUNCH FEATURES
hfeat = TB_params.FEAT_HANDLES{TB_params.FEATURES};
temp = func2str(hfeat);
fprintf(1, 'Launching feature module (%s)...\n', temp);
if ~isdeployed
    feat_paths = genpath([TB_params.TB_ROOT,filesep,'Features',...
        filesep,temp(6:end)]);
    addpath(feat_paths);
end
new_contacts = hfeat(new_contacts, new_ecdata, new_ofdata); % Keep 1 output b/c Feature module should only be writing to contacts.features.
if ~isdeployed
    rmpath(feat_paths);
end
% Timing info
timings = timing_sub(timings);

% Sort contacts in 'chronological' order (i.e., in the manner of a
% waterfall plot)
[new_contacts, new_ecdata] = sort_contacts(new_contacts, new_ecdata);

if TB_params.TB_FEEDBACK_ON == 1
    %%% 5.) READ BACKUP
    fprintf(1, '%-s\n', 'Loading previous contacts...');
    wait_if_flag({[TB_params.TB_ROOT,filesep,'bkup_atr_busy.flag'];...
        [TB_params.TB_ROOT,filesep,'bkup_gui_busy.flag']});
    % code is now free to edit the backup file
    
    % write flag (blue)
    write_flag([TB_params.TB_ROOT,filesep,'bkup_atr_busy.flag'], TB_params.FLAG_MSGS_ON);
    % read locked and unlocked backup files
    prev_contacts = read_backups(TB_params.L_BKUP_PATH, TB_params.U_BKUP_PATH, TB_params.TB_HEAVY_TEXT); 
    % Load the index of the last locked contact during the prior run
    % (stored in first slot of backup file)
    lastlock_index_old = read_lock_index(TB_params.U_BKUP_PATH, TB_params.TB_HEAVY_TEXT);
    % Timing info
    timings = timing_sub(timings);

    %%% 6.) READ FEEDBACK FILE
    fprintf(1, '%-s\n', 'Reading feedback from file...');
    % wait for all clear
    wait_if_flag([TB_params.TB_ROOT,filesep,'opfb_atr_busy.flag']);
    % code is now free to edit the feedback file...
    
    % write flag (green)
    write_flag([TB_params.TB_ROOT,filesep,'opfb_atr_busy.flag'], TB_params.FLAG_MSGS_ON);
    % Read feedback file
    [op_mods] = read_feedback(TB_params.FEEDBACK_PATH, TB_params.TB_HEAVY_TEXT);
    if TB_params.TB_HEAVY_TEXT == 1
        temp_str = cellfun(@(a) (a.type), op_mods);
        fprintf(1,' Total number of changes from feedback: %d mods (%s)\n',...
            length(op_mods),temp_str);
    end
    % Timing info
    timings = timing_sub(timings);

    %%% 7.) UPDATE CONTACTS WITH FILE DATA AND DELETE FEEDBACK FILE
    fprintf(1, 'Updating contact list with file data...\n');
    fprintf(1, ' (%d op_mods to apply)', length(op_mods));
    % start with previous contact struct
    % (i.e., prev_contacts exists)
   
   % apply all feedback changes
	if ~isempty(op_mods)
    prev_contacts = apply_op_mods(prev_contacts, op_mods,...
        TB_params);
	end

    % delete the feedback file
    if exist(TB_params.FEEDBACK_PATH, 'file') == 2
        delete(TB_params.FEEDBACK_PATH);
    end
    reset_opfile_cnt(TB_params.TB_ROOT);
    % delete flag (green)
    delete_flag([TB_params.TB_ROOT,filesep,'opfb_atr_busy.flag'], TB_params.FLAG_MSGS_ON);
    
    if TB_params.TB_HEAVY_TEXT == 0
        fprintf(1, '%-s\n','');
    end
    % Timing info
    timings = timing_sub(timings);
else % TB_FEEDBACK_ON == 0
    % just use prev_contacts as it is
end % end if TB_FEEDBACK_ON == 1...

for k = 1:length(new_contacts)
    % add ID field to data structures
    temp = length(prev_contacts) + k;
    new_contacts(k).ID = temp;
    new_ecdata(k).ID = temp;
    % add filename strings to contacts
    new_contacts(k).ecdata_fn = [TB_params.ECD_DIR,filesep,'contact_',num2str(temp),'.ecd'];
end

%%% 8.) CONCATENATE NEW CONTACTS ONTO CONTACT LIST
fprintf(1, '%-s\n', 'Concatenating contact list...');
new_img_ind = length(prev_contacts) + 1;
if isempty(new_contacts) == 0       % new_contacts contains data
    if isempty(prev_contacts) == 0  % prev_contacts contains data
        contacts = [prev_contacts, new_contacts];
    else                            % prev_contacts is empty
        contacts = new_contacts;
    end
else                                % new_contacts is empty
    contacts = prev_contacts;
end
clear new_contacts prev_contacts
if TB_params.TB_HEAVY_TEXT == 1
    fprintf(1, ' New image starts at : %d\n', new_img_ind);
    fprintf(1, ' Size of contacts: %d\n', size(contacts));
end
% Determine the last contact that the operator has evaluated
lastlock_index = find_last_locked(contacts, TB_params.TB_HEAVY_TEXT);
lastview_index = find_last_viewed(contacts, new_img_ind, TB_params.TB_HEAVY_TEXT);
if TB_params.TB_HEAVY_TEXT == 1
    fprintf(1, ' Last locked index: %d\n', lastlock_index);
    fprintf(1, ' Last viewed index: %d\n', lastview_index);
end
% Timing info
timings = timing_sub(timings);

%%% 9.) LAUNCH CLASSIFIER MODULE
if isempty(contacts) == 0
    % Isaac's classifier doesn't need to run on contacts it has already
    % classified, so don't pass those into the classifier.
    hcls = TB_params.CLS_HANDLES{TB_params.CLASSIFIER};
    if any( strcmp( func2str(hcls), {'cls_Isaacs','cls_Test', 'cls_Test_multi'} ) ) == 1
         % start where this image would begin
        first_index = new_img_ind;
    else
        first_index = 1;
    end
    last_index = length(contacts);
    if ~isdeployed
        % add necessary folders to path
        cls_paths = get_clspaths(TB_params);
        addpath(cls_paths);
    end
    % run classifier
    fprintf(1,'Launching classifier (%s)...\n',func2str(hcls));
    contacts_after = hcls(contacts(first_index:last_index),...
        TB_params.CDATA_FILES{TB_params.CLASS_DATA});
    contacts(first_index:last_index) = contacts_after;
    if ~isdeployed
        % remove folders from path (to prevent overload conflicts)
        rmpath(cls_paths);
    end    
else
    fprintf(1, '%-s\n', 'Skipping classifier (no contacts)...');
end
% Timing info
timings = timing_sub(timings);

if TB_params.TB_FEEDBACK_ON == 1
    %%% 10.) WRITE CONTACT LIST BACKUPS
    fprintf(1, 'Saving contact list backups...\n');
    % append newly locked contacts
    write_backups(contacts, lastlock_index_old, lastlock_index,...
        TB_params.L_BKUP_PATH, TB_params.U_BKUP_PATH, TB_params.TB_HEAVY_TEXT);
    
    % Delete flag (blue)
    delete_flag([TB_params.TB_ROOT,filesep,'bkup_atr_busy.flag'], TB_params.FLAG_MSGS_ON);
    % Timing info
    timings = timing_sub(timings); %#ok<NASGU>
end

%%% 11.) WRITE EXTRA CONTACT DATA
% DK: keep this outside of if-branch.  Otherwise, snippets etc. will no
% longer be accessible unless MATS is running in feedback mode.
write_all_ecdata(contacts, new_ecdata);
write_all_ofdata(contacts, new_ofdata);

%%% 12.) UPDATE STOPLIGHT STATUS
if ~isempty(input_struct)
num_mines = 0;
for qq = 0:((new_img_ind-1)-1)
    num_mines = num_mines + contacts(end - qq).class;
end
temp = isfield(perf_out,'ATRstatus');
if temp && strcmpi(perf_out.ATRstatus, 'R') || num_mines > 10
    perf_out.ATRstatus = 'R';
elseif temp && strcmpi(perf_out.ATRstatus, 'Y') || num_mines > 5
    perf_out.ATRstatus = 'Y';
elseif temp
    perf_out.ATRstatus = 'G';
end
end

%%% Save timing info
if ~isempty(input_struct) && TBp_ok == 0 % not for NSAM
    [junk, f] = fileparts(input_struct.fn);
    if ~isempty(tim_dir)
        tim_fname = [tim_dir,filesep,'TIM_',f,'_',input_struct.side,'.mat'];
        save(tim_fname, 'timings');
    end
end

end

function det_paths = get_detpaths(TB_params)
% Get all folder paths for a given detector.
hdet = TB_params.DET_HANDLES{TB_params.DETECTOR};
temp = func2str(hdet);
if strcmpi( temp((end-1):end),'HF' ) == 1 ...
        || strcmpi( temp((end-1):end),'BB' )
    det_folder = temp(5:(end-3));
else
    det_folder = temp(5:end);
end
det_paths = genpath([TB_params.TB_ROOT,filesep,'Detectors',filesep,det_folder]);
end

function cls_paths = get_clspaths(TB_params)
% Get all folder paths for a given classifier.
hcls = TB_params.CLS_HANDLES{TB_params.CLASSIFIER};
temp = func2str(hcls);
if strcmpi( temp((end-1):end),'HF' ) == 1 ...
        || strcmpi( temp((end-1):end),'BB' )
    cls_folder = temp(5:(end-3));
else
    cls_folder = temp(5:end);
end
cls_paths = genpath([TB_params.TB_ROOT,filesep,'Classifiers',filesep,cls_folder]);
end

function t = timing_sub(t)
t = [t, toc];
fprintf(1, '%-s\n\n', ['Time elapsed in this step: ',...
    num2str( t(end)-t(end-1) ), ' sec']);
end

function prev_contacts = apply_op_mods(prev_contacts, op_mods, TB_params)
% Apply each op_mod update in sequence
A_cnt = 0; O_cnt = 0; M_cnt = 0;
for q = 1:length(op_mods)
    msg = op_mods{q};
    if strcmp(msg.type,'V') == 1        % verified a contact
        prev_contacts = apply_op_update(prev_contacts, msg, TB_params);
        c_ind = find_ID_index(msg, prev_contacts);
        op_mine = msg.data.opconf >= 4;
        cls_mine = prev_contacts(c_ind).class;
        if op_mine == cls_mine  % classifier agrees with operator/GT
            O_cnt = O_cnt + 1;  % okay
        else
            M_cnt = M_cnt + 1;  % misclassified
        end
    elseif strcmp(msg.type,'A') == 1	% added a contact
        prev_contacts = apply_op_add(prev_contacts, msg, TB_params);
        A_cnt = A_cnt + 1;
    else
        disp('Invalid mod type');
    end
end

% if TBp_ok == 0 % not for NSAM
% %%% record test
% fprintf(1,'\nRecent Feedback: Added: %d Okay: %d Misclassified: %d\n',...
%     A_cnt, O_cnt, M_cnt);
% if exist([TB_params.TB_ROOT,filesep,'perf.mat'],'file') == 2
%     load('perf','A','O','M');
% else
%     A = []; O = []; M = [];
% end
% A = [A, A_cnt]; O = [O, O_cnt]; M = [M, M_cnt];
% save('perf', 'A','O','M');
% end
end

function k = find_ID_index(update, c_list)
% Find the index of the contact featured in 'update' within 'c_list'.
% In most situations, this should bring you right to the proper index.  If 
% a contact has been manually added, the contact that you're looking for
% might be a few contacts later, but you won't have to search through the
% whole list...
up_ind = update.est_index; temp_done = 0;
while up_ind <= length(c_list)+1 && temp_done == 0
    if up_ind == length(c_list)+1
        disp('Feedback update unable to be performed; expected ID not found.')
%             keyboard;
        return
    end
    if update.data.ID == c_list(up_ind).ID
        % ID of change file entry matched ID of list contact
        k = up_ind; temp_done = 1;
    end
    up_ind = up_ind + 1;
end
end

function prev_contacts = apply_op_update(prev_contacts, update,...
        TB_params)
% Processes an update message from the feedback file
%
% prev_contacts = contact list
% update = update structure (contains data, type, est_index)

dispmod = 10; % This exists somewhere else too; maybe move to TB_params?

    % Find the location of the contact that this update applies to
    k = find_ID_index(update, prev_contacts);
    
    % k is the index of the update
    % if everything matches...
    if strcmpi(update.data.fn, prev_contacts(k).fn) == 1 ...
            && strcmpi(update.data.side, prev_contacts(k).side) == 1 ...
            && update.data.x == prev_contacts(k).x ...
            && update.data.y == prev_contacts(k).y
        % ...update opconf and opdisplay
        prev_contacts(k).opfeedback.opconf = update.data.opconf;
        prev_contacts(k).opfeedback.opdisplay = update.data.opdisplay;
        prev_contacts(k).opfeedback.type = update.data.type; 
        if TB_params.TB_HEAVY_TEXT == 1
            fprintf(1,' Updating contact #%d (ID#%d) opconf to %d and opdisplay to %d\n',...
                k, prev_contacts(k).ID, update.data.opconf, update.data.opdisplay);
        else
            fprintf(1,'%-s','V');
        end

        % back fill if interpreting no operator comment as implicit
        % agreement with classifications
        if TB_params.OPCONF_MODE == 1
            prev_contacts = backfill_opdata(prev_contacts, k);
        else
            % what has been read from the feedback file is all that is
            % known for sure...
        end
        
        % start at location immediately prior to this contact (k-1) and
        % mark all contacts with a display value of zero as processed until
        % you reach one with a nonzero value
        k_back = k-1; temp_done_back = 0;
        while k_back > 0 && temp_done_back == 0
            k_opdisp = prev_contacts(k_back).opfeedback.opdisplay;
            k_opconf = prev_contacts(k_back).opfeedback.opconf;
            if k_opdisp > 0 && k_opconf == 0
                % skipped case
                prev_contacts(k_back).opfeedback.opdisplay = k_opdisp - 15;
                k_back = k_back - 1;
            else
                temp_done_back = 1;
            end
        end
%                     keyboard
    else
        disp(' Update coords. do not match existing contact coords....');
%     keyboard
    end
% end
end

function prev_contacts = apply_op_add(prev_contacts, add,...
        TB_params)
% Processes an add message from the feedback file.

% det_paths = get_detpaths(TB_params);
% addpath(det_paths);

dispmod = 10;
% Find proper index of contact to update
k = add.est_index;
% k is the estimated index of the update
% if everything matches...
if add.data.ID == prev_contacts(k).ID
    fprintf(1,'Contact est. @ %d has already been added\n',k);
else
    % Create new contact
    new_cont = struct;
    new_ecdata = struct;
    new_cont.ID          = add.data.ID;
    new_ecdata.ID = add.data.ID;
    new_cont.x           = add.data.x;
    new_cont.y           = add.data.y;
    new_cont.fn          = add.data.fn;
    new_cont.side        = add.data.side;
    new_cont.gt          = 1; % operator is basically ground truthing the data

    
%%% ecdata fields
    new_ecdata.sensor      = add.data.sensor;
    new_ecdata.detscore    = -99;
    new_ecdata.hfsnippet   = add.data.hfsnippet;
    new_ecdata.bbsnippet   = add.data.bbsnippet;
    new_ecdata.lf1snippet  = add.data.lf1snippet;
    new_ecdata.lat         = add.data.lat;
    new_ecdata.long        = add.data.long;
    new_ecdata.heading     = add.data.heading;
    new_ecdata.time        = add.data.time;
    new_ecdata.alt         = add.data.alt;
    new_ecdata.hf_ares     = add.data.hf_ares;
    new_ecdata.hf_cres     = add.data.hf_cres;
    new_ecdata.hf_anum     = add.data.hf_anum;
    new_ecdata.hf_cnum     = add.data.hf_cnum;
    new_ecdata.bb_ares     = add.data.bb_ares;
    new_ecdata.bb_cres     = add.data.bb_cres;
    new_ecdata.bb_anum     = add.data.bb_anum;
    new_ecdata.bb_cnum     = add.data.bb_cnum;
    new_ecdata.lf1_ares    = add.data.lf1_ares;
    new_ecdata.lf1_cres    = add.data.lf1_cres;
    new_ecdata.lf1_anum    = add.data.lf1_anum;
    new_ecdata.lf1_cnum    = add.data.lf1_cnum;
    new_ecdata.veh_lats    = add.data.veh_lats;
    new_ecdata.veh_longs   = add.data.veh_longs;
    new_ecdata.veh_heights = add.data.veh_heights;

%%% Old optional fields
%     new_cont.bg_snippet = add.data.bg_snippet;
%     new_cont.bg_offset = add.data.bg_offset;
%     new_cont.hfraw = add.data.hfraw;
%     new_cont.bbraw = add.data.bbraw;
%     new_cont.lb1raw = add.data.lb1raw;
%     new_cont.hfac = add.data.hfac;
%     new_cont.bbac = add.data.bbac;
%     new_cont.lb1ac = add.data.lb1ac;
    
    new_cont.normalizer = add.data.normalizer;
    %%%
    
    new_cont.class       = -99;
    new_cont.type        = -99;
    new_cont.classconf   = -99;
    new_ecdata.groupnum    = -99;
    new_ecdata.groupconf   = -99;
    new_ecdata.grouplat    = -99;
    new_ecdata.grouplong   = -99;
    new_ecdata.groupcovmat = [];
    new_cont.detector    = 'Manual';
    new_cont.featureset  = '';
    new_cont.classifier  = '';
    new_cont.contcorr    = '';
    new_cont.opfeedback.opdisplay  = add.data.opdisplay - dispmod;
    new_cont.opfeedback.opconf  = add.data.opconf;
    new_cont.opfeedback.type  = add.data.type;
    % DK: This prevents a feature mismatch, but we'll need to fill in the
    % features properly later. %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if strcmpi( prev_contacts(1).detector, 'CCA' ) == 1 && ...
            strcmpi( prev_contacts(1).classifier, 'JI1' ) == 1
    new_cont.features = feature_snippet(new_ecdata.hfsnippet, new_ecdata.bbsnippet);
    else
        new_cont.features = [];
    end
    
    % Write ecdata file
    temp_fn = [TB_params.ECD_DIR,filesep,'contact_',num2str(new_cont.ID),'_man.ecd'];
    write_extra_cdata(temp_fn, new_ecdata);
    new_cont.ecdata_fn = temp_fn;
    
    % Insert new contact into the at position k 
    prev_contacts = [prev_contacts(1:(k-1)), new_cont,...
        prev_contacts(k:end)];
    if TB_params.TB_HEAVY_TEXT == 1
%         disp([' Inserting ID#',num2str(add.data.ID),...
%             '''s contact @ index ',num2str(k)]);
        fprintf(' Inserting ID#%d''s contact @ index %d\n',add.data.ID,k);
    else
        fprintf(1,'%-s','A');
    end
        
    % start at location immediately prior to this contact (k-1) and
    % mark all contacts with a display value of zero as processed until
    % you reach one with a nonzero value
    k_back = k-1; temp_done_back = 0;
    while k_back > 0 && temp_done_back == 0
        if prev_contacts(k_back).opfeedback.opdisplay == 0
            prev_contacts(k_back).opfeedback.opdisplay = ...
                prev_contacts(k_back).opfeedback.opdisplay - dispmod;
            prev_contacts(k_back).opfeedback.opconf = 0; %%%%
            k_back = k_back - 1;
        else
            temp_done_back = 1;
        end
    end
end
% rmpath(det_paths);
end

function prev_contacts = backfill_opdata(prev_contacts, k)
% Fills in operator data for past, unviewed mines.
% k = index of current viewed mine
w = k - 1; % temp index starting at contact before current
while w > 0 && prev_contacts(w).opfeedback.opdisplay >= 0
    switch prev_contacts(w).opfeedback.opdisplay
        case 0      % not a mine
            prev_contacts(w).opfeedback.opconf = 1;
            prev_contacts(w).opfeedback.opdisplay = -10;
        case 1      % mine
            prev_contacts(w).opfeedback.opconf = 5;
            prev_contacts(w).opfeedback.opdisplay = -9;
        case 2      % maybe a mine
            prev_contacts(w).opfeedback.opconf = 3;
            prev_contacts(w).opfeedback.opdisplay = -8;
    end
    w = w - 1;
end
end

function [params, ok, tim_dir] = get_params(ins, input_struct)
% make default parameter set
tbr = fileparts(mfilename('fullpath'));
ok = 0;
if length(ins) >=1 && isstruct(ins{1})
    % first extra parameter is possibly valid TB_params structure
    temp = ins{1};
else
    temp = [];
end
if length(ins) >= 2 && ischar(ins{2})
    tim_dir = ins{2};
else
    tim_dir = [];
end
%%% CONFIGURATION PARAMETERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TB_HEAVY_TEXT: toggles more detailed printed statements
%   0 = off; 1 = on
% DEBUG_MODE: 
%   1 = saves input file with outputs; 0 = doesn't
% FLAG_MSGS_ON: toggles messages regarding the existence of control flags
%   0 = off; 1 = on
% MAN_ATR_SEL: enable manual detector/classifier selection
%   1 = use detector and classifier selelcted by user
%   0 = use default detector and classifier based on the target type
% DETECTOR: index of detector to be used from detector list DET_HANDLES
% CLASSIFIER: index of classifier to be used from classifier list CLS_HANDLES
% DET_HANDLES: list of valid detector handles
% CLS_HANDLES: list of valid classifier handles
% TB_ROOT: root directory of the ATR Testbed
% SKIP_DETECTOR: bypasses the detector and uses saved results (for dev)
%   0 = off; 1 = on
% SKIP_PERF_EST: bypasses the performance estimation
%   0 = off; 1 = on
% SKIP_FEEDBACK: feedback mode
%   0 = use feedback stub GUI
%   1 = simulate operator feedback with saved archive file
%   2 = skip feedback completely (e.g., for normal classifier)
%   3 = use GT values for operator calls
% ARCH_FEEDBACK: toggles archival of operator feedback
%   0 = off; 1 = on
% TB_FEEDBACK_ON: toggles code related to feedback
%   0 = off; 1 = on
% OPCONF_MODE:
%   0 = every contact is confirmed/rejected by the operator
%   1 = interpret no operator comment as implicit agreement
%   2 = only use explicit operator calls (don't assume agreement)
% % Options (0) and (2) are functionally similar except that in (2) contacts
% % can be skipped.  In (1), after loading the saved information from the
% % feedback file, the code will then try to fill in the gaps based on the
% % expected operator response in order to try to get more data to the
% % feedback classifier.
% FEEDBACK_PATH: file location of the feedback file
% OPARCHIVE_PATH: file location of the operative archive
% L_BKUP_PATH: file location of the locked backup/storage file
% U_BKUP_PATH: file location of the unlocked backup/storage file
% MAN_ATR_SEL: manual ATR component selection
%   1 = user can manually select which detector and classifier he wants
%   0 = testbed uses defaults based on target type
% PLOTS_ON: enables plots after each image
%   0 = off; 1 = on
% PLOT_OPTIONS: enables highlights for [detections, classifications, GT]
%   0 = off; 1 = on
% PLOT_PAUSE_ON: enables pause after images are shown
%   0 = off; 1 = on
% SAVE_IMAGE: enables saving of each .jpg image with highlights
%   0 = off; 1 = on
% FEATURES: index of features to be used from feature list FEAT_HANDLES
% FEAT_HANDLES: list of valid feature handles
% INV_IMG_ON: enables inverse imaging module for acoustic color, etc.
%   0 = off; 1 = on
% CLASS_DATA: index of classifier data file to be used from list
%   CDATA_FILES
% CDATA_FILES: list of valid data file names for the given classifier
% SRC_DIR: folder contains the input data files (e.g., HDF5, .mat files)
% OUT_DIR: folder in which the output files will be stored
% ECD_DIR: folder in which the extra contact data will be stored.
% Currently, this is set to be a subdirectory in .OUT_DIR called 'ecd'
% TEMP_DIR: folder for storing temporary files (e.g., those saved by the
% contact correlation algorithm)
%
% Note: GUI version also has several other fields, but those are not
% relevant to the ATR processing.  These include:
%   - BURIED_MODE, MULTICLASS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
params = struct('TB_HEAVY_TEXT', 0,...
    'DEBUG_MODE', 0,...
    'FLAG_MSGS_ON', 0,...
    'DETECTOR', 1,...
    'CLASSIFIER', 1,...
    'PERFORMANCE', 1,...
    'DET_HANDLES', {{@det_Test}},...  % default det set for Progeny
    'CLS_HANDLES', {{@cls_Test}},...    % default cls set for Progeny
    'PERF_HANDLES', {{@perf_Test}},...
    'TB_ROOT', tbr,...
    'SKIP_DETECTOR', 0,...
    'PRE_DET_RESULTS','',...
    'SKIP_PERF_EST', 0,...
    'SKIP_FEEDBACK', 0,...
    'ARCH_FEEDBACK', 0,...
    'TB_FEEDBACK_ON', 0,...
    'OPCONF_MODE', 0,...
    'FEEDBACK_PATH', [tbr,filesep,'feedback.txt'],...
    'OPARCHIVE_PATH', [tbr,filesep,'oparchive.txt'],...
    'L_BKUP_PATH', [tbr,filesep,'bkuplock.txt'],...
    'U_BKUP_PATH', [tbr,filesep,'bkupedit.txt'],...
    'MAN_ATR_SEL', 0,...
    'PLOTS_ON', 0,...
    'PLOT_OPTIONS', [0,0,0],...
    'PLOT_PAUSE_ON', 0,...
    'SAVE_IMAGE', 0,...
    'FEATURES', 1,...
    'FEAT_HANDLES', {{@feat_No_extra}},...
    'INV_IMG_ON', 0,...
    'INV_IMG_MODES', {{}},...
    'BG_SNIPPET_ON', 0,...
    'CDATA_FILES', {{'data_bogus_default.mat'}},...
    'CLASS_DATA', 1,...
    'SRC_DIR','???',...
    'OUT_DIR','???',...
    'ECD_DIR','???',...
    'TEMP_DIR','???');

if isempty(temp)
    % Defaults if no parameters passed in (i.e., for NSAM)
    if ~isempty(input_struct)
    switch input_struct.targettype % automatic D/C selection
        case {'wedge','truncated cone','cylindrical','torpedo','sphere'}
            % Use Isaac's features
            % Choose appropriate class. data file
            if strcmpi(input_struct.sensor, 'ONR SSAM')
                params.CDATA_FILES = {'data_JI_SSAM1_default.mat'};
            elseif any(strcmpi(input_struct.sensor, {'ONR SSAM2', 'MK 18 mod 2'}))
                params.CDATA_FILES = {'data_JI_SSAM2_default.mat'};
            else
                error('Classifier not trained for sensor type ''%s''.',...
                    input_struct.sensor);
            end
        case {'preproc','???'}
            % Not sure, use chosen gui files
        otherwise
            % Use SIG classifier
            params.TB_FEEDBACK_ON = 1;
            params.CLASSIFIER = 2;
            % Choose appropriate class. data file (NO DATA FILE FOR SSAM II)
            if strcmpi(input_struct.sensor, 'ONR SSAM')
                params.CDATA_FILES = {'data_SIGdefault.mat'};
            else
                error('Classifier not trained for sensor type ''%s''.',...
                    input_struct.sensor);
            end
    end
    else % classifier retrain
        params.TB_FEEDBACK_ON = 1;
        params.CLASSIFIER = 2;
        params.CDATA_FILES = {'data_SIGdefault.mat'};
    end
else
    try
        % Params have been passed in.  Copy valid values into 'params'.
        params = copy_valid_int_field(temp,params,'TB_HEAVY_TEXT',0:1);
        params = copy_valid_int_field(temp,params,'DEBUG_MODE',0:1);
        params = copy_valid_int_field(temp,params,'FLAG_MSGS_ON',0:1);
        params = copy_valid_int_field(temp,params,'MAN_ATR_SEL',0:1);
        if params.MAN_ATR_SEL == 1 % manual D/C selection
            params = copy_valid_indvec_field(temp,params,'DETECTOR','DET_HANDLES');
            params = copy_valid_indvec_field(temp,params,'CLASSIFIER','CLS_HANDLES');
            params = copy_valid_indvec_field(temp,params,'FEATURES','FEAT_HANDLES');
            params = copy_valid_indvec_field(temp,params,'CLASS_DATA','CDATA_FILES');
            params = copy_valid_int_field(temp, params, 'INV_IMG_ON', 0:1);
            if isfield(temp,'INV_IMG_MODES') && iscell(temp.INV_IMG_MODES)
                params.INV_IMG_MODES = temp.INV_IMG_MODES;
            end
            params = copy_valid_int_field(temp, params, 'BG_SNIPPET_ON', 0:1);

        else                        % automatic D/C selection
            switch input_struct.targettype
                case {'wedge','truncated cone','cylindrical','torpedo','sphere'}
                    params.DETECTOR = 1;
                    params.CLASSIFIER = 1;
                    params.FEATURES = 1;
                    if strcmpi(input_struct.sensor, 'ONR SSAM')
                        params.CDATA_FILES = {'data_JI_SSAM1_default.mat'};
                    elseif any(strcmpi(input_struct.sensor, {'ONR SSAM2', 'MK 18 mod 2'}))
                        params.CDATA_FILES = {'data_JI_SSAM2_default.mat'};
                    else
                        error('Classifier not trained for sensor type ''%s''.',...
                            input_struct.sensor);
                    end
                    params.CLASS_DATA = 1;
                    params.INV_IMG_ON = 0;
                    params.INV_IMG_MODES = {};
                    params.TB_FEEDBACK_ON = 0;
                otherwise
                    params.DETECTOR = 1;
                    params.CLASSIFIER = 2;
                    params.FEATURES = 1;
                    if strcmpi(input_struct.sensor, 'ONR SSAM')
                        params.CDATA_FILES = {'data_SIGdefault.mat'};
                    else
                        error('Classifier not trained for sensor type ''%s''.',...
                            input_struct.sensor);
                    end
                    params.CLASS_DATA = 1;
                    params.INV_IMG_ON = 0;
                    params.INV_IMG_MODES = {};
                    params.TB_FEEDBACK_ON = 1;
            end
        end

        params = copy_valid_indvec_field(temp,params,'PERFORMANCE','PERF_HANDLES');
        params = copy_valid_str_field(temp, params, 'TB_ROOT');
        params = copy_valid_int_field(temp, params, 'SKIP_DETECTOR', 0:1);
        params = copy_valid_int_field(temp, params, 'SKIP_PERF_EST', 0:1);
        params = copy_valid_int_field(temp, params, 'SKIP_FEEDBACK', 0:3);
        % make sure inputs are being saved if using SIG GUI
        if isfield(temp, 'SKIP_FEEDBACK') && temp.SKIP_FEEDBACK == 4
            params.DEBUG_MODE = 1;
        end
        params = copy_valid_int_field(temp, params, 'ARCH_FEEDBACK', 0:1);
        params = copy_valid_int_field(temp, params, 'TB_FEEDBACK_ON', 0:1);
        params = copy_valid_int_field(temp, params, 'OPCONF_MODE', 0:2);
        params = copy_valid_int_field(temp, params, 'PLOTS_ON', 0:1);
        params = copy_valid_int_field(temp, params, 'PLOT_OPTIONS', 0:1);
        params = copy_valid_int_field(temp, params, 'PLOT_PAUSE_ON', 0:1);
        params = copy_valid_int_field(temp, params, 'SAVE_IMAGE', 0:1);
        params = copy_valid_str_field(temp, params, 'PRE_DET_RESULTS');
        params = copy_valid_str_field(temp, params, 'SRC_DIR');
        params = copy_valid_str_field(temp, params, 'OUT_DIR');
        params = copy_valid_str_field(temp, params, 'ECD_DIR');
        params = copy_valid_str_field(temp, params, 'TEMP_DIR');
        % Check to make sure output folders exist.  If they don't, make them.
        % Otherwise an error will occur when file writing is attempted to
        % the non-existent folder.
        if exist(params.OUT_DIR, 'dir') == 0
            mkdir(params.OUT_DIR);
        end
        if exist(params.ECD_DIR, 'dir') == 0
            mkdir(params.ECD_DIR);
        end
        if exist(params.TEMP_DIR, 'dir') == 0
            mkdir(params.TEMP_DIR);
        end
        ok = 1;
    catch ME
    %     disp('Parameter mismatch.');
    %     keyboard;
    end % end try block
end     % end 'if isempty(temp)'
end     % end function
