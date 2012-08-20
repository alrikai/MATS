function gt = nswc_scrubbed_gt_reader(gt_fname, fname)
% Generates substructure containing ground truth data
%
% INPUTS:
%   gt_fname - path of the groundtruth file
%   fname - name of current data file; used to search for gt
%     entries within the file currently being processed
%   port_or_stbd - side of image currently being processed; either
%     'PORT' or 'STBD'
%   show_details - flag for displaying loaded information
% OUTPUTS:
%   gt - groundtruth substructure
    
    if(~exist(gt_fname,'file'))
       [gt_fname, gt_path] = uigetfile('*.txt', 'Select Ground Truth File');
       gt_fname = fullfile(gt_path, gt_fname);
    end
    file_id = fopen(gt_fname,'r');
    gt = [];
    i=0;

    % scan all GT data
    while 0==0 
        %read the range
        [x_i,count] = fscanf(file_id,'%f',1);	
        % test for another line; if no line exists exit reading
        if (count ~= 1)
            break; 
        end               
        
        %read the cross range
        y_i = fscanf(file_id,'%f',1);
        %read the code (this is ignored)
        code_i = fscanf(file_id,'%f',1);
        %get the corresponding filename
        fn_i = fscanf(file_id,'%s',1);
        [~, fname_gt] = fileparts(fn_i);
        
        %test for left or right side
        if(x_i < 0)
            fname_append = '_LEFT';
        else
            fname_append = '_RIGHT';
        end
        %make the full filename
        full_gtfname = strcat(fname_gt, fname_append);
        %get the input data file's name
        [~,fname_data] = fileparts(fname);
        
        % if this GT object is located in this data file, add it.
        if strcmpi(fname_data, full_gtfname)
            i=i+1;
            gt.y(i) = y_i;
            gt.x(i) = x_i;
            gt.code(i) = code_i;
            gt.fn{i} = fn_i;
            gt.score(i) = 0;
            if(x_i < 0)
                gt.side{i} = 'Port';
            else
                gt.side{i} = 'Stbd';
            end
            gt.type(i) = -99; % FIX LATER
        end
    end     % end while loop
end


% %NOTE: this would be for having an input variable named "show_details"
% %(from the TB_HEAVY_TEXT field of the TB_params struct). However, these
% %fields font exist in this data set's ground truth file, so its been
% %removed
% %             if show_details == 1
% %                 fprintf(1,'%-s\n',['GT: Object is on: ',side_i,'; processing: ',port_or_stbd(1)]);
% %             end
%             % if this GT object is located on the side being processed, add it.
% %             if strcmpi(side_i, port_or_stbd)
                