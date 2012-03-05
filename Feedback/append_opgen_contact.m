function append_opgen_contact(cont, ecdata, index, fb_path, show_details)
% append a contact manually
% cont    = the contact with complete data
% index   = index of contact insertion
% fb_path = location of the feedback file
% show_details = shows a more detailed status string
%
% Derek Kolacinski, NSWC PC (derek.kolacinski@navy.mil)
% Last update: 11 Aug 2010

if show_details == 1
    fprintf(1, '%-s\n', [' Appending to feedback file feedback ID #',...
        num2str(cont.ID),'at position #',num2str(index),'...']);
else
    fprintf(1,'%-s','A');
end
fid = fopen(fb_path, 'a');
% ID
fwrite(fid, cont.ID, 'uint16');
% estimated index
fwrite(fid, index, 'uint16');
% type (add)
fwrite(fid, 'A', 'uchar');                         
% filename
len = length(cont.fn);
fwrite(fid, len, 'uint8');
fwrite(fid, cont.fn, 'uchar');
% side
fwrite(fid, cont.side, 'uchar');
% sensor
len = length(ecdata.sensor);
fwrite(fid, len, 'uint8');
fwrite(fid, ecdata.sensor, 'uchar');
% position
fwrite(fid, cont.x, 'uint16');
fwrite(fid, cont.y, 'uint16');
% % detscore
% fwrite(fid, cont.detscore, 'float32');
% operator feedback
fwrite(fid, cont.opfeedback.opdisplay, 'int8');
fwrite(fid, cont.opfeedback.opconf, 'int8');
fwrite(fid, cont.opfeedback.type, 'int8');
% hf snippet (complex)
[rows, cols] = size(ecdata.hfsnippet);
fwrite(fid, rows, 'uint16');
fwrite(fid, cols, 'uint16');
fwrite(fid, real(ecdata.hfsnippet), 'float32'); %
fwrite(fid, imag(ecdata.hfsnippet), 'float32'); %
% fwrite(fid, cont.hfsnippet, 'float32');
% bb snippet (complex)
[rows, cols] = size(ecdata.bbsnippet);
fwrite(fid, rows, 'uint16');
fwrite(fid, cols, 'uint16');
fwrite(fid, real(ecdata.bbsnippet), 'float32'); %
fwrite(fid, imag(ecdata.bbsnippet), 'float32'); %
% fwrite(fid, cont.bbsnippet, 'float32');
% lf1 snippet (complex)
[rows, cols] = size(ecdata.lf1snippet);
fwrite(fid, rows, 'uint16');
fwrite(fid, cols, 'uint16');
fwrite(fid, real(ecdata.lf1snippet), 'float32'); %
fwrite(fid, imag(ecdata.lf1snippet), 'float32'); %
% fwrite(fid, cont.lf1snippet, 'float32');
% latitude
fwrite(fid, ecdata.lat, 'float32');
% longitude
fwrite(fid, ecdata.long, 'float32');
% heading
fwrite(fid, ecdata.heading, 'float32');
% time
fwrite(fid, ecdata.time, 'float64');
% altitude
fwrite(fid, ecdata.alt, 'float32');
% hf resolution
fwrite(fid, ecdata.hf_ares, 'float32');  
fwrite(fid, ecdata.hf_cres, 'float32');    
%%% New group of added fields
fwrite(fid, ecdata.hf_anum, 'uint16');
fwrite(fid, ecdata.hf_cnum, 'uint16');
fwrite(fid, ecdata.bb_ares, 'float32');
fwrite(fid, ecdata.bb_cres, 'float32');
fwrite(fid, ecdata.bb_anum, 'uint16');
fwrite(fid, ecdata.bb_cnum, 'uint16');
fwrite(fid, ecdata.lf1_ares, 'float32');
fwrite(fid, ecdata.lf1_cres, 'float32');
fwrite(fid, ecdata.lf1_anum, 'uint16');
fwrite(fid, ecdata.lf1_cnum, 'uint16');

len = length(ecdata.veh_lats);
fwrite(fid, len, 'uint16');
fwrite(fid, ecdata.veh_lats, 'float32');

len = length(ecdata.veh_longs);
fwrite(fid, len, 'uint16');
fwrite(fid, ecdata.veh_longs, 'float32');

len = length(ecdata.veh_heights);
fwrite(fid, len, 'uint16');
fwrite(fid, ecdata.veh_heights, 'float32');
% %%% OLD OPTIONAL FIELDS
% % bg snippet
% [rows, cols] = size(cont.bg_snippet);
% fwrite(fid, rows, 'uint16');
% fwrite(fid, cols, 'uint16');
% fwrite(fid, real(cont.bg_snippet), 'float32'); %
% fwrite(fid, imag(cont.bg_snippet), 'float32'); %
% % fwrite(fid, cont.bg_snippet, 'float32');
% % bg offset
% fwrite(fid, cont.bg_offset, 'int16');
% %%%
% % inverse image raw data - hf
% [rows, cols] = size(cont.hfraw);
% fwrite(fid, rows, 'uint16');
% fwrite(fid, cols, 'uint16');
% fwrite(fid, real(cont.hfraw), 'float32');
% fwrite(fid, imag(cont.hfraw), 'float32');
% % fwrite(fid, cont.hfraw, 'float32');
% % inverse image raw data - bb
% [rows, cols] = size(cont.bbraw);
% fwrite(fid, rows, 'uint16');
% fwrite(fid, cols, 'uint16');
% fwrite(fid, real(cont.bbraw), 'float32');
% fwrite(fid, imag(cont.bbraw), 'float32');
% % fwrite(fid, cont.bbraw, 'float32');
% % inverse image raw data - lb1
% [rows, cols] = size(cont.lb1raw);
% fwrite(fid, rows, 'uint16');
% fwrite(fid, cols, 'uint16');
% fwrite(fid, real(cont.lb1raw), 'float32');
% fwrite(fid, imag(cont.lb1raw), 'float32');
% % fwrite(fid, cont.lb1raw, 'float32');
% % acoustic color - hf
% [rows, cols] = size(cont.hfac);
% fwrite(fid, rows, 'uint16');
% fwrite(fid, cols, 'uint16');
% fwrite(fid, real(cont.hfac), 'float32');
% fwrite(fid, imag(cont.hfac), 'float32');
% % fwrite(fid, cont.hfac, 'float32');
% % acoustic color - bb
% [rows, cols] = size(cont.bbac);
% fwrite(fid, rows, 'uint16');
% fwrite(fid, cols, 'uint16');
% fwrite(fid, real(cont.bbac), 'float32');
% fwrite(fid, imag(cont.bbac), 'float32');
% % fwrite(fid, cont.bbac, 'float32');
% % acoustic color - lb1
% [rows, cols] = size(cont.lb1ac);
% fwrite(fid, rows, 'uint16');
% fwrite(fid, cols, 'uint16');
% fwrite(fid, real(cont.lb1ac), 'float32');
% fwrite(fid, imag(cont.lb1ac), 'float32');
% % fwrite(fid, cont.lb1ac, 'float32');
% normalizer
len = length(cont.normalizer);
fwrite(fid, len, 'uint8');
fwrite(fid, cont.normalizer, 'uchar');
%%%
fclose(fid);
end