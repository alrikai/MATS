function compare_results(gt_file, c_list, out_file, fmt_index, hi_sfnames)
% function compare_results()
% Produces a list comparing the list of detections in 'c_list' with the
% ground truth data in 'gt_file'.
%
% INPUTS:
%   gt_file = filename of ground truth text file
%   c_list = contact list
%   out_file = filename of text file to be savedfigure
%
% Derek Kolacinski, NSWC PC (derek.kolacinski@navy.mil)
% Last update: 12 Aug 2011

if isempty(c_list), return, end
% Load groundtruth data
ecdata = read_extra_cdata(c_list(1).ecdata_fn);
gtf_id = fopen(gt_file);
gt_data = struct('xs',[],'ys',[],'codes',[],'fns',{},'scores',[],'sides',[]);
% gt_cnt = 1;
while 0 == 0
    switch fmt_index
        case 1 % Bravo
            [x_i, count] = fscanf(gtf_id, '%f', 1);
            if count ~= 1, break; end
            x_i = abs(x_i);
            y_i = fscanf(gtf_id, '%f', 1);
            code_i = fscanf(gtf_id, '%f', 1);
            fn_i = fscanf(gtf_id, '%s', 1);
            score_i = fscanf(gtf_id, '%f', 1);
            side_i = fn_i((end-8):(end-5));
        case {2,3,4,6,8,9}
            [x_i,count] = fscanf(gtf_id,'%f',1);	% test for another line
            if count ~= 1, break; end               % no line exists
            y_i = fscanf(gtf_id,'%f',1);
            code_i = fscanf(gtf_id,'%f',1);
            side_i = fscanf(gtf_id,'%s',1);
            fn_i = fscanf(gtf_id,'%s',1);
            %     score_i = [];
        case {5,10} %HDF5
            [x_i,count] = fscanf(gtf_id,'%f',1);	% test for another line
            if count ~= 1, break; end               % no line exists
            y_i = fscanf(gtf_id,'%f',1);
            code_i = fscanf(gtf_id,'%s',1);
            if x_i < 0
                side_i = 'Port';
            else
                side_i = 'Stbd';
            end
            x_i = abs(x_i);
            fn_i = fscanf(gtf_id,'%s',1);
            
        case {7,12} %ET and NSWC scrub (.PGM)
            [x_i,count] = fscanf(gtf_id,'%f',1);	
            % test for another line no line exists
            if (count ~= 1)
                break; 
            end               
            y_i = fscanf(gtf_id,'%f',1);
            code_i = fscanf(gtf_id,'%s',1);
            fn_i = fscanf(gtf_id,'%s',1);
            if x_i < 0
                side_i = 'Port';
                fn_i = strcat(fn_i, '_LEFT');
            else
                side_i = 'Stbd';
                fn_i = strcat(fn_i, '_RIGHT');
            end
            x_i = abs(x_i);
            
    end
    
    gt_data(1).xs = [gt_data.xs, x_i];
    gt_data(1).ys = [gt_data.ys, y_i];
    gt_data(1).fns = [gt_data.fns; cellstr(fn_i)];
    gt_data(1).codes = [gt_data.codes, str2double(code_i)];
    %     gt_data(1).scores = [gt_data.scores, score_i];
    gt_data(1).sides = [gt_data.sides; cellstr(side_i)];
end

% Extract core parts of the file names listed in groundtruth file
fname_gcore = cell(size(gt_data.fns));
for k = 1:length(gt_data.fns)
    [junk,fname_gt] = fileparts(gt_data.fns{k});  % filename from gt file (bravo)
    switch fmt_index
        case 1 % Bravo
            fname_gcore{k} = fname_gt(1:(end-8));
        case {2,3,4,5,6,7,8,9,10,12}
            fname_gcore{k} = fname_gt;
    end
end

% Extract core parts of the file names listed in file list
fname_lcore = cell(size(hi_sfnames));
for k = 1:length(hi_sfnames)
    [junk,fname_list] = fileparts(hi_sfnames{k});  % filename from file list
    if strcmp(fname_list(1:3), 'IO_') % call from GUI
        fname_lcore{k} = fname_list(4:(end-5));
    else
        fname_lcore{k} = fname_list;
    end
end

% Purge groundtruth elements from images that were not run from list
run_mask = zeros(size(fname_gcore));
for q = 1:length(fname_gcore)
    gt_file_match = strcmp(fname_lcore, fname_gcore{q});
    if any(gt_file_match)
        run_mask(q) = 1;
    end
end
fname_gcore = fname_gcore(run_mask == 1);
gt_data.xs = gt_data.xs(run_mask == 1);
gt_data.ys = gt_data.ys(run_mask == 1);
gt_data.codes = gt_data.codes(run_mask == 1);
gt_data.fns = gt_data.fns(run_mask == 1);
% gt_data.scores = gt_data.xs(run_mask == 1);
gt_data.sides = gt_data.sides(run_mask == 1);
    
% Define tolerances for what constitutes a match
% x_tol = 2; y_tol = 2;
x_tol = 5/ecdata.hf_cres; y_tol = 5/ecdata.hf_ares;
% x_tol = 250; y_tol = 250;
match_indicies = zeros(size(c_list));
% For each contact in the contact list...
for q = 1:length(c_list)
    % ...compare this contact with the groundtruth entries
    
    [junk,fname_dcore] = fileparts(c_list(q).fn); % filename from contact list
    % compare file name of this contact with that of all gt entries
    file_match = strcmpi(fname_dcore, fname_gcore);
    % compare side character of this contact with that of all gt entries
    side_match = strcmpi( c_list(q).side, gt_data.sides );
    %     side_match = strcmpi( c_list(q).side(1), gt_data.sides );
    % check if coordinates of this contact is 'close enough' to any
    % coordinates in gt entries
    x_match = abs( c_list(q).x - gt_data.xs' ) <= x_tol;
    y_match = abs( c_list(q).y - gt_data.ys' ) <= y_tol;
    gt_match = c_list(q).gt;
    
    %     [file_match, side_match, x_match, y_match]
%     match = file_match & side_match & x_match & y_match;
%     match = file_match & side_match & gt_match;
    match = file_match & side_match & gt_match & x_match & y_match;
    match_ind = find(match);
    
    if isempty(match_ind)
        match_indicies(q) = -1;
    else
        % store index corresponding to gt entry that is the closest match
        diffs = ( (gt_data.xs(match_ind) - c_list(q).x).^2 + (gt_data.ys(match_ind) - c_list(q).y).^2 ) .^0.5;
        [~,temp] = min(diffs);
        match_indicies(q) = match_ind(temp(1));
    end
end

% indicies of gt entries that match contacts
used_gt_ind = unique(match_indicies);
% indicies of gt entries that do not match contacts
missed_gt_ind = setdiff(1:length(gt_data.fns), used_gt_ind);
% filename cores of gt entries that do not match contacts
missed_gt_fns = fname_gcore(missed_gt_ind);
% side chars of gt entries that do not match contacts
missed_gt_sides = gt_data.sides(missed_gt_ind);

missed_gt_xs = gt_data.xs(missed_gt_ind);
missed_gt_ys = gt_data.ys(missed_gt_ind);

% Print information on main screen
record(1);
% Also print in text file
w_id = fopen(out_file,'w');
record(w_id);
fclose(w_id);

    function record(fid)
        % Display results
        fprintf(fid,'\nDetections vs. Groundtruth\n');
        
        last_fn = ''; last_side = ' ';
        for qq = 1:length(c_list)
            [junk,this_fn] = fileparts(c_list(qq).fn); this_side = c_list(qq).side;
            % if code has moved on to the next image/side...
            if strcmp(this_fn, last_fn) == 0 || strcmp(this_side, last_side) == 0
                % went to next file, show skipped gt from prev file first
                mask = strcmp(last_fn, missed_gt_fns) == 1 & ...
                    strcmpi(last_side, missed_gt_sides) == 1;
                skipped_img_ind = missed_gt_ind(mask);
                for w = 1:length(skipped_img_ind)
                    fprintf(fid, '........No match..... -------- GT#%03d @ (%4d,%4d)\n',...
                        skipped_img_ind(w), gt_data.xs(skipped_img_ind(w)),...
                        gt_data.ys(skipped_img_ind(w)));
                end
            end
            
            if strcmp(this_fn, last_fn) == 0 || strcmp(this_side, last_side) == 0
                fprintf(fid,'\n       %s, %s\n\n',this_fn,this_side);
            end
            if match_indicies(qq) == -1
                fprintf(fid,'%s C#%03d @ (%4d,%4d) -------- ......No match......\n',...
                    char( (c_list(qq).class >= 1)*'x' + (c_list(qq).class == 0)*' ' ),...
                    qq, c_list(qq).x, c_list(qq).y);
            else
                fprintf(fid,'%s C#%03d @ (%4d,%4d) -------- GT#%03d @ (%4d,%4d)\n',...
                    char( (c_list(qq).class >= 1)*'x' + (c_list(qq).class == 0)*' ' ),...
                    qq, c_list(qq).x, c_list(qq).y, match_indicies(qq), gt_data.xs(match_indicies(qq)),...
                    gt_data.ys(match_indicies(qq)));
            end
            
            last_fn = this_fn; last_side = this_side;
        end
        % process skipped gt for last file/side (copied from loop above)
        mask = strcmp(last_fn, missed_gt_fns) == 1 & ...
            strcmpi(last_side, missed_gt_sides) == 1;
        skipped_img_ind = missed_gt_ind(mask);
        for w = 1:length(skipped_img_ind)
            fprintf(fid, '.......No match...... -------- GT#%03d @ (%4d,%4d)\n',...
                skipped_img_ind(w), gt_data.xs(skipped_img_ind(w)),...
                gt_data.ys(skipped_img_ind(w)));
        end
        fprintf(fid,'\nUndetected GT:\n');
        for w = 1:length(missed_gt_fns)
            fprintf(fid,'%s  %s  (%4d,%4d)\n',missed_gt_fns{w},...
                missed_gt_sides{w}, missed_gt_xs(w), missed_gt_ys(w));
        end
        fprintf(fid,'-----------------------------------------------------\n');
        totaltarg = length(gt_data(1).xs);
        detecttarg = totaltarg - length(missed_gt_fns);
        PD = 100*(detecttarg/totaltarg);
        fprintf(fid,'Total Targets: %d / Detected Targets: %d\n',totaltarg,detecttarg);
        fprintf(fid,'Probability of Detection: %.2f%%\n',PD);
    end % end record function

end