function [p,s] = csdt_reader(fname, gtf, TB_params)%show_details)

%Michael Rowe 2/10/2011
%This file will read in CSDT data into the testbed. 
%The image is graphed but the boxes around the targets are not correct



[sonar_port0, sonar_stbd0, data1, data2, error_code] = read_csdt(fname);



[junk,fn,ext] = fileparts(fname); %#ok<*ASGLU>

p = struct; s = struct;

p.fn= [fn,ext];
%Load CSDT image port image
p.hf = sonar_port0';
%Number of cross range pixels
p.hf_cnum = size((sonar_port0),2);
%Number of along range pixels
p.hf_anum = size((sonar_port0),1);
%range resolution
p.hf_cres = mean(arrayfun(@(a) (a.range_port), data2))/mean(arrayfun(@(a) (a.spl_port), data2));
%Along track resolution
p.hf_ares = mean(arrayfun(@(a) (a.track_res), data2));
%Side of sonar
p.side = 'PORT';
%Latitude
p.lat = mean(arrayfun(@(a) (a.lat), data2));
%Longitude
p.long = mean(arrayfun(@(a) (a.lng), data2));
%Heading THIS VALUE CHANGES SLIGHTLY
p.heading = mean(arrayfun(@(a) (a.head), data2));
p.targettype = '???';
% filling in blank parameters that are not part of ET
p.bb = [];
p.bb_cnum = 0;
p.bb_anum = 0;
p.bb_cres = 0;
p.bb_ares = 0;
p.time = 0;
%Performance estimation variables
perf_p = struct;
perf_p.depth = mean(arrayfun(@(a) (a.depth), data2));
perf_p.height = mean(arrayfun(@(a) (a.altitude), data2));
perf_p.minrange = 0;
perf_p.maxrange = mean(arrayfun(@(a) (a.range_port), data2));
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
    p.havegt = 1;
    if TB_params.GT_FORMAT == 1
        p.gtimage = et_gt_reader(fname, 'Port', gtf, 0);
    elseif TB_params.GT_FORMAT == 2
        p.gtimage = latlong_gt_reader(p, gtf);
    end
end


s.fn= [fn,ext];
%Load CSDT image stbd image
s.hf = sonar_stbd0';
%Number of cross range pixels
s.hf_cnum = size((sonar_stbd0),2);
%Number of along range pixels
s.hf_anum = size((sonar_stbd0),1);
%Cross range resolution
s.hf_cres = mean(arrayfun(@(a) (a.range_stbd), data2))/mean(arrayfun(@(a) (a.spl_stbd), data2));
%Along range resolution
s.hf_ares = mean(arrayfun(@(a) (a.track_res), data2));
%Side of sonar
s.side = 'STBD';
%Latitude
s.lat = mean(arrayfun(@(a) (a.lat), data2));
%Longitude
s.long = mean(arrayfun(@(a) (a.lng), data2));
%Heading THIS VALUE CHANGES SLIGHTLY
s.heading = mean(arrayfun(@(a) (a.head), data2));
s.targettype = '???';
% filling in blank parameters that are not part of ET
s.bb = [];
s.bb_cnum = 0;
s.bb_anum = 0;
s.bb_cres = 0;
s.bb_ares = 0;
s.time = 0;
%Performance estimation variables
perf_s = struct;
perf_s.depth = mean(arrayfun(@(a) (a.depth), data2));
perf_s.height = mean(arrayfun(@(a) (a.altitude), data2));
perf_s.maxrange = mean(arrayfun(@(a) (a.range_port), data2));
s.perfparams = perf_s;
if TB_params.SKIP_PERF_EST == 1
    s.mode = 'A';
else
    s.mode = 'B';
end

% gt
if isempty(gtf)
    s.havegt = 0;
    s.gtimage = [];
else
    s.havegt = 1;
    if TB_params.GT_FORMAT == 1
        s.gtimage = et_gt_reader(fname, 'Stbd', gtf, 0);
    elseif TB_params.GT_FORMAT == 2
        s.gtimage = latlong_gt_reader(s, gtf);
    end
end

end

