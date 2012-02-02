function overwrite_backups(c_list, lock_ind_new, atr_dir)
% Use this function to manually overwrite the backup files
%
% Normally, the locked list is only appended to, since by definition the
% contacts within the locked list cannot change.  However, it may be
% desirable to manually remove contacts that causes problems for the ATR,
% which would also require removing it from the locked backup.  In this
% case, call this function.
%
% INPUTS:
% c_list = a contact list
% lock_ind_new = index of last contact that should be locked
% atr_dir = root directory of ATR

wait_if_flag('bkup_atr_busy.flag');
write_flag([atr_dir,filesep,'bkup_atr_busy.flag'], 0);
write_backups(c_list, 0, lock_ind_new, [atr_dir,filesep,'bkuplock.txt'],...
    [atr_dir,filesep,'bkupedit.txt'], 0);
delete([atr_dir,filesep,'bkup_atr_busy.flag']);
end