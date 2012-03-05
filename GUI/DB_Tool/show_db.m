function data = show_db(fields, db, varargin)
% Display a formatted table containing certain fields of a structure array.
% This function can also handle nested fields.
%
% Derek Kolacinski, NSWC PC (derek.kolacinski@navy.mil)
% Last update: 20 Jan 2012

if ~isempty(varargin)
    out_file = varargin{1};
else
    out_file = '';
end

% Print information on main screen
record(1,fields,db);

if~isempty(out_file)
% Also print in text file
w_id = fopen(out_file,'w');
record(w_id,fields,db);
fclose(w_id);
end

end

function record(fid, fields, db)
fields = check_fields(fields, db);
num_fields = size(fields,2); max_nest = size(fields,1);
data = cell([length(db), num_fields+1]);
% Determine dimensions of cells and populate data matrix
longests = zeros(1, num_fields+1);
% longests = zeros(1, length(fields)+1);
for q = 1:length(db)
    for w = 1:(num_fields+1)
        if w == 1
            data{q,w} = db(q).ID;
            isnumvec = 0;
        else
            if max_nest == 1 % no nesting
                data{q,w} = db(q).(fields{1, w-1});
                isnumvec = length(data{q,w})>1 && ~ischar(data{q,w});
                n_level(w-1) = 1;       % nesting level
            else
                n = 2; n_done = 0; temp = db(q).(fields{1,w-1});
                while n <= max_nest && n_done == 0
                    if ~isempty(fields{n,w-1})  % another nest level
                        temp = temp.(fields{n,w-1});
                        n = n + 1;
                    else                        % on last nest level
                        n_done = 1;
                    end
                end
                n_level(w-1) = n-1;     % nesting level
                data{q,w} = temp;
                isnumvec = length(data{q,w})>1 && ~ischar(data{q,w});
            end
        end
        if isnumvec
            % [entry width] + [groups of ' | ']
            longests(w) = max([longests(w); 11*length(data{q,w}) + 3*(length(data{q,w}) - 1)]);
        else
            longests(w) = max([longests(w); length(num2str(data{q,w}))]);
        end
    end
end
longests = max([longests; 3*ones(size(longests))]);
titles = cell([1, length(n_level)]);
for q = 1:length(n_level)
    titles{q} = fields{n_level(q), q};
end
temp2{1} = 'id';
title_lens = cellfun(@(a) (length(a)),[temp2,titles]); % use last level's field name

% div_len = [column widths] + [padding spaces] + [dividers]
div_len = sum(max(title_lens, longests)) + 2*length(longests) + ...
    length(longests)+1;
for q = 1:length(db)
    if floor((q-1)/20) == (q-1)/20
        % Print top border
        div = char(61*ones(1,div_len));
        fprintf(fid,'%s\n',div);
        % Print ID name
        lpad = (longests(1) - length('ID'))/2;
        if lpad == round(lpad)
            rpad = lpad;
        else
            rpad = floor(lpad);
            lpad = ceil(lpad);
        end
        lpad = char(32*ones(1,lpad));
        rpad = char(32*ones(1,rpad));
        fprintf(fid,['| ',lpad,'%s',rpad,' '],'ID');
        
        % Print other field names
        for r = 1:num_fields
            % basic padding amount = ([col width] - [title width])/2
            lpad = (longests(r+1) - length(titles{r}))/2;
%             lpad = (longests(r+1) - length(fields{r}))/2;
            if lpad == round(lpad)  % col width is even
                rpad = lpad;    % paddings are equal
            else                    % col width is odd
                rpad = floor(lpad); % give the extra space to right half
                lpad = ceil(lpad);
            end
            % make padding strings
            lpad = char(32*ones(1,lpad));
            rpad = char(32*ones(1,rpad));
            fprintf(fid,['| ',lpad,'%s',rpad,' '],upper(titles{r}));
        end
        fprintf(fid,'|\n');
        % Print bottom border
        fprintf(fid,'%s\n',div);
    end
    % Print data
    for w = 1:length(data(q,:))
        temp = data{q,w};
        if islogical(temp), temp = double(temp); end
        isnumvec = length(temp)>1 && ~ischar(temp);
        dpad = 0;
        if isnumvec %vector that is not a string
            width = '+10.4e';
        else
            if ischar(temp)
                width = [num2str(longests(w)),'s'];
            elseif isinteger(temp) || sum((temp - round(temp)) == 0) == length(temp)
                width = [num2str(longests(w)),'d'];
            elseif isfloat(temp)
                width = [num2str(longests(w)),'g'];
            end
            if w ~= 1
                dpad = max(0, length(titles{w-1}) - longests(w));
            end
        end
        
        lpad = dpad/2;
        if lpad == round(lpad)
            rpad = lpad;
        else
            rpad = floor(lpad);
            lpad = ceil(lpad);
        end
        lpad = char(32*ones(1,lpad));
        rpad = char(32*ones(1,rpad));
        fprintf(fid,['| ',lpad,'%',width,rpad,' '],temp);

%         dpad = char(32*ones(1,dpad));
%         fprintf(fid,['| %',width,dpad,' '],temp);
    end
    fprintf(fid,'|\n');
end
fprintf(fid,'%s\n',div);
end

