function contacts = opfeedback_display_gui(input, contacts, TB_params, varargin)
% This function is intended to merge the functionality of the general
% display function with the feedback stub in order to add more
% functionality to the GUIs
%
% contacts (in) = array of contact structures representing potential
%   targets in all images up to this point
% TB_params = testbed configuration structure
% label_nums (optional) = indices of the vector contacts.  Without this
%   vector present, the first contact will be labeled #1, the second #2,
%   and so on.  If the contact list has been cherry-picked (e.g., reviewing
%   all of the contacts that have been skipped) then this will not match
%   the actual indices of the contacts.
%
% contacts (out) = same as above, but with field .opfeedback.opconf
%   filled in.
%
% Derek Kolacinski, NSWC PC (derek.kolacinski@navy.mil)
% Last update: 25 Jan 2012

%% PREP FROM OPFEEDBACK_STUB
% Determine the contact labellings.  Normally, this is the contact's index
% in the list, but this can be overridden for the final summary of
% previously skipped contacts
label_nums = 1:length(contacts);
if ~isempty(varargin)
    temp = varargin{1};
    if isvector(temp)
        label_nums = temp;
    end
end

% Determine if this image has any mines to show
mine_sum = 0;
for q = 1:length(contacts)
    if contacts(q).opfeedback.opdisplay > 0     %%%
        mine_sum = mine_sum + contacts(q).class;
    end                                         %%%
end
if mine_sum == 0
    % contact list for this image doesn't contain any mines
    return
end

% negative offset for .opdisplay. This will be subtracted from the initial
% values to indicate that the contact has been viewed and processed.
dispmod = 10;
% Start at beginning of contact list
img_cnt = 1;
% number of contacts to be processed by the operator before reclassification
% occurs.
reclass_at = 500;
% reclass_at = 5;

% Skip over contacts at the beginning that have been already marked as
% viewed
while img_cnt <= length(contacts) && contacts(img_cnt).opfeedback.opdisplay < 0
    img_cnt = img_cnt + 1;
end
% Skip over contacts that won't be shown
while img_cnt <= length(contacts) && contacts(img_cnt).opfeedback.opdisplay <= 0
    contacts(img_cnt).opfeedback.opdisplay = contacts(img_cnt).opfeedback.opdisplay - dispmod; % mark processed
    contacts(img_cnt).opfeedback.opconf = 0;
    img_cnt = img_cnt + 1;
end
% Note: img_cnt now points to first contact designated to be shown to the user

% in the event that there are no contacts to view, prepare to exit quickly
if img_cnt > length(contacts)
    done = 1;
else
    done = 0;
end

%% PREP FROM GENERAL_DISPLAY
side = input.side;
filename = input.fn;
gt = input.gtimage;
[m_hf, n_hf] = size(input.hf); [m_bb, n_bb] = size(input.bb);

if ~isempty(contacts)
    fmatch = strcmp({contacts.fn}, filename) & strcmp({contacts.side},side);
    in_this_file = contacts(fmatch);
    num_old = find(fmatch == 0, 1, 'last');
    if isempty(num_old), num_old = 0; end
    temp = [in_this_file.opfeedback]; temp = [temp.opdisplay];
    itf_ind = find(temp > 0, 1);
    % position of current location indicator
    cur_x = in_this_file(itf_ind).x;	cur_y = in_this_file(itf_ind).y;
    % number labels for contact boxes
    box_labels = 1:length(in_this_file);
    % number labels for manually added contact boxes
    opadd_labels = [];
else
    in_this_file = [];
    num_old = 0;
    itf_ind = [];
    cur_x = 1;
    cur_y = 1;
    box_labels = [];
    opadd_labels = [];
end

% If using previous results, classification boxes will be split:
%   left half = old classifications; right half = new classifications
split_box = 0;
if ~isempty(TB_params.PRE_DET_RESULTS)
    [junk, f] = fileparts(input.fn);
    roc_fn = [TB_params.PRE_DET_RESULTS,filesep,'ROC_',f,'_',input.side,'.mat'];
    try
        old = load(roc_fn);
        assert(length(old.classes) == length([in_this_file.class]), 'Incorrect ROC file loaded');
        split_box = 1;
    catch ME
        
    end
end

% image parameters
[image, band_tag, rng_res, trk_res, x_ratio, y_ratio, roix, roiy] = ...
            get_disp_params(input, TB_params);
[m_track,n_range] = size(image);    % dimensions of image
range_axis=[0, n_range*rng_res];    % scale for range axis
track_axis=[0, m_track*trk_res];    % scale for track axis
spacerx = 5*rng_res; spacery = 10*trk_res;


%% GUI DIMENSIONS
f = figure(22);
screen_info = get(0,'ScreenSize');
% Spacing/borders
spacing = 20;       % for radio buttons
axis_border = 20;   % buffer for axis labels
mid_div = 20;       % divider between main image and the rest of the GUI
leg_space = 50;     % height buffer for legend
% Region dimensions
% - img_*:  area around main image
% - snip_*: area around snippet
% - fb_*:   area around radio buttons/heading
% - gui_*:  whole GUI
fb_w = 500;
snip_w = fb_w;
snip_h = snip_w;
inst_w = fb_w;
inst_h = 100;
fb_h = snip_h + 10 + 7*spacing + inst_h;
img_h = 0.8*screen_info(4) - leg_space;
% img_h = 700;
% img_h = fb_h - leg_space;
max_w = min(screen_info(3)-50, 1600);          % max screen width
% max_w = min(screen_info(3), 1600);          % max screen width
img_w = min(max_w-fb_w-mid_div, img_h*max(range_axis)/max(track_axis)); % adjust width to fit height
gui_w = fb_w + mid_div + img_w;
gui_h = max(fb_h, img_h+leg_space);
img_off_w = fb_w + mid_div;
img_off_h = leg_space;
set(f, 'Visible', 'off', 'Position', [25, screen_info(4)-gui_h-25-25, gui_w, gui_h]);

%% BUILD GUI
% FEEDBACK GROUP
% Feedback rating radio buttons
hratinggroup = uibuttongroup('Position', [0, 0, 1, 1]);
hrs = uicontrol('Style', 'Radio', 'String', 'Skip',...
    'Position', [10,10,150,16], 'UserData', [], ...
    'Parent', hratinggroup, 'BackgroundColor', 'white');
if TB_params.OPCONF_MODE == 0 % disable skipping when all contacts must be confirmed
    set(hrs, 'Enable', 'off');
end
hr1 = uicontrol('Style', 'Radio', 'String', '1 - Likely Clutter',...
    'Position', [10,10+1*spacing,150,16], 'UserData', 1, ...
    'Parent', hratinggroup, 'BackgroundColor', 'white');
hr2 = uicontrol('Style', 'Radio', 'String', '2',...
    'Position', [10,10+2*spacing,150,16], 'UserData', 2,...
    'Parent', hratinggroup, 'BackgroundColor', 'white');
hr3 = uicontrol('Style', 'Radio', 'String', '3 - Unsure',...
    'Position', [10,10+3*spacing,150,16], 'UserData', 3,...
    'Parent', hratinggroup, 'BackgroundColor', 'white');
hr4 = uicontrol('Style', 'Radio', 'String', '4',...
    'Position', [10,10+4*spacing,150,16], 'UserData', 4,...
    'Parent', hratinggroup, 'BackgroundColor', 'white');
hr5 = uicontrol('Style', 'Radio', 'String', '5 - Likely mine',...
    'Position', [10,10+5*spacing,150,16], 'UserData', 5,...
    'Parent', hratinggroup, 'BackgroundColor', 'white');
set(hratinggroup, 'SelectedObject', []);
% Label for feedback rating radio buttons
hlabel = uicontrol('Style', 'text', 'String', ['Contact #',num2str(label_nums(img_cnt))],...
    'Position', [10, 10+6*spacing, 100, 16]);

% Dropdown menu for classifier type (only for multiclass case)
if TB_params.MULTICLASS == 1
uicontrol('Style', 'text', 'String', 'Mine type:',...
    'Position', [160, 10+6*spacing, 100, 16]);
[type_vals, type_str_list] = get_objtype_vals();
htypemenu = uicontrol('Style', 'popupmenu', 'String', type_str_list,...
    'Position', [260, 10+6*spacing+2, 100, 16]);
end

% Next button - goes to next contact for which feedback is requested
hnextbutton = uicontrol('Style', 'pushbutton', 'String', 'Next',...
    'Position', [110, 10+6*spacing, 50, 16], 'Callback', {@next_clbk});

% IMAGE BUTTONS
% Add button - adds a manual contact
haddbutton = uicontrol('Style', 'pushbutton', 'String', 'Add',...
    'Position', [210, 10+0*spacing,100,16], 'Callback', {@add_clbk});
% Revert (?) button - goes back to the next contact for which feedback is
% requested. (This is sort of like the next button, except used in
% different circumstances.  We could probably combine the two, but this is
% simpler for now.)
hrevbutton = uicontrol('Style', 'pushbutton', 'String', 'Revert',...
    'Position', [210, 10+1*spacing,100,16], 'Callback', {@rev_clbk});
uicontrol('Style','text','String','Manual Add Buttons:',...
    'Position', [210, 10+2*spacing,100,32]);


% Handle for snippet axes
haxes = axes('Color', 'white', 'Units', 'pixels', 'Position',...
    [10+axis_border, 10+7*spacing+axis_border, snip_w-2*axis_border, snip_h-2.5*axis_border]);
% Handle for main image axes
haxes_img = axes('Color', 'white', 'Units', 'pixels', 'Position',...
    [1+fb_w+mid_div+axis_border, 1+axis_border+leg_space, img_w-2*axis_border, img_h-2.5*axis_border], 'XGrid','on','YGrid','on');  


% Instructions
uicontrol('Style','text','Position', [5, gui_h-inst_h-5, inst_w, inst_h],...
    'String',{'Instructions:';...
        '-Choose feedback rating for the snippet below, then click ''Next'' to advance to the next contact.';...
        ['-Contacts may be added manually by clicking on the main image to the right '...
        'to update the snippet shown.  Click ''Add'' to add the contact, or ''Revert'' ',...
        'to go to the next ATR contact.']});

op_mode = set_mode('V'); % mode = 'V';     % 'V' -> verify mode; 'A' -> add mode


%% Prep data vectors
gt_x = []; gt_y = []; dets_x = []; dets_y = []; clss_x = []; clss_y = [];
clss_x_old = []; clss_y_old = []; classes = [];  old_classes = [];
opadds_x = []; opadds_y = [];

if ~isempty(in_this_file)
    dets_x = [in_this_file.x]/x_ratio * rng_res;
    dets_y = [in_this_file.y]/y_ratio * trk_res;
    con_inds = [in_this_file.class] >= 1;
    mines = in_this_file(con_inds);
    if ~isempty(mines)
        clss_x = [mines.x]/x_ratio * rng_res;
        clss_y = [mines.y]/y_ratio * trk_res;
        classes = [mines.class];
    end
    if split_box == 1
        mines_old = in_this_file(old.classes >= 1);
        if ~isempty(mines_old);
            clss_x_old = [mines_old.x]/x_ratio * rng_res;
            clss_y_old = [mines_old.y]/y_ratio * trk_res;
            old_classes = old.classes(old.classes >= 1);
        end
    end
end

if ~isempty(gt)
    gt_x = gt.x/x_ratio * rng_res;
    gt_y = gt.y/y_ratio * trk_res;
end

axes(haxes_img); lab_colors = {'Black'; 'Black'; 'Black'};

%% Display
snippet = [];
% Display main image and all annotations
display_image_axes();
% Display legend
display_legend(1+fb_w+mid_div+axis_border, 1);
% Display image snippet
display_snippet()

set(f, 'Name', 'Image/Feedback GUI', 'NumberTitle', 'off', 'Visible', 'on', 'MenuBar', 'none');

if TB_params.MULTICLASS == 1
    % Set default mine type to be that determined by the classifier
    def_ind = get_def_index( contacts(img_cnt).class, type_vals );
    set(htypemenu, 'Value', def_ind);
end
        
%% WAIT LOOP %%
% Pause if using GUI for feedback
done = ~(TB_params.SKIP_FEEDBACK == 0 || TB_params.PLOT_PAUSE_ON == 1);
while ~done
    fprintf(1,'.');
    pause(1);
% keyboard
end

fprintf(1,'\n%-s\n\n','Operator block done.');


%% CALLBACK FUNCTIONS
    function img_click_clbk(junk, junk2) %#ok<INUSD>
        % Callback for when the user clicks somewhere in the main image.
        % Switches to add mode
        
        % Find where the click corresponds to in the image
        temp_pt = get(haxes_img, 'CurrentPoint');
        rng_m = temp_pt(1,1);
        trk_m = temp_pt(1,2);
        % Translate to pixels
        rng_p = rng_m / input.hf_cres;
        trk_p = trk_m / input.hf_ares;
        
%         fprintf(1,'(%d, %d) m ----[%d, %d] pixels\n', rng_m, trk_m, rng_p, trk_p);

%         hold on;
%         plot(haxes_img, rng_m, trk_m, '+g', 'MarkerSize',10);
        
        img_px = fix(rng_p);
        img_py = fix(trk_p);
        % Get snippet at this location
        snippet = make_snippet_alt(img_px, img_py, 401, 401, image);
        % Update snippet display
        set(f, 'CurrentAxes', haxes);
        temp = imadjust(clip_image( abs(snippet) ) ,[0.001 0.70],[],1);
        imagesc(temp);
        axis image
        grid on;
        
        % Change contact label
        set(hlabel, 'String', 'Contact #--');
        % clear radio button selection
        set(hratinggroup, 'SelectedObject', []); 
        % Update current marker
        cur_x = img_px; cur_y = img_py;
        % Update main image display
        display_image_axes();
        drawnow();
        % switch to add mode
        op_mode = set_mode('A');
    end

    % Callback function for next button - adds feedback data into an existing contact
    % and advances to next existing contact.
    function next_clbk(junk, junk2) %#ok<INUSD>
        % Imports rating data, appends to the feedback file, and resets
        % the GUI for the next contact, all provided that the operator has
        % selected a valid rating.  Requires verify mode; otherwise does
        % nothing.
        
        % Get selected radio button
        choice = get(hratinggroup, 'SelectedObject');
        if op_mode == 'V' && ~isempty(choice)     % in verfiy mode and rating has been chosen...
            temp_opconf = get(choice, 'UserData');
            if ~isempty(temp_opconf)    % ...and the rating is not 'skip'...
                % import operator choice into contact list
                contacts(img_cnt).opfeedback.opconf = temp_opconf;
                if TB_params.MULTICLASS == 1
                    contacts(img_cnt).opfeedback.type = ...
                        type_vals(get(htypemenu,'Value'));
                end
                if TB_params.TB_HEAVY_TEXT == 1
                    disp(['Selected choice #',num2str(get(choice, 'UserData'))]);
                end
                if TB_params.ARCH_FEEDBACK == 1
                    % archive operator data
                    archive_opfile(img_cnt, TB_params.OPARCHIVE_PATH);
                end

                % wait for opportunity to write to feedback file
                wait_if_flag('opfb_atr_busy.flag');
                % code is now free to edit the feedback file...
                
                % write flag (red)
                write_flag([TB_params.TB_ROOT,filesep,'opfb_op_busy.flag'],...
                    TB_params.FLAG_MSGS_ON);

                % mark contact as processed
                contacts(img_cnt).opfeedback.opdisplay = contacts(img_cnt).opfeedback.opdisplay - dispmod;
                
                % append this contact to the feedback file
                append_feedback(contacts(img_cnt), input.sensor, img_cnt,...
                    TB_params.FEEDBACK_PATH, TB_params.TB_HEAVY_TEXT);
                % increment counter in file
                opfeedback_file_cnt = incr_opfile_cnt();
                
                % delete flag (red)
                delete_flag([TB_params.TB_ROOT,filesep,'opfb_op_busy.flag'],...
                    TB_params.FLAG_MSGS_ON);
                
                % periodically retrain classifier
                if opfeedback_file_cnt >= reclass_at
                    fprintf(1,'\nLaunching classifier update...\n\n');
                    [junk, contacts] = atr_testbed_altfb([], contacts, TB_params); %#ok<ASGLU>
                    % clear feedback file (all updates stored therein have
                    % been incorporated into the contact list
                    reset_opfile_cnt(TB_params.TB_ROOT);
                    figure(f);
                end

    %             fprintf(1, '%-s\n', [' (Contact #',num2str(img_cnt),' of ',num2str(length(contacts))]);

            end
            % advance to next contact
            img_cnt = img_cnt + 1;
            itf_ind = itf_ind + 1;
            % skip over contacts that shouldn't be shown or were manually
            % added (we've already 'seen' these...)
            while img_cnt <= length(contacts) && ...
                    (contacts(img_cnt).opfeedback.opdisplay == 0 || ...
                    strcmpi(contacts(img_cnt).detector,'manual') == 1)
                contacts(img_cnt).opfeedback.opdisplay = contacts(img_cnt).opfeedback.opdisplay - dispmod; % mark processed
                contacts(img_cnt).opfeedback.opconf = 0; %%%%%
                if strcmpi(contacts(img_cnt).detector,'manual') == 0
                    itf_ind = itf_ind + 1;
                end
                img_cnt = img_cnt + 1;
            end
            
            % prepare for next iteration
            if img_cnt > length(contacts)
                % all contacts in this block have been processed
                done = 1;
                close(f);
            else
                % counter is on new contact to be processed
%                 disp(['** Preparing for #',num2str(img_cnt)]);
                cur_x = in_this_file(itf_ind).x;
                cur_y = in_this_file(itf_ind).y;                
                % refresh image snippet
                display_snippet();
                % refresh main image
                display_image_axes();
                if TB_params.MULTICLASS == 1
                    % Set default mine type to be that determined by the classifier
                    def_ind = get_def_index( contacts(img_cnt).class, type_vals );
                    set(htypemenu, 'Value', def_ind);
                end
                % clear radio button selection
                set(hratinggroup, 'SelectedObject', []); 
            end
           
        else
            disp('No choice selected!!');
        end
        
        if TB_params.TB_HEAVY_TEXT == 1
            disp('End of next callback function');
        end
    end


    % Callback function for add button - adds a new contact to the contact
    % list based on a point that the user has chosen in the image, and
    % advances to next existing contact.
    function add_clbk(junk,junk2) %#ok<INUSD>
        % Imports rating data, appends to the feedback file, and resets
        % the GUI for the next contact, all provided that the operator has
        % selected a valid rating.  Requires add mode; otherwise does
        % nothing. Switches to verify mode.
        choice = get(hratinggroup, 'SelectedObject');
        if op_mode == 'A' && ~isempty(choice)     % in add mode and rating has been chosen...
            temp_opconf = get(choice, 'UserData');
            if ~isempty(temp_opconf)    % ...and the rating is not 'skip'...
        set(haddbutton,'Enable','off');
        set(hrevbutton,'Enable','off');
        set(hnextbutton,'Enable','off');

            % add to contact list
            new_ID = length(contacts) + 1;
            [new_contact, new_ecdata] = make_new_contact(new_ID);
            % Find index of new target
            index = find(cur_y == sort([cur_y, [contacts.y].*fmatch]));
            % add contact to the list (mainly to keep track of proper
            % indices in case multiple contacts are added)
            contacts = [contacts(1:(index-1)),new_contact,contacts(index:end)];
            % Update fmatch to prevent mismatch on future add
            fmatch = strcmp({contacts.fn}, filename) & strcmp({contacts.side},side);
            % if contact was inserted before the contact being viewed, the
            % counter must be incremented to keep up.  Also, the opdisplay
            % value must show that it has passed this index
            if index <= img_cnt
                img_cnt = img_cnt + 1;
%                 itf_ind = itf_ind + 1;
                dispmod = 10;
                contacts(index).opfeedback.opdisplay = ...
                    contacts(index).opfeedback.opdisplay - dispmod;
                % advance label number on GUI
%                 set(hlabel, 'String', ['Contact #',num2str(label_nums(img_cnt))]); % redundant
            end
            lab_index = index - num_old;
            % Shift later box labels to reflect inserted contact
            temp = find( lab_index <= box_labels, 1);
            box_labels(temp:end) = box_labels(temp:end) + 1;
            temp = find( lab_index <= opadd_labels, 1);
            opadd_labels(temp:end) = opadd_labels(temp:end) + 1;
            % Add this new location to opadd label list
            temp2 = find(lab_index == sort([lab_index, opadd_labels]));
            opadd_labels = [opadd_labels(1:(temp2-1)), lab_index, opadd_labels(temp2:end)];
            opadds_x = [opadds_x(1:(temp2-1)), cur_x/x_ratio*rng_res, opadds_x(temp2:end)];
            opadds_y = [opadds_y(1:(temp2-1)), cur_y/y_ratio*trk_res, opadds_y(temp2:end)];
            % Lengthen contact label vector to prevent overflow
            label_nums = [label_nums, length(label_nums)+1];
            
            cur_x = in_this_file(itf_ind).x;
            cur_y = in_this_file(itf_ind).y;
            % Add contact to feedback file (this is what really matters for ATR)
            append_opgen_contact(new_contact, new_ecdata, index,...
                TB_params.FEEDBACK_PATH, TB_params.TB_HEAVY_TEXT);
            incr_opfile_cnt();

        set(haddbutton,'Enable','on');
        set(hrevbutton,'Enable','on');
        set(hnextbutton,'Enable','on');
        display_image_axes();
        display_snippet();
        drawnow();
        % after adding contact, switch to verifying next contact
        op_mode = set_mode('V');
            else
                disp('No choice selected!!');
            end
        end
    end

    % Callback function for next/revert button - goes back to the next
    % contact in the list that is to be shown.
    function rev_clbk(junk, junk2) %#ok<INUSD>
        % Switches to verify mode
        
        % Revert to next contact to review
        cur_x = in_this_file(itf_ind).x;
        cur_y = in_this_file(itf_ind).y;
        % clear radio button selection
        set(hratinggroup, 'SelectedObject', []); 
        display_image_axes();
        display_snippet();
        drawnow();
        % switch back to verify mode
        op_mode = set_mode('V');
    end

%% HELPER FUNCITONS - Display
    % Display legend
    function display_legend(x, y)
        % (x,y) is lower-left corner of legend
        w1 = 80; w2 = 105; w3 = 100; w4 = 135; w5 = 135;
        gap = 10;
        h = get(haxes_img,'Parent');
        uicontrol(h, 'Style', 'Text', 'String', 'Detections',...
            'ForegroundColor', lab_colors{1}, 'BackgroundColor','Black',...
            'Position', [x, y+2, w1, 16], 'FontWeight', 'bold');
        uicontrol(h, 'Style', 'Text', 'String', 'Classifications',...
            'ForegroundColor', lab_colors{2}, 'BackgroundColor', 'Black',...
            'Position', [x+w1+gap, y+2, w2, 16], 'FontWeight', 'bold');
        uicontrol(h, 'Style', 'Text', 'String', 'Ground truth',...
            'ForegroundColor', lab_colors{3}, ...
            'Position', [x+w1+w2+2*gap, y+2, w3, 16], 'FontWeight', 'bold');
        uicontrol(h, 'Style', 'Text', 'String', 'Manual Addition',...
            'ForegroundColor', lab_colors{4}, 'BackgroundColor', 'Black',...
            'Position', [x+w1+w2+w3+3*gap, y+2, w4, 16], 'FontWeight', 'bold');
        uicontrol(h, 'Style', 'Text', 'String', 'Current Location',...
            'ForegroundColor', lab_colors{5}, 'BackgroundColor', 'Black',...
            'Position', [x+w1+w2+w3+w4+4*gap, y+2, w5, 16], 'FontWeight', 'bold');
        drawnow
    end

    % Display image and all annotations
    function display_image_axes()
        set(f, 'CurrentAxes', haxes_img);
        % Display image
        display_image(image, range_axis, track_axis, [filename,'  ',side,' ',band_tag], haxes_img);

        % Mark Targets
        if(TB_params.PLOT_OPTIONS(3) > 0) % GT
            mark_gts(gt_x, gt_y, roix, roiy, rng_res, trk_res);
            lab_colors{3} = 'Blue';
        end

        if(TB_params.PLOT_OPTIONS(1) > 0) % DET
            mark_dets(dets_x, dets_y, roix, roiy, rng_res, trk_res, spacery);
            lab_colors{1} = 'Green';
        end

        if(TB_params.PLOT_OPTIONS(2) > 0) % CLASS
            % y is track; x is range
            mark_clss(clss_x, clss_y, clss_x_old, clss_y_old, classes, old_classes,...
                roix, roiy, rng_res, trk_res, spacerx, spacery, split_box, TB_params.MULTICLASS);
            lab_colors{2} = 'Red';
        end
        mark_opadds(opadds_x, opadds_y, roix, roiy, rng_res, trk_res, spacery)
        lab_colors{4} = 'Magenta';
        mark_current(cur_x, cur_y, roix, roiy,...
            rng_res, trk_res, x_ratio, y_ratio);
        lab_colors{5} = 'White';
        drawnow;
    end

    % Display snippet
    function display_snippet()
        set(f, 'CurrentAxes', haxes);
        color_map = change_cmap;
        colormap(color_map);
        ecdata = load_ecd(contacts(img_cnt));
        snippet = ecdata.hfsnippet;
        temp = imadjust(clip_image( abs(snippet) ) ,[0.001 0.70],[],1);
        imagesc(temp);
        title([band_tag,' Snippet']);
        axis image;
        axis xy;
        grid on;
        % refresh contact # label
        set(hlabel, 'String', ['Contact #',num2str(label_nums(img_cnt))]);
        % clear radio button selection
        set(hratinggroup, 'SelectedObject', []);
        
    end

    % Display image
    function display_image(image_data, x_axis, y_axis, filename, hax)
        color_map = change_cmap;
        colormap(color_map);
        image_data = clip_image(image_data);
        image_data = imadjust(image_data,[0.001 0.70],[],1);
        hi = imagesc(image_data, 'XData',x_axis,'Ydata',y_axis,'Parent',hax);
        title(['Full Image: ',filename],'Interpreter', 'none');
        set(gca,'YDir','normal');
%         set(gcf,'Color','black');
%         set(gcf,'inverthardcopy','off');
%         set(gca,'XColor','white','YColor','white');
%         set(get(gca,'Title'),'Color','white');
        set(hi,'ButtonDownFcn', {@img_click_clbk});
        xlabel('Range (m)');
        ylabel('Along-Track (m)');
        axis image;
        axis xy;
        grid on;
    end

%% HELPER FUNCTIONS - Markings
    % Mark manually added contacts
    function mark_opadds(oas_x, oas_y, roix, roiy, rng_res, trk_res, spacery)
    % y is track; x is range
    xsize=fix(roix)* rng_res;
    ysize=fix(roiy)* trk_res;
    for ii = 1:length(oas_x)
        line([oas_x(ii)+xsize oas_x(ii)+xsize],[oas_y(ii)-ysize oas_y(ii)+ysize],'LineWidth',3,'Color','m','LineStyle','--');
        line([oas_x(ii)-xsize oas_x(ii)-xsize],[oas_y(ii)-ysize oas_y(ii)+ysize],'LineWidth',3,'Color','m','LineStyle','--');
        line([oas_x(ii)-xsize oas_x(ii)+xsize],[oas_y(ii)-ysize oas_y(ii)-ysize],'LineWidth',3,'Color','m','LineStyle','--');
        line([oas_x(ii)-xsize oas_x(ii)+xsize],[oas_y(ii)+ysize oas_y(ii)+ysize],'LineWidth',3,'Color','m','LineStyle','--');
        text(oas_x(ii), oas_y(ii)-ysize-spacery,num2str(opadd_labels(ii)),'Color','white',...
            'VerticalAlignment','top', 'HorizontalAlignment', 'center',...
            'Clipping', 'on');
    end
    end

    % Mark ground truth
    function mark_gts(gt_x, gt_y, roix, roiy, rng_res, trk_res)
    if ~isempty(gt_x)
        % y is track; x is range
        xsize=fix((roix+15))* rng_res;
        ysize=fix((roiy+15))* trk_res;
        for ii = 1:length(gt_x)
            line([gt_x(ii)+xsize gt_x(ii)+xsize],[gt_y(ii)-ysize gt_y(ii)+ysize],'LineWidth',3,'Color','b');
            line([gt_x(ii)-xsize gt_x(ii)-xsize],[gt_y(ii)-ysize gt_y(ii)+ysize],'LineWidth',3,'Color','b');
            line([gt_x(ii)-xsize gt_x(ii)+xsize],[gt_y(ii)-ysize gt_y(ii)-ysize],'LineWidth',3,'Color','b');
            line([gt_x(ii)-xsize gt_x(ii)+xsize],[gt_y(ii)+ysize gt_y(ii)+ysize],'LineWidth',3,'Color','b');
        end
    end
    end

    % Mark detections
    function mark_dets(dets_x, dets_y, roix, roiy, rng_res, trk_res, spacery)
    % y is track; x is range
    xsize=fix(roix)* rng_res;
    ysize=fix(roiy)* trk_res;
    for ii = 1:length(dets_x)
        line([dets_x(ii)+xsize dets_x(ii)+xsize],[dets_y(ii)-ysize dets_y(ii)+ysize],'LineWidth',3,'Color','g');
        line([dets_x(ii)-xsize dets_x(ii)-xsize],[dets_y(ii)-ysize dets_y(ii)+ysize],'LineWidth',3,'Color','g');
        line([dets_x(ii)-xsize dets_x(ii)+xsize],[dets_y(ii)-ysize dets_y(ii)-ysize],'LineWidth',3,'Color','g');
        line([dets_x(ii)-xsize dets_x(ii)+xsize],[dets_y(ii)+ysize dets_y(ii)+ysize],'LineWidth',3,'Color','g');
        text(dets_x(ii), dets_y(ii)-ysize-spacery,num2str(box_labels(ii)),'Color','white',...
            'VerticalAlignment','top', 'HorizontalAlignment', 'center',...
            'Clipping', 'on');
%         text(dets_x(ii), dets_y(ii)-ysize-spacery,num2str(ii),'Color','white',...
%             'VerticalAlignment','top', 'HorizontalAlignment', 'center',...
%             'Clipping', 'on');
    end
    end

    % Mark classifications
    function mark_clss(clss_x, clss_y, clss_x_old, clss_y_old, classes, old_classes,...
            roix, roiy, rng_res, trk_res, spacerx, spacery, split_box, multiclass)
    xsize=fix(roix)* rng_res;
    ysize=fix(roiy)* trk_res;
    if split_box == 1   % comparing to previous results
    for ii = 1:length(clss_x_old)   % left side of box (old)
        line([clss_x_old(ii)-xsize clss_x_old(ii)-xsize],[clss_y_old(ii)-ysize clss_y_old(ii)+ysize],'LineWidth',3,'Color','r');
        line([clss_x_old(ii)-xsize clss_x_old(ii)],[clss_y_old(ii)-ysize clss_y_old(ii)-ysize],'LineWidth',3,'Color','r');
        line([clss_x_old(ii)-xsize clss_x_old(ii)],[clss_y_old(ii)+ysize clss_y_old(ii)+ysize],'LineWidth',3,'Color','r');
        % Technically we want the TB_params from the previous run, but those
        % aren't saved.  This is a decent approximation.
        if multiclass == 1
        text(clss_x_old(ii)-xsize-spacerx, clss_y_old(ii), ['C=',num2str(old_classes(ii))],'Color','white',...
            'VerticalAlignment','middle','HorizontalAlignment','right',...
            'Clipping', 'on');
        end
    end
    for ii = 1:length(clss_x)       % right side of box (new)
        line([clss_x(ii)+xsize clss_x(ii)+xsize],[clss_y(ii)-ysize clss_y(ii)+ysize],'LineWidth',3,'Color','r');
        line([clss_x(ii) clss_x(ii)+xsize],[clss_y(ii)-ysize clss_y(ii)-ysize],'LineWidth',3,'Color','r');
        line([clss_x(ii) clss_x(ii)+xsize],[clss_y(ii)+ysize clss_y(ii)+ysize],'LineWidth',3,'Color','r');
        if multiclass == 1
        text(clss_x(ii)+xsize+spacerx, clss_y(ii), ['C=',num2str(classes(ii))],'Color','white',...
            'VerticalAlignment','middle','HorizontalAlignment','left',...
            'Clipping', 'on');
        end
    end
    else    % no previous comparison
    for ii = 1:length(clss_x)
        line([clss_x(ii)+xsize clss_x(ii)+xsize],[clss_y(ii)-ysize clss_y(ii)+ysize],'LineWidth',3,'Color','r');
        line([clss_x(ii)-xsize clss_x(ii)-xsize],[clss_y(ii)-ysize clss_y(ii)+ysize],'LineWidth',3,'Color','r');
        line([clss_x(ii)-xsize clss_x(ii)+xsize],[clss_y(ii)-ysize clss_y(ii)-ysize],'LineWidth',3,'Color','r');
        line([clss_x(ii)-xsize clss_x(ii)+xsize],[clss_y(ii)+ysize clss_y(ii)+ysize],'LineWidth',3,'Color','r');
        if multiclass == 1
        text(clss_x(ii), clss_y(ii)+ysize+spacery, ['C=',num2str(classes(ii))],'Color','white',...
            'VerticalAlignment','bottom', 'HorizontalAlignment', 'center',...
            'Clipping', 'on');
        end
    end
    end
    end

    % Mark current location
    function mark_current(x, y, roix, roiy, rng_res, trk_res, x_ratio, y_ratio)
    temp_x = x/x_ratio * rng_res;
    temp_y = y/y_ratio * trk_res;
    xsize=fix(roix)* rng_res;
    ysize=fix(roiy)* trk_res;
%     % diamond
%     line([temp_x temp_x+2*xsize], [temp_y+2*ysize temp_y],'LineWidth',2,...
%         'Color','w', 'LineStyle', ':');
%     line([temp_x+2*xsize temp_x], [temp_y temp_y-2*ysize],'LineWidth',2,...
%         'Color','w', 'LineStyle', ':');
%     line([temp_x temp_x-2*xsize], [temp_y-2*ysize temp_y],'LineWidth',2,...
%         'Color','w', 'LineStyle', ':');
%     line([temp_x-2*xsize temp_x], [temp_y temp_y+2*ysize],'LineWidth',2,...
%         'Color','w', 'LineStyle', ':');
    % top-left corner
    line([temp_x-1.2*xsize, temp_x-1.2*xsize, temp_x-0.8*xsize],...
        [temp_y+0.8*ysize, temp_y+1.2*ysize, temp_y+1.2*ysize],...
        'LineWidth', 2, 'Color', 'w');
    % top-right corner
    line([temp_x+1.2*xsize, temp_x+1.2*xsize, temp_x+0.8*xsize],...
        [temp_y+0.8*ysize, temp_y+1.2*ysize, temp_y+1.2*ysize],...
        'LineWidth', 2, 'Color', 'w');
    % bottom-right corner
    line([temp_x+1.2*xsize, temp_x+1.2*xsize, temp_x+0.8*xsize],...
        [temp_y-0.8*ysize, temp_y-1.2*ysize, temp_y-1.2*ysize],...
        'LineWidth', 2, 'Color', 'w');
    % bottom-left corner
    line([temp_x-1.2*xsize, temp_x-1.2*xsize, temp_x-0.8*xsize],...
        [temp_y-0.8*ysize, temp_y-1.2*ysize, temp_y-1.2*ysize],...
        'LineWidth', 2, 'Color', 'w');
    end


%% HELPER FUNCTIONS - Other

    function mode = set_mode(mode_char)
        switch mode_char
            case 'A'
                mode = 'A';
                set(haddbutton, 'Enable', 'on');
                set(hrevbutton, 'Enable', 'on');
                set(hnextbutton, 'Enable', 'off');
            case 'V'
                mode = 'V';
                set(haddbutton, 'Enable', 'off');
                set(hrevbutton, 'Enable', 'off');
                set(hnextbutton, 'Enable', 'on');
            otherwise
                error('Invalid mode %s',mode_char);
        end
        
    end

    % Create a new contact
    %
    % Note: Several of these values are just placeholders.
    function [contact, ecdata] = make_new_contact(new_ID)
        opconf = get_rating();
        contact = struct();
        contact.x = cur_x;
        contact.y = cur_y;
        contact.features = []; %%%
        contact.fn = filename;
        contact.side = side;
        contact.normalizer = '???'; %%%
        contact.detector = 'Manual';
        contact.featureset = '???'; %%%
        contact.classifier = 'Manual';
        contact.class = 1*(opconf > 3); %%%
        contact.classconf = opconf/5; %%%
        contact.type = -99; %%%
        contact.contcorr = '';
        contact.opfeedback.opdisplay = 4; %%%
        contact.opfeedback.opconf = opconf;
        if TB_params.MULTICLASS == 1
            contact.opfeedback.type = type_vals( get(htypemenu, 'Value') );
        else
            contact.opfeedback.type = -99;
        end
        contact.gt = 1;
        contact.ID = new_ID;
        contact.ecdata_fn = ''; %%%
        
        ecdata.hfsnippet = snippet;
        ecdata.bbsnippet = [];
        ecdata.lf1snippet = [];
        [junk, ecdata] = detsub_contact_fill(contact, ecdata, 1, input);
    end

    function [image, band_tag, rng_res, trk_res, x_ratio, y_ratio, roix, roiy] = ...
            get_disp_params(input, TB_params)
        [m_hf, n_hf] = size(input.hf); [m_bb, n_bb] = size(input.bb);
        [detname, var] = get_detname(TB_params);
        if strcmpi(var, 'BB') == 1      % using BB detector
            if strcmpi(input.sensor, 'SSAM III') && ~isempty(input.lf1)
                image = abs(input.lf1);
                band_tag = 'LF1';
                [m_lf1, n_lf1] = size(input.lf1);
            else
                image = abs(input.bb);
                band_tag = 'BB';
            end
        elseif  ~isempty(input.hf)      % using HF detector, or both bands
            % use HF image if available
            image = abs(input.hf);
            band_tag = 'HF';
        elseif ~isempty(input.bb)
            image = abs(input.bb);
            band_tag = 'BB';
        else 
            error('No data input to general display function')
        end

        switch band_tag
            case {'HF','hf'}
                rng_res = input.hf_cres;
                trk_res = input.hf_ares;
                y_ratio = 1; x_ratio = 1;
                switch input.sensor
                    case {'ONR SSAM','ONR SSAM2','MK 18 mod 2'}
                        roix = 130;
                        roiy = 100;
                    case 'MUSCLE'
                        roix = 60;
                        roiy = 70;
                    case 'EDGETECH'
                        roix = 2;
                        roiy = 300;
                    otherwise
                        error('Sensor not recognized')
                end
            case {'BB','bb'}
                rng_res = input.bb_cres;
                trk_res = input.bb_ares;
                y_ratio = m_hf/m_bb; x_ratio = n_hf/n_bb;
                switch input.sensor
                    case {'ONR SSAM','ONR SSAM2','MK 18 mod 2'}
                        roix = round(75/x_ratio);
                        roiy = round(50/y_ratio);
                    case 'MUSCLE'
                        roix = round(60/x_ratio);
                        roiy = round(70/y_ratio);
                    case 'EDGETECH'
                        roix = round(2/x_ratio);
                        roiy = round(300/y_ratio);              
                    otherwise
                        error('Sensor not recognized')
                end
            case {'LF1','lf1'}
                rng_res = input.lf1_cres;
                trk_res = input.lf1_ares;
                y_ratio = m_hf/m_lf1; x_ratio = n_hf/n_lf1;
                switch input.sensor
                    case 'SSAM III'
                        roix = round(75/x_ratio);
                        roiy = round(50/y_ratio);  
                end
        end
    end

    function ecd = load_ecd(contact)
        ecd_fname = contact.ecdata_fn;
        assert(~isempty(ecd_fname), 'Filename for ecdata is empty');
        ecd = read_extra_cdata(ecd_fname);
    end

    function val = incr_opfile_cnt()
        % increment the value stored in the opfeedback counter file
        cnt_fid = fopen([TB_params.TB_ROOT,filesep,'feedback_cnt.txt'], 'r+'); %read and write
        if cnt_fid == -1
            % file could not be opened (does not exist?); I doubt this will
            % happen, but just in case, use write-only mode instead and
            % reset the counter
            cnt_fid = fopen([TB_params.TB_ROOT,filesep,'feedback_cnt.txt'], 'w'); %write only
            val = 1;
        else
            % file opened safely
            val = fread(cnt_fid, 1, 'uint8');
            val = val + 1;
        end
        % move pointer back to the beginning
        fseek(cnt_fid, 0, 'bof');
        fwrite(cnt_fid, val, 'uint8');
        fclose(cnt_fid);
    end

    function archive_opfile(index, arc_path)
        % save feedback data to archive
        % index    = list index of contact to be archived
        % arc_path = location of the archive file
        
        if TB_params.TB_HEAVY_TEXT == 1
            disp([' Appending to opfile archive contact #',num2str(index),...
                ' of ',num2 str(length(contacts)),'...']);
        else
            fprintf(1,'%-s','+');
        end
        fid = fopen(arc_path, 'a');
        % index
        fwrite(fid, index, 'uint8');
        % filename
        len = length(contacts(index).fn);
        fwrite(fid, len, 'uint8');
        fwrite(fid, contacts(index).fn, 'uchar');
        % side
        fwrite(fid, contacts(index).side, 'uchar');
        fwrite(fid, contacts(index).x, 'uint16');
        fwrite(fid, contacts(index).y, 'uint16');
        % fwrite(fid, contacts(index).opfeedback.opdisplay, 'int8');
        fwrite(fid, contacts(index).opfeedback.opconf, 'int8');
               
        fclose(fid);
    end

    function ind = get_def_index(val, val_list)
        ind = find( val == val_list , 1);
        if isempty(ind)
            ind = 1;
        end
    end

    function rating = get_rating()
        handle = get(hratinggroup, 'SelectedObject');
        switch handle
            case hr1
                rating = 1;
            case hr2
                rating = 2;
            case hr3
                rating = 3;
            case hr4
                rating = 4;
            case hr5
                rating = 5;
            otherwise
                rating = [];
        end
    end

%     function block_opconf()
%         % disable radio buttons
%         set(hrs, 'Enable', 'off');
%         set(hr1, 'Enable', 'off');
%         set(hr2, 'Enable', 'off');
%         set(hr3, 'Enable', 'off');
%         set(hr4, 'Enable', 'off');
%         set(hr5, 'Enable', 'off');
%         set(hnextbutton, 'Enable', 'off');
%     end
% 
%     function unblock_opconf()
%         % disable radio buttons
%         set(hrs, 'Enable', 'on');
%         set(hr1, 'Enable', 'on');
%         set(hr2, 'Enable', 'on');
%         set(hr3, 'Enable', 'on');
%         set(hr4, 'Enable', 'on');
%         set(hr5, 'Enable', 'on');
%         if TB_params.OPCONF_MODE == 0
%             set(hnextbutton, 'Enable', 'off');
%         end
%     end
% 
%     function add_clbk_stub(junk, junk2) %#ok<INUSD>
%         % stub... revert to next contact to review
%         cur_x = in_this_file(itf_ind).x;
%         cur_y = in_this_file(itf_ind).y;
%         display_image_axes();
%         display_snippet();
%         drawnow();
%     end
end