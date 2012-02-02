function reset_opfile_cnt(tbr)
% resets the value stored in the opfeedback counter file to zero
cnt_fid = fopen([tbr,filesep,'feedback_cnt.txt'], 'w');
data = 0;
fwrite(cnt_fid, data, 'uint8');
fclose(cnt_fid);
end