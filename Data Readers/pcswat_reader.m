function [p,s] = pcswat_reader(fname_hi, fname_lo, PORT, gtf, TB_params)

%This file will read in nurc MUSCLE data into the Testbed
%It will graph the data with the general display function
%

load(fname_hi)

[junk,fn,ext] = fileparts(fname_hi); %#ok<*ASGLU>

p = struct; %s = struct;

p.fn = [fn,ext];
%Load pcswat image image
p.hf = (data);
%Number of cross track pixels
p.hf_cnum = size(data,2);
%Number of along track pixels
p.hf_anum = size(data,1);
%Cross track resolution
p.hf_cres = .05;
%Along track resolution
p.hf_ares = .05;
%Port or starboard side
p.side = 'PORT';
load(fname_lo)
p.bb = (data);
%Number of cross track pixels
p.bb_cnum = size(data,2);
%Number of along track pixels
p.bb_anum = size(data,1);
%Cross track resolution
p.bb_cres = .05;
%Along track resolution
p.bb_ares = .05;
%Port or starboard 

if isempty(gtf)
    p.havegt = 0;
    p.gtimage = [];
else
     p.havegt = 1;
     p.gtimage = pcswat_gt_reader(fname_hi, p.side, gtf, TB_params.TB_HEAVY_TEXT);
end

%Vehicle latitude, longitude, orientation, and targettype
p.lat = -99;
p.long = -99;
p.heading = -99; 
p.targettype = '???';
p.time = -99;

%Performance estimation variables
perf_p = struct;
perf_p.depth = -99;
perf_p.height = -99;
perf_p.minrange = -99;
perf_p.maxrange = -99;
p.perfparams = perf_p;
if TB_params.SKIP_PERF_EST == 1
    p.mode = 'A';
else
    p.mode = 'B';
end
p.sweetspot = [1, p.hf_cnum];

%gt
if isempty(gtf)
    p.havegt = 0;
    p.gtimage = [];
else
    p.havegt = 1;
    if TB_params.GT_FORMAT == 1
        p.gtimage = pcswat_gt_reader(fname_hi, p.side, gtf, TB_params.TB_HEAVY_TEXT);
    else
        p.gtimage = latlong_gt_reader(p, gtf);
    end
end

if strcmpi(p.side,'PORT')
    s = [];
elseif strcmpi(p.side,'STBD')
    s = p;
    p = [];
end