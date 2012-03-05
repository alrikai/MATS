function afn = get_aboutfname(TB_params, varargin)

if isempty(varargin)
    [detname, variant] = get_detname(TB_params);
else
    [detname, variant] = get_detname(TB_params, varargin);
end

if isempty(variant)
    afn = 'about.txt';
else
    afn = ['about_',variant,'.txt'];
end

end