function delete_flag(filename, msg_on)
% Deletes a flag file

delete(filename);
there = exist(filename,'file') > 0;
if ~there && msg_on
    disp([filename, ' is gone!']);
end
end