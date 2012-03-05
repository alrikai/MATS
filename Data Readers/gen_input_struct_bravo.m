function s = gen_input_struct_bravo(fname, port_or_stbd, gtf, TB_params)
% Generates an input struct from the Bravo set.
%
% fname = filename of data file
% port_or_stbd = 'port' or 'stbd' (file in 'fname' contains both sides)
% gtf = filename of groundtruth file (if none, use '')
% show_details = prints structure if 1; doesn't if 0
%
% Last update: 13 Dec 2010

load(fname,'ff');
s = struct;
% filename
s.fn = fname;
if strcmpi(port_or_stbd, 'port') == 1
    % High frequency
    s.hf = ff(1,1).data;
    s.hf_cnum = length(s.hf(1,:));
    s.hf_anum = length(s.hf(:,1));
    s.hf_cres = ff(1,1).dx;
    s.hf_ares = ff(1,1).dy;
    % Low frequency
    s.bb = ff(2,1).data;
    s.bb_cnum = length(s.bb(1,:));
    s.bb_anum = length(s.bb(:,1));
    s.bb_cres = ff(2,1).dx;
    s.bb_ares = ff(2,1).dy;
    s.side = upper(ff(1,1).Side);
else    % Stbd
    % High frequency
    s.hf = ff(1,2).data;
    s.hf_cnum = length(s.hf(1,:));
    s.hf_anum = length(s.hf(:,1));
    s.hf_cres = ff(1,2).dx;
    s.hf_ares = ff(1,2).dy;
    % Low frequency
    s.bb = ff(2,2).data;
    s.bb_cnum = length(s.bb(1,:));
    s.bb_anum = length(s.bb(:,1));
    s.bb_cres = ff(2,2).dx;
    s.bb_ares = ff(2,2).dy;
    s.side = upper(ff(1,2).Side);
end
s.lat = ff(1,1).lat;
s.long = ff(1,1).lon;
if isempty(gtf)
    s.havegt = 0;
    s.gtimage = [];
else
    s.havegt = 1;
    s.gtimage = bravo_gt_reader(fname, port_or_stbd, gtf, TB_params.TB_HEAVY_TEXT);
end
s.targettype = 'truncated cone';
s.perfparams = gen_perf_struct(ff);

s.time = ff(1,1).sasTime;
s.heading = ff(1,1).heading;
if TB_params.SKIP_PERF_EST == 1
    s.mode = 'A';   % ATR only
else
    s.mode = 'B';   % Both ATR and performance estimation
end

% sweet spot
s.sweetspot = [300 2180];%calc_sweetspot(s); %HARD CODE FOR SIG TEST ONLY (makes more contacts faster)

if TB_params.TB_HEAVY_TEXT == 1
% if 0 == 1
    disp('**** Input Structure: *******');
    disp(s);
    disp(' Groundtruth Substructure:');
    disp(s.gtimage);
    disp(' Performance Substructure:');
    disp(s.perfparams);
    disp('**** End Input Structure ****');
    disp(' ');
end

end

function ps = gen_perf_struct(ff)
% Generates substructure containing performance parameters
ps = struct;
ps.depth = ff(1,1).depth;
ps.height = ff(1,1).altitude;
ps.minrange = 0;
ps.maxrange = ff(1,1).Xs;
end

