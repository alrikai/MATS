function s = hdf5_reader(fname_hi, fname_lo, port_or_stbd, gtf, TB_params)
% Reads data from an hdf5 file and store the data into a testbed input
% structure
%
% INPUTS:
%   fname_hi - filename of the high frequency image
%   fname_lo - filename of the low frequency image
%   port_or_stbd - string indicating side of the vehicle = {'PORT', 'STBD'}
%   gtf - filename of the groundtruth file
% OUTPUT:
%   s = input structure for a side of data

% readHDF5_mcmSpec runs as a script so we're going to have to do everything
% for one frequency before moving on to the other.

s = struct;

readHDF5_mcmSpec(fname_hi);
% hi_frequency code...
% filename
[junk, fn, ext] = fileparts(fname_hi); %#ok<*ASGLU>
s.fn = [fn,ext];
% hf image data
if SpecVersionMajor == 1 && SpecVersionMinor == 0
    mags = squeeze(PingData)';
    phases = squeeze(PingDataPhase)';
    s.hf = mags.*exp(1i*phases);
elseif SpecVersionMajor == 1 && SpecVersionMinor == 1
    s.hf = squeeze(PingData).';
elseif SpecVersionMajor == 2
    s.hf = squeeze(PingData).';
end

s.hf_cnum = length(s.hf(1,:));
s.hf_anum = length(s.hf(:,1));
% hf resolutions
mex_ok = check_mex();
res_switch = (ChannelInfo.AcrossTrackResolution == 0);
if res_switch 
    % Pre-King's Bay format - resolutions obfuscated
    assert(mex_ok);
    s.hf_cres = decodeRes(NERDS.AcrossTrack,NERDS.X0,NERDS.MeanAltitude);
    s.hf_ares = decodeRes(NERDS.AlongTrack,NERDS.Xs,NERDS.MeanAltitude);
else
    % Post-King's Bay format - resolutions easily accessible
    s.hf_cres = ChannelInfo.AcrossTrackResolution;
    s.hf_ares = ChannelInfo.AlongTrackResolution;
end
% side
s.side = upper(port_or_stbd);
% lat/long
s.lat  = PlatformNavigation.Latitude;
s.long = PlatformNavigation.Longitude;
% target type
s.targettype = 'sphere';
% performance estimation parameters
perf = struct;
perf.depth  = PlatformNavigation.Depth;
perf.height = PlatformNavigation.Altitude;
perf.minrange = 0;
perf.maxrange = ChannelInfo.Range;
% perf.maxrange = NERDS.Xs;
s.perfparams = perf;
% time
%%% Convert DataTime structure to proper format
YEAR = double( PlatformTime.Year );
MONTH = double( PlatformTime.Month );
DAY = double( PlatformTime.Day );
HOUR = double( PlatformTime.Hour );
MINUTE = double( PlatformTime.Minute );
SEC = double( PlatformTime.DecimalSec );
comp_years = YEAR - 1970;
comp_leapdays = ceil( (YEAR - 1972)/4 );
secs_from_full_yrs = (comp_years*365 + comp_leapdays)*24*60*60;

leap = (mod(YEAR(1),4)==0 & mod(YEAR(1),100)~=0); %1 for leap year, 0 otherwise
% days in months
dim = [31,28+leap,31,30,31,30,31,31,30,31,30,31];
% days in months completed (this year)
dimc = 0;
if MONTH > 1, dimc = sum( dim(1:(MONTH-1)) ); end
% [DAY-1]  = completed days this month
% [HOUR]   = completed hours this day
% [MINUTE] = completed minutes this hour
this_years_secs = ((((dimc+DAY-1)*24 + HOUR)*60 + MINUTE)*60 + SEC);
s.time = secs_from_full_yrs + this_years_secs;

% heading
if res_switch
    s.heading = calcNominalHeading(s.lat, s.long);
else
    s.heading = DataNavigation.Yaw;
end

readHDF5_mcmSpec(fname_lo);
% lo_frequency code...

% bb image data
if SpecVersionMajor == 1 && SpecVersionMinor == 0
    mags = squeeze(PingData)';
    phases = squeeze(PingDataPhase)';
    s.bb = mags.*exp(1i*phases);
elseif SpecVersionMajor == 1 && SpecVersionMinor == 1
    s.bb = squeeze(PingData).';
elseif SpecVersionMajor == 2
    s.bb = squeeze(PingData).';
end

s.bb_cnum = length(s.bb(1,:));
s.bb_anum = length(s.bb(:,1));
% bb resolutions
if res_switch
    % Pre-King's Bay format - resolutions obfuscated
    s.bb_cres = decodeRes(NERDS.AcrossTrack,NERDS.X0,NERDS.MeanAltitude);
    s.bb_ares = decodeRes(NERDS.AlongTrack,NERDS.Xs,NERDS.MeanAltitude);
else
    % Post-King's Bay format - resolutions easily accessible
    s.bb_cres = ChannelInfo.AcrossTrackResolution;
    s.bb_ares = ChannelInfo.AlongTrackResolution;
end

% runtime mode
if TB_params.SKIP_PERF_EST == 1
    s.mode = 'A';
else
    s.mode = 'B';
end

% sweet spot
s.sweetspot = calc_sweetspot(s);

% gt
if isempty(gtf)
    s.havegt = 0;
    s.gtimage = [];
else
    s.havegt = 1;
    if TB_params.GT_FORMAT == 1
        s.gtimage = hdf5_gt_reader(fname_hi, port_or_stbd, gtf, TB_params.TB_HEAVY_TEXT);
    elseif TB_params.GT_FORMAT == 2
        s.gtimage = latlong_gt_reader(s, gtf);
    end
end

end

function ok = check_mex()
ok = (exist(['decodeRes.',mexext],'file') == 3); % 3 == MEX file
if ~ok
    % If not, check if c file is present and MEX that instead
    has_c = (exist('decodeRes.c','file') == 2);
    if has_c
        try
            mex_folder = [fileparts(mfilename('fullpath')),filesep,'hdf5'];
            mex_path = [mex_folder,filesep,'decodeRes.c'];
            eval(['mex ''',mex_path,''' -outdir ''',mex_folder,'''']);
        catch ME
            keyboard;
            error('MEX file could not be created from decodeRes.c.');
        end
    else
        error('decodeRes%s does not exist',mexext);
    end
end
end