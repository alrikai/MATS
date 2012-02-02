function dev_clean(TB_ROOT)
% Deletes all communication files and status flags to allow a clean,
% repeatable test run.  This file requires that the ATR Core subdirectory
% be on the Matlab path.
%
% INPUT:
% TB_ROOT = root directory of the testbed 

fclose('all');
% temporarily supporess warnings in case file does not exist
warning off all;
fprintf(1,'Cleaning directory ''%s''\n',TB_ROOT);
% delete all progress files from previous run
delete([TB_ROOT,filesep,'feedback.txt']);
delete([TB_ROOT,filesep,'changes.txt']);
delete([TB_ROOT,filesep,'bkuplock.txt']);
delete([TB_ROOT,filesep,'bkupedit.txt']);
% delete flags
delete([TB_ROOT,filesep,'opfb_atr_busy.flag']);
delete([TB_ROOT,filesep,'changes_atr_busy.flag']);
delete([TB_ROOT,filesep,'opfb_op_busy.flag']);
delete([TB_ROOT,filesep,'bkup_atr_busy.flag']);


delete([TB_ROOT,filesep,'perf.mat']);
% reset counter for number of contacts with operator feedback
reset_opfile_cnt(TB_ROOT);
% allow warnings
warning on all;
fprintf(1,'%-s\n\n','Intial cleanup complete...');
end