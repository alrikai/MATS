function [dest, changed] = copy_valid_indvec_field(src, dest, ifield, vfield)
% Copies a field from source structure (src) to destination structure
% (dest) if the index field (ifield) contains a valid index to the vector
% (vfield).  If the data is valid, both fields will be copied to the
% destination structure.

changed = 0;
if all(isfield(src, {ifield, vfield})) && any(src.(ifield) == (1:length( src.(vfield) )))
    dest.(ifield) = src.(ifield);
    dest.(vfield) = src.(vfield);
    changed = 1;
end

end