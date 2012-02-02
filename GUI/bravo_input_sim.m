function bravo_input_sim(sd, use_index, gtf, od, sensor, TB_params, sbar)
% Simulates the input of data from NSAM by iterating through all of the
% files in the Bravo data set.  For each file, a structure is created from
% the data, which is fed into the main testbed routine (atr_testbed).
% In the future, input structures will be fed into atr_testbed directly.
%
% sd = path of the directory with image files
% use_index = vector of all file indicies to use
% gtf = path of groundtruth file
% od = path of the output directory
%
% Derek Kolacinski, NSWC PC (derek.kolacinski@navy.mil)
% Last update: 24 May 2011

%added by Michael Rowe on 11/2/10

if TB_params.SKIP_DETECTOR == 1
    %pick input file
    pathname = uigetdir('','Select the folder were the preprocessed results are located');
    %pathname(end) = '';
    if pathname ~= 0
        TB_params.PRE_DET_RESULTS = pathname;
    else
        return
    end
end
if TB_params.SKIP_FEEDBACK == 1
    % load data from stored opfile
    fprintf(1, '%-s\n','Loading data from operator archive...');
    new_img_ind = 1;
    oper_ind = 1;
    [confs, inds] = get_opconfs(TB_params.OPARCHIVE_PATH);
    pause;
end

% if ~isdeployed
%     % addpath(genpath( TB_params.TB_ROOT ));
%     tic
%     addpath(TB_params.TB_ROOT);
%     addpath(genpath([TB_params.TB_ROOT,filesep,'ATR Core']));
%     addpath(genpath([TB_params.TB_ROOT,filesep,'Data Readers']));
%     addpath(genpath([TB_params.TB_ROOT,filesep,'Feedback']));
%     addpath(genpath([TB_params.TB_ROOT,filesep,'Performance Estimation']));
%     addpath(genpath([TB_params.TB_ROOT,filesep,'AC Prep']));
%     toc
% end

dev_clean(TB_params.TB_ROOT);	% clean up any unwanted leftover files

% Add source directory to Matlab path (This needs to be run, even in the
% compiled version)
addpath(sd);

if TB_params.TB_HEAVY_TEXT == 1
    fprintf(1,'Source file dir = %s\n',sd);
end

% Generate list of data files to be processed
if TB_params.SKIP_DETECTOR == 1
    % Get list of I/O files
    [hi_sfnames, lo_sfnames] = gen_proc_file_list(TB_params.PRE_DET_RESULTS);
    k_init = 1;
    k_end = length(hi_sfnames);
else
    % Get list of input files
    [hi_sfnames, lo_sfnames, fullpath] = gen_file_list(sd, TB_params.DATA_FORMAT, 1);
    hi_sfnames = hi_sfnames(use_index);
    lo_sfnames = lo_sfnames(use_index);
    if iscell(fullpath)
        fullpath = fullpath(use_index);
    end
    if length(use_index) == 1
        k_init = 1;
        k_end = 1;
    else
        k_init = TB_params.DATA_RANGE(1);
        k_end = TB_params.DATA_RANGE(2);
    end
end
num_k = k_end - k_init + 1; % total number of files to be processed

if TB_params.SKIP_FEEDBACK == 4 % Using SIG GUI
    sig_params.DATA_DIR = od;
    sig_params.CONTACTS_PATH = [TB_params.TB_ROOT,filesep,'??????.???'];
    sig_params.DISPLAY_TYPE = 'block';
    sig_params.CLASS_DATA = fullfile(TB_params.TB_ROOT,'Classifiers',...
        'SIG','Data','histData_demoSSAM.mat');
    
    % save initial parameters to pass to SIG GUI via .mat file
    sig_init_fname = [TB_params.TB_ROOT,filesep,'sig_init.mat'];
    save(sig_init_fname, 'sig_params');
    eval_str = ['!matlab -r IRAFT_init'];
%     eval_str = ['!matlab -r ',TB_params.TB_ROOT,filesep,'IRAFT_init'];
%     eval_str = ['!matlab -r IRAFT_init(''',sig_init_fname,''');'];
    %%% start SIG GUI (aka IRAFT)
    eval(eval_str);
end

% list of all previous contacts
allprev = struct([]);

k = k_init;
disp(['length(hi_sfnames) = ',num2str(length(hi_sfnames))]);
while k <= k_end   % for each source image...
    % Extract sonar data, sizes, resolutions, etc. from .mat files.
    % (This will not be run for NSAM, only the testbed.)
    fprintf(1,'*** Current file: %s\n',hi_sfnames{k});
    
    proc_str =  ['Processing file ',num2str(k-k_init+1),...
        ' of ',num2str(num_k)];     % String printed to GUI
    wait_prog = (k-k_init)/num_k;   % Status bar fill percentage
    set(sbar.hpatch, 'XData', [0,0,wait_prog,wait_prog]);
    drawnow

    % Import data into input structure
    % [p_in_struct, s_in_struct] = import_data_switch(...)
    
    if TB_params.SKIP_DETECTOR == 1
    %   ...make a simplified input structure just containing the name and
    %   side of the file (so that atr_testbed can find it)
        addpath(TB_params.PRE_DET_RESULTS);
        p_in_struct = []; s_in_struct = []; side_b = '';
        [junk, fn_a] = fileparts(hi_sfnames{k});
        side_a = fn_a((end-3):end);
        if (k+1) <= length(hi_sfnames)
            [junk, fn_b] = fileparts(hi_sfnames{k+1});
            side_b = fn_b((end-3):end);
        end
        % Determine what files are present and align next file(s) in list
        % with the port/stbd pair paradigm of the code.
        [port_on, stbd_on, k_mod_p, k_mod_s, k_inc] = ...
            load_prep(side_a, side_b, 'PORT', 'STBD');
        
        % Load port structure, if present
        if port_on
            try     % maybe this I/O file has an input structure in it?
                load(hi_sfnames{k+k_mod_p}, 'input_struct');
                p_in_struct = input_struct;
                clear input_struct
            catch ME
                p_in_struct.fn = hi_sfnames{k+k_mod_p}(4:(end-9));
                p_in_struct.side = 'PORT';
                p_in_struct.targettype = 'preproc';
				p_in_struct.mode = 'A';

            end
            p_sfn = hi_sfnames{k+k_mod_p}(4:(end-9));
        end
        % Load stbd structure, if present
        if stbd_on
            try     % maybe this I/O file has an input structure in it?
                load(hi_sfnames{k+k_mod_s}, 'input_struct');
                s_in_struct = input_struct;
                clear input_struct
            catch ME
                s_in_struct.fn = hi_sfnames{k+k_mod_s}(4:(end-9));
                s_in_struct.side = 'STBD';
                s_in_struct.targettype = 'preproc';
				s_in_struct.mode = 'A';
            end
            s_sfn = hi_sfnames{k+k_mod_s}(4:(end-9));
        end
        % Increment filename list index past whichever files were actually
        % used during this iteration
        k = k + k_inc;

    else
    %   ...do the stuff below
    switch TB_params.DATA_FORMAT
        case 1 % old mat (Bravo)
            p_sfn = hi_sfnames{k};  % Port save file name
            s_sfn = hi_sfnames{k};
            p_in_struct = gen_input_struct_bravo(hi_sfnames{k}, 'PORT',...
                gtf, TB_params);
            s_in_struct = gen_input_struct_bravo(hi_sfnames{k}, 'STBD',...
                gtf, TB_params);
            if ~isempty(p_in_struct)
                p_in_struct.sensor = sensor;
            end
            if ~isempty(s_in_struct)
                s_in_struct.sensor = sensor;
            end
            k = k + 1;
        case 2 % mymat
            p_sfn = hi_sfnames{k};
            s_sfn = hi_sfnames{k};
            p_in_struct = [];
            s_in_struct = [];
            if strcmpi('P',hi_sfnames{k}(1))
                p_in_struct = mymat_reader([sd,filesep,'HF',filesep,hi_sfnames{k}],...
                    [sd,filesep,'LF',filesep,lo_sfnames{k}],'PORT', gtf, TB_params);
                p_in_struct.sensor = sensor;
            elseif strcmpi('S',hi_sfnames{k}(1))
                s_in_struct = mymat_reader([sd,filesep,'HF',filesep,hi_sfnames{k}],...
                    [sd,filesep,'LF',filesep,lo_sfnames{k}],'STBD', gtf, TB_params);
                s_in_struct.sensor = sensor;
            end
            k = k + 1;
        case 3 % scrub mat
            p_sfn = hi_sfnames{k};
            s_sfn = hi_sfnames{k};
            tempf = [sd,filesep,'Sensor2_EnvB_07Aug11',filesep,'Images',filesep];
            tempf_lo = [sd,filesep,'Sensor3_EnvB_07Aug11',filesep,'Images',filesep];
            [p_in_struct, s_in_struct] = mat_reader(...
                [tempf,hi_sfnames{k}], [tempf_lo,lo_sfnames{k}], 'scrub',...
                gtf, TB_params);
            if ~isempty(p_in_struct)
                p_in_struct.sensor = sensor;
            end
            if ~isempty(s_in_struct)
                s_in_struct.sensor = sensor;
            end
            k = k + 1;
        case 4 % new mat (nswc)
            % Both sides are in one file
            p_sfn = hi_sfnames{k};
            s_sfn = hi_sfnames{k};
            [p_in_struct, s_in_struct] = mat_reader(...
                [sd,filesep,hi_sfnames{k}], [], 'nswc', gtf, TB_params);
            if ~isempty(p_in_struct)
                p_in_struct.sensor = sensor;
            end
            if ~isempty(s_in_struct)
                s_in_struct.sensor = sensor;
            end
            k = k + 1;
        case 5 % HDF5
            % Separate port and stbd files
            p_sfn = hi_sfnames{k};
            s_sfn = hi_sfnames{k};
            p_in_struct = [];
            s_in_struct = [];
            side_a = hi_sfnames{k}(1); side_b = '';
            if (k+1) <= length(hi_sfnames)
                s_sfn = hi_sfnames{k};
                side_b = hi_sfnames{k+1}(1);
            end
            [port_on, stbd_on, k_mod_p, k_mod_s, k_inc] = ...
                load_prep(side_a, side_b, 'P', 'S');
             
            if port_on
                try
                p_in_struct = hdf5_reader([fullpath{k+k_mod_p},filesep,hi_sfnames{k+k_mod_p}],...
                    [fullpath{k+k_mod_p},filesep,lo_sfnames{k+k_mod_p}], 'PORT', gtf, TB_params);
                p_in_struct.sensor = sensor;
                catch
                    display(['Skipped: ' hi_sfnames{k}]);
                end
            end
            if stbd_on
                try
                s_in_struct = hdf5_reader([fullpath{k+k_mod_s},filesep,hi_sfnames{k+k_mod_s}],...
                    [fullpath{k+k_mod_s},filesep,lo_sfnames{k+k_mod_s}], 'STBD', gtf, TB_params);   
                s_in_struct.sensor = sensor;
                s_sfn = hi_sfnames{k+k_mod_s};

                catch
                    display(['Skipped: ' hi_sfnames{k+k_mod_s}]);
                end
            end
            k = k + k_inc;
        case 6 %NURC MUSCLE DATA
            p_sfn = hi_sfnames{k};
            s_sfn = hi_sfnames{k};
            p_in_struct = [];
            s_in_struct = [];
            temptext = textscan(hi_sfnames{k},'%s%s%s%s%s%s%s%s%s%s','Delimiter','_');
            if strcmpi(temptext{6},'p')
                [p_in_struct,s_in_struct] = mat_reader([fullpath{k},filesep,hi_sfnames{k}],...
                    [], 'nurc', gtf, TB_params);
                p_in_struct.sensor = sensor;
            elseif strcmpi(temptext{6},'s')
                [p_in_struct,s_in_struct] = mat_reader([fullpath{k},filesep,hi_sfnames{k}],...
                    [], 'nurc', gtf, TB_params);
                s_in_struct.sensor = sensor;
            end
            k = k + 1;
        case 7 %CSDT 
            p_sfn = hi_sfnames{k};
            s_sfn = hi_sfnames{k};
            [p_in_struct, s_in_struct] = mat_reader(...
                [sd,filesep,hi_sfnames{k}], [], 'csdt', gtf, TB_params);
            if ~isempty(p_in_struct)
                p_in_struct.sensor = sensor;
            end
            if ~isempty(s_in_struct)
                s_in_struct.sensor = sensor;
            end
            k = k + 1;
        case 8 %POND
            p_sfn = hi_sfnames{k};
            s_sfn = hi_sfnames{k};
            p_in_struct = [];
            s_in_struct = [];
            [p_in_struct, s_in_struct] = mat_reader([sd, filesep, hi_sfnames{k}],...
                [], 'pond', gtf, TB_params);
            if ~isempty(p_in_struct)
                p_in_struct.sensor = sensor;
            end
            if ~isempty(s_in_struct)
                s_in_struct.sensor = sensor;
            end
            k = k + 1;
        case 9 % PCSWAT Imagery
            p_sfn = hi_sfnames{k};
            s_sfn = hi_sfnames{k};
            p_in_struct = [];
            s_in_struct = [];
            p_in_struct = pcswat_reader([sd,filesep,'HF',filesep,hi_sfnames{k}],...
                [sd,filesep,filesep,'LF',filesep,lo_sfnames{k}],'PORT', gtf, TB_params);
            p_in_struct.sensor = sensor;
            k = k + 1;
        case 10 % MATS input structures
            p_sfn = hi_sfnames{k};
            s_sfn = hi_sfnames{k};
            p_in_struct = [];
            s_in_struct = [];
            p_in_struct = mats_struct_reader([sd,filesep,hi_sfnames{k}],...
                gtf, TB_params); % this will need work once I get files from Brad
            p_in_struct.sensor = sensor;
            keyboard
        otherwise
            disp('Error: Invalid data format index.');
            return
            
    end
    end
    
    %%% PORT SIDE
    if ~isempty(p_in_struct)
        disp('*** Processing port side...');
        % Update waitbar
        set(sbar.hlabel, 'String', [proc_str,' (PORT)...']);
        drawnow
        img_start = length(allprev)+1;
        % Run ATR on port side data
        [perfout, contacts] = proc_side(p_in_struct, allprev, TB_params);
        % Save input and output structures
        save_io(p_sfn, od, p_in_struct, contacts(img_start:end),...
            perfout, TB_params);
        % Save results for 'operator feedback'
        allprev = contacts;
        if TB_params.TB_FEEDBACK_ON == 1
            % Get feedback
            allprev = feedback_switch(allprev, TB_params);
        end
        
        % Save data to make ROC curve up to this point
        save_roc_data(p_sfn, od, p_in_struct.side, allprev, img_start);
        
        %%% DISPLAY IMAGE
        if TB_params.PLOTS_ON == 1 && ~isempty(p_in_struct)...
                && isfield(p_in_struct,'hf')
            general_display(p_in_struct, contacts, TB_params, od);
        end
    end
    
    %%% STBD SIDE
    if ~isempty(s_in_struct)
        disp('*** Processing starboard side...');
        % Update waitbar
        set(sbar.hlabel, 'String', [proc_str,' (STBD)...']);  
        drawnow
        img_start = length(allprev)+1;
        % Run ATR on starboard side data
        [perfout, contacts] = proc_side(s_in_struct, allprev, TB_params);
        % Save input and output structures
        save_io(s_sfn, od, s_in_struct, contacts(img_start:end),...
            perfout, TB_params);
        % Save results for 'operator feedback'
        allprev = contacts;
        if TB_params.TB_FEEDBACK_ON == 1
            % Get feedback
            allprev = feedback_switch(allprev, TB_params);
        end
        
        % Save data to make ROC curve up to this point
        save_roc_data(s_sfn, od, s_in_struct.side, allprev, img_start);
        
        %%% DISPLAY IMAGE
        if TB_params.PLOTS_ON == 1 && ~isempty(s_in_struct)...
                && isfield(s_in_struct,'hf')
            general_display(s_in_struct, contacts, TB_params, od);
        end
    end
    if ~exist('contacts','var');
        contacts = struct([]);
    end
end     % end image loop

%%% Handle skipped contacts
if TB_params.TB_FEEDBACK_ON == 1 && TB_params.SKIP_FEEDBACK ~= 2
    skipped_bin = arrayfun(@(a) (a.opfeedback.opdisplay == -14), contacts) ...
        | arrayfun(@(a) (a.opfeedback.opdisplay == -13), contacts);
    skipped = contacts(skipped_bin);
    skip_ind = find(skipped_bin);
    if TB_params.TB_HEAVY_TEXT == 1
        fprintf(1,'Skipped contact #s: ');
        for qq = 1:length(skip_ind)
            fprintf(1,'%d ',skip_ind(qq));
        end
        fprintf(1,'\n');
    end
    ocm_opts = {'Review', 'Confirm all', 'Discard all'};
    temp = sprintf('There are %d skipped contacts. What would you like to do with them?', length(skipped));
    opconf_choice = questdlg(temp,'Skipped contacts',...
        ocm_opts{1},ocm_opts{2},ocm_opts{3},ocm_opts{TB_params.OPCONF_MODE+1});
    if strcmp(opconf_choice,ocm_opts{1}) == 1 % operator must respond
        % Mark skipped contacts so that they'll show in existing opfeedback stub
        for qq = 1:length(skip_ind)
            skipped(qq).opfeedback.opdisplay = 1;
        end
        skipped = opfeedback_stub(skipped, TB_params, skip_ind);
        % Transfer ratings from skipped list back to contacts list
        for qq = 1:length(skip_ind)
            contacts(skip_ind(qq)).opfeedback.opdisplay = skipped(qq).opfeedback.opdisplay;
            contacts(skip_ind(qq)).opfeedback.opconf = skipped(qq).opfeedback.opconf;
        end
    elseif strcmp(opconf_choice,ocm_opts{2}) == 1 % skips ok, assume skip == agreement
        for qq = 1:length(skip_ind)
            contacts(skip_ind(qq)).opfeedback.opdisplay = contacts(skip_ind(qq)).opfeedback.opdisplay + 5; %%??
            contacts(skip_ind(qq)).opfeedback.opconf = 6 - (contacts(skip_ind(qq)).opfeedback.opdisplay + 10); %?????
        end
    elseif strcmp(opconf_choice,ocm_opts{3}) == 1 % skips ok, discard skips
        contacts(skip_ind) = [];
    end
end

%%% Contact correlation
if TB_params.CONTCORR_ON
    set(sbar.hlabel, 'String', 'Contact correlation...');
    hcor = TB_params.CC_HANDLES{TB_params.CONTCORR};
    if ~isdeployed
        temp = func2str(hcor);
        cor_folder = temp(5:end);
        cor_paths = genpath([TB_params.TB_ROOT,filesep,'Contact Correlation',filesep,cor_folder]);
        addpath(cor_paths);
    end
    fprintf(1,'Launching contact correlation (%s)...\n',func2str(hcor));
    mine_ind = arrayfun(@(a) (a.class == 1 || (~isempty(a.gt) && a.gt == 1)),contacts);
    contacts(mine_ind) = hcor(contacts(mine_ind));
    % contacts = hcor(contacts);
    if ~isdeployed
        rmpath(cor_paths);
    end
end

%%% Compare results to the groundtruth file, if such file has been selected
if ~isempty(gtf)
    % Break source directory path into chunks
    sd_chunks = regexp(sd, (filesep), 'split');
    % Get timestamp string
    time_chunk = cell2mat( regexp(datestr(now), '(-|:)', 'split') );
    compare_results(gtf, contacts,...
        [od,filesep,sd_chunks{end},' ',time_chunk,'.txt'],...
        TB_params.DATA_FORMAT, hi_sfnames(k_init:k_end));
    % Results are now stored in file with name:
    %   'Subdir DDMonYYYY HHMMSS.txt'
end

set(sbar.hpatch, 'XData', [0,0,1,1]);
set(sbar.hlabel, 'String', 'Batch complete.');
drawnow
toc
%%% END OF MAIN FUNCTION

%%% INTERNAL SUBROUTINES

% Process a side of image data
    function [perfout, contacts] = proc_side(input_struct, allprev, TB_params)
        % Process a side of image data.
        % NOTE: This used to be all in the main function. I moved it over
        % here to keep the code from getting too convoluted. It still
        % shares the same work space as the main function though, meaning
        % that the variables in the main function are altered significantly
        % by somewhat hidden code.  This should probably be cleaned up
        % later, but it does work.
        new_img_ind = length(allprev) + 1;
        if TB_params.TB_HEAVY_TEXT == 1
            fprintf(1, 'New image starts at index #%d\n', new_img_ind);
        end
        % Process this image structure through the testbed
        if TB_params.NSAM_MODE_ON == 1
            [perfout, contacts] = atr_testbed_altfb(input_struct, allprev);
        else
            [perfout, contacts] = atr_testbed_altfb(input_struct, allprev, TB_params, od);
        end
        
        if TB_params.TB_HEAVY_TEXT == 1
            fprintf(1,'Contacts structure for file ''%s'':\n', input_struct.fn);
            disp(contacts);
            fprintf(1,'Perfout structure for file ''%s'':\n', input_struct.fn);
            disp(perfout);
        end
    end

% Subroutine for feedback step
    function allprev = feedback_switch(allprev, TB_params)
        %%% OPERATOR FEEDBACK
        fprintf(1, ' Size of contacts: %d\n\n\n', length(contacts));
        switch TB_params.SKIP_FEEDBACK
            case 1
                % read in results from operator archive instead
                fprintf(1, '%-s\n', 'Operator feedback (from archive)...');
                allprev = import_opfile(allprev);
            case 0
                % use feedback stub gui
                fprintf(1, '%-s\n', 'Operator feedback (from stub GUI)...');
                allprev = opfeedback_stub(allprev, TB_params);
            case 3
                % use gt values for operator calls
                fprintf(1, '%-s\n', 'Operator feedback (from GT data)...');
                for z = new_img_ind:length(allprev)
                    %                     allprev(z).opfeedback.opconf = allprev(z).gt;
                    if allprev(z).gt == 1
                        temp = 5;
                    elseif allprev(z).gt == 0
                        temp = 1;
                    else
                        temp = 3;
                    end
                    allprev(z).opfeedback.opdisplay = allprev(z).opfeedback.opdisplay - 10;
                    allprev(z).opfeedback.opconf = temp;
                    append_feedback(allprev(z), z,...
                        TB_params.FEEDBACK_PATH, TB_params.TB_HEAVY_TEXT);
                    fprintf(1, '#%d: GT %d used for .opconf\n',...
                        z, temp);
                end
        end
    end

% Incorporates the proper data from the confs array to the contact list
    function contacts = import_opfile(contacts)
        % Imports the proper data from the confs array (returned from function
        % get_opconfs) to the contact list
        %
        % contacts = a list of contacts in the form of an array of contact
        %   structures
        disp('Reading from opfile archive...');
        cind = new_img_ind;         % index in contact list
        opind = oper_ind;           % index in operator archive list
        while cind <= length(contacts)  % for each spot in this segment...
            if opind <= length(confs)       % if still more opconf data...
                if inds(opind) < cind           % if archive data from past image...
                    % ignore, try next archive entry
                    disp('ignore, try next archive entry');
                    opind = opind + 1;
                elseif inds(opind) > length(contacts)   % else if archive data from future image...
                    fprintf(1, 'Bailing out (next opconf @%d > contact length of %d)\n',...
                        inds(opind), length(contacts));
                    % ignore, might as well quit
                    % however, there may or may not be leftover contacts,
                    % so fill those in first
                    for q = cind:length(contacts)
                        contacts(q).opfeedback.opconf = 0;
                        disp('0 fill');
                    end
                    return
                else
                    % this data is in this set
                    if cind == inds(opind)
                        % match! store
                        disp('match! store');
                        contacts(cind).opfeedback.opconf = confs(opind);
                        % advance both indicies
                        cind = cind + 1;
                        opind = opind + 1;
                        % advance marker so that next image starts in right
                        % place
                        oper_ind = oper_ind + 1;
                    else
                        % archive data is in same image but does not match
                        contacts(cind).opfeedback.opconf = 0;
                        disp('archive data is in same image but does not match');
                        % advance contacts index
                        cind = cind + 1;
                    end
                end
            else
                % opconf data is exhausted
                disp('opconf data is exhausted');
                contacts(cind).opfeedback.opconf = 0;
                % advance contacts index
                cind = cind + 1;
            end
        end     % end while
    end

% Read operator data from saved operator archive file
    function [confs, inds] = get_opconfs(filename)
        % Read operator data from the saved operator file
        %
        % filename = file path of the operator file
        % confs = array of operator confidence ratings (.opconf) from file
        % inds  = indexes corresponding to the values in 'confs'
        memstep = 20;
        confs = zeros(1, memstep); inds = zeros(1, memstep);
        fid = fopen(filename,'r');
        try
            fid = fopen(filename, 'r'); % read from file
        catch ME
            type = regexp(ME.identifier, '(?<=:)\w+$', 'match');
            if strcmp(type, 'InvalidFid') == 1
                disp([' ',filename,' cannot be opened.']);
            else
                disp([' An error has occured using ',filename]);
                keyboard
            end
        end
        cnt = 1;
        while feof(fid) == 0
            %%% read data
            % index
            chunk = fread(fid, 1, 'uint8');
            if isempty(chunk) %|| chunk > length(contacts)
                disp('end import_opfile');
                endpos = max( find(inds == 0,1,'first')-1, 1);
                
                inds = inds(1:endpos);
                confs = confs(1:endpos);
                return
            end
            if cnt > length(inds)
                % grow array
                disp('++++');
                temp = zeros(1, length(inds)+memstep);
                temp(1:(end-memstep)) = inds;
                inds = temp;
                temp = zeros(1, length(confs)+memstep);
                temp(1:(end-memstep)) = confs;
                confs = temp;
            end
            index = chunk;
            % filename
            len = fread(fid, 1, 'uint8');
            fn = char( fread(fid, len, 'uchar')' );
            % side
            side = char( fread(fid, 4, 'uchar')' );
            % x
            x = fread(fid, 1, 'uint16');
            % y
            y = fread(fid, 1, 'uint16');
            % opconf
            
            opconf = fread(fid, 1, 'int8');
            fprintf(1, '  #%d: %s, %s (%d,%d) -- opconf = %d\n',...
                index, fn, side, x, y, opconf);
            % store values
            confs(cnt) = opconf;
            inds(cnt) = index;
            cnt = cnt + 1;
        end
        
        fclose(fid);
    end

end

%%% EXTERNAL SUBROUTINES

% Save ROC curve data to a file
function save_roc_data(sfn, od, side, contacts, start_of_img) 
% Save ROC data to file of form ['ROC_',f,'_',side,'.mat']
% sfn = sonar (input) file path
% od = output directory
% contacts = contact list

% This value will allow for some backwards compatibility
roc_version = 2; %#ok<NASGU>

vec_len = length(contacts) - start_of_img + 1;
classes = -99*ones(1, vec_len);
gts = -99*ones(1, vec_len);
confs = -99*ones(1, vec_len);
for k = 1:vec_len
    classes(k) = contacts(k-1+start_of_img).class;
    gts(k) = contacts(k-1+start_of_img).gt;
    confs(k) = contacts(k-1+start_of_img).classconf;
end

if ~isempty(contacts)
    det_name = contacts(1).detector; %#ok<NASGU>
    cls_name = contacts(1).classifier; %#ok<NASGU>
else
    det_name = ''; %#ok<NASGU>
    cls_name = ''; %#ok<NASGU>
end

[junk, f] = fileparts(sfn); %#ok<*ASGLU>
roc_fname = [od,filesep,'ROC_',f,'_',side,'.mat'];
fprintf(1,'%-s\n\n',['Saving ROC data in ',roc_fname,'...']);
save(roc_fname,'classes','gts','confs','start_of_img','det_name',...
    'cls_name', 'roc_version');
end

% Save I/O data to a file
function save_io(sfn, od, input_struct, contacts, perfout, TB_params)  %#ok<INUSL>
% Save input and output data to file
[junk, f] = fileparts(sfn);
io_fname = [od,filesep,'IO_',f,'_',input_struct.side,'.mat'];

% Ensure that an image GUI process (e.g., SIG) isn't currently reading
% files in the output directory
wait_if_flag([TB_params.TB_ROOT,filesep,'iofile_gui_busy.flag']);
write_flag([TB_params.TB_ROOT,filesep,'iofile_atr_busy.flag'], 0);

fprintf(1,'%-s\n\n',['Saving I/O structures in ',io_fname,'...']);
if TB_params.DEBUG_MODE == 1
    save(io_fname,'input_struct','contacts','perfout');
else
    save(io_fname,'contacts','perfout');
end

delete_flag([TB_params.TB_ROOT,filesep,'iofile_atr_busy.flag'], 0);
end