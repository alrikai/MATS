function matches = searchfile(filename, str, params)

fid = fopen(filename,'r');
done = 0;
linenum = 1;
matches = [];
while done == 0
    % Get line of text
    line = fgetl(fid);
%     disp(line);

        
    if line == -1
        % Abort loop at end of file
        done = 1;
    else
        % Find words with search string in them
        [index, token] = regexp(line, ['(\w*)?',str,'(\w*)?'], 'start', 'match');
            
        % If line contains search string, add to data structure
        if ~isempty(index) % at least one match
        
            veto = 0;
            comment_index = regexp(line, '[ ]*[\%]+[ ]*', 'start');
%             if length(comment_index)>1, keyboard, end
            if sum( strcmp(params, 'nocomments') ) > 0 && ...
                    ~isempty(comment_index) && (sum(comment_index(1) < index)==length(index))
                % reject comment line
                veto = 1;
            end
            
            if sum( strcmp(params, 'exact') ) > 0
                % search string must be present exactly
                addthis = sum( strcmp(str, token) == 1 ) > 0;
            else
                % substrings are okay
                addthis = 1;
            end
            
            if addthis == 1 && veto == 0 % a match is in there somewhere
                match = struct();
                match.filename = filename;
                match.linenum = linenum;
                match.charnum = index(addthis);
                match.line = line;
                fprintf(1,'<a href="matlab: opentoline(''%s'',%d)">%s, line %d, char %d</a>:\n%s\n\n',filename,linenum,...
                    filename, linenum, match.charnum(1), line);
                matches = [matches, match];
            end
        end
        % Increment line counter
        linenum = linenum + 1;
    end
end
fclose(fid);
end
