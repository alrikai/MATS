function c_struct = read_contacts(filename, skipbytes, show_details)
% Reads an entire contact structure from a file.
% filename  = file location from which the contacts will be read
% skipbytes = number of initial bytes to skip (for extra variables stored
%   at the beginning)
% c_struct  = list of contacts in the form of a contact structure
%
% Derek Kolacinski, NSWC PC (derek.kolacinski@navy.mil)
% Last update: 09 June 2010

c_struct = struct([]);
fprintf(' Reading %s...\n',filename);
% disp([' Reading ',filename,'...']);
fid = fopen(filename, 'r');
if fid == -1
    fprintf(1,'  %s could not be opened.\n',filename);
    return
end
fseek(fid, skipbytes, 'bof');
count = 1;  done = 0;
while done == 0
% while feof(fid) == 0
    % ID
    temp = fread(fid, 1, 'uint16');
    if isempty(temp), done = 1; break, end
    c_struct(count).ID = temp;
    % filename
    len = fread(fid, 1, 'uint8');
    assert(len >= 0, 'length must be non-negative');
    c_struct(count).fn = char( fread(fid, len, 'uchar')' );
    % side
    c_struct(count).side = char( fread(fid, 4, 'uchar')' );
    % sensor
    len = fread(fid, 1, 'uint8');
    assert(len >= 0, 'length must be non-negative');
    c_struct(count).sensor = char ( fread(fid, len, 'uchar')' );
    % x
    c_struct(count).x = fread(fid, 1, 'uint16');
    % y
    c_struct(count).y = fread(fid, 1, 'uint16');
    % features
    len = fread(fid, 1, 'uint8');
    assert(len >= 0, 'length must be non-negative');
    c_struct(count).features = fread(fid, len, 'float32');
    % det score
    c_struct(count).detscore = fread(fid, 1, 'float32');
    % hf snippet
    rows = fread(fid, 1, 'uint16');
    assert(rows >= 0, 'rows must be non-negative');
    cols = fread(fid, 1, 'uint16');
    assert(cols >= 0, 'cols must be non-negative');
    c_struct(count).hfsnippet = fread(fid, [rows, cols], 'float32');
    % bb snippet
    rows = fread(fid, 1, 'uint16');
    assert(rows >= 0, 'rows must be non-negative');
    cols = fread(fid, 1, 'uint16');
    assert(cols >= 0, 'cols must be non-negative');
    %%%FIX THIS LATER
    c_struct(count).bbsnippet = fread(fid, [rows, cols], 'float32');
    % gt value
    c_struct(count).gt = fread(fid, 1, 'int8');
    if c_struct(count).gt == -80
        c_struct(count).gt = [];
    end
    % latitude
    c_struct(count).lat = fread(fid, 1, 'float32');
    % longitude
    c_struct(count).long = fread(fid, 1, 'float32');
    % classification
    c_struct(count).class = fread(fid, 1, 'int8');
    % classification confidence
    c_struct(count).classconf = fread(fid, 1, 'float32');
    % group ID
    len = fread(fid, 1, 'uint8');
    assert(len >= 0, 'length must be non-negative');
    c_struct(count).groupnum = fread(fid, len, 'uchar');
    % group confidence
    c_struct(count).groupconf = fread(fid, 1, 'float32');
    % group latitude
    c_struct(count).grouplat = fread(fid, 1, 'float32');
    % group longitude
    c_struct(count).grouplong = fread(fid, 1, 'float32');
    % group covariance matrix
    c_struct(count).groupcovmat(1,1) = fread(fid, 1, 'float32');
    c_struct(count).groupcovmat(1,2) = fread(fid, 1, 'float32');
    c_struct(count).groupcovmat(2,1) = fread(fid, 1, 'float32');
    c_struct(count).groupcovmat(2,2) = fread(fid, 1, 'float32');
    % detector string
    len = fread(fid, 1, 'uint8');
    assert(len >= 0, 'length must be non-negative');
    c_struct(count).detector = char( fread(fid, len, 'uchar')' );
    % classifier string
    len = fread(fid, 1, 'uint8');
    assert(len >= 0, 'length must be non-negative');
    c_struct(count).classifier = char( fread(fid, len, 'uchar')' );
    % feature set string
    len = fread(fid, 1, 'uint8');
    assert(len >= 0, 'length must be non-negative');
    c_struct(count).featureset = char( fread(fid, len, 'uchar')' );
    % contact correlation string
    len = fread(fid, 1, 'uint8');
    assert(len >= 0, 'length must be non-negative');
    c_struct(count).contcorr = char( fread(fid, len, 'uchar')' );
    % operator feedback
    temp_struct = struct;
    temp_struct.opdisplay = fread(fid, 1, 'int8');
    temp_struct.opconf = fread(fid, 1, 'int8');
    c_struct(count).opfeedback = temp_struct;
    %%% These are in here somewhat awkwardly but are necessary for the
    %%% contact correlation
    % heading
    c_struct(count).heading = fread(fid, 1, 'float32');
    % time
    c_struct(count).time = fread(fid, 1, 'float64');
    % altitude
    c_struct(count).alt = fread(fid, 1, 'float32');
    % hf resolution
    c_struct(count).hf_ares = fread(fid, 1, 'float32');
    c_struct(count).hf_cres = fread(fid, 1, 'float32');
    %%% New set of added fields
    c_struct(count).hf_anum = fread(fid, 1, 'float32');
    c_struct(count).hf_cnum = fread(fid, 1, 'float32');
    c_struct(count).bb_ares = fread(fid, 1, 'float32');
    c_struct(count).bb_cres = fread(fid, 1, 'float32');
    c_struct(count).bb_anum = fread(fid, 1, 'float32');
    c_struct(count).bb_cnum = fread(fid, 1, 'float32');
    len = fread(fid, 1, 'uint16');
    assert(len >= 0, 'length must be non-negative');
    c_struct(count).veh_lats = fread(fid, len, 'float32');
    len = fread(fid, 1, 'uint16');
    assert(len >= 0, 'length must be non-negative');
    c_struct(count).veh_longs = fread(fid, len, 'float32');
    len = fread(fid, 1, 'uint16');
    assert(len >= 0, 'length must be non-negative');
    c_struct(count).veh_heights = fread(fid, len, 'float32');
    %%%
    % bg snippet
    rows = fread(fid, 1, 'uint16');
    assert(rows >= 0, 'rows must be non-negative');
    cols = fread(fid, 1, 'uint16');
    assert(cols >= 0, 'cols must be non-negative');
    c_struct(count).bg_snippet = fread(fid, [rows, cols], 'float32');
    % bg offset
    c_struct(count).bg_offset = fread(fid, [1,2], 'int16');
    % inverse image raw data - hf
    rows = fread(fid, 1, 'uint16');
    assert(rows >= 0, 'rows must be non-negative');
    cols = fread(fid, 1, 'uint16');
    assert(cols >= 0, 'cols must be non-negative');
    c_struct(count).hfraw = fread(fid, [rows, cols], 'float32');
    % inverse image raw data - bb
    rows = fread(fid, 1, 'uint16');
    assert(rows >= 0, 'rows must be non-negative');
    cols = fread(fid, 1, 'uint16');
    assert(cols >= 0, 'cols must be non-negative');
    c_struct(count).bbraw = fread(fid, [rows, cols], 'float32');
    % inverse image raw data - lb1
    rows = fread(fid, 1, 'uint16');
    assert(rows >= 0, 'rows must be non-negative');
    cols = fread(fid, 1, 'uint16');
    assert(cols >= 0, 'cols must be non-negative');
    c_struct(count).lb1raw = fread(fid, [rows, cols], 'float32');
    % acoustic color - hf
    rows = fread(fid, 1, 'uint16');
    assert(rows >= 0, 'rows must be non-negative');
    cols = fread(fid, 1, 'uint16');
    assert(cols >= 0, 'cols must be non-negative');
    c_struct(count).hfac = fread(fid, [rows, cols], 'float32');
    % acoustic color - bb
    rows = fread(fid, 1, 'uint16');
    assert(rows >= 0, 'rows must be non-negative');
    cols = fread(fid, 1, 'uint16');
    assert(cols >= 0, 'cols must be non-negative');
    c_struct(count).bbac = fread(fid, [rows, cols], 'float32');
    % acoustic color - lb1
    rows = fread(fid, 1, 'uint16');
    assert(rows >= 0, 'rows must be non-negative');
    cols = fread(fid, 1, 'uint16');
    assert(cols >= 0, 'cols must be non-negative');
    c_struct(count).lb1ac = fread(fid, [rows, cols], 'float32');
    
    % normalizer string
    len = fread(fid, 1, 'uint8');
    assert(len >= 0, 'length must be non-negative');
    c_struct(count).normalizer = char( fread(fid, len, 'uchar')' );
    
    count = count + 1;
end
fprintf(1,'  (%d loaded)\n', length(c_struct));
fclose(fid);
end