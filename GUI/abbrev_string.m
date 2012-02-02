
% Shorten string to fit in a fixed space.  All strings longer than 'thresh'
% will have only their first and last 10 letters shown
function s = abbrev_string(str,thresh)
if length(str) > thresh
    s = [str(1:10),'...',str((end-10):end)];
else
    s = str;
end
end