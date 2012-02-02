function input_struct = normalize_images(input_struct)

switch input_struct.sensor
    case {'SSAM I','ONR SSAM','SSAM II', 'ONR SSAM2'}
        
        % get sweetspot image bounds
        x1 = input_struct.sweetspot(1);
        x2 = input_struct.sweetspot(2)-100;
        
        % % HF
        
        % convert complex data to magnitude and phase
        mag_img = abs(input_struct.hf);
        pha_img = angle(input_struct.hf);
        
        % normalize magnitude
        mag_ss = mag_img(:, x1:x2);         % mags over sweet spot
        mag_ss = mag_ss - min(mag_ss(:));
        m = mean2(mag_ss);                  % scaling factor
        mag_img = mag_img - min(mag_ss(:));
        mag_img = mag_img/m;
        % covert back to a+bi format
        out = mag_img .* exp(1j*pha_img);
        % clip everything higher that 16*MEAN
        
        out = min(out, 16);
        % save hf image
        input_struct.hf = out;
        
        % % BB
        
        ratio_range = input_struct.hf_cnum/input_struct.bb_cnum;
        x1 = x1/ratio_range;
        x2 = x2/ratio_range;
        % convert complex data to magnitude and phase
        mag_img = abs(input_struct.bb);
        pha_img = angle(input_struct.bb);
        
        % normalize magnitude
        mag_ss = mag_img(:, x1:x2);         % mags over sweet spot
        mag_ss = mag_ss - min(mag_ss(:));
        m = mean2(mag_ss);                  % scaling factor
        mag_img = mag_img - min(mag_ss(:));
        mag_img = mag_img/m;
        % covert back to a+bi format
        out = mag_img .* exp(1j*pha_img);
        % clip everything higher that 16*MEAN
        out = min(out, 16);
        % save hf image
        input_struct.bb = out;
        
        % input_struct.normalizer = 'nwsc-pcd';
        
    case 'MUSCLE'
        % get sweetspot image bounds
        input_struct.sweetspot(1)=1;
        x1 = input_struct.sweetspot(1);
        x2 = input_struct.sweetspot(2)-100;
        
        % % HF
        
        % convert complex data to magnitude and phase
        mag_img = abs(input_struct.hf);
        pha_img = angle(input_struct.hf);
        
        % normalize magnitude
        mag_ss = mag_img(:, x1:x2);         % mags over sweet spot
        mag_ss = mag_ss - min(mag_ss(:));
        m = mean2(mag_ss);                  % scaling factor
        mag_img = mag_img - min(mag_ss(:));
        mag_img = mag_img/m;
        % covert back to a+bi format
        out = mag_img .* exp(1j*pha_img);
        % clip everything higher that 16*MEAN
        
        out = min(out, 80);
        % save hf image
        input_struct.hf = out;
    otherwise
        
        disp('Sensor Not Recognized')
        return
        
end
