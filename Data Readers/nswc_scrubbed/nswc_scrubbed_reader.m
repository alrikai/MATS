function [p,s] = nswc_scrubbed_reader(fname, PORT, gtf, TB_params)
%reads the .pgm file(s) from the nswc scrubbed dataset and composes an
%output datastructure for the MATS framework

    nswc_data = read_pgm(fname);
    [~,fn,ext] = fileparts(fname);
    
    %store the filename
    p.fn = [fn,ext];
    
    %set the image data and its dimensions
    p.hf = nswc_data;
    [p.hf_anum, p.hf_cnum] = size(p.hf);
    
    %arbitrarily taken from the pcswat_reader settings
    p.hf_cres = 0.05;
    p.hf_ares = 0.05;

    p.side = 'PORT';
    %check if we have a ground truth file, if so load it
    if isempty(gtf)
        p.havegt = 0;
        p.gtimage = [];
    else
        p.havegt = 1;
        p.gtimage = nswc_scrubbed_gt_reader(gtf, fname);
        if(~isempty(p.gtimage))
            if(p.gtimage.x > 0)
               p.side = 'STBD';
            else
               p.gtimage.x = abs(p.gtimage.x);
            end
        end
    end
    
    
    %bb (broadband) image is taken to be the same as hf
    p.bb = p.hf;
    p.bb_cnum = p.hf_cnum;
    p.bb_anum = p.hf_anum;
    p.bb_cres = p.hf_cres;
    p.bb_ares = p.hf_ares;
    
    %these are unset...
    p.lat = -99;
    p.long = -99;
    p.heading = -99; 
    p.targettype = -99;
    p.time = -99;
    
    %this one (performance estimation) is unset too 
    p.perfparams = struct('depth', -99, 'height', -99, 'minrange', -99, 'maxrange', -99);
    %flag for whether using the performance estimation or not
    if(TB_params.SKIP_PERF_EST == 1)
        p.mode = 'A';
    else
        p.mode = 'B';
    end
    %image ROI
    p.sweetspot = [1, p.hf_cnum];
    
    %have data in port (p) or starboard (s) datastructure
    if(strcmpi(p.side,'port'))
        s = [];
    else
        s = p;
        p = [];
    end
end

% TB_params.TB_HEAVY_TEXT = 0;
% TB_params.SKIP_PERF_EST = 1
% fpath = '/home/alrik/NSWC_Datasets/NSWC Scrub/'
% 
% dfile_name = '27JAN032_LEFT.PGM'
% gtfile_name = 'GT_All_SCRUBBED_IMAGES.TXT'
% 
% fname = strcat(fpath, dfile_name);
% gtf = strcat(fpath, gtfile_name);
% [p,s] = nswc_scrubbed_reader(fname, 'PORT', gtf, TB_params)
