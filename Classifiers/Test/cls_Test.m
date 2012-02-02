function new_contacts = cls_Test(new_contacts, class_data)

k = 1:length(new_contacts);
m = mod(k,2);

for k = 1:length(new_contacts)
    
new_contacts(1,k).class = m(k);
new_contacts(1,k).classconf = rand(1,1);
new_contacts(1,k).classifier = 'Test';

new_contacts(1,k).opfeedback.opdisplay = (m(k) == 1);

% new_contacts(1,2).class = 1;
% new_contacts(1,2).classconf = 85;
% new_contacts(1,2).classifier = '';
% 
% new_contacts(1,3).class = 1;
% new_contacts(1,3).classconf = 95;
% new_contacts(1,3).classifier = '';
% 
% new_contacts(1,4).class = 0;
% new_contacts(1,4).classconf = 85;
% new_contacts(1,4).classifier = '';

end
end