function [vals, strs] = get_objtype_vals()

% Values that will show up in .type field
vals = [-2,-1,0,1,2,3,4,5,6,7,8,9,10];
% Corresponding strings that will appear in the dropdown menu in the
% feedback GUI (for now, just the string version of 'vals')
strs = regexprep( cellstr(num2str(vals')), '^[ ]+', '');
end