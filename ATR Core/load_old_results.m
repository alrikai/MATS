function [new_contacts, new_ecdata] = load_old_results(fname)
% Load a previously saved result file to simulate using a detector
try 
load(fname, 'contacts');    % 'contacts' has been loaded...

temp = arrayfun(@(a) (a.ID), contacts);
ids = num2cell(temp);

new_contacts = struct('x',-99,'y',-99,'class',-99,'classconf',-99,...
    'features',[],'fn','','side','','gt',-99,'type',-99,'detector','',...
    'classifier','','featureset','','contcorr','','normalizer','',...
    'opfeedback',struct('opdisplay',0,'opconf',0,'type',-99),'ID',ids);

new_ecdata = struct('hfsnippet',[],'bbsnippet',[],'lf1snippet',[],'lat',-99,'long',-99,...
    'groupnum',-99,'groupconf',-99,'grouplat',-99,'grouplong',-99,...
    'groupcovmat',[],'heading',-99,'time',-99,'alt',-99,'hf_ares',-99,'hf_cres',-99,...
    'hf_anum',-99,'hf_cnum',-99,'bb_ares',-99,'bb_cres',-99,...
    'bb_anum',-99,'bb_cnum',-99,'lf1_ares',-99,'lf1_cres',-99,...
    'lf1_anum',-99,'lf1_cnum',-99,'veh_lats',[],'veh_longs',[],...
    'veh_heights',[],'ID',ids,'sensor','','detscore',-99);

% Common fields (i.e., those still in contact list)
for q = 1:length(new_contacts)
    new_contacts(q).x           = contacts(q).x;
    new_contacts(q).y           = contacts(q).y;
    new_contacts(q).features    = [];
    new_contacts(q).class       = -99;
    new_contacts(q).classconf   = -99;
    new_contacts(q).fn          = contacts(q).fn;
    new_contacts(q).side        = contacts(q).side;
    new_contacts(q).gt          = contacts(q).gt;
    if isfield(contacts(q), 'type')
    new_contacts(q).type        = contacts(q).type;
    end
    new_contacts(q).detector    = contacts(q).detector;
    new_contacts(q).featureset  = '';
    new_contacts(q).classifier  = '';
    new_contacts(q).contcorr    = '';
    if isfield(contacts(q), 'normalizer')
    new_contacts(q).normalizer  = contacts(q).normalizer;
    end
    new_contacts(q).opfeedback  = contacts(q).opfeedback;
    if ~isfield(new_contacts(q).opfeedback, 'type')
        new_contacts(q).opfeedback.type = -99;
    end
   
    split_mode = isfield(contacts,'ecdata_fn');
    if split_mode   % seperate files exist; load these into memory
        new_contacts(q).ecdata_fn   = contacts(q).ecdata_fn;
        
        temp = read_extra_cdata( contacts(q).ecdata_fn );
        new_ecdata(q).hfsnippet     = temp.hfsnippet;
        new_ecdata(q).bbsnippet     = temp.bbsnippet;
        if isfield(temp,'lf1snippet')
        new_ecdata(q).lf1snippet    = temp.lf1snippet;
        end
        new_ecdata(q).lat           = temp.lat;
        new_ecdata(q).long          = temp.long;
        new_ecdata(q).heading       = temp.heading;
        new_ecdata(q).time          = temp.time;
        new_ecdata(q).alt           = temp.alt;
        new_ecdata(q).hf_ares       = temp.hf_ares;
        new_ecdata(q).hf_cres       = temp.hf_cres;
        new_ecdata(q).hf_anum       = temp.hf_anum;
        new_ecdata(q).hf_cnum       = temp.hf_cnum;
        new_ecdata(q).bb_ares       = temp.bb_ares;
        new_ecdata(q).bb_cres       = temp.bb_cres;
        new_ecdata(q).bb_anum       = temp.bb_anum;
        new_ecdata(q).bb_cnum       = temp.bb_cnum;
        if isfield(temp,'lf1_ares')
        new_ecdata(q).lf1_ares      = temp.lf1_ares;
        end
        if isfield(temp,'lf1_cres')
        new_ecdata(q).lf1_cres      = temp.lf1_cres;
        end
        if isfield(temp,'lf1_anum')
        new_ecdata(q).lf1_anum      = temp.lf1_anum;
        end
        if isfield(temp,'lf1_cnum')
        new_ecdata(q).lf1_cnum      = temp.lf1_cnum;
        end
        new_ecdata(q).veh_lats      = temp.veh_lats;
        new_ecdata(q).veh_longs     = temp.veh_longs;
        new_ecdata(q).veh_heights   = temp.veh_heights;
        new_ecdata(q).sensor        = temp.sensor;
        new_ecdata(q).detscore      = temp.detscore;
    else            % all in one file; must manually separate data
        new_contacts(q).ecdata_fn   = '';
        % Create 'ecdata' from extra fields in 'contacts'
        new_ecdata(q).hfsnippet     = contacts(q).hfsnippet;
        new_ecdata(q).bbsnippet     = contacts(q).bbsnippet;
        if isfield(contacts(q), 'lf1snippet')
        new_ecdata(q).lf1snippet    = contacts(q).lf1snippet;
        end
        new_ecdata(q).lat           = contacts(q).lat;
        new_ecdata(q).long          = contacts(q).long;
        new_ecdata(q).heading       = contacts(q).heading;
        new_ecdata(q).time          = contacts(q).time;
        new_ecdata(q).alt           = contacts(q).alt;
        new_ecdata(q).hf_ares       = contacts(q).hf_ares;
        new_ecdata(q).hf_cres       = contacts(q).hf_cres;
        new_ecdata(q).hf_anum       = contacts(q).hf_anum;
        new_ecdata(q).hf_cnum       = contacts(q).hf_cnum;
        new_ecdata(q).bb_ares       = contacts(q).bb_ares;
        new_ecdata(q).bb_cres       = contacts(q).bb_cres;
        new_ecdata(q).bb_anum       = contacts(q).bb_anum;
        new_ecdata(q).bb_cnum       = contacts(q).bb_cnum;
        if isfield(contacts(q), 'lf1_ares')
        new_ecdata(q).lf1_ares      = contacts(q).lf1_ares;
        end
        if isfield(contacts(q), 'lf1_cres')
        new_ecdata(q).lf1_cres      = contacts(q).lf1_cres;
        end
        if isfield(contacts(q), 'lf1_anum')
        new_ecdata(q).lf1_anum      = contacts(q).lf1_anum;
        end
        if isfield(contacts(q), 'lf1_cnum')
        new_ecdata(q).lf1_cnum      = contacts(q).lf1_cnum;
        end
        new_ecdata(q).veh_lats      = contacts(q).veh_lats;
        new_ecdata(q).veh_longs     = contacts(q).veh_longs;
        new_ecdata(q).veh_heights   = contacts(q).veh_heights;
        new_ecdata(q).sensor        = contacts(q).sensor;
        new_ecdata(q).detscore      = contacts(q).detscore;
        
    end

    new_ecdata(q).groupnum      = -99;
    new_ecdata(q).groupconf     = -99;
    new_ecdata(q).grouplat      = -99;
    new_ecdata(q).grouplong     = -99;
    new_ecdata(q).groupcovmat   = [];

end

catch ME
    display(['Skipped: ', fname]);
    new_contacts = [];
end

end