function wait_if_flag(flagname)
% waits while file(s) defined in 'flagname' exist.  'flagname' can either
% be a string representing the filename of the flag to wait for, or a cell
% array of multiple such strings.
wait = 1;
while wait == 1
    if iscell(flagname) % multiple flags to watch for
        ok = 1;
        for q = 1:length(flagname)
        ok = ok && ~(exist(flagname{q},'file') > 0);	% check if flag exists
        end
        wait = ~ok;
        if wait > 0                       	% if so...
            pause(1);                     	% ...wait a second
            fprintf(1,'.');
        end
    else                % only one flag to watch for
        wait = exist(flagname,'file') > 0;	% check if flag exists
        if wait > 0                       	% if so...
            pause(1);                     	% ...wait a second
            fprintf(1,'.');
        end
    end
end
end