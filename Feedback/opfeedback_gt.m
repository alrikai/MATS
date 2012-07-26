function contacts = opfeedback_gt(contacts, sensor, TB_params)
% stand-in for operator feedback. Uses ground truth as user input.
%
% contacts (in) = array of contact structures representing potential
%   targets in all images up to this point
% TB_params = testbed configuration structure
%
% contacts (out) = same as above, but with field .opfeedback.opconf
%   filled in.
%
% Bailey Kong, UtopiaCompression Corp. (bailey@utopiacompression.com)
% Last update: 8 Mar 2012

% negative offset for .opdisplay. This will be subracted from the initial
% values to indicate that the contact has been viewed and processed.
dispmod = 10;
% Start at beginning of newest image
img_cnt = 1;
% Track the number of contacts processed per pass
query_cnt = 0;
% Track the number of contacts processed total
total_queries = 0;

% find the first contact to show
img_cnt = find_next_contact(img_cnt);
% in the event that there are no contacts to view, prepare to exit quickly
if img_cnt > length(contacts)
    done = 1;
else
    done = 0;
end

% wait loop
while 0 == 0
    if done == 1
        fprintf(1,'\n%-s\n\n','Operator block done.');
        return
    else
        % wait for opportunity to write to feedback file
        wait_if_flag('opfb_atr_busy.flag');
        % code is now free to edit the feedback file...
        
        % write flag (red)
        write_flag([TB_params.TB_ROOT,filesep,'opfb_op_busy.flag'],...
            TB_params.FLAG_MSGS_ON);

        if contacts(img_cnt).gt == 1
            contacts(img_cnt).opfeedback.opconf = 5;
        elseif contacts(img_cnt).gt == 0
            contacts(img_cnt).opfeedback.opconf = 1;
        else
            contacts(img_cnt).opfeedback.opconf = 3;
        end
        % mark contact as processed
        contacts(img_cnt).opfeedback.opdisplay = contacts(img_cnt).opfeedback.opdisplay - dispmod;
        query_cnt = query_cnt + 1;
        total_queries = total_queries + 1;
        
        % append this contact to the feedback file
        append_feedback(contacts(img_cnt), sensor, img_cnt,...
            TB_params.FEEDBACK_PATH, TB_params.TB_HEAVY_TEXT);
        % increment counter in file
        opfeedback_file_cnt = incr_opfile_cnt();
        
        % delete flag (red)
        delete_flag([TB_params.TB_ROOT,filesep,'opfb_op_busy.flag'],...
            TB_params.FLAG_MSGS_ON);
        
        % advance to next contact
        img_cnt = img_cnt + 1;
        % find the next contact to show.
        img_cnt = find_next_contact(img_cnt);
        
        % check for exit case
        if total_queries >= TB_params.FEEDBACK_LIMIT
            done = 1;
        elseif img_cnt > length(contacts)
            if query_cnt == 0
                done = 1;
            else
                img_cnt = 1;
                query_cnt = 0;
                % retrain classifier after each pass
                fprintf(1,'\nLaunching classifier update...\n\n');
                [junk, contacts] = atr_testbed_altfb([], contacts, TB_params);
                % clear feedback file (all updates stored therein have
                % been incorporated into the contact list
                reset_opfile_cnt(TB_params.TB_ROOT);

                % find the next contact to show.
                img_cnt = find_next_contact(img_cnt);
                if img_cnt > length(contacts)
                    done = 1;
                end
            end
        end
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

    function img_cnt = find_next_contact(img_cnt)
        while img_cnt <= length(contacts) && ...
            (contacts(img_cnt).opfeedback.opdisplay <= 0 || strcmpi(contacts(img_cnt).detector,'manual') == 1)
          img_cnt = img_cnt + 1;
        end
    end

end
