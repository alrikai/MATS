function new_contacts = load_old_results(fname)
try 
load(fname, 'contacts');    % 'contacts' has been loaded...

temp = arrayfun(@(a) (a.ID), contacts);
ids = num2cell(temp);

new_contacts = struct('x',-99,'y',-99,'class',-99,'classconf',-99,...
    'features',[],'fn','','side','','sensor','','detscore',-99,...
    'hfsnippet',[],'bbsnippet',[],'bg_snippet',[],'bg_offset',[],...
    'gt',-99,'lat',-99,'long',-99,'groupnum',-99,'groupconf',-99,...
    'grouplat',-99,'grouplong',-99,'groupcovmat',[],'detector','',...
    'classifier','',...
    'contcorr','','opfeedback',struct('opdisplay',0,'opconf',0),...
    'heading',-99,'time',-99,'alt',-99,'hf_ares',-99,'hf_cres',-99,...
    'hf_anum',-99,'hf_cnum',-99,'bb_ares',-99,'bb_cres',-99,...
    'bb_anum',-99,'bb_cnum',-99,'veh_lats',[],'veh_longs',[],...
    'veh_heights',[],'ID',ids,'hfraw',[],'bbraw',[],'lb1raw',[],...
    'hfac',[],'bbac',[],'lb1ac',[]);

fields = fieldnames(contacts);
for q = 1:length(contacts)
    for f = 1:length(fields)
        new_contacts(q).(fields{f}) = contacts(q).(fields{f});
    end
end

% MUST CLEAR OUT FEATURES OR BAD THINGS HAPPEN!
% This won't work for results with detectors other than Tucker's.
for q = 1:length(new_contacts)
    new_contacts(q).features      = [];%contacts(q).features(59:end);
    % Also set fields that would not have been run yet to their default
    % (bogus) values
    new_contacts(q).class         = -99;
    new_contacts(q).classconf     = -99;
    new_contacts(q).classifier    = '';
    new_contacts(q).groupnum      = -99;
    new_contacts(q).groupconf     = -99;
    new_contacts(q).grouplat      = -99;
    new_contacts(q).grouplong     = -99;
    new_contacts(q).groupcovmat   = [];
    new_contacts(q).bg_snippet    = [];
    new_contacts(q).bg_offset     = [0,0];
end
catch
    display(['Skipped: ', fname]);
    new_contacts = [];
end

end