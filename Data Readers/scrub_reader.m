function [p_struct, s_struct] = scrub_reader(fname_hi, fname_lo, gtf, TB_params)
load(fname_hi); %contains variable 'Image2'
% Find out what the name of the variable is called (it appears to be
% different for high and low.
temp = whos('-file',fname_hi);
eval(['in_hi = ',temp(1).name,';'])
load(fname_lo);
temp = whos('-file',fname_lo);
eval(['in_lo = ',temp(1).name,';'])

% input is now in the variable 'in'

p_struct = struct; % port structure
s_struct = struct; % starboard structure
% filename
[junk, fn,ext] = fileparts(fname_hi); %#ok<*ASGLU>
p_struct.fn = [fn,ext];
s_struct.fn = [fn,ext];
% image data (port)
if isempty(in_hi.ImagePort)
    p_struct.hf = [];
    p_struct.hf_cnum = 0;
    p_struct.hf_anum = 0;
    p_struct.hf_cres = 0;
    p_struct.hf_ares = 0;
else
    p_struct.hf = in_hi.ImagePort;
    p_struct.hf_cnum = length(p_struct.hf(1,:));
    p_struct.hf_anum = length(p_struct.hf(:,1));
    p_struct.hf_cres = in_hi.ResXmeter;
    p_struct.hf_ares = in_hi.ResYmeter;
end
if isempty(in_lo.ImagePort)
    p_struct.bb = [];
    p_struct.bb_cnum = 0;
    p_struct.bb_anum = 0;
    p_struct.bb_cres = 0;
    p_struct.bb_ares = 0;
else
    p_struct.bb = in_lo.ImagePort;
    p_struct.bb_cnum = length(p_struct.bb(1,:));
    p_struct.bb_anum = length(p_struct.bb(:,1));
    p_struct.bb_cres = in_lo.ResXmeter;
    p_struct.bb_ares = in_lo.ResYmeter;
end
% image data (starboard)
if isempty(in_hi.ImageStbd)
    s_struct.hf = [];
    s_struct.hf_cnum = 0;
    s_struct.hf_anum = 0;
    s_struct.hf_cres = 0;
    s_struct.hf_ares = 0;
else
    s_struct.hf = in_hi.ImageStbd;
    s_struct.hf_cnum = length(s_struct.hf(1,:));
    s_struct.hf_anum = length(s_struct.hf(:,1));
    s_struct.hf_cres = in_hi.ResXmeter;
    s_struct.hf_ares = in_hi.ResYmeter;
end
if isempty(in_lo.ImageStbd)
    s_struct.bb = [];
    s_struct.bb_cnum = 0;
    s_struct.bb_anum = 0;
    s_struct.bb_cres = 0;
    s_struct.bb_ares = 0;
else
    s_struct.bb = in_lo.ImageStbd;
    s_struct.bb_cnum = length(s_struct.bb(1,:));
    s_struct.bb_anum = length(s_struct.bb(:,1));
    s_struct.bb_cres = in_lo.ResXmeter;
    s_struct.bb_ares = in_lo.ResYmeter;
end
% side
p_struct.side = 'PORT';
s_struct.side = 'STBD';
% lat/long
p_struct.lat  = in_hi.Lat;
p_struct.long = in_hi.Lon;
s_struct.lat  = in_hi.Lat;
s_struct.long = in_hi.Lon;
% gt data
if isempty(gtf)
    p_struct.havegt = 0;
    p_struct.gtimage = [];
    s_struct.havegt = 0;
    s_struct.gtimage = [];
else
    p_struct.havegt = 1;
    p_struct.gtimage = scrub_gt_reader(fn, 'PORT', gtf, TB_params.TB_HEAVY_TEXT);
    s_struct.havegt = 1;
    s_struct.gtimage = scrub_gt_reader(fn, 'STBD', gtf, TB_params.TB_HEAVY_TEXT);
end
% target type
p_struct.targettype = '???';
s_struct.targettype = '???';

p_struct.heading = in_hi.Heading;
s_struct.heading = in_hi.Heading;
% The time data is bogus for this format, but something must be filled in
% in order to get the testbed to work with it...
p_struct.time = pi*ones(size(p_struct.heading));
s_struct.time = pi*ones(size(p_struct.heading));
% performance estimation parameters
perf_p = struct;
perf_p.depth = in_hi.Depth;
perf_p.height = in_hi.Alt;
perf_p.minrange = 0;
perf_p.maxrange = in_hi.ResXmeter * length(in_hi.ImagePort(1,:));

perf_s = struct;
perf_s.depth = in_hi.Depth;
perf_s.height = in_hi.Alt;
perf_s.minrange = 0;
perf_s.maxrange = in_hi.ResXmeter * length(in_hi.ImagePort(1,:));

p_struct.perfparams = perf_p;
s_struct.perfparams = perf_s;

if TB_params.SKIP_PERF_EST == 1
    p_struct.mode = 'A';
    s_struct.mode = 'A';
else
    p_struct.mode = 'B';
    s_struct.mode = 'B';
end
end