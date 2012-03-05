function [dest, changed] = copy_valid_str_field(src, dest, field)

changed = 0;
if isfield(src, field) && ~isempty(src.(field))
    dest.(field) = src.(field);
    changed = 1;
end

end