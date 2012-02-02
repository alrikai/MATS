function fields = check_fields(fields, db)

tokens = regexp(fields, '(\S+)', 'tokens');
valid_fields = cellfun(@(a) (isfield(db,a)),tokens);

fields = tokens(valid_fields);
for q = 1:length(fields)
    fields(q) = fields{q};
end
end