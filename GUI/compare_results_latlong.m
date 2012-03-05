function compare_results_latlong(gt_file, c_list, out_file, hi_sfnames)
% Produces a list comparing the list of detections in 'c_list' with the
% lat/long ground truth data in 'gt_file'.
%
% INPUTS:
%   gt_file = filename of ground truth text file
%   c_list = contact list
%   out_file = filename of text file to be saved


% This function is similar to compare_results, except instead of comparing
% pixel locations and filenames, we have to attempt to map the target lat/longs to
% each image frame.

lat_thresh = .001;  long_thresh = .003; % arbitrary distance thresholds


if isempty(c_list), return, end

% Miscellaneous structure (subset of input structure fields)
% (stub to get to gt_lat/long_vecs
ecdata = read_extra_cdata(c_list(1).ecdata_fn);
misc.lat = ecdata.veh_lats;
misc.long = ecdata.veh_longs;
misc.perfparams.height = ecdata.veh_heights;
misc.fn = c_list(1).fn;
misc.side = c_list(1).side;
misc.heading = ecdata.heading;
misc.hf_ares = ecdata.hf_ares;
misc.hf_cres = ecdata.hf_cres;
misc.hf_anum = ecdata.hf_anum;
misc.hf_cnum = ecdata.hf_cnum;

% gt_data = array of all gt structs up until the current contact
% gt_lat_vec = array of all gt latitudes
% gt_long_vec = array of all gt longitudes
% gt_ind = indices of gt elements in current image
[gt_data, gt_lat_vec, gt_long_vec, gt_ind] = latlong_gt_reader(misc, gt_file);
inds_seen = gt_ind;
gts_per_image = {gt_ind};   % element q has vector of GT indices that are in image #q

lats = zeros(1, length(c_list));            % all contact latitudes
longs = zeros(1, length(c_list));           % all contact longitudes
match_indices = zeros(1, length(c_list));   % all indices of matching GT elements
image_nums = zeros(1, length(c_list));      % value of q means contact is in image #q
image_cnt = 1;

for q = 1:length(c_list)    % for each contact...
    
    % if this contact is in a new image, update gt info for this image
    if q > 1 && (strcmpi(c_list(q-1).fn, c_list(q).fn) == 0 || strcmpi(c_list(q-1).side, c_list(q).side) == 0)
        ecdata = read_extra_cdata(c_list(q).ecdata_fn);
        misc.lat = ecdata.veh_lats;
        misc.long = ecdata.veh_longs;
        misc.perfparams.height = ecdata.veh_heights;
        misc.fn = c_list(q).fn;
        misc.side = c_list(q).side;
        misc.heading = ecdata.heading;
        misc.hf_ares = ecdata.hf_ares;
        misc.hf_cres = ecdata.hf_cres;
        misc.hf_anum = ecdata.hf_anum;
        misc.hf_cnum = ecdata.hf_cnum;
        [gt_data_img, ~, ~, gt_ind] = latlong_gt_reader(misc, gt_file);
        gts_per_image = [gts_per_image, gt_ind];
        gt_data = [gt_data, gt_data_img];
        image_cnt = image_cnt + 1;
    end
    ecdata = read_extra_cdata(c_list(q).ecdata_fn);
    lats(q) = ecdata.lat;
    longs(q) = ecdata.long;
    lat_match = abs(ecdata.lat*180/pi - gt_lat_vec) <= lat_thresh;      % temp
    long_match = abs(ecdata.long*180/pi - gt_long_vec) <= long_thresh;  % temp
    match = lat_match & long_match & c_list(q).gt;
    match_ind = find(match);
    image_nums(q) = image_cnt;
    if isempty(match_ind)
        match_indices(q) = -1;
    else
        % store index corresponding to gt entry that is the closest match
        diffs = ( (lats(q) - gt_lat_vec(match_ind)).^2 + (longs(q) - gt_long_vec(match_ind)).^2).^0.5;
        [~,temp] = min(diffs);
        match_indices(q) = match_ind(temp(1));
    end
    inds_seen = union(inds_seen, gt_ind);
end
gts = [c_list.gt];


lats_deg = lats * 180/pi;
lats_d_deg = floor(lats_deg);                           % all contacts' degrees lat.
lats_d_min = (lats_deg - lats_d_deg) * 60;              % all contacts' minutes lat.
longs_deg = longs * 180/pi;
longs_d_deg = floor(longs_deg);                         % all contacts' degrees long.
longs_d_min = (longs_deg - longs_d_deg) * 60;           % all contacts' minutes long.

gt_lats_d_deg = floor(gt_lat_vec);                      % all GT degrees lat.
gt_lats_d_min = (gt_lat_vec - gt_lats_d_deg) * 60;      % all GT minutes lat.
gt_longs_d_deg = floor(gt_long_vec);                    % all GT degrees long.
gt_longs_d_min = (gt_long_vec - gt_longs_d_deg) * 60;   % all GT minutes long.

used_gt_ind = setdiff( unique(match_indices), -1);
missed_gt_ind = setdiff(inds_seen, used_gt_ind);
missed_per_image = cell(0);

fid = 1;
% Display results
fprintf(fid,'\nDetections vs. Groundtruth\n');
last_fn = ''; last_side = ' '; image_cnt = 1;
for qq = 1:length(c_list)
    [junk,this_fn] = fileparts(c_list(qq).fn); this_side = c_list(qq).side;
    % if code has moved on to the next image/side...
    if qq>1 && (strcmp(this_fn, last_fn) == 0 || strcmp(this_side, last_side) == 0)
        % went to next file, show skipped gt from prev file first
        keyboard
        temp = match_indices( image_nums == image_nums(qq-1));
        found_gt_inds = setdiff(temp, -1); % GT found in this image
        skipped_gt_ind = setdiff(gts_per_image{image_cnt}, found_gt_inds);
        % Display data for GT entries left over in this image 
        for w = 1:length(skipped_gt_ind)
            r = skipped_gt_ind(w);
            temp = '......................';
            fprintf(fid, '%s.No match%s -------- GT#%03d @ <%3d%s %2.4f, %3d%s %2.4f>\n',...
                temp, temp, r, gt_lats_d_deg(r), char(176), gt_lats_d_min(r),...
                gt_longs_d_deg(r), char(176), gt_longs_d_min(r)); % 176 -> degree sign
        end
        missed_per_image = [missed_per_image, {skipped_gt_ind}];
        image_cnt = image_cnt + 1;
    end
    
    % If beginning of file, display file header
    if strcmp(this_fn, last_fn) == 0 || strcmp(this_side, last_side) == 0
        fprintf(fid,'\n       %s, %s\n\n',this_fn,this_side);
    end
    % Display data for this contact
    if match_indices(qq) == -1      % does not match a GT entry
        fprintf(fid,'%s C#%03d @ (%4d,%4d), <%3d%s %2.4f'', %3d%s %2.4f''> -------- ......No match......\n',...
            char( (c_list(qq).class == 1)*'x' + (c_list(qq).class == 0)*' ' ),...
            qq, c_list(qq).x, c_list(qq).y, lats_d_deg(qq), char(176), lats_d_min(qq),...
            longs_d_deg(qq), char(176), longs_d_min(qq));
    else                            % matches GT
        fprintf(fid,'%s C#%03d @ (%4d,%4d), <%3d%s %2.4f'', %3d%s %2.4f''> -------- GT#%03d @ <%3d%s %2.4f, %3d%s %2.4f>\n',...
            char( (c_list(qq).class == 1)*'x' + (c_list(qq).class == 0)*' ' ),...
            qq, c_list(qq).x, c_list(qq).y, lats_d_deg(qq), char(176), lats_d_min(qq),...
            longs_d_deg(qq), char(176), longs_d_min(qq),...
            match_indices(qq), gt_lats_d_deg(match_indices(qq)), char(176),...
            gt_lats_d_min(match_indices(qq)), gt_longs_d_deg(match_indices(qq)),...
            char(176), gt_longs_d_min(match_indices(qq)));
    end

    last_fn = this_fn; last_side = this_side;
end

% Display data for GT entries left over in last image (copied from loop above)
temp = match_indices( image_nums == image_nums(qq-1));
found_gt_inds = setdiff(temp, -1); % found in this image
skipped_gt_ind = setdiff(gts_per_image{image_cnt}, found_gt_inds);
for w = 1:length(skipped_gt_ind)
    r = skipped_gt_ind(w);
    temp = '......................';
    fprintf(fid, '%s.No match%s -------- GT#%03d @ <%3d%s %2.4f, %3d%s %2.4f>\n',...
        temp, temp, r, gt_lats_d_deg(r), char(176), gt_lats_d_min(r),...
        gt_longs_d_deg(r), char(176), gt_longs_d_min(r));
end
missed_per_image = [missed_per_image, {skipped_gt_ind}];

% show undetected ground truth elements
fprintf(fid,'\nUndetected GT:\n');
for w = 1:length(missed_gt_ind)
    r = missed_gt_ind(w);
    fprintf(fid,'GT#%03d @ <%3d%s %2.4f'', %3d%s %2.4f''>\n',r, gt_lats_d_deg(r),...
        char(176), gt_lats_d_min(r), gt_longs_d_deg(r), char(176),...
        gt_longs_d_min(r));
end
fprintf(fid,'-----------------------------------------------------\n');
totaltarg = length( cell2mat(gts_per_image) );
totalmissed = length( cell2mat(missed_per_image) );
detecttarg = totaltarg - totalmissed;
PD = 100*(detecttarg/totaltarg);
fprintf(fid,'Total Targets: %d / Detected Targets: %d\n',totaltarg,detecttarg);
fprintf(fid,'Probability of Detection: %.2f%%\n',PD);

end