function new_contacts = det_Test(input_struct)
% Sample detector that 'finds' objects at random locations.

known_fmts = {'ONR SSAM', 'ONR SSAM2', 'SSAM III', 'MUSCLE', 'EDGETECH', 'MK 18 mod 2'};
if any(strcmpi(input_struct.sensor, known_fmts))
    [ahf,bhf]=size(input_struct.hf);
    if isfield(input_struct,'bb') && ~isempty(input_struct.bb)
        [alf,blf]=size(input_struct.bb);
        ratio_rows = ahf/alf; %DK: ratio of rows (y)
        ratio_cols = bhf/blf; %DK: ratio of cols (x)
    end

    %%% Modify as needed
    NumTargets = ceil(15*rand(1,1));
    Xlimit = input_struct.hf_cnum;
    Ylimit = input_struct.hf_anum;
    new_contacts = struct;
    for k = 1:NumTargets
        x = ceil(Xlimit*rand);
        y = ceil(Ylimit*rand);
        new_contacts(k).x = x;
        new_contacts(k).y = y;
        new_contacts(k).features = single(1);
        new_contacts(k).fn = input_struct.fn;

        new_contacts(k).side = input_struct.side;
        new_contacts(k).sensor = input_struct.sensor;
        new_contacts(k).detscore = rand;
        if isfield(input_struct,'bb') && ~strcmpi(input_struct.sensor,'SSAM III')
            new_contacts(k).hfsnippet = make_snippet_alt(x,y,400,400,...
                abs(input_struct.hf));
        if ~isempty(input_struct.bb)
            new_contacts(k).bbsnippet = make_snippet_alt(floor(x/ratio_cols),floor(y/ratio_rows),...
                round(400/ratio_cols),round(400/ratio_rows),...
                abs(input_struct.bb));
        end
        end

        new_contacts(k).detector = 'Test';
        new_contacts(k).normalizer = 'N/A';
        %%% End
        
        % The remaining field initializations can be calculated directly
        % from the input structure.
        new_contacts = detsub_contact_fill(new_contacts, k, input_struct);

    end
    new_contacts = detsub_gt(new_contacts, input_struct);

else 
    error('Sensor not recognized')
end
end
