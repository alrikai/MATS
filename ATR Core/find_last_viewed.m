function lastview_index = find_last_viewed(contacts, new_img_ind, show_details)
% Determine last contact that the operator saw.  Start at the first contact
% from this image and move backward through the list until: get to a negative
% value of opdisplay or before the beginning of the list (0) if none
% viewed

if isempty(new_img_ind)
    % if start of new image is unknown, start the search at the end of the
    % contact list
    tempmarker = length(contacts);
else
    tempmarker = new_img_ind - 1;
end
tempdone = 0;
lastview_index = 0;
while tempmarker > 1 && tempdone == 0
    if contacts(tempmarker).opfeedback.opdisplay < 0
        lastview_index = tempmarker;
        tempdone = 1;
    end
    tempmarker = tempmarker - 1;
end
if show_details == 1
    fprintf(1, 'Index last viewed by the operator: %d\n\n', lastview_index);
end
end