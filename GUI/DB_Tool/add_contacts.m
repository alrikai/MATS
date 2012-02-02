function contact_db = add_contacts(data_dir, contact_db)
% Adds contacts located in files in the 'data_dir' directory to the contact
% database.
new_contacts = scan_contacts(data_dir);
contact_db = [contact_db, new_contacts];
end
