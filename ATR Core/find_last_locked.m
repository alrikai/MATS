function lastlock_index = find_last_locked(contacts, show_details)
% Determine the last 'lockable' contact (i.e., the last one whose data is
% fixed and will no longer change).  This is done by forward searching the
% list for an .opconf value < 0, which indicates an unlocked contact.

% lastlock_index = 0;
lastlock_index = length(contacts);
tempdone = 0;
tempmarker = 1;
while tempmarker <= length(contacts) && tempdone == 0
    if contacts(tempmarker).opfeedback.opconf < 0
        % contacts(tempmarker) is the first unlocked contact
        
        % Mark the previous contact with lastlock_index
        lastlock_index = tempmarker - 1;
        tempdone = 1;
    end
    tempmarker = tempmarker + 1;
end
% if tempdone == 0
%    % No negative values exist (all values are locked)
%    
%    % Mark the last contact with lastlock_index
%    lastlock_index = length(contacts);
% end
if show_details == 1
    fprintf(1, 'Index last locked: %d\n\n', lastlock_index);
end
end
        