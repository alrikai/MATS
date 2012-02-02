function append_opgen_contact(cont, index, fb_path, show_details)
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
len = length(cont.sensor);
fwrite(fid, len, 'uint8');
fwrite(fid, cont.sensor, 'uchar');
% position
fwrite(fid, cont.x, 'uint16');
fwrite(fid, cont.y, 'uint16');
% % detscore
% fwrite(fid, cont.detscore, 'float32');
% operator feedback
fwrite(fid, cont.opfeedback.opdisplay, 'int8');
fwrite(fid, cont.opfeedback.opconf, 'int8');
% hf snippet (complex)
[rows, cols] = size(cont.hfsnippet);
fwrite(fid, rows, 'uint16');
fwrite(fid, cols, 'uint16');
fwrite(fid, real(cont.hfsnippet), 'float32'); %
fwrite(fid, imag(cont.hfsnippet), 'float32'); %
% fwrite(fid, cont.hfsnippet, 'float32');
% bb snippet (complex)
[rows, cols] = size(cont.bbsnippet);
fwrite(fid, rows, 'uint16');
fwrite(fid, cols, 'uint16');
fwrite(fid, real(cont.bbsnippet), 'float32'); %
fwrite(fid, imag(cont.bbsnippet), 'float32'); %
% fwrite(fid, cont.bbsnippet, 'float32');
% latitude
fwrite(fid, cont.lat, 'float32');
% longitude
fwrite(fid, cont.long, 'float32');
% heading
fwrite(fid, cont.heading, 'float32');
% time
fwrite(fid, cont.time, 'float64');
% altitude
fwrite(fid, cont.alt, 'float32');
% hf resolution
fwrite(fid, cont.hf_ares, 'float32');  
fwrite(fid, cont.hf_cres, 'float32');    
%%% New group of added fields
fwrite(fid, cont.hf_anum, 'uint16');
fwrite(fid, cont.hf_cnum, 'uint16');
fwrite(fid, cont.bb_ares, 'float32');
fwrite(fid, cont.bb_cres, 'float32');
fwrite(fid, cont.bb_anum, 'uint16');
fwrite(fid, cont.bb_cnum, 'uint16');

len = length(cont.veh_lats);
fwrite(fid, len, 'uint16');
fwrite(fid, cont.veh_lats, 'float32');

len = length(cont.veh_longs);
fwrite(fid, len, 'uint16');
fwrite(fid, cont.veh_longs, 'float32');

len = length(cont.veh_heights);
fwrite(fid, len, 'uint16');
fwrite(fid, cont.veh_heights, 'float32');
%%%
% bg snippet
[rows, cols] = size(cont.bg_snippet);
fwrite(fid, rows, 'uint16');
fwrite(fid, cols, 'uint16');
fwrite(fid, real(cont.bg_snippet), 'float32'); %
fwrite(fid, imag(cont.bg_snippet), 'float32'); %
% fwrite(fid, cont.bg_snippet, 'float32');
% bg offset
fwrite(fid, cont.bg_offset, 'int16');
%%%
% inverse image raw data - hf
[rows, cols] = size(cont.hfraw);
fwrite(fid, rows, 'uint16');
fwrite(fid, cols, 'uint16');
fwrite(fid, real(cont.hfraw), 'float32');
fwrite(fid, imag(cont.hfraw), 'float32');
% fwrite(fid, cont.hfraw, 'float32');
% inverse image raw data - bb
[rows, cols] = size(cont.bbraw);
fwrite(fid, rows, 'uint16');
fwrite(fid, cols, 'uint16');
fwrite(fid, real(cont.bbraw), 'float32');
fwrite(fid, imag(cont.bbraw), 'float32');
% fwrite(fid, cont.bbraw, 'float32');
% inverse image raw data - lb1
[rows, cols] = size(cont.lb1raw);
fwrite(fid, rows, 'uint16');
fwrite(fid, cols, 'uint16');
fwrite(fid, real(cont.lb1raw), 'float32');
fwrite(fid, imag(cont.lb1raw), 'float32');
% fwrite(fid, cont.lb1raw, 'float32');
% acoustic color - hf
[rows, cols] = size(cont.hfac);
fwrite(fid, rows, 'uint16');
fwrite(fid, cols, 'uint16');
fwrite(fid, real(cont.hfac), 'float32');
fwrite(fid, imag(cont.hfac), 'float32');
% fwrite(fid, cont.hfac, 'float32');
% acoustic color - bb
[rows, cols] = size(cont.bbac);
fwrite(fid, rows, 'uint16');
fwrite(fid, cols, 'uint16');
fwrite(fid, real(cont.bbac), 'float32');
fwrite(fid, imag(cont.bbac), 'float32');
% fwrite(fid, cont.bbac, 'float32');
% acoustic color - lb1
[rows, cols] = size(cont.lb1ac);
fwrite(fid, rows, 'uint16');
fwrite(fid, cols, 'uint16');
fwrite(fid, real(cont.lb1ac), 'float32');
fwrite(fid, imag(cont.lb1ac), 'float32');
% fwrite(fid, cont.lb1ac, 'float32');
% normalizer
len = length(cont.normalizer);
fwrite(fid, len, 'uint8');
fwrite(fid, cont.normalizer, 'uchar');
%%%
fclose(fid);
end