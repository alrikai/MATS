% function write_calls_file()

dir_name = uigetdir;
dir_struct = dir([dir_name, filesep, 'IO*.mat']); 
[sorted_names,sorted_index] = sortrows({dir_struct.name}');
handles.file_names = sorted_names;
handles.is_dir = [dir_struct.isdir];
handles.sorted_index = [sorted_index];
[NImages,g] = size(sorted_names);
listname = [sorted_names(1:NImages,:)];

[fn,path] = uiputfile(...
    {['*txt'], ['(*.txt)']},...
    ['Save contacts list as...']);
fid = fopen([path fn],'w');
hand = waitbar(0,'Loading Contacts ... ');
for loop1 = 1:NImages
    load([dir_name, filesep, listname{loop1,:}]);
    for loop2 = 1:size(contacts,2);
        if contacts(loop2).class == 1;
            name = contacts(loop2).fn;
            name = name(1:end-4);
            if strcmp(contacts(loop2).side,'STBD');
                side = -1;
            else side = 1;
            end
            
            fprintf(fid,[int2str(side*contacts(loop2).x) ' ' int2str(contacts(loop2).y) ' ' mat2str(contacts(loop2).classconf,4) ' ' name '_hf_' lower(contacts(loop2).side) '\n']);
            waitbar(loop1/NImages,hand,'Loading Contacts');
            %[ x loc. y loc. conf_score filename]. Since gt files differ
            %between datasets, maybe the use of either '-' for STBD or
            %'STBD' and 'PORT' to ref side in the calls file is nec. Should
            %test this on multiple sets.
        end;
    end;
end
delete(hand)
fclose(fid)
open([path,fn]);%add path of save file if nec.