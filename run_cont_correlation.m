function contacts = run_cont_correlation(contacts, varargin)

if ~isempty(varargin)
    temp = varargin{1};
    if isscalar(temp) && isreal(temp) 
        if temp == 1
            cc_alg = 'Cobb';
        elseif temp == 2
            cc_alg = 'Metron';
        end
    end
else
    cc_alg = 'Cobb';
end

cc_root = [fileparts(mfilename('fullpath')),filesep,...
    'Contact Correlation',filesep,cc_alg];
if ~isdeployed
    cc_path = genpath(cc_root);
    addpath(cc_path);
end

if strcmp(cc_alg, 'Cobb')
    contacts = cor_Cobb(contacts);
elseif strcmp(cc_alg, 'Metron')
    contacts = cor_Metron(contacts);
end
if ~isdeployed
    rmpath(cc_path);
end

end