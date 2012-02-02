% function c_list = read_backup(TB_params)
function c_list = read_backups(filename_locked, filename_unlocked,...
    show_details)
% Reads the backup files specified in filename_locked and filename_unlocked
% and imports the data into a contact list
% 
% INPUTS:
% filename_locked = file name of the backup file used to store unchangeable
%   contacts
% filename_unlocked = file name of the backup file used to store contacts
%   that can still be changed
%
% OUTPUTS:
% c_list = a contact list containing all of the data contained in the input
%  file names
%
% Derek Kolacinski, NSWC PC (derek.kolacinski@navy.mil)
% Last update: 08 June 2010

% filename_locked = TB_params.L_BKUP_PATH;
% filename_unlocked = TB_params.U_BKUP_PATH;
% show_details = TB_params.TB_HEAVY_TEXT;

fid = fopen(filename_unlocked, 'r');
if fid == -1
    fprintf(1,' Backup %s does not exist.\n', filename_unlocked);
    num = 0;
else
    num = fread(fid, 1, 'uint16'); % number of contacts that should be in 'locked'
    fprintf(1,'Lock inded read from backup: %d\n', num);
    fclose(fid);
end

% read locked backup file
locked = read_contacts(filename_locked, 0, show_details);
% read unlocked backup file, accounting for extra bytes at the beginning
% containing the final lock index
unlocked = read_contacts(filename_unlocked, 2, show_details);

if length(locked) ~= num
    disp('Warning: Stored value of locked length does not match actual # of locked contacts.');
    disp([' From file = ',num2str(num),'; From list = ',num2str(length(locked))]);
    keyboard
%     pause;
end

if show_details == 1
    fprintf(1, '%-s\n', [' Total number of loaded locked contacts: ',...
        num2str(length(locked))]);
    fprintf(1, '%-s\n', [' Total number of loaded unlocked contacts: ',...
        num2str(length(unlocked))]);
end
% combine lists
c_list = [locked, unlocked];
% keyboard
end