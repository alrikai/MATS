function [mods] = read_feedback(filename, show_details)
% Reads a feedback file, which contains all data in contacts that changed
% since the last classifier update.
%
% filename = file location of the feedback file
%
% mods = array of update structures
%
% Derek Kolacinski, NSWC PC (derek.kolacinski@navy.mil)
% Last update: 18 May 2010

mods = cell({});
try
    fid = fopen(filename, 'r'); % read from file
    cnt = 1;
    while feof(fid) == 0
        %%% read data
        % ID
        chunk = fread(fid, 1, 'uint16');
        if isempty(chunk)
            fclose(fid);
            return
        end
        temp = struct;
        cont = struct;
        temp.ID = chunk;
        % estimated index
        est_index = fread(fid, 1, 'uint16');
        % feedback type
        type = fread(fid, 1, '*char');
        % filename
        len = fread(fid, 1, 'uint8');
        assert(len >= 0, 'length must be non-negative');
        temp.fn = fread(fid, len, '*char')';
        % side
        temp.side = fread(fid, 4, '*char')';
        % sensor
        len = fread(fid, 1, 'uint8');
        assert(len >= 0, 'length must be non-negative');
        temp.sensor = fread(fid, len, '*char')';
        % x
        temp.x = fread(fid, 1, 'uint16');
        % y
        temp.y = fread(fid, 1, 'uint16');
%         % det score
%         temp.detscore = fread(fid, 1, 'float32');
        % opdisplay
        temp.opdisplay = fread(fid, 1, 'int8');
        % opconf
        temp.opconf = fread(fid, 1, 'int8');
        % optype
        temp.type = fread(fid, 1, 'int8');
        
        if strcmp('V', type) == 1   % Operator 'verify'
            cont.data = temp;
            cont.type = type;
            cont.est_index = est_index;
            mods{cnt} = cont;
            cnt = cnt + 1;
            if show_details == 1
                fprintf(1,' Verify read for ID# %d, est. @ index %d\n',...
                    temp.ID,est_index);
            end
        elseif strcmp('A', type) == 1   % Operator 'add'
            % get HF snippet
            rows = fread(fid, 1, 'uint16');
            assert(rows >= 0, 'rows must be non-negative');
            cols = fread(fid, 1, 'uint16');
            assert(cols >= 0, 'cols must be non-negative');
            re = fread(fid, [rows,cols], 'float32');    % real part %
            im = fread(fid, [rows,cols], 'float32');    % imag part %
            temp.hfsnippet = re + 1i*im;                            %
%             temp.hfsnippet = fread(fid, [rows,cols], 'float32');
            % get BB snippet
            rows = fread(fid, 1, 'uint16');
            assert(rows >= 0, 'rows must be non-negative');
            cols = fread(fid, 1, 'uint16');
            assert(cols >= 0, 'cols must be non-negative');
            re = fread(fid, [rows,cols], 'float32');    % real part %
            im = fread(fid, [rows,cols], 'float32');    % imag part %
            temp.bbsnippet = re + 1i*im;                            %
%             temp.bbsnippet = fread(fid, [rows,cols], 'float32');
            % get LF1 snippet
            rows = fread(fid, 1, 'uint16');
            assert(rows >= 0, 'rows must be non-negative');
            cols = fread(fid, 1, 'uint16');
            assert(cols >= 0, 'cols must be non-negative');
            re = fread(fid, [rows,cols], 'float32');    % real part %
            im = fread(fid, [rows,cols], 'float32');    % imag part %
            temp.lf1snippet = re + 1i*im;                            %
%             temp.lf1snippet = fread(fid, [rows,cols], 'float32');
            % latitude
            temp.lat = fread(fid, 1, 'float32');
            % longitude
            temp.long = fread(fid, 1, 'float32');
            % heading
            temp.heading = fread(fid, 1, 'float32');
            % time
            temp.time = fread(fid, 1, 'float64');
            % altitude
            temp.alt = fread(fid, 1, 'float32');
            % hf resolution (along-track)
            temp.hf_ares = fread(fid, 1, 'float32');
            % hf resolution (cross-track)
            temp.hf_cres = fread(fid, 1, 'float32');
            % hf height (along-track)
            temp.hf_anum = fread(fid, 1, 'uint16');
            % hf width (cross-track)
            temp.hf_cnum = fread(fid, 1, 'uint16');
            % bb resolution (along-track)
            temp.bb_ares = fread(fid, 1, 'float32');
            % bb resolution (cross-track)
            temp.bb_cres = fread(fid, 1, 'float32');
            % bb height (along-track)
            temp.bb_anum = fread(fid, 1, 'uint16');
            % bb width (cross-track)
            temp.bb_cnum = fread(fid, 1, 'uint16');
            % bb resolution (along-track)
            temp.lf1_ares = fread(fid, 1, 'float32');
            % bb resolution (cross-track)
            temp.lf1_cres = fread(fid, 1, 'float32');
            % bb height (along-track)
            temp.lf1_anum = fread(fid, 1, 'uint16');
            % bb width (cross-track)
            temp.lf1_cnum = fread(fid, 1, 'uint16');
            % vehicle latitude vector
            len = fread(fid, 1, 'uint16');
            temp.veh_lats = fread(fid, len, 'float32');
            % vehicle longitude vector
            len = fread(fid, 1, 'uint16');
            temp.veh_longs = fread(fid, len, 'float32');
            % vehicle height vector
            len = fread(fid, 1, 'uint16');
            temp.veh_heights = fread(fid, len, 'float32');
%%% OPTIONAL FIELDS             
%             % get bg snippet
%             rows = fread(fid, 1, 'uint16');
%             assert(rows >= 0, 'rows must be non-negative');
%             cols = fread(fid, 1, 'uint16');
%             assert(cols >= 0, 'cols must be non-negative');
%             re = fread(fid, [rows,cols], 'float32');    % real part %
%             im = fread(fid, [rows,cols], 'float32');    % imag part %
%             temp.bg_snippet = re + 1i*im;                           %
% %             temp.bg_snippet = fread(fid, [rows,cols], 'float32');
%             % get bg offset
%             temp.bg_offset = fread(fid, [1,2], 'int16');
%             % inverse image raw data - hf
%             rows = fread(fid, 1, 'uint16');
%             assert(rows >= 0, 'rows must be non-negative');
%             cols = fread(fid, 1, 'uint16');
%             assert(cols >= 0, 'cols must be non-negative');
%             re = fread(fid, [rows,cols], 'float32');    % real part %
%             im = fread(fid, [rows,cols], 'float32');    % imag part %
%             temp.hfraw = re + 1i*im;                           %
% %             temp.hfraw = fread(fid, [rows,cols], 'float32');
%             % inverse image raw data - bb
%             rows = fread(fid, 1, 'uint16');
%             assert(rows >= 0, 'rows must be non-negative');
%             cols = fread(fid, 1, 'uint16');
%             assert(cols >= 0, 'cols must be non-negative');
%             re = fread(fid, [rows,cols], 'float32');    % real part %
%             im = fread(fid, [rows,cols], 'float32');    % imag part %
%             temp.bbraw = re + 1i*im;                           %
% %             temp.bbraw = fread(fid, [rows,cols], 'float32');
%             % inverse image raw data - lb1
%             rows = fread(fid, 1, 'uint16');
%             assert(rows >= 0, 'rows must be non-negative');
%             cols = fread(fid, 1, 'uint16');
%             assert(cols >= 0, 'cols must be non-negative');
%             re = fread(fid, [rows,cols], 'float32');    % real part %
%             im = fread(fid, [rows,cols], 'float32');    % imag part %
%             temp.lb1raw = re + 1i*im;                           %
% %             temp.lb1raw = fread(fid, [rows,cols], 'float32');
%             % acoustic color - hf
%             rows = fread(fid, 1, 'uint16');
%             assert(rows >= 0, 'rows must be non-negative');
%             cols = fread(fid, 1, 'uint16');
%             assert(cols >= 0, 'cols must be non-negative');
%             re = fread(fid, [rows,cols], 'float32');    % real part %
%             im = fread(fid, [rows,cols], 'float32');    % imag part %
%             temp.hfac = re + 1i*im;                           %
% %             temp.hfac = fread(fid, [rows,cols], 'float32');
%             % acoustic color - bb
%             rows = fread(fid, 1, 'uint16');
%             assert(rows >= 0, 'rows must be non-negative');
%             cols = fread(fid, 1, 'uint16');
%             assert(cols >= 0, 'cols must be non-negative');
%             re = fread(fid, [rows,cols], 'float32');    % real part %
%             im = fread(fid, [rows,cols], 'float32');    % imag part %
%             temp.bbac = re + 1i*im;                           %
% %             temp.bbac = fread(fid, [rows,cols], 'float32');
%             % acoustic color - lb1
%             rows = fread(fid, 1, 'uint16');
%             assert(rows >= 0, 'rows must be non-negative');
%             cols = fread(fid, 1, 'uint16');
%             assert(cols >= 0, 'cols must be non-negative');
%             re = fread(fid, [rows,cols], 'float32');    % real part %
%             im = fread(fid, [rows,cols], 'float32');    % imag part %
%             temp.lb1ac = re + 1i*im;                           %
% %             temp.lb1ac = fread(fid, [rows,cols], 'float32');

            % normalizer
            len = fread(fid, 1, 'uint8');
            assert(len >= 0, 'length must be non-negative');
            temp.normalizer = fread(fid, len, '*char')';
            
            cont.data = temp;
            cont.type = type;
            cont.est_index = est_index;
            mods{cnt} = cont;
            cnt = cnt + 1;
            if show_details == 1
                fprintf(1,' Add read for ID# %d, est. @ index %d\n',...
                    temp.ID,est_index);
            end
        end
    end
    fclose(fid);
catch ME
    type = regexp(ME.identifier, '(?<=:)\w+$', 'match');
    if strcmp(type, 'InvalidFid') == 1
        disp([' ',filename,' cannot be opened.']);
    else
        disp([' An error has occured using ',filename]);
        keyboard
    end
end
end