function [p, s] = nswc_reader(fname, gtf, TB_params)

load(fname);
% workspace now contains variable 'data' that contains everything

data_present = ones(1,4);
for q = 1:4
    data_present(q) = ~isempty( data(q).data );
end

[junk,fn,ext] = fileparts(fname);

if data_present(1) && data_present(3)
    % load port data
    p = struct;
    % filename
    p.fn = [fn,ext];
    % hf image
    p.hf = data(1).data;
    p.hf_cnum = length( p.hf(1,:) );
    p.hf_anum = length( p.hf(:,1) );
    p.hf_cres = data(1).dx*data(1).xResRed;
    p.hf_ares = data(1).dy*data(1).yResRed;
    % bb image
    p.bb = data(3).data;
    p.bb_cnum = length( p.bb(1,:) );
    p.bb_anum = length( p.bb(:,1) );
    p.bb_cres = data(3).dx*data(3).xResRed;
    p.bb_ares = data(3).dy*data(3).yResRed;
    % side
    p.side = upper(data(1).Side);
    % latitute
    p.lat = data(1).lat;
    % longitude
    p.long = data(1).lon;
    p.targettype = '???';
    % performance estimation parameters
    perf_p = struct;
    perf_p.depth = data(1).depth;
    perf_p.height = data(1).altitude;
    perf_p.minrange = 0;
    perf_p.maxrange = data(1).Xs;
    p.perfparams = perf_p;
    p.time = data(1).sasTime;
    p.heading = data(1).heading;
    if TB_params.SKIP_PERF_EST == 1
        p.mode = 'A';
    else
        p.mode = 'B';
    end
    % groundtruth
    if isempty(gtf)
        p.havegt = 0;
        p.gtimage = [];
    else
        p.havegt = 1;
        if TB_params.GT_FORMAT == 1
            p.gtimage = nswc_gt_reader(fn, 'PORT', gtf, TB_params.TB_HEAVY_TEXT);
        elseif TB_params.GT_FORMAT == 2
            p.gtimage = latlong_gt_reader(p, gtf);
        end
    end
else
    p = [];
end

if data_present(2) && data_present(4)
    % load stbd data
    s = struct;
    % filename
    s.fn = [fn,ext];
    % hf image
    s.hf = data(2).data;
    s.hf_cnum = length( s.hf(1,:) );
    s.hf_anum = length( s.hf(:,1) );
    s.hf_cres = data(2).dx*data(2).xResRed;
    s.hf_ares = data(2).dy*data(2).yResRed;
    % bb image
    s.bb = data(4).data;
    s.bb_cnum = length( s.bb(1,:) );
    s.bb_anum = length( s.bb(:,1) );
    s.bb_cres = data(4).dx*data(4).xResRed;
    s.bb_ares = data(4).dy*data(4).yResRed;
    % side
    s.side = upper(data(2).Side);
    % latitute
    s.lat = data(2).lat;
    % longitude
    s.long = data(2).lon;
    % groundtruth - NEED TO INCORPORATE GT FILE ONCE FORMAT IS KNOWN
    if isempty(gtf)
        s.havegt = 0;
        s.gtimage = [];
    else
        s.havegt = 1;
        s.gtimage = nswc_gt_reader(fn, 'STBD', gtf, TB_params.TB_HEAVY_TEXT);
    end
    s.targettype = '???';
    % performance estimation parameters
%     load('TTSM_Input.mat');
    perf_s = struct;
%     perf_s.numpasses = NUMBER_OF_TARGET_PASSES;
    perf_s.depth = data(2).depth;
    perf_s.height = data(2).altitude;
    perf_s.maxrange = data(2).Xs;
%     perf_s.maxminecs = MAX_MINE_CROSS_SECTION;
%     perf_s.spheremineflag = SPHERICAL_MINE;
%     perf_s.maxmineht = MAX_MINE_HEIGHT_DIAMETER;
%     perf_s.numcadcac = NUMBER_OF_CADCAC_ALGORITHMS;
    s.perfparams = perf_s;
    s.time = data(2).sasTime;
    s.heading = data(2).heading;
    if TB_params.SKIP_PERF_EST == 1
        s.mode = 'A';
    else
        s.mode = 'B';
    end
else
    s = [];
end

end