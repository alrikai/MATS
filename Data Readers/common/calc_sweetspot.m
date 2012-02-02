function bounds = calc_sweetspot(input_struct)
% Calculates the 'sweet spot' for which data is good for ATR

% A_px = near range bound
A_m = 1.5*max(input_struct.perfparams.height);
A_px = A_m / input_struct.hf_cres;

% B_px = far range bound
dark_mask = zeros(size(input_struct.hf));
dark_mask(abs(input_struct.hf) < .009) = 1;
dark_colsum = sum(dark_mask,1);
col_list = find(dark_colsum > 100);
B_px = min( col_list( col_list>1000 ) );
if isempty(B_px)    % no long-range black region exists
    B_px = input_struct.hf_cnum;
end

% B_px = .75*input_struct.hf_cnum; % stub

bounds = [round(A_px), round(B_px)-100];

end