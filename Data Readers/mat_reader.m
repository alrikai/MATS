function [p_struct, s_struct] = mat_reader(fname_hi, fname_lo, mode, gtf, TB_params)
% Reads .mat format sonar data and converts it into a standard image input
% structure
%
% INPUTS:
%   fname_hi - filename of the high frequency image
%   fname_lo - filename of the low frequency image (empty for nswc)
%   gtf - filename of the groundtruth file (NEEDS TO BE FULLY USED!)

% fname_hi = 'H:\TESTBED\Datasets\Matlab Something\Image1_Sensor2_EnvB_07Aug11.mat';
% fname_lo = 'H:\TESTBED\Datasets\Matlab Something\Image1_Sensor3_EnvB_07Aug11.mat';

if strcmpi(mode,'scrub')
    [p_struct, s_struct] = scrub_reader(fname_hi, fname_lo, gtf, TB_params);
elseif strcmpi(mode, 'nswc')
    [p_struct, s_struct] = nswc_reader(fname_hi, gtf, TB_params);
elseif strcmpi(mode, 'nurc')
    [p_struct, s_struct] = nurc_reader(fname_hi, gtf, TB_params);
elseif strcmpi(mode, 'csdt')
    [p_struct, s_struct] = csdt_reader(fname_hi, gtf, TB_params);
elseif strcmpi(mode, 'pond')
    [p_struct, s_struct] = pond_reader(fname_hi, gtf, TB_params);
else
    disp(['Error: Unknown reader mode ',mode]);
    p_struct = [];
    s_struct = [];
end

end


