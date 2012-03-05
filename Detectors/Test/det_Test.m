function [new_contacts, new_ecdata] = det_Test(input_struct)
% Sample detector that 'finds' objects at random locations.

known_fmts = {'ONR SSAM', 'ONR SSAM2', 'SSAM III', 'MUSCLE', 'EDGETECH', 'MK 18 mod 2', 'MARINESONIC'};
if any(strcmpi(input_struct.sensor, known_fmts))
    [ahf,bhf]=size(input_struct.hf);
    if isfield(input_struct,'bb') && ~isempty(input_struct.bb)
        [alf,blf]=size(input_struct.bb);
        ratio_rows = ahf/alf;
        ratio_cols = bhf/blf;
    end

    %%% Modify as needed
    
    % If GT info is available, include those positions in the contact list
    % to make sure that the classifer has a chance to see them.
    if input_struct.havegt && ~isempty(input_struct.gtimage)
        xs = input_struct.gtimage.x;
        ys = input_struct.gtimage.y;
        num_gt_targets = length(xs);
    else
        xs = []; ys = [];
        num_gt_targets = 0;
    end
    NumTargets = randi(8,1) + num_gt_targets;
    Xlimit = input_struct.hf_cnum;
    Ylimit = input_struct.hf_anum;
    xs = [xs, randi([200 Xlimit-200],1,NumTargets-num_gt_targets)];
    ys = [ys, randi([50 Ylimit-50],1,NumTargets-num_gt_targets)];
    
    new_contacts = struct;  % to contain fields necessary for feedback
    new_ecdata = struct;    % to contain all other standard fields
    for k = 1:NumTargets
        x = xs(k);
        y = ys(k);
        new_contacts(k).x = x;
        new_contacts(k).y = y;
        new_contacts(k).features = [];
        new_contacts(k).fn = input_struct.fn;
        new_contacts(k).side = input_struct.side;
        
        new_ecdata(k).detscore = rand;
        if isfield(input_struct,'bb') && ~strcmpi(input_struct.sensor,'SSAM III')
            if strcmpi(input_struct.sensor,'EDGETECH')
                new_ecdata(k).hfsnippet = make_snippet_alt(x,y,201,31,...
                abs(input_struct.hf));
            else
            new_ecdata(k).hfsnippet = make_snippet_alt(x,y,401,401,...
                abs(input_struct.hf));
            end
        if ~isempty(input_struct.bb)
            new_ecdata(k).bbsnippet = make_snippet_alt(floor(x/ratio_cols),floor(y/ratio_rows),...
                round(401/ratio_cols),round(401/ratio_rows),...
                abs(input_struct.bb));
        else 
            new_ecdata(k).bbsnippet = [];
        end
        end
        new_ecdata(k).lf1snippet = [];
        new_contacts(k).normalizer = 'N/A';
        new_contacts(k).detector = 'Test';
        %%% End
        
        % The remaining field initializations can be calculated directly
        % from the input structure.
        [new_contacts, new_ecdata] = detsub_contact_fill(new_contacts, new_ecdata,...
            k, input_struct);

    end
    new_contacts = detsub_gt(new_contacts, input_struct);

else 
    error('Sensor not recognized')
end
end
