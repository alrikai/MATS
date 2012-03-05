function dln = get_detlistname(TB_params, varargin)

if isempty(varargin)
    [detname, variant] = get_detname(TB_params);
else
    [detname, variant] = get_detname(TB_params, varargin);
end

if isempty(variant)
    dln = detname(5:end);
else
    dln = [detname(5:end),' (',variant,')'];
end

end