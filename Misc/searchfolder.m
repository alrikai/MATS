function matches = searchfolder(folderpath, str, params)
% function matches = searchfolder(folderpath, str, mode, matches)

% folderpath = 'H:\ATR_TestBed';
matches = [];
folderdir = dir(folderpath);


% remove '.' and '..' entries
temp = arrayfun(@(a) ( strcmp(a.name,'.') || strcmp(a.name,'..') ), folderdir);
folderdir(temp) = [];

% A file has a period in the name but doesn't start with it
isfile = arrayfun(@(a) ( ~isempty(regexp(a.name,'\S+\.','match')) ),folderdir);
% sort files and folders
subfolders = folderdir(~isfile);
files = folderdir(isfile);
% skip system-like folders (e.g., .git)
isfolder = arrayfun(@(a) ( ~isempty(regexp(a.name,'^[a-zA-Z_0-9]','match')) ), subfolders);
subfolders = subfolders(isfolder);
% filter out m files
istext = arrayfun(@(a) ( ~isempty(regexp(a.name,'\S+\.[m]$','match')) ),files);
files = files(istext);

% Look in all files in this directory
for q = 1:length(files)
%     fprintf(1,'\n\nLooking in %s...\n\n',[folderpath,filesep,files(q).name]);
%     keyboard
    fi_matches = searchfile([folderpath,filesep,files(q).name], str, params);
    matches = [matches, fi_matches];
end

% Look recursively in all subdirectories
for q = 1:length(subfolders)
    fo_matches = searchfolder([folderpath,filesep,subfolders(q).name],...
        str, params);
    matches = [matches, fo_matches];
end
end