function subset = filter_db(cond, db)
% Selects a subset of the data containing all members who meet condition
% 'cond'.
temp = regexp(cond, '(\S+)', 'tokens');
field = temp{1}{1}; %#ok<NASGU>
op = temp{2}{1};
value = temp{3}{1};
eval(['mask = arrayfun(@(a) (a.(field) ',op,' ',value,'), db);']);
subset = db(mask);
end