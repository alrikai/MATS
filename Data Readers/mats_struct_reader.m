function data = mats_struct_reader(fname, gtf, TB_params)

assert( exist(fname, 'file') == 2, 'File %s does not exist.', fname);
load(fname); % loads structure named 'data'
data.targettype = 'wedge';
find_filesep = strfind(fname,filesep);
data.fn = fname(find_filesep(end)+1:end-4);
% runtime mode
if TB_params.SKIP_PERF_EST == 1
    data.mode = 'A';
else
    data.mode = 'B';
end
data.heading = 0;
data.time = 0;
data.lat = 0;
data.long = 0;
data.perfparams.height = 0;
data.perfparams.depth = 0;
% sweet spot
data.sweetspot = [500 size(data.hf,2)];%data.sweetspot = calc_sweetspot(data);

% gt
if isempty(gtf)
    data.havegt = 0;
    data.gtimage = [];
else
    if TB_params.GT_FORMAT == 1
         data.havegt = 1;
         data.gtimage = mats_struct_gt_reader(fname, 'PORT', gtf, TB_params.TB_HEAVY_TEXT);
    elseif TB_params.GT_FORMAT == 2
        data.gtimage = latlong_gt_reader(data, gtf);
        data.havegt = 1;
    end
end

end