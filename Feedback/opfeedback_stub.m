function contacts = opfeedback_stub(contacts, TB_params, varargin)
% stand-in for operator feedback.  Shows images and allows for user input.
% Adds user input to a hard-coded feedback file.  Optionally, this function
% can also write user input to an archive file to be used for later
% testing.  (Right now, there is only one hard-coded archive location so
% if this is to be expanded/include in the NSWC testbed, user-defined file
% paths would have to be implemented.)
%
% contacts (in) = array of contact structures representing potential
%   targets in all images up to this point
% TB_params = testbed configuration structure
%
% contacts (out) = same as above, but with field .opfeedback.opconf
%   filled in.
%
% Derek Kolacinski, NSWC PC (derek.kolacinski@navy.mil)
% Last update: 10 Feb 2010

full_version = 0; % 1 = normal mode; 0 = public release version

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
% if isempty(contacts) == 1, return, end;

% negative offset for .opdisplay. This will be subracted from the initial
% values to indicate that the contact has been viewed and processed.
dispmod = 10;
% Start at beginning of newest image
img_cnt = 1;
% number of contacts to be processed by the operator before reclassification
% occurs.
reclass_at = 5;

% skip over contacts at the beginning that have been already marked as
% viewed
while img_cnt <= length(contacts) && contacts(img_cnt).opfeedback.opdisplay < 0
    img_cnt = img_cnt + 1;
end
% skip over contacts that won't be shown
while img_cnt <= length(contacts) && contacts(img_cnt).opfeedback.opdisplay <= 0
% while img_cnt <= length(contacts) && contacts(img_cnt).opfeedback.opdisplay == 0
    contacts(img_cnt).opfeedback.opdisplay = contacts(img_cnt).opfeedback.opdisplay - dispmod; % mark processed
    contacts(img_cnt).opfeedback.opconf = 0; %%%%%
    img_cnt = img_cnt + 1;
%     lastview_index = img_cnt;
end
% in the event that there are no contacts to view, prepare to exit quickly
if img_cnt > length(contacts)
    done = 1;
else
    done = 0;
end

%%% GUI
f = figure(2);
set(f, 'Visible', 'off', 'Position', [200, 300, 400, 500])
spacing = 20; 

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

hlabel = uicontrol('Style', 'text', 'String', ['Contact #',num2str(label_nums(img_cnt))],...
    'Position', [10, 10+6*spacing, 100, 16]);

hnextbutton = uicontrol('Style', 'pushbutton', 'String', 'Next',...
    'Position', [110, 10+6*spacing, 50, 16], 'Callback', {@next_clbk});

if full_version
uicontrol('Style', 'text', 'String', 'Add bogus contact @ index',...
    'Position', [210, 10+6*spacing,100,16]);
haddinput = uicontrol('Style', 'edit',...
    'Position', [310, 10+6*spacing,50,16]);
haddbutton = uicontrol('Style', 'pushbutton', 'String', 'Add',...
    'Position', [210, 10+5*spacing,100,16], 'Callback', {@add_clbk});
end

haxes = axes('Position', [.1, .35, .8, .6], 'Color', 'white');

set(f, 'Name', 'Rating Feedback Stub', 'NumberTitle', 'off', 'Visible', 'on');

% wait loop
while 0 == 0
    if done == 1
        fprintf(1,'\n%-s\n\n','Operator block done.');
        return
    else
        disp('Waiting for operator response...');
        figure(f);
        set(f, 'CurrentAxes', haxes);
        imagesc(abs(contacts(img_cnt).hfsnippet));
        waitfor(f)
    end
end
%%% CALLBACKS
    % Callback function for add button
    function add_clbk(junk,junk2)
        % Adds a bogus contact at the location specified in the text field,
        % provided that that location is valid for the current contact
        % list.
        set(haddbutton,'Enable','off');
        set(hnextbutton,'Enable','off');
        index = str2double( get(haddinput, 'String') );
        if ischar(index)
            disp('Input to text box must be a number');
        elseif round(index) ~= index
            disp('Input to test box must be an integer');
        elseif index > 0 && index > length(contacts) + 1
            disp('Index out of range');
        else
            % okay to add to contact list
            load('bs_contact.mat', 'bs_contact');
            new_ID = length(contacts) + 1;
            bs_contact.ID = new_ID;
            % add contact to the list (mainly to keep track of proper
            % indices in case multiple contacts are added)
            contacts = [contacts(1:(index-1)),bs_contact,contacts(index:end)];
            % if contact was inserted before the contact being viewed, the
            % counter must be incremented to keep up.  Also, the opdisplay
            % value must show that it has passed this index
            if index <= img_cnt
                img_cnt = img_cnt + 1;
                dispmod = 10;
                contacts(index).opfeedback.opdisplay = ...
                    contacts(index).opfeedback.opdisplay - dispmod;
                % advance label number on GUI
                set(hlabel, 'String', ['Contact #',num2str(label_nums(img_cnt))]);
            end
            % add contact to feedback file (this is what really matters)
            append_opgen_contact(bs_contact, index,...
                TB_params.FEEDBACK_PATH, TB_params.TB_HEAVY_TEXT);
            incr_opfile_cnt();
        end
        set(haddbutton,'Enable','on');
        set(hnextbutton,'Enable','on');
    end

    % Callback function for next button
    function next_clbk(junk, junk2)
        % Imports rating data, appends to the feedback file, and resets
        % the GUI for the next image, all provided that the operator has
        % selected a valid rating.
        
        % get selected radio button
        choice = get(hratinggroup, 'SelectedObject');
        if ~isempty(choice)     % something has been chosen...
            temp_opconf = get(choice, 'UserData');
            if ~isempty(temp_opconf)    % ...and the choice was not skipped...
                % import operator choice into contact list
                contacts(img_cnt).opfeedback.opconf = temp_opconf;
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
                append_feedback(contacts(img_cnt), img_cnt,...
                    TB_params.FEEDBACK_PATH, TB_params.TB_HEAVY_TEXT);
                % increment counter in file
                opfeedback_file_cnt = incr_opfile_cnt();
                
                % delete flag (red)
                delete_flag([TB_params.TB_ROOT,filesep,'opfb_op_busy.flag'],...
                    TB_params.FLAG_MSGS_ON);
                
                % periodically retrain classifier
                if opfeedback_file_cnt >= reclass_at
                    fprintf(1,'\nLaunching classifier update...\n\n');
                    [junk, contacts] = atr_testbed_altfb([], contacts, TB_params);
                    % clear feedback file (all updates stored therein have
                    % been incorporated into the contact list
                    reset_opfile_cnt(TB_params.TB_ROOT);
                    figure(f);
                end

    %             fprintf(1, '%-s\n', [' (Contact #',num2str(img_cnt),' of ',num2str(length(contacts))]);

            end
            % advance to next contact
            img_cnt = img_cnt + 1;
            % skip over contacts that shouldn't be shown or were manually
            % added (we've already 'seen' these...)
            while img_cnt <= length(contacts) && ...
                    (contacts(img_cnt).opfeedback.opdisplay == 0 || ...
                    strcmpi(contacts(img_cnt).detector,'manual') == 1)
                contacts(img_cnt).opfeedback.opdisplay = contacts(img_cnt).opfeedback.opdisplay - dispmod; % mark processed
                contacts(img_cnt).opfeedback.opconf = 0; %%%%%
                img_cnt = img_cnt + 1;
            end
            
            % prepare for next iteration
            if img_cnt > length(contacts)
                % all contacts in this block have been processed
%                 disp('** Wrapping up process...');
                % clear image snippet
                cla(haxes);
                % set contact label to final message
                set(hlabel, 'String', 'Press any key.');
                % clear radio button selection
                set(hratinggroup, 'SelectedObject', []); 
                % disable radio buttons
                set(hrs, 'Enable', 'off');
                set(hr1, 'Enable', 'off');
                set(hr2, 'Enable', 'off');
                set(hr3, 'Enable', 'off');
                set(hr4, 'Enable', 'off');
                set(hr5, 'Enable', 'off');
                set(hnextbutton, 'Enable', 'off');
                done = 1;
                close(f);
            else
                % counter is on new contact to be processed
%                 disp(['** Preparing for #',num2str(img_cnt)]);                
                % refresh image snippet
                set(f, 'CurrentAxes', haxes);
                imagesc(abs(contacts(img_cnt).hfsnippet));
                % refresh contact # label
                set(hlabel, 'String', ['Contact #',num2str(label_nums(img_cnt))]);
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

%%% HELPER FUNCTIONS
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

end