function convert_latlong_gt_to_xy()
% Converts a ground truth file with lat/long data into a ground truth file
% with pixel coordinates.

%%% SSAM II test config
% sd = '/home/dkola/Datasets/demo/13Jun2011_select';
% fmt = 5; % for hdf5
% gtf = '/home/dkola/Desktop/demo_gt_latlongs.txt';
% xy_gtf = '/home/dkola/Desktop/xy_demo13_test.txt';

%%% SSAM I test config
% sd = '/mnt/Glacier-Data/2008MayAUVFest/Images';
% fmt = 2; % for mymat
% gtf = '/mnt/Glacier-Data/2008MayAUVFest/GT_Targets_A1Z2.txt';
% xy_gtf = '/home/dkola/Desktop/xy_2008MayAUVFest.txt';

% sd = '/home/dkola/Datasets/Bravo';
% fmt = 1;
% gtf = '/home/dkola/Datasets/Bravo/gt_ssam_hf_bravo_06apr25.txt';
% xy_gtf = '/home/dkola/Desktop/xy_Bravo.txt';

%%% NURC test config
% % sd = '/media/UNTITLED/ARISE11/SAS_Tiles';
% sd = '/media/UNTITLED/ARISE11/SAS_Tiles/20110524/MUSCLE_ARI1_20110524_1/Leg00007';
% fmt = 6; % for NURC
% gtf = '/media/UNTITLED/AriseGT_new.txt';
% xy_gtf = '/media/UNTITLED/AriseGT_xytest.txt';

%%% get info from user
% input directory
addpath('ATR Core');
addpath(genpath('Data Readers'));
cmap = change_cmap; % sonar color map
sd = uigetdir(pwd, 'Select Data Directory');
if sd == 0  % cancel
    return;
end
% file format
list = {'Old .mat (Bravo)', 'Mymat', 'Scrub .mat', 'NSWC .mat',...
    'HDF5', 'NURC .mat (MUSCLE)','CSDT', 'POND', 'PC SWAT Imagery .mat',...
    'MATS input struct','MSTL .mst'};
[fmt,ok] = listdlg('ListString',list,'SelectionMode','single',...
    'PromptString','Which format is this data?',...
    'OKString','Continue','ListSize',[150,300]);
assert(ok == 1, 'Invalid detector selection.');
% lat/long gt file name
[gtf, temp] = uigetfile({'*.txt','Ground truth file'},'Select lat/long ground truth file',sd);
if gtf == 0
    return;
else
    gtf = [temp,  gtf];
end
% x/y gt file name
[xy_gtf, temp] = uiputfile({'*.txt','Ground truth file'},'Choose name for new x/y ground truth file',sd);
if xy_gtf == 0
    return;
else
    xy_gtf = [temp, xy_gtf];
end

%%%%%%%%%%

switch fmt  % This function is currently only configured for these data formats
    case 2
        lat_deg = 0;
    case {1,5, 6}
        lat_deg = 1;
    otherwise
        warning('Required value for ''lat_deg'' unknown');
        keyboard;
end

TB_params.SKIP_PERF_EST = 1;
TB_params.GT_FORMAT = 1;
TB_params.TB_HEAVY_TEXT = 0;

[hi_sfnames, lo_sfnames, fullpath] = gen_file_list(sd, fmt, 1);

[hi_sfnames, lo_sfnames, fullpath, sides] = get_sides(hi_sfnames, lo_sfnames, fullpath, fmt);
if isempty(fullpath)
    fullpath = repmat({sd}, length(hi_sfnames), 1);
end

hwb = waitbar(0, 'Reading data and calculating x/y coordinates...');

gts = struct;
fchk_list = []; xchk_list = []; ychk_list = [];

try

for img_num = 1:length(hi_sfnames);

    [input, side_sign] = load_datafile(fullpath{img_num},hi_sfnames{img_num},...
        lo_sfnames{img_num}, fmt, sides{img_num});

    % Get lat/longs from gt file
    if img_num == 1
        [~, gt_lat_vec, gt_long_vec] = latlong_gt_reader(input, gtf);
    end
    
    y_samp = (input.hf_anum/length(input.lat));
    if y_samp >= 0.1 * input.hf_anum    % no vector
        y_samp = 5;
    end
    y_grid_px = 1:y_samp:input.hf_anum;
    x_samp = 5;
    x_grid_px = 1:x_samp:input.hf_cnum;
    
    y_samp_a = (input.hf_anum/length(input.perfparams.height));
    alt_vec_int = interp1(1:y_samp_a:input.hf_anum,...
        input.perfparams.height, 1:input.hf_anum, 'linear', 'extrap');
%     y_samp_h = (input.hf_anum/length(input.heading));
%     hdg_vec_int = interp1(1:y_samp_h:input.hf_anum,...
%         input.heading, 1:input.hf_anum, 'linear', 'extrap');
    
    % interpolated vectors
    if length(input.lat) == 1 && length(input.long) == 1
        [latnew,lonnew] = calcdistbear(input.hf_anum*input.hf_ares,...
            input.heading, input.lat, input.long);
        lat_vec_int = interp1([1 input.hf_anum],...
            [input.lat latnew], 1:input.hf_anum, 'linear', 'extrap');
        long_vec_int = interp1([1 input.hf_anum],...
            [input.long lonnew], 1:input.hf_anum, 'linear', 'extrap');
    else 
    lat_vec_int = interp1(y_grid_px, input.lat, 1:input.hf_anum, 'linear', 'extrap');
    long_vec_int = interp1(y_grid_px, input.long, 1:input.hf_anum, 'linear', 'extrap');
    end
    
    lat_mat = zeros(length(y_grid_px), length(x_grid_px));
    long_mat = zeros(length(y_grid_px), length(x_grid_px));
    
    %%% vectorized version
    lat_v_rad_alt = lat_vec_int(y_grid_px);
    long_v_rad_alt = long_vec_int(y_grid_px);
    if lat_deg == 1
        lat_v_rad_alt = pi/180 * lat_v_rad_alt;
        long_v_rad_alt = pi/180 * long_v_rad_alt;
    end
    altitude_alt = alt_vec_int(y_grid_px);
    heading = input.heading;
    
    range_alt = side_sign * x_grid_px * input.hf_cres;
    
    [lat_c_rad_alt, long_c_rad_alt] = geolocate_batch(lat_v_rad_alt, long_v_rad_alt,...
        heading, 0, range_alt, altitude_alt);
    
    lat_mat = lat_c_rad_alt * 180/pi;
    long_mat = long_c_rad_alt * 180/pi;
    
    %%% original version
%     for yi = 1:length(y_grid_px)       % for each grid point in track
%     
%         y = y_grid_px(yi);
%         lat_v_rad = lat_vec_int(y);
%         long_v_rad = long_vec_int(y);
%         if lat_deg == 1
%             lat_v_rad = pi/180 * lat_vec_int(y);
%             long_v_rad = pi/180 * long_vec_int(y);
%         end
%         altitude = alt_vec_int(y);
%         heading = input.heading;
% %         heading = hdg_vec_int(y);
%             
%         for xi = 1:length(x_grid_px)       % for each grid point in range 
%             
%             x = x_grid_px(xi);
%             range = side_sign * x * input.hf_cres;
%             
%             [lat_c_rad,long_c_rad] = geolocate(lat_v_rad,long_v_rad,...
%                 heading,0,range,altitude);
%             
%             lat_mat(yi, xi) = lat_c_rad * 180/pi;
%             long_mat(yi, xi) = long_c_rad * 180/pi;
%         end
%     end
    %%%

    % calc gt locations
    for gt_num = 1:length(gt_lat_vec)
        % calc distance to each grid point from gt point
        diff_lat = lat_mat - gt_lat_vec(gt_num);
        diff_long = long_mat - gt_long_vec(gt_num);
        z = ( diff_lat.^2 + diff_long.^2 ).^0.5;
%         figure(444); imagesc(z);
        % calc index coords of min
        [row_mins, row_inds] = min(z);
        [glob_min, col_ind] = min(row_mins);
        row_ind = row_inds(col_ind);
        % calc pixel coords of min
        x_center_px = x_grid_px(col_ind);
        y_center_px = y_grid_px(row_ind);
        if x_center_px > 10 && x_center_px < x_grid_px(end) && ...
                y_center_px > 10 && y_center_px < y_grid_px(end) % not on edge of image
            
            % save for later
            fchk_list = [fchk_list, img_num];
            xchk_list = [xchk_list, x_center_px];
            ychk_list = [ychk_list, y_center_px];
            
            fprintf(1, 'Object in %s @ (%d,%d)\n', hi_sfnames{img_num}, x_center_px, y_center_px);
            
        else
            % gt point lies outside the bounds of this image. ignore.
        end
        
    end % end gt_num loop
    
    waitbar(img_num/length(hi_sfnames), hwb);
    
end % end img_num loop

waitbar(0, hwb, 'Requesting operator feedback...');

prev_findex = 0;
% Query user
for q = 1:length(xchk_list)
    cur_findex = fchk_list(q);
    if prev_findex ~= cur_findex
        % this is different file; load new input structure
        [input, side_sign] = load_datafile(fullpath{cur_findex},hi_sfnames{cur_findex}, lo_sfnames{cur_findex}, fmt, sides{cur_findex});
    end
    % make snippet
    [snip, x_bounds, y_bounds] = make_snippet_alt(xchk_list(q), ychk_list(q),...
        801, 801, abs(input.hf));
    % plot snippet
    figure(111); colormap(cmap);
    imagesc(x_bounds, y_bounds, clip_image(snip));
    axis xy;
    hold on;
    box_hr = 20; box_vr = 20;
    line(xchk_list(q) + [box_hr, box_hr, -box_hr, -box_hr, box_hr],...
        ychk_list(q) + [box_vr, -box_vr, -box_vr, box_vr, box_vr],...
        'Color', 'y', 'LineWidth',3);
    text(xchk_list(q)-30, ychk_list(q)-30, 'Click on target to confirm; click outside image to reject','Color',[1 1 1]);
    title(input.fn)
    hold off;
    % get gt point from user
    [gx, gy] = ginput(1);
    gx = round(gx); gy = round(gy);
    if gx < x_bounds(1) || gx > x_bounds(end) || gy < y_bounds(1) || gy > y_bounds(end)
        % selected point out of bounds
    else
        if ~isfield(gts,'x')        % first gt match
            cnt = 1;
            gts.x = gx;
            gts.y = gy;
            gts.fn{1} = input.fn;
            gts.side{1} = input.side;
        else
            cnt = cnt + 1;
            gts.x = [gts.x, gx];
            gts.y = [gts.y, gy];
            gts.fn{cnt} = input.fn;
            gts.side{cnt} = input.side;
        end
    end
    
    waitbar(q/length(xchk_list), hwb);
    
end


% gts now contains all gt info
write_gt(gts, xy_gtf);

catch ME
    keyboard;
end

close(hwb);
close(111);

function [hi_sfnames, lo_sfnames, fullpath, sides] = get_sides(hi_sfnames, lo_sfnames, fullpath, fmt)
% Get side info from file names.  Also, in the event both sides being in one file, add
% an extra entry to cover both sides.
sides = cell(size(hi_sfnames));
switch fmt  % both sides; double all entries and alternate sides
    case 1
        sides = repmat({'PORT';'STBD'}, length(hi_sfnames), 1);
        hi_sfnames = reshape( repmat(hi_sfnames, 1, 2)', [], 1);
        lo_sfnames = reshape( repmat(lo_sfnames, 1, 2)', [], 1);
        fullpath = reshape( repmat(fullpath, 1, 2)', [], 1);
    otherwise   % examine file names
        
        for w = 1:length(hi_sfnames)
            switch fmt
                case 1 
                case {2,5}
                    if strcmpi('P',hi_sfnames{w}(1))
                        sides{w} = 'PORT';
                    elseif strcmpi('S', hi_sfnames{w}(1))
                        sides{w} = 'STBD';
                    end
                case 6
                    temptext = textscan(hi_sfnames{w},'%s%s%s%s%s%s%s%s%s%s','Delimiter','_');
                    if strcmpi(temptext{6},'p')
                        sides{w} = 'PORT';
                    elseif strcmpi(temptext{6},'s')
                        sides{w} = 'STBD';
                    end
                case {8,9}
                    sides{w} = 'PORT';
            end
        end
end
end

function [input, side_sign] = load_datafile(fullpath,hi_sfname, lo_sfname, fmt, side)
    if strcmpi(side, 'PORT') == 1
        is_port = 1;
        side_sign = -1;
    elseif strcmpi(side, 'STBD') == 1
        is_port = 0;
        side_sign = 1;
    else
        error('Invalid side value %s', side);
    end
    switch fmt % note: mirrors but is not quite similar to struct in bravo_input_sim
        case 1  % Bravo
            input = gen_input_struct_bravo([fullpath,filesep,hi_sfname], side, gtf, TB_params);
        case 2  % mymat
            input = mymat_reader([sd,filesep,'HF',filesep,hi_sfname],...
                    [sd,filesep,'LF',filesep,lo_sfname], side, gtf, TB_params);
        case 5  % hdf5
            input = hdf5_reader([fullpath,filesep,hi_sfname],...
                    [fullpath,filesep,lo_sfname], side, gtf, TB_params);
        case 6  % NURC
            [p_in_struct,s_in_struct] = mat_reader([fullpath,filesep,hi_sfname],...
                    [], 'nurc', gtf, TB_params);
            if is_port
                input = p_in_struct;
            else
                input = s_in_struct;
            end
        case 7 %CSDT espec. ET
            
            [input, s_in_struct] = mat_reader(...
                [fullpath,filesep,hi_sfname], [], 'csdt', gtf, TB_params);  
            
    end
end

function write_gt(gts, fname)
    fid = fopen(fname, 'w');
    if ~isfield(gts, 'x')
        num_gt = 0;
    else
        num_gt = length(gts.x);
    end
    for k = 1:num_gt
        fprintf(fid, '%d ', gts.x(k));
        fprintf(fid, '%d ', gts.y(k));
        fprintf(fid, '%d ', 0);
        fprintf(fid, '%s ', char(gts.side{k}));
        fprintf(fid, '%s\n', char(gts.fn{k}));
    end
    fclose(fid);
end

end