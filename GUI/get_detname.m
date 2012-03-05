function [detname, variant] = get_detname(TB_params, varargin)

if ~isempty(varargin) && isfloat(varargin{1}{1})
    index = varargin{1}{1};
else
    index = TB_params.DETECTOR;
end

str = func2str(TB_params.DET_HANDLES{index});
index = regexp(str,'(HF|BB|hf|bb)$');
if isempty(index)   % normal case
    detname = str;
    variant = '';
else
    detname = str(1:(index(end)-2)); % assumes one char buffer
    variant = str(index(end):end);
end

end
    