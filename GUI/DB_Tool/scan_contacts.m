function [set_contacts, file_list_io] = scan_contacts(data_dir)
% Reads IO_* files in a given folder and imports them into a contact list.
% As of 20 Jan 2012, the extra contact data is also imported into the
% contact list.
%
% Derek Kolacinski, NSWC PC (derek.kolacinski@navy.mil)
% Last update: 20 Jan 2012
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
    catch ME
        display(['Skipped: ',file_list_io{k}])
        contacts = struct([]);
    end
    % contacts is now loaded into the workspace...
    
    if isfield(contacts, 'ecdata_fn')
        % split data (mem_fix); need to load ecdata as well
        if ~isempty(contacts)
            try
                for qq = 1:length(contacts)
                    ecdata = read_extra_cdata(contacts(qq).ecdata_fn); % this image's ecdata
                    ecd_fields = fieldnames(ecdata);
                    assert(contacts(qq).ID == ecdata.ID, ['ID mismatch between',...
                        ' contacts and ecdata.  Data has been corrupted somehow.']);
                    % Copy fields from ecdata back into contact list
                    for ww = 1:length(ecd_fields)
                        % For first contact, fields will be missing; for subsequent
                        % contacts, fields will have been added, but missing
                        if ~isfield(contacts, ecd_fields{ww}) || isempty(contacts(qq).(ecd_fields{ww}))
%                             contacts = copy_field(contacts, qq, ecdata, ecd_fields{ww});
                            contacts(qq).(ecd_fields{ww}) = ecdata.(ecd_fields{ww});
                        end
                    end
                end
            catch ME
                display(['Error: Could not load file ',contacts(qq).ecdata_fn]);
            end
            set_contacts = [set_contacts, contacts];
        end
    else
        % original code
        if ~isempty(contacts)
            for kk = 1:length(contacts)
                contacts(kk).hfraw = [];
                contacts(kk).bbraw = [];
            end
            set_contacts = [set_contacts, contacts];
        end
    end
     waitbar(k/length(file_list_io),hand,'Loading Contacts ... ');
    
end
delete(hand)
fprintf(1,'\n');fprintf(1,'\n');

end

%     function contacts = copy_field(contacts, ind, ecdata, field_str)
%         contacts(ind).(field_str) = ecdata.(field_str);
%     end
