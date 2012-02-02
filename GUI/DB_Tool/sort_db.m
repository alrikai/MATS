function sorted_db = sort_db(fields, db, desc)
% fields = fields to sort by
% db = database/contact list
% desc = 1 - descending, 0 - ascending
%
% sorted = sorted/reorganized database/contact list

fields = check_fields(fields, db);
data = zeros([length(db), length(fields)]);
for q = 1:length(fields)
    temp = [db.(fields{1})];
%     data(:,q) = temp.';
    for w = 1:length(db)
        data(w,q) = temp(w);
    end
end


if desc == 1
    [junk, new_indices] = sort(data, 1, 'descend'); %#ok<*ASGLU>
elseif desc == 0
    [junk, new_indices] = sort(data, 1, 'ascend');
else
    error('desc parameter must be 0 or 1.');
end
sorted_db = db(new_indices);
end