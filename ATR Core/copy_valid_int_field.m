function [dest, changed] = copy_valid_int_field(src, dest, field, range)
% Copies a field from source structure (src) to destination structure
% (dest) if the field contains a valid integer value, or several such
% values in vector.

changed = 0;
if isfield(src, field) && all( ismember(src.(field), range) )
% if isfield(src, field) && any( src.(field) == range)
    dest.(field) = src.(field);
    changed = 1;
end

end
