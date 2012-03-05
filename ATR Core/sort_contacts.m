function [sorted_contacts, sorted_ecdata] = sort_contacts(contacts, ecdata)
% Sorts contacts based on y-coordinates.
%
% Derek Kolacinski, NSWC PC (derek.kolacinski@navy.mil)
% Last update: 21 November 2011

% if the length of the list is empty or only one element, the sorting is
% trivial... abort
if length(contacts) <= 1
    sorted_contacts = contacts;
    sorted_ecdata = ecdata;
    return
end

y = zeros(size(contacts));
x = zeros(size(contacts));
for k = 1:length(contacts)
    y(k) = contacts(k).y;
    x(k) = contacts(k).x;
end
% y = y
[junk, y_index] = sort(y); %#ok<*ASGLU>
sorted_contacts = contacts(y_index);
sorted_ecdata = ecdata(y_index);
end