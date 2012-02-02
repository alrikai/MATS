function gt = bravo_gt_reader(data_file_name, port_or_stbd, gtf, show_details)
% Generates substructure containing ground truth data
%
% INPUTS:
%   data_file_name - name of current data file; used to search for gt
%     entries within the file currently being processed
%   port_or_stbd - side of image currently being processed; either
%     'PORT' or 'STBD'
%   gtf - path of the groundtruth file
% OUTPUTS:
%   gt - groundtruth substructure

file_id = fopen(gtf,'r');
gt = [];
i=0;

while 0==0 % scan all GT data
    [x_i,count] = fscanf(file_id,'%f',1);	% test for another line
    if count ~= 1, break; end               % no line exists
    x_i = abs(x_i);
    y_i = fscanf(file_id,'%f',1);
    code_i = fscanf(file_id,'%f',1);
    fn_i = fscanf(file_id,'%s',1);
    score_i = fscanf(file_id,'%f',1);
    side_char = fn_i(end-8);
    
    [junk,fname_data] = fileparts(data_file_name); %#ok<*ASGLU> % filename from input struct
    [junk,fname_gt] = fileparts(fn_i);             % filename from gt file (bravo)
    % Cut off freq. and side info from file name (not in Bravo data set)
    u = find(fname_gt == '_',2,'last');
    fname_gt = fname_gt(1:u(1)-1);

    % if this GT object is located in this data file, add it.
    if (strcmpi(fname_data, fname_gt) == 1)
        if show_details == 1
            fprintf(1,'%-s\n',['GT: Object is on: ',side_char,'; processing: ',port_or_stbd(1)]);
        end
        % if this GT object is located on the side being processed, add it.
        if strcmpi(side_char, port_or_stbd(1))
            i=i+1;
            gt.y(i) = y_i;
            gt.x(i) = x_i;
            gt.code(i) = code_i;
            gt.fn = fn_i;
            gt.score(i) = score_i;
            if strcmpi(side_char, 'p')
                gt.side = 'Port';
            elseif strcmpi(side_char, 's')
                gt.side = 'Stbd';
            else
                gt.side = '????';
            end
        end
    end
end     % end while loop

end