function s = mymat_reader(fname_hi, fname_lo, port_or_stbd, gtf, TB_params)
% Reads data from a mymat file and stores the data into a testbed input
% structure
%
% INPUTS:
%   fname_hi - filename of the high frequency image
%   fname_lo - filename of the low frequency image
%   port_or_stbd - string indicating side of the vehicle = {'PORT', 'STBD'}
%   gtf - filename of the groundtruth file
% OUTPUT:
%   s = input structure for a side of data

temp = fileparts(mfilename('fullpath'));
newpath = [temp,filesep,'mymat'];
if ~isdeployed
addpath(newpath);
end

loaded_hi = myload(fname_hi);
loaded_lo = myload(fname_lo);

s = struct;
% filename
[junk, fn,ext] = fileparts(fname_hi); %#ok<*ASGLU>
s.fn = [fn,ext];
% image data
s.hf = loaded_hi.data;
s.hf_cnum = length(s.hf(1,:));
s.hf_anum = length(s.hf(:,1));
s.hf_cres = loaded_hi.Xs/s.hf_cnum;
s.hf_ares = loaded_hi.Dr/2; % not sure about this but matches what Derek
                            % said earlier (see detector main)
s.bb = loaded_lo.data;
s.bb_cnum = length(s.bb(1,:));
s.bb_anum = length(s.bb(:,1));
s.bb_cres = loaded_lo.Xs/s.bb_cnum;
s.bb_ares = loaded_lo.Dr/2;
% side
if loaded_hi.port == 1
    s.side = 'PORT';
else
    s.side = 'STBD';
end
% lat/long
s.lat  = loaded_hi.latitude;
s.long = loaded_hi.longitude;
s.heading = zeros(1,length(loaded_hi.latitude));
% gt
if isempty(gtf)
    s.havegt = 0;
    s.gtimage = [];
else
    s.havegt = 1;
    s.gtimage = mymat_gt_reader(fname_hi, port_or_stbd, gtf, TB_params.TB_HEAVY_TEXT);
end
% target type
s.targettype = '???';
% performance estimation parameters
perf = struct;
perf.depth = loaded_hi.depth;
perf.height = loaded_hi.altitude;
perf.minrange = 0;
perf.maxrange = loaded_hi.Xs;
s.perfparams = perf;
if TB_params.SKIP_PERF_EST == 1
    s.mode = 'A';
else
    s.mode = 'B';
end

if ~isdeployed
    rmpath(newpath);
end
end