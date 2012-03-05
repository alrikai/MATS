function ecdata = read_extra_cdata(filename)
% Reads the contents of a contact's extra data to a file
%
% filename = file location where the extra data is stored
% ecdata = structure containing one contact's worth of extra data

ecdata = struct;
% fprintf(' Reading %s...\n',filename);
fid = fopen(filename, 'r');
if fid == -1
    fprintf(1,'  %s could not be opened.\n',filename);
    return
end
done = 0;
while done == 0 % I think this loop is unnecessary (one contact per file)
    % ID
    temp = fread(fid, 1, 'uint16');
    if isempty(temp), done = 1; break, end
    ecdata.ID = temp;
    
    % hf snippet
    rows = fread(fid, 1, 'uint16');
    assert(rows >= 0, 'rows must be non-negative');
    cols = fread(fid, 1, 'uint16');
    assert(cols >= 0, 'cols must be non-negative');
    ecdata.hfsnippet = fread(fid, [rows, cols], 'float32');
    % bb snippet
    rows = fread(fid, 1, 'uint16');
    assert(rows >= 0, 'rows must be non-negative');
    cols = fread(fid, 1, 'uint16');
    assert(cols >= 0, 'cols must be non-negative');
    ecdata.bbsnippet = fread(fid, [rows, cols], 'float32');
    % lf1 snippet
    rows = fread(fid, 1, 'uint16');
    assert(rows >= 0, 'rows must be non-negative');
    cols = fread(fid, 1, 'uint16');
    assert(cols >= 0, 'cols must be non-negative');
    ecdata.lf1snippet = fread(fid, [rows, cols], 'float32');
    
    % latitude
    ecdata.lat = fread(fid, 1, 'float32');
    % longitude
    ecdata.long = fread(fid, 1, 'float32');
    
    % group ID
    len = fread(fid, 1, 'uint8');
    assert(len >= 0, 'length must be non-negative');
    ecdata.groupnum = fread(fid, len, 'uchar');
    % group confidence
    ecdata.groupconf = fread(fid, 1, 'float32');
    % group latitude
    ecdata.grouplat = fread(fid, 1, 'float32');
    % group longitude
    ecdata.grouplong = fread(fid, 1, 'float32');
    % group covariance matrix
    ecdata.groupcovmat(1,1) = fread(fid, 1, 'float32');
    ecdata.groupcovmat(1,2) = fread(fid, 1, 'float32');
    ecdata.groupcovmat(2,1) = fread(fid, 1, 'float32');
    ecdata.groupcovmat(2,2) = fread(fid, 1, 'float32');
%     % normalizer string
%     len = fread(fid, 1, 'uint8');
%     assert(len >= 0, 'length must be non-negative');
%     ecdata.normalizer = char( fread(fid, len, 'uchar')' );
%     % detector string
%     len = fread(fid, 1, 'uint8');
%     assert(len >= 0, 'length must be non-negative');
%     ecdata.detector = char( fread(fid, len, 'uchar')' );
%     % classifier string
%     len = fread(fid, 1, 'uint8');
%     assert(len >= 0, 'length must be non-negative');
%     ecdata.classifier = char( fread(fid, len, 'uchar')' );
%     % feature set string
%     len = fread(fid, 1, 'uint8');
%     assert(len >= 0, 'length must be non-negative');
%     ecdata.featureset = char( fread(fid, len, 'uchar')' );
%     % contact correlation string
%     len = fread(fid, 1, 'uint8');
%     assert(len >= 0, 'length must be non-negative');
%     ecdata.contcorr = char( fread(fid, len, 'uchar')' );
    
    % heading
    ecdata.heading = fread(fid, 1, 'float32');
    % time
    ecdata.time = fread(fid, 1, 'float64');
    % altitude
    ecdata.alt = fread(fid, 1, 'float32');
    % hf resolution (along-track)
    ecdata.hf_ares = fread(fid, 1, 'float32');
    % hf resolution (cross-track)
    ecdata.hf_cres = fread(fid, 1, 'float32');
    % hf height (along-track)
    ecdata.hf_anum = fread(fid, 1, 'float32');
    % hf width (cross-track)
    ecdata.hf_cnum = fread(fid, 1, 'float32');
    % bb resolution (along-track)
    ecdata.bb_ares = fread(fid, 1, 'float32');
    % bb resolution (cross-track)
    ecdata.bb_cres = fread(fid, 1, 'float32');
    % bb height (along-track)
    ecdata.bb_anum = fread(fid, 1, 'float32');
    % bb width (cross-track)
    ecdata.bb_cnum = fread(fid, 1, 'float32');
    % lf1 resolution (along-track)
    ecdata.lf1_ares = fread(fid, 1, 'float32');
    % lf1 resolution (cross-track)
    ecdata.lf1_cres = fread(fid, 1, 'float32');
    % lf1 height (along-track)
    ecdata.lf1_anum = fread(fid, 1, 'float32');
    % lf1 width (cross-track)
    ecdata.lf1_cnum = fread(fid, 1, 'float32');
    % vehicle latitude vector
    len = fread(fid, 1, 'uint16');
    assert(len >= 0, 'length must be non-negative');
    ecdata.veh_lats = fread(fid, len, 'float32');
    % vehicle longitude vector
    len = fread(fid, 1, 'uint16');
    assert(len >= 0, 'length must be non-negative');
    ecdata.veh_longs = fread(fid, len, 'float32');
    % vehicle height vector
    len = fread(fid, 1, 'uint16');
    assert(len >= 0, 'length must be non-negative');
    ecdata.veh_heights = fread(fid, len, 'float32');
    
    % det score
    ecdata.detscore = fread(fid, 1, 'float32');
    % sensor
    len = fread(fid, 1, 'uint8');
    assert(len >= 0, 'length must be non-negative');
    ecdata.sensor = char ( fread(fid, len, 'uchar')' );
end

fclose(fid);
end