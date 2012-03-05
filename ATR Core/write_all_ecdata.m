function write_all_ecdata(contacts, ecdata)
% Writes all of the elements of ecdata into a binary file.
adj = length(contacts) - length(ecdata);
for q = 1:length(ecdata)
    % A future update could add a folder var in TB_params and pass it into
    % this function, thus reducing redundancy in the saved data.  This will
    % do for now though.
    write_extra_cdata( contacts(q+adj).ecdata_fn, ecdata(q) );
end

end