function contacts = feat_No_extra(contacts)
for q = 1:length(contacts)
    contacts(q).featureset = 'N/A';
end
end