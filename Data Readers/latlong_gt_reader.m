function [gt, gt_lat_vec, gt_long_vec, ind_vec] = latlong_gt_reader(input, gtf, varargin)
% Generates substructure containing ground truth data based on lat/long
% positions
%
% INPUTS:
%   input_struct - input structure containing lat/long data (among other things)
%   gtf - path of the ground truth file
%
% OUTPUTS:
%   gt - ground truth substructure

if isempty(varargin)
    single_image = 1;
elseif strcmpi(varargin{1}, 'all')
    single_image = 0;
elseif strcmpi(varargin{1}, 'single')
    single_image = 1;
else
    single_image = 1;
end

PLOT = 0;
gt_count = 0; gt = [];
% avg_height = mean(input.perfparams.height);
% 
% R_EARTH = 6368941.0;	% earth radius in meters
% img_is_port = strcmpi(input.side, 'PORT') == 1;
% img_is_stbd = strcmpi(input.side, 'STBD') == 1;
% 
% veh_lats_rad = input.lat;
% veh_longs_rad = input.long;
% veh_head_rad = input.heading;

if PLOT
    figure(321);
    plot(180/pi * input.long, 180/pi * input.lat,'b');
    hold on; axis equal;
    plot(180/pi * input.long(1), 180/pi * input.lat(1),'bo'); % o at initial point
end

% Read file
fid = fopen(gtf,'r');
done = 0;
gt_lat_vec = []; gt_long_vec = []; type_vec = [];
while ~done
    [lat_deg, count] = fscanf(fid, '%f', 1);
    if count ~= 1
        done = 1;
    else
        lat_min  = fscanf(fid, '%f', 1);
        long_deg = fscanf(fid, '%f', 1);
        long_min = fscanf(fid, '%f', 1);
        num = fscanf(fid, '%f', 1);
        type = fscanf(fid, '%s', 1);
        gt_lat_vec = [gt_lat_vec, sign(lat_deg)*(abs(lat_deg) + lat_min/60)];
        gt_long_vec = [gt_long_vec, sign(long_deg)*(abs(long_deg) + long_min/60)];
        type_vec = [type_vec, type];
    end
end

rec_in_image = []; ind_vec = [];
for q = 1:length(gt_lat_vec)
    
    % TEMP - plotting markers for GT objects
    if PLOT
        plot(gt_long_vec(q), gt_lat_vec(q), 'kx');
        text(gt_long_vec(q), gt_lat_vec(q), num2str(q));
    end
    
    [gt_x_px, gt_y_px] = latlong_to_xy(gt_lat_vec(q), gt_long_vec(q), input);

    if ~(isempty(gt_x_px) || isempty(gt_y_px)) || ~single_image
        rec_in_image = [rec_in_image; 1];
        %%% Write to gt structure
        gt_count = gt_count + 1;
        if gt_count == 1
            gt.y(gt_count) = gt_y_px;
            gt.x(gt_count) = abs(gt_x_px);
            gt.code(gt_count) = 0;
            gt.fn{gt_count} = input.fn;
            gt.score(gt_count) = 0;
            gt.side{gt_count} = input.side;
            gt.type(gt_count) = type_vec(q);
            ind_vec = [ind_vec, q];
        else
            gt.y = [gt.y, gt_y_px];
            gt.x = [gt.x, abs(gt_x_px)];
            gt.code = [gt.code, 0];
            gt.fn = [gt.fn; input.fn];
            gt.score = [gt.score, 0];
            gt.side = {gt.side; input.side};
            gt.type = [gt.type, type_vec(q)];
        end
    else
        rec_in_image = [rec_in_image; 0];
    end
end

end