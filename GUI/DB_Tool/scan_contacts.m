function [set_contacts, file_list_io] = scan_contacts(data_dir)
% Reads IO_* files in a given folder and imports them into a contact list
% data_dir = uigetdir(pwd,'Select directory with contacts to import');
% if data_dir == 0, return, end
% data_dir = 'H:\TESTBED\Bravo Result Sets\Bravo TI with PE';
dir_struct_io = dir([data_dir,filesep,'IO*.mat']);

file_list_io = cell( length(dir_struct_io),1 );
for k = 1:length(file_list_io)
    file_list_io{k} = dir_struct_io(k).name;
end

fprintf(1,'\nLoading IO files from %s', data_dir);
set_contacts = struct([]);
% Import contacts into contact list
hand = waitbar(0,'Loading Contacts...');
for k = 1:length(file_list_io)
    try
    load([data_dir,filesep,file_list_io{k}]);
    catch
        display(['Skipped: ',file_list_io{k}])
        contacts = struct([]);
    end
    % contacts is now loaded into the workspace...
    if ~isempty(contacts)
        for kk = 1:length(contacts)
            contacts(kk).hfraw = [];
            contacts(kk).bbraw = [];
        end
        set_contacts = [set_contacts, contacts];
    end
     waitbar(k/length(file_list_io),hand,'Loading Contacts ... ');
    
end
delete(hand)
fprintf(1,'\n');fprintf(1,'\n');

end
