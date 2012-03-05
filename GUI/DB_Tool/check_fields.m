% function nesteds = check_fields(fields, db)
function nesteds = check_fields_alt(fields, db)

tokens = regexp(fields, '([A-Za-z\._]+)', 'tokens');
valid_fields = cellfun(@(a) (isfield(db,a)),tokens);

%test for nested
nesteds = cell(10, length(tokens));
for q = 1:length(tokens)
    [t,s] = regexp(tokens{q}, '(\.)', 'tokens', 'split');
    if length(s{1}) >= 2
        go = 1; n = 2;
        lvl1_exists = isfield(db(q), s{1}{1});
        assert(lvl1_exists, 'Error');
        lvl1 = s{1}{1};
        nesteds{1,q} = lvl1;
        temp = db(q).(lvl1);
        while go == 1 && n <= length(s{1})
            % there is a period; test if the nested var is valid
            if isstruct(temp) && isfield(temp, s{1}{n});
                temp = temp.(s{1}{n});
                nesteds{n,q} = s{1}{n};
                n = n + 1;
            else
                go = 0;
            end
        end
        valid_fields(q) = go; % go == 1 if it reached the end of the field string
    elseif length(s{1}) == 1 && valid_fields(q)
        nesteds{1,q} = s{1}{1};
    end
end
% nesteds = nesteds(:,valid_fields);
temp = find( prod( cellfun(@(a) (isempty(a)*1),nesteds), 2), 1, 'first');
nesteds = nesteds(1:(temp-1), valid_fields);
end