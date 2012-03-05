function new_contacts = cls_Test(new_contacts, class_data)

k = 1:length(new_contacts);
m = mod(k,2);

for k = 1:length(new_contacts)
    
new_contacts(k).class = m(k);
new_contacts(k).classconf = randi(100,1)/100;
new_contacts(k).classifier = 'Test';

new_contacts(k).opfeedback.opdisplay = (m(k) == 1);

end
end