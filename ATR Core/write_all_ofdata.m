function write_all_ofdata(contacts, ofdata)
% Writes all of the elements of opdata into mat files.
adj = length(contacts) - length(ofdata);
for q = 1:length(ofdata)
    % use same file name as ecdata, but with different extension
    [pathstr, fn] = fileparts(contacts(q+adj).ecdata_fn);
    write_ofdata( [pathstr,filesep,fn,'.ofd'], ofdata(q) );
end

end