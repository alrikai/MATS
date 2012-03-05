function [cstruct, ecdstruct] = detsub_contact_fill(cstruct, ecdstruct, k, input_struct)
% Fills in many contact fields of contacts(k) with default values or values
% coming directly from the input structure.
    
    cstruct(k).featureset = '';
    cstruct(k).classifier = '';
    cstruct(k).class = -99;
    cstruct(k).classconf = -99;
    cstruct(k).type = -99;
    cstruct(k).contcorr = '';
    
    cstruct(k).opfeedback.opdisplay = 0;
    cstruct(k).opfeedback.opconf = -99;
    cstruct(k).opfeedback.type = -99;
    
    ecdstruct(k).groupnum = -99;
    ecdstruct(k).groupconf = -99;
    ecdstruct(k).grouplat = -99;
    ecdstruct(k).grouplong = -99;
    ecdstruct(k).groupcovmat = [];
    
    side_sign = 1;
    if( strcmpi(cstruct(k).side,'PORT') )
        side_sign = -1;
    end
    
    vec_index = cstruct(k).y;
    y_sample_rate = (input_struct.hf_anum/length(input_struct.perfparams.depth));

    if length(input_struct.heading) == 1    % one heading element
        heading = input_struct.heading;
    else                                    % heading vector
        y_sample_rateh = (input_struct.hf_anum/length(input_struct.heading));
        hdg_vec_int = interp1(1:y_sample_rateh:input_struct.hf_anum,...
            input_struct.heading, 1:input_struct.hf_anum, 'linear', 'extrap');
        heading = hdg_vec_int( vec_index );
    end
    if length(input_struct.perfparams.height) == 1  % one height element
        altitude = input_struct.perfparams.height;
    else                                            % height vector
        y_sample_ratea = (input_struct.hf_anum/length(input_struct.perfparams.height));
        alt_vec_int = interp1(1:y_sample_ratea:input_struct.hf_anum,...
            input_struct.perfparams.height, 1:input_struct.hf_anum, 'linear', 'extrap');
        altitude = alt_vec_int( vec_index );
    end    
    if length(input_struct.lat) == 1 && length(input_struct.long) == 1
        % individual lat/long coord
        [latnew,lonnew] = calcdistbear(input_struct.hf_anum*input_struct.hf_ares,heading,input_struct.lat,input_struct.long);
        lat_vec_int = interp1([1 input_struct.hf_anum],...
            [input_struct.lat latnew], 1:input_struct.hf_anum, 'linear', 'extrap');
        long_vec_int = interp1([1 input_struct.hf_anum],...
            [input_struct.long lonnew], 1:input_struct.hf_anum, 'linear', 'extrap');
        range = side_sign * cstruct(k).x * input_struct.hf_cres;
        lat_v_rad = pi/180 * lat_vec_int( vec_index );
        long_v_rad = pi/180 * long_vec_int( vec_index );
        [lat_c_rad,long_c_rad] = geolocate(lat_v_rad,long_v_rad,...
            0,range,0,altitude);

        ecdstruct(k).lat = 180/pi * lat_c_rad;    % store as degrees
        ecdstruct(k).long = 180/pi * long_c_rad;  % store as degrees
    elseif length(input_struct.lat) > 1 && length(input_struct.long) > 1
        % vector of lat/longs
        y_sample_ratel = (input_struct.hf_anum/length(input_struct.lat));
        lat_vec_int = interp1(1:y_sample_ratel:input_struct.hf_anum,...
            input_struct.lat, 1:input_struct.hf_anum, 'linear', 'extrap');
        long_vec_int = interp1(1:y_sample_ratel:input_struct.hf_anum,...
            input_struct.long, 1:input_struct.hf_anum, 'linear', 'extrap');
    
        range = side_sign * cstruct(k).x * input_struct.hf_cres;
        lat_v_rad = pi/180 * lat_vec_int( vec_index );
        long_v_rad = pi/180 * long_vec_int( vec_index );
        [lat_c_rad,long_c_rad] = geolocate(lat_v_rad,long_v_rad,...
            heading,0,range,altitude);

        ecdstruct(k).lat = 180/pi * lat_c_rad;    % store as degrees
        ecdstruct(k).long = 180/pi * long_c_rad;  % store as degrees
    else
        % length mix or possibly one vector is missing.
        error('Invalid format for lat/long coordinates');
    end

    if isfield(input_struct, 'heading')
        ecdstruct(k).heading = heading;
    end
    if isfield(input_struct, 'time')
        if length(input_struct.time) > 1
            time_vec_int = interp1(1:y_sample_rate:input_struct.hf_anum,...
                input_struct.time, 1:input_struct.hf_anum, 'linear', 'extrap');
            ecdstruct(k).time = time_vec_int( vec_index );
        else
            ecdstruct(k).time = input_struct.time;
        end
    end
    ecdstruct(k).alt = altitude;
    ecdstruct(k).hf_ares = input_struct.hf_ares;
    ecdstruct(k).hf_cres = input_struct.hf_cres;
    ecdstruct(k).hf_anum = input_struct.hf_anum;
    ecdstruct(k).hf_cnum = input_struct.hf_cnum;
    ecdstruct(k).bb_ares = input_struct.bb_ares;
    ecdstruct(k).bb_cres = input_struct.bb_cres;
    ecdstruct(k).bb_anum = input_struct.bb_anum;
    ecdstruct(k).bb_cnum = input_struct.bb_cnum;
    if isfield(input_struct, 'lf1_ares')
        ecdstruct(k).lf1_ares = input_struct.lf1_ares;
    else
        ecdstruct(k).lf1_ares = 0;
    end
    if isfield(input_struct, 'lf1_cres')
        ecdstruct(k).lf1_cres = input_struct.lf1_cres;
    else
        ecdstruct(k).lf1_cres = 0;
    end
    if isfield(input_struct, 'lf1_anum')
        ecdstruct(k).lf1_anum = input_struct.lf1_anum;
    else
        ecdstruct(k).lf1_anum = 0;
    end
    if isfield(input_struct, 'lf1_cnum')
        ecdstruct(k).lf1_cnum = input_struct.lf1_cnum;
    else
        ecdstruct(k).lf1_cnum = 0;
    end
    ecdstruct(k).veh_lats = input_struct.lat;
    ecdstruct(k).veh_longs = input_struct.long;
    ecdstruct(k).veh_heights = input_struct.perfparams.height;
    % Note: background snippet call moved to optional module call in
    % atr_testbed_altfb.m
    ecdstruct(k).sensor = input_struct.sensor;
    
%     %%% These will remain in this structure for the moment, but they will
%     %%% eventually be moved into a separate temporary structure entirely.
%     %%% The functions that look for these variables will have to look in
%     %%% that new structure and check to see if the data exists.
%     cstruct(k).bg_snippet = [];
%     cstruct(k).bg_offset = [0,0];
%     cstruct(k).hfraw = [];
%     cstruct(k).bbraw = [];
%     cstruct(k).lb1raw = [];
%     cstruct(k).hfac = [];
%     cstruct(k).bbac = [];
%     cstruct(k).lb1ac = [];
end