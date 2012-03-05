function [p,s] = pond_reader(fname, gtf, TB_params)


load(fname)

[junk,fn,ext] = fileparts(fname); %#ok<*ASGLU>

p = struct; s = struct;
%Load file name
p.fn = [fn,ext];

%Load in the raw data file
p.lb1raw = new_data;
%Load hf and bb data
p.hf = [];
p.bb = stolt(p.lb1raw, SASInfo, 't');
%Number of cross range pixels
p.hf_cnum = size(new_data,1);
%Number of along range pixels
p.hf_anum = size(new_data,2);
%Cross range resolution
p.hf_cres = SASInfo.Dp;
%Along range resolution
p.hf_ares = SASInfo.Dp;
%Port or starboard side
%p.side = channel;
%if strcmpi(channel, 'port')
    p.side = 'PORT';
%elseif strcmpi(channel, 'starboard')
%    p.side = 'STBD';
%end

p.SASInfo.c = SASInfo.c;

p.SASInfo.time = SASInfo.time;

p.SASInfo.crange = SASInfo.crange;

p.SASInfo.f0 = SASInfo.f0;

p.SASInfo.Bw = SASInfo.Bw;

%Vehicle latitude, longitude, orientation, and targettype
p.lat = 30.1699;
p.long = -85.7523;
p.heading = 0; 
p.targettype = '???';

%Performance estimation variables
perf_p = struct;
perf_p.depth = zeros(1,10);
perf_p.height = zeros(1,10);
perf_p.minrange = 0;
perf_p.maxrange = max(SASInfo.range);
p.perfparams = perf_p;

if TB_params.SKIP_PERF_EST == 1
    p.mode = 'A';
else
    p.mode = 'B';
end

% gt
if isempty(gtf)
    p.havegt = 0;
    p.gtimage = [];
else
    if TB_params.GT_FORMAT == 1
        error('Reader does not exist for this data type.');
    elseif TB_params.GT_FORMAT == 2
        p.havegt = 1;
        p.gtimage = latlong_gt_reader(p, gtf);
    end
end

s = [];
