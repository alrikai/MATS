function write_contacts(filename, contacts, filemode)
% Writes an entire array of contact structures to a file.
% filename = file location where the contacts file will be saved
% contacts = list of contacts in the form of a contact structure
% filemode = type of file access mode (e.g., 'a' for appending, 'r' for
% reading, etc.)
fid = fopen(filename, filemode);
for c_num = 1:length(contacts)
    % ID
    fwrite(fid, contacts(c_num).ID, 'uint16');
    % filename
    len = length(contacts(c_num).fn);
    fwrite(fid, len, 'uint8');
    fwrite(fid, contacts(c_num).fn, 'uchar');
    % side
    fwrite(fid, contacts(c_num).side, 'uchar');
    % sensor
    len = length(contacts(c_num).sensor);
    fwrite(fid, len, 'uint8');
    fwrite(fid, contacts(c_num).sensor, 'uchar');
    % x
    fwrite(fid, contacts(c_num).x, 'uint16');
    % y
    fwrite(fid, contacts(c_num).y, 'uint16');
    % features
    len = length(contacts(c_num).features);
    fwrite(fid, len, 'uint8');
    fwrite(fid, contacts(c_num).features, 'float32');
    % det score
    fwrite(fid, contacts(c_num).detscore, 'float32');
    % hf snippet
    [rows, cols] = size(contacts(c_num).hfsnippet);
    fwrite(fid, rows, 'uint16');
    fwrite(fid, cols, 'uint16');
    fwrite(fid, contacts(c_num).hfsnippet, 'float32');
    % bb snippet
    [rows, cols] = size(contacts(c_num).bbsnippet);
    fwrite(fid, rows, 'uint16');
    fwrite(fid, cols, 'uint16');
    fwrite(fid, contacts(c_num).bbsnippet, 'float32');
    % gt value
    if isempty( contacts(c_num).gt )
        fwrite(fid, -80, 'int8');
    else
        fwrite(fid, contacts(c_num).gt, 'int8');
    end
    % latitude
    fwrite(fid, contacts(c_num).lat, 'float32');
    % longitude
    fwrite(fid, contacts(c_num).long, 'float32');
    % classification
    fwrite(fid, contacts(c_num).class, 'int8');
    % classification confidence
    fwrite(fid, contacts(c_num).classconf, 'float32');
    % group ID
    len = length(contacts(c_num).groupnum);
    fwrite(fid, len, 'uint8');
    fwrite(fid, contacts(c_num).groupnum, 'uchar');
    % group confidence
    fwrite(fid, contacts(c_num).groupconf, 'float32');
    % group latitude
    fwrite(fid, contacts(c_num).grouplat, 'float32');
    % group longitude
    fwrite(fid, contacts(c_num).grouplong, 'float32');
    % group covariance matrix
    if isempty( contacts(c_num).groupcovmat ) == 1
        for w = 1:4
            fwrite(fid, 0, 'float32');
        end
    else
        fwrite(fid, contacts(c_num).groupcovmat(1,1), 'float32');
        fwrite(fid, contacts(c_num).groupcovmat(1,2), 'float32');
        fwrite(fid, contacts(c_num).groupcovmat(2,1), 'float32');
        fwrite(fid, contacts(c_num).groupcovmat(2,2), 'float32');
    end
    % detector string
    len = length(contacts(c_num).detector);
    fwrite(fid, len, 'uint8');
    fwrite(fid, contacts(c_num).detector, 'uchar');
    % classifier string
    len = length(contacts(c_num).classifier);
    fwrite(fid, len, 'uint8');
    fwrite(fid, contacts(c_num).classifier, 'uchar');
    % feature set string
    len = length(contacts(c_num).featureset);
    fwrite(fid, len, 'uint8');
    fwrite(fid, contacts(c_num).featureset, 'uchar');
    % contact correlation string
    len = length(contacts(c_num).contcorr);
    fwrite(fid, len, 'uint8');
    fwrite(fid, contacts(c_num).contcorr, 'uchar');
    % opdisplay
    fwrite(fid, contacts(c_num).opfeedback.opdisplay, 'int8');
    % opconf
    fwrite(fid, contacts(c_num).opfeedback.opconf, 'int8');
    % heading
    fwrite(fid, contacts(c_num).heading, 'float32');
    % time
    fwrite(fid, contacts(c_num).time, 'float64');
    % altitude
    fwrite(fid, contacts(c_num).alt, 'float32');
    % hf resolution
    fwrite(fid, contacts(c_num).hf_ares, 'float32');
    fwrite(fid, contacts(c_num).hf_cres, 'float32');
    %%% New group of added fields
    fwrite(fid, contacts(c_num).hf_anum, 'float32');
    fwrite(fid, contacts(c_num).hf_cnum, 'float32');
    fwrite(fid, contacts(c_num).bb_ares, 'float32');
    fwrite(fid, contacts(c_num).bb_cres, 'float32');
    fwrite(fid, contacts(c_num).bb_anum, 'float32');
    fwrite(fid, contacts(c_num).bb_cnum, 'float32');
    
    len = length(contacts(c_num).veh_lats);
    fwrite(fid, len, 'uint16');
    fwrite(fid, contacts(c_num).veh_lats, 'float32');
    
    len = length(contacts(c_num).veh_longs);
    fwrite(fid, len, 'uint16');
    fwrite(fid, contacts(c_num).veh_longs, 'float32');
    
    len = length(contacts(c_num).veh_heights);
    fwrite(fid, len, 'uint16');
    fwrite(fid, contacts(c_num).veh_heights, 'float32');
    %%%
    % bg snippet
    [rows, cols] = size(contacts(c_num).bg_snippet);
    fwrite(fid, rows, 'uint16');
    fwrite(fid, cols, 'uint16');
    fwrite(fid, contacts(c_num).bg_snippet, 'float32');
    % bg offset
    if isempty(contacts(c_num).bg_offset)
        fwrite(fid, [0,0], 'int16');
    else
        fwrite(fid, contacts(c_num).bg_offset, 'int16');
    end
    %%%
    % inverse image raw data - hf
    [rows, cols] = size(contacts(c_num).hfraw);
    fwrite(fid, rows, 'uint16');
    fwrite(fid, cols, 'uint16');
    fwrite(fid, contacts(c_num).hfraw, 'float32');
    % inverse image raw data - bb
    [rows, cols] = size(contacts(c_num).bbraw);
    fwrite(fid, rows, 'uint16');
    fwrite(fid, cols, 'uint16');
    fwrite(fid, contacts(c_num).bbraw, 'float32');
    % inverse image raw data - lb1
    [rows, cols] = size(contacts(c_num).lb1raw);
    fwrite(fid, rows, 'uint16');
    fwrite(fid, cols, 'uint16');
    fwrite(fid, contacts(c_num).lb1raw, 'float32');
    % acoustic color - hf
    [rows, cols] = size(contacts(c_num).hfac);
    fwrite(fid, rows, 'uint16');
    fwrite(fid, cols, 'uint16');
    fwrite(fid, contacts(c_num).hfac, 'float32');
    % acoustic color - bb
    [rows, cols] = size(contacts(c_num).bbac);
    fwrite(fid, rows, 'uint16');
    fwrite(fid, cols, 'uint16');
    fwrite(fid, contacts(c_num).bbac, 'float32');
    % acoustic color - lb1
    [rows, cols] = size(contacts(c_num).lb1ac);
    fwrite(fid, rows, 'uint16');
    fwrite(fid, cols, 'uint16');
    fwrite(fid, contacts(c_num).lb1ac, 'float32');
    
    % normalizer string
    len = length(contacts(c_num).normalizer);
    fwrite(fid, len, 'uint8');
    fwrite(fid, contacts(c_num).normalizer, 'uchar');
    
end
fclose(fid);
end