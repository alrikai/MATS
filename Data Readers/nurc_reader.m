function [p,s] = nurc_reader(fname, gtf, TB_params)

%This file will read in nurc MUSCLE data into the Testbed
%It will graph the data with the general display function
%

load(fname)

[junk,fn,ext] = fileparts(fname); %#ok<*ASGLU>

p = struct; s = struct;
pixels = double(pixels);
pixel_dims = double(pixel_dims);
pings = double(pings);
p.fn = [fn,ext];
%Load muscle image
p.hf = double(fliplr(sas_tile_raw.'));
%Number of cross range pixels
p.hf_cnum = pixels(2);
%Number of along range pixels
p.hf_anum = pixels(1);
%Cross range resolution
p.hf_cres = pixel_dims(2);
%Along range resolution
p.hf_ares = pixel_dims(1);
%Port or starboard side
p.side = channel;
if strcmpi(channel, 'port')
    p.side = 'PORT';
elseif strcmpi(channel, 'starboard')
    p.side = 'STBD';
end

if isempty(gtf)
    p.havegt = 0;
    p.gtimage = [];
else
    p.havegt = 1;
    p.gtimage = nurc_gt_reader(fname, p.side, gtf, TB_params.TB_HEAVY_TEXT);
end

%Vehicle latitude, longitude, orientation, and targettype
p.lat = latitude;
p.long = longitude;
p.heading = orientation; 
p.targettype = '???';

% filling in blank parameters that are not part of MUSCLE
p.bb = [];
p.bb_cnum = 0;
p.bb_anum = 0;
p.bb_cres = 0;
p.bb_ares = 0;
p.time = 0;

%Performance estimation variables
perf_p = struct;
perf_p.depth = mean(depth,2);
perf_p.height = mean(altitude,2);
perf_p.minrange = tile_ranges(1);
perf_p.maxrange = tile_ranges(2);
p.perfparams = perf_p;
if TB_params.SKIP_PERF_EST == 1
    p.mode = 'A';
else
    p.mode = 'B';
end
p.sweetspot = calc_sweetspot(p);
p.sweetspot = [1 p.sweetspot(2)]; % NURC cuts of the first 40m any way so the first calculation is not valid
fclose('all');

if strcmpi(p.side,'PORT')
    s = [];
elseif strcmpi(p.side,'STBD')
    s = p;
    p = [];
end




