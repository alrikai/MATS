function input_struct = normalize_images(input_struct)

switch input_struct.sensor
    case{'SSAM III', 'ONR SSAM3'}
        % get sweetspot image bounds
        x1 = input_struct.sweetspot(1)+200;
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
        SWEETSPOTDATA = zeros(size(mag_img));
        SWEETSPOTDATA(:,x1:x2) = 1;
        out = out.*SWEETSPOTDATA;
        % clip everything higher that 16*MEAN
        
        out = min(out, 30);
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
        SWEETSPOTDATA = zeros(size(mag_img));
        SWEETSPOTDATA(:,x1:x2) = 1;
        out = out.*SWEETSPOTDATA;
        % clip everything higher that 16*MEAN
        out = min(out, 30);
        % save hf image
        input_struct.bb = out;
        
        % % LF1
               
        ratio_range = input_struct.hf_cnum/input_struct.lf1_cnum;
        x1 = x1/ratio_range;
        x2 = x2/ratio_range;
        % convert complex data to magnitude and phase
        mag_img = abs(input_struct.lf1);
        pha_img = angle(input_struct.lf1);
        
        % normalize magnitude
        mag_ss = mag_img(:, x1:x2);         % mags over sweet spot
        mag_ss = mag_ss - min(mag_ss(:));
        m = mean2(mag_ss);                  % scaling factor
        mag_img = mag_img - min(mag_ss(:));
        mag_img = mag_img/m;
        % covert back to a+bi format
        out = mag_img .* exp(1j*pha_img);
        SWEETSPOTDATA = zeros(size(mag_img));
        SWEETSPOTDATA(:,x1:x2) = 1;
        out = out.*SWEETSPOTDATA;
        % clip everything higher that 16*MEAN
        out = min(out, 30);
        % save hf image
        input_struct.lf1 = out;
        
        % input_struct.normalizer = 'nwsc-pcd';
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

	case {'MARINESONIC'} % use gerry sfbf normalizer
		image_data = input_struct.hf;
		[image_smooth, smooth_error] = mex_normalizer_SBR(image_data', 100*input_struct.hf_cres, 100*input_struct.hf_ares, ...
			0, input_struct.perfparams.depth, 0);
		if smooth_error ~= 0, smooth_error, end
		input_struct.hf=image_smooth';
    case {'EDGETECH'}
        meancol = mean(input_struct.hf,1);
        meancol = repmat(meancol,size(input_struct.hf,1),1);
        out = double(input_struct.hf./meancol);
        out = min(out,80);
        input_struct.hf = out;
    otherwise
        
        disp('Sensor Not Recognized for Normalization')
        return
        
end
