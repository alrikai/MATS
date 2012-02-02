function cstruct = detsub_contact_fill(cstruct, k, input_struct)
% Fills in many contact fields of contacts(k) with default values or values
% coming directly from the input structure.
    
    cstruct(k).featureset = '';
    cstruct(k).classifier = '';
    cstruct(k).class = -99;
    cstruct(k).classconf = -99;
    cstruct(k).contcorr = '';
    
    cstruct(k).opfeedback.opdisplay = 0;
    cstruct(k).opfeedback.opconf = -99;
    
    cstruct(k).groupnum = 0;
    cstruct(k).groupconf = -99;
    cstruct(k).grouplat = -99;
    cstruct(k).grouplong = -99;
    cstruct(k).groupcovmat = [];
    
    side_sign = 1;
    if( strcmpi(cstruct(k).side,'PORT') )
        side_sign = -1;
    end
    
    vec_index = cstruct(k).y;
    y_sample_rate = (input_struct.hf_anum/length(input_struct.perfparams.depth));
    % 20 July - replacing heading vector with one-element nominal heading
    % is throwing off the contacts' lat/longs
    if length(input_struct.heading) == 1
        heading = input_struct.heading; % new case
    else
        hdg_vec_int = interp1(1:y_sample_rate:input_struct.hf_anum,...
            input_struct.heading, 1:input_struct.hf_anum, 'linear', 'extrap');
        heading = hdg_vec_int( vec_index );    % old case
    end
    if length(input_struct.perfparams.height) == 1
        altitude = input_struct.perfparams.height;
    else
        alt_vec_int = interp1(1:y_sample_rate:input_struct.hf_anum,...
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

        cstruct(k).lat = 180/pi * lat_c_rad;    % store as degrees
        cstruct(k).long = 180/pi * long_c_rad;  % store as degrees
    elseif length(input_struct.lat) > 1 && length(input_struct.long) > 1
        % vector of lat/longs
        lat_vec_int = interp1(1:y_sample_rate:input_struct.hf_anum,...
            input_struct.lat, 1:input_struct.hf_anum, 'linear', 'extrap');
        long_vec_int = interp1(1:y_sample_rate:input_struct.hf_anum,...
            input_struct.long, 1:input_struct.hf_anum, 'linear', 'extrap');
    
        range = side_sign * cstruct(k).x * input_struct.hf_cres;
        lat_v_rad = pi/180 * lat_vec_int( vec_index );
        long_v_rad = pi/180 * long_vec_int( vec_index );
        [lat_c_rad,long_c_rad] = geolocate(lat_v_rad,long_v_rad,...
            heading,0,range,altitude);

        cstruct(k).lat = 180/pi * lat_c_rad;    % store as degrees
        cstruct(k).long = 180/pi * long_c_rad;  % store as degrees
    else
        % mix or possibly one is missing.
        error('Invalid format for lat/long coordinates');
    end

    if isfield(input_struct, 'heading')
        cstruct(k).heading = heading;
    end
    if isfield(input_struct, 'time')
        if length(input_struct.time) > 1
            time_vec_int = interp1(1:y_sample_rate:input_struct.hf_anum,...
                input_struct.time, 1:input_struct.hf_anum, 'linear', 'extrap');
            cstruct(k).time = time_vec_int( vec_index );
        else
            cstruct(k).time = input_struct.time;
        end
    end
    cstruct(k).alt = altitude;
    cstruct(k).hf_ares = input_struct.hf_ares;
    cstruct(k).hf_cres = input_struct.hf_cres;
    cstruct(k).hf_anum = input_struct.hf_anum;
    cstruct(k).hf_cnum = input_struct.hf_cnum;
    cstruct(k).bb_ares = input_struct.bb_ares;
    cstruct(k).bb_cres = input_struct.bb_cres;
    cstruct(k).bb_anum = input_struct.bb_anum;
    cstruct(k).bb_cnum = input_struct.bb_cnum;
    cstruct(k).veh_lats = input_struct.lat;
    cstruct(k).veh_longs = input_struct.long;
    cstruct(k).veh_heights = input_struct.perfparams.height;
    % Note: background snippet call moved to optional module call in
    % atr_testbed_altfb.m
    cstruct(k).sensor = input_struct.sensor;
    cstruct(k).bg_snippet = [];
    cstruct(k).bg_offset = [0,0];
    cstruct(k).hfraw = [];
    cstruct(k).bbraw = [];
    cstruct(k).lb1raw = [];
    cstruct(k).hfac = [];
    cstruct(k).bbac = [];
    cstruct(k).lb1ac = [];
end