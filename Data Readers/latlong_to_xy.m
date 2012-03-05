function [gt_x_px, gt_y_px] = latlong_to_xy(gt_lat, gt_long, input)
% Convert a lat/long location into an x/y pixel coordinate in some image frame

avg_height = mean(input.perfparams.height);

R_EARTH = 6368941.0;	% earth radius in meters
img_is_port = strcmpi(input.side, 'PORT') == 1;
img_is_stbd = strcmpi(input.side, 'STBD') == 1;

veh_lats_rad = (pi/180) * input.lat;
veh_longs_rad = (pi/180) * input.long;
veh_head_rad = (pi/180) * input.heading;   
gt_lat_i_rad = (pi/180) * gt_lat;
gt_long_i_rad = (pi/180) * gt_long;


%%% Calculations from C source
delta_lat = (gt_lat_i_rad - veh_lats_rad(1)) * R_EARTH;
delta_long = (gt_long_i_rad - veh_longs_rad(1)) * R_EARTH .* cos(veh_lats_rad(1));

delta_x = delta_long*sin(veh_head_rad(1)) + delta_lat*cos(veh_head_rad(1));
% if abs(delta_x) < 1e-6, delta_x = 0; end
delta_y = delta_long*cos(veh_head_rad(1)) - delta_lat*sin(veh_head_rad(1));
if abs(delta_y) < 1e-6, delta_y = 0; end
% if abs(delta_y) < avg_height, delta_y = 0; end

% 'copysign' portion in c source.
temp = sqrt(delta_y.^2 + avg_height.^2);
delta_y2 = sign(delta_y) .* abs(temp);
delta_x2 = abs(delta_x);

% Note: These assignments seem backwards, but they work.
gt_is_port = delta_y < -1;
gt_is_stbd = delta_y > 1;
% pixel location of GT object within this image (Might be out of bounds)
% with copysign portion
gt_x_px = sign(delta_y) * (floor( abs(delta_y2) / input.hf_cres) + 1);
gt_y_px = sign(delta_x) * (floor( abs(delta_x2) / input.hf_ares) + 1);

side_match = (gt_is_port && img_is_port) || (gt_is_stbd && img_is_stbd);
x_in_bounds = abs(gt_x_px) >= 1 && abs(gt_x_px) <= input.hf_cnum;
y_in_bounds = gt_y_px >= 1 && gt_y_px <= input.hf_anum;
if ~( side_match && x_in_bounds && y_in_bounds )
    gt_x_px = []; gt_y_px = [];
end
end