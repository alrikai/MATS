function data = mats_struct_reader(fname, gtf, TB_params)

assert( exist(fname, 'file') == 2, 'File %s does not exist.', fname);
load(fname); % loads structure named 'data'
data.targettype = 'wedge';

% runtime mode
if TB_params.SKIP_PERF_EST == 1
    data.mode = 'A';
else
    data.mode = 'B';
end

% sweet spot
data.sweetspot = calc_sweetspot(data);
end