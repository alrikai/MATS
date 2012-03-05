function write_extra_cdata(filename, ecdata)
% Writes the contents of a contact's extra data to a file
%
% filename = file location where the extra data will be stored
% ecdata = structure containing one contact's worth of extra data

fid = fopen(filename, 'w');
    % ID
    fwrite(fid, ecdata.ID, 'uint16');
    % hf snippet
    [rows, cols] = size(ecdata.hfsnippet);
    fwrite(fid, rows, 'uint16');
    fwrite(fid, cols, 'uint16');
    fwrite(fid, ecdata.hfsnippet, 'float32');
    % bb snippet
    [rows, cols] = size(ecdata.bbsnippet);
    fwrite(fid, rows, 'uint16');
    fwrite(fid, cols, 'uint16');
    fwrite(fid, ecdata.bbsnippet, 'float32');
    % lf1 snippet
    [rows, cols] = size(ecdata.lf1snippet);
    fwrite(fid, rows, 'uint16');
    fwrite(fid, cols, 'uint16');
    fwrite(fid, ecdata.lf1snippet, 'float32');

    % latitude
    fwrite(fid, ecdata.lat, 'float32');
    % longitude
    fwrite(fid, ecdata.long, 'float32');
    
    % group ID
    len = length(ecdata.groupnum);
    fwrite(fid, len, 'uint8');
    fwrite(fid, ecdata.groupnum, 'uchar');
    % group confidence
    fwrite(fid, ecdata.groupconf, 'float32');
    % group latitude
    fwrite(fid, ecdata.grouplat, 'float32');
    % group longitude
    fwrite(fid, ecdata.grouplong, 'float32');
    % group covariance matrix
    if isempty( ecdata.groupcovmat ) == 1
        for w = 1:4
            fwrite(fid, 0, 'float32');
        end
    else
        fwrite(fid, ecdata.groupcovmat(1,1), 'float32');
        fwrite(fid, ecdata.groupcovmat(1,2), 'float32');
        fwrite(fid, ecdata.groupcovmat(2,1), 'float32');
        fwrite(fid, ecdata.groupcovmat(2,2), 'float32');
    end
%     % normalizer string
%     len = length(ecdata.normalizer);
%     fwrite(fid, len, 'uint8');
%     fwrite(fid, ecdata.normalizer, 'uchar');
%     % detector string
%     len = length(ecdata.detector);
%     fwrite(fid, len, 'uint8');
%     fwrite(fid, ecdata.detector, 'uchar');
%     % classifier string
%     len = length(ecdata.classifier);
%     fwrite(fid, len, 'uint8');
%     fwrite(fid, ecdata.classifier, 'uchar');
%     % feature set string
%     len = length(ecdata.featureset);
%     fwrite(fid, len, 'uint8');
%     fwrite(fid, ecdata.featureset, 'uchar');
%     % contact correlation string
%     len = length(ecdata.contcorr);
%     fwrite(fid, len, 'uint8');
%     fwrite(fid, ecdata.contcorr, 'uchar');
    
    % heading
    fwrite(fid, ecdata.heading, 'float32');
    % time
    fwrite(fid, ecdata.time, 'float64');
    % altitude
    fwrite(fid, ecdata.alt, 'float32');
    % hf resolution (along-track)
    fwrite(fid, ecdata.hf_ares, 'float32');
    % hf resolution (cross-track/range)
    fwrite(fid, ecdata.hf_cres, 'float32');
    % hf height (along-track)
    fwrite(fid, ecdata.hf_anum, 'float32');
    % hf width (cross-track/range)
    fwrite(fid, ecdata.hf_cnum, 'float32');
    % bb resolution (along-track)
    fwrite(fid, ecdata.bb_ares, 'float32');
    % bb resolution (cross-track/range)
    fwrite(fid, ecdata.bb_cres, 'float32');
    % bb height (along-track)
    fwrite(fid, ecdata.bb_anum, 'float32');
    % bb width (cross-track/range)
    fwrite(fid, ecdata.bb_cnum, 'float32');
    % lf1 resolution (along-track)
    fwrite(fid, ecdata.lf1_ares, 'float32');
    % lf1 resolution (cross-track/range)
    fwrite(fid, ecdata.lf1_cres, 'float32');
    % lf1 height (along-track)
    fwrite(fid, ecdata.lf1_anum, 'float32');
    % lf1 width (cross-track/range)
    fwrite(fid, ecdata.lf1_cnum, 'float32');
    % vehicle latitude vector
    len = length(ecdata.veh_lats);
    fwrite(fid, len, 'uint16');
    fwrite(fid, ecdata.veh_lats, 'float32');
    % vehicle longitude vector
    len = length(ecdata.veh_longs);
    fwrite(fid, len, 'uint16');
    fwrite(fid, ecdata.veh_longs, 'float32');
    % vehicle height vector
    len = length(ecdata.veh_heights);
    fwrite(fid, len, 'uint16');
    fwrite(fid, ecdata.veh_heights, 'float32');
    
    % det score
    fwrite(fid, ecdata.detscore, 'float32');
    % sensor
    len = length(ecdata.sensor);
    fwrite(fid, len, 'uint8');
    fwrite(fid, ecdata.sensor, 'uchar');
    fclose(fid);
end