% function write_backups(c_list, lock_ind_old, lock_ind_new, TB_params)
function write_backups(c_list, lock_ind_old, lock_ind_new,...
    filename_lock, filename_unlock, show_details)
% Writes the contact list (c_list) over two files: filename_lock, for
% past contacts that cannot be changed again, and filename_unlock, for more
% recent contacts that may be reclassified again.
%
% Normally, the locked list is only appended to, since by definition the
% contacts within the locked list cannot change.  However, it may be
% desirable to manually remove a contact that causes problems for the ATR,
% which would also require removing it from the locked backup.  In this
% case, call this function with 'lock_ind_old' == 0.  This will mimic the
% first call to this function and overwrite the locked backup with all
% contacts up to and including # lock_ind_new.
%
% INPUTS:
% c_list = a contact list
% lock_ind_old = index of last locked contact from previous ATR call
% lock_ind_new = index of last locked contact from current ATR call
% filename_lock = file name of the backup file used to store unchangeable
%   contacts
% filename_unlock = file name of the backup file used to store contacts
%   that can still be updated
%
% Derek Kolacinski, NSWC PC (derek.kolacinski@navy.mil)
% Last update: 08 June 2010

% filename_lock = TB_params.L_BKUP_PATH;
% filename_unlock = TB_params.U_BKUP_PATH;
% show_details = TB_params.TB_HEAVY_TEXT;

% Write last locked index in first slot
fid = fopen(filename_unlock,'w');
if fid ~= -1
    fwrite(fid, lock_ind_new, 'uint16');
    fprintf(1,'Lock index written to backup: %d\n',lock_ind_new);
    fclose(fid);
else
    fprintf(1,'Unlock file %s could not be opened.\n', filename_unlock);
%     fid = fopen(filename_lock,'w');
%     fwrite(fid, lock_ind_new, 'uint16');
%     fclose(fid);
end
% keyboard
% Append all newly locked contacts to the permanent backup file.
new_locked = c_list((lock_ind_old+1):lock_ind_new);
unlocked = c_list((lock_ind_new+1):end);
if ~isempty(new_locked)     % if new locked contacts to write...
    if show_details == 1
        fprintf(1,' Adding contact #%d-%d to locked list\n',lock_ind_old+1,...
            lock_ind_new);
    end
    if lock_ind_old == 0
        % Overwrite the locked backup: (Either this is the first call of
        % the run, or the backup is being manually reset.)
        write_contacts(filename_lock, new_locked, 'w');
    else
        % Append the locked backup as normal.
        write_contacts(filename_lock, new_locked, 'a');
    end
else
    if show_details == 1
        fprintf(1,' No locked contacts to add to locked list\n');
    end
end
% Append all unlocked contacts to the temporary backup file. (Note:
% combined with the overwriting statement above regarding lock_ind_new,
% this is effectively overwriting the previous temporary backup file.)
if ~isempty(unlocked)
    if show_details == 1
        fprintf(1,' Overwriting contact #%d-%d in unlocked list\n',lock_ind_new+1,...
            length(c_list));
    end
    write_contacts(filename_unlock, unlocked, 'a');
else
    if show_details == 1
        fprintf(1,' No unlocked contacts to add to unlocked list\n');
    end
end

end