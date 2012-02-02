function [cdata_list, def_index] = import_classdata(cls_handle, tbr)
temp = func2str(cls_handle);
cdata_list = import_cls_data(...
    [tbr,filesep,'Classifiers',filesep,temp(5:end)]);
temp = regexp(cdata_list, '^.+default.+$', 'match');
def_index = find( cellfun(@(a) (length(a)), temp), 1, 'first');
end
    
function fnames = import_cls_data(cls_dir)
prefix = 'data';
dir_cell = struct2cell( dir(cls_dir) );
files = dir_cell(1, :);
matches = regexp(files, [prefix,'\w+|\+\.mat$'],'match');
matches_bool = ~cellfun('isempty',matches);
fnames = files(matches_bool);
end