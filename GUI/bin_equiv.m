function bin = bin_equiv(x)
% Interprets the variable 'x' as a logical value.  Input can of be any one of
% the following forms:
%
% - 1/0
% - Yes/No (any case)

if isnumeric(x)
    if x == 0
        bin = 0;
    elseif x == 1
        bin = 1;
    else
        bin = -1;
    end
elseif ischar(x)
    if strcmpi(x,'no') == 1 || str2double(x) == 0
        bin = 0;
    elseif strcmpi(x,'yes') == 1 || str2double(x) == 1
        bin = 1;
    else
        bin = -1;
    end
else
    bin = -1;
end
end