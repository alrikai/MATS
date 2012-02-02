function append_feedback(cont, index, fb_path, show_details)
% append feedback data for a contact evaluation to the feedback file
% cont    = the contact with complete data
% index   = index of contact
% fb_path = location of the feedback file
% show_details = shows a more detailed status string
%
% Derek Kolacinski, NSWC PC (derek.kolacinski@navy.mil)
% Last update: 11 Aug 2010

if show_details == 1
    fprintf(1, ' Appending to feedback file feedback #%d\n',cont.ID);
else
    fprintf(1,'%-s','V');
end
fid = fopen(fb_path, 'a');
% ID
fwrite(fid, cont.ID, 'uint16');
% estimated index - where this contact was at the time of judgement.  This
% might be off a little if contacts were added manually in front of it in
% the list, but this is a good first guess
fwrite(fid, index, 'uint16');
% type (verify)
fwrite(fid, 'V', 'uchar');
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
fclose(fid);
end