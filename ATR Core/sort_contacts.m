function sorted_contacts = sort_contacts(contacts)
% Sorts contacts based on y-coordinates.
%
% Derek Kolacinski, NSWC PC (derek.kolacinski@navy.mil)
% Last update: 03 Sept 2010

% if the length of the list is empty or only one element, the sorting is
% trivial... abort
if length(contacts) <= 1
    sorted_contacts = contacts;
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
end