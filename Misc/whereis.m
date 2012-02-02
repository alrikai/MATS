function matches = whereis(rootpath, str, mode)
% find a string in a large project
% rootpath = 'H:\ATR_TestBed'; str = 'contacts'; mode = 'exact nocomments';

params = regexp(mode,'(\w+)','match');

matches = searchfolder(rootpath, str, params);
end



