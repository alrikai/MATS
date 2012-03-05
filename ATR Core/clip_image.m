function M = clip_image(M,varargin)
% Suggested values are:
%   clip_image(0.05,0.05,0.6,0.99,0.02,0.95)
% or mimic the original clipping scheme
%   clip_image(data,0.4,0.99,1,1,0.001,0.70)

% Dynamic range compression for sas imagery.  Specificialy for cases where
% gammaclip is not providing acceptable results.
%
% This algorithm stretches the dynamic range of typical bottom returns to
% range between 0 and lowRangeMax.  The highlight dynamic range is also
% stretched to range between upperRangeMin and 1.  The mid-intensity points
% (clipBot to clipTop) dynamic range is compressed.
% M --> data array
if ~isempty(varargin)
    lowRangeMax=varargin{1};% Upper limit of lower range return after adjustment
else
    lowRangeMax = 0.40;
end
if length(varargin)>1
    lowerPercent=varargin{2};% Percent of values to be placed in the lower range
else
    lowerPercent = 0.99;% 99% of values will be in the lower range (i.e. 99% of return is from the bottom, 1% from target)
end;
if length(varargin)>2
    midRangeMax=varargin{3};% Upper limit of mid range after adjustment
else
    midRangeMax = 1;% Default settings use only one partition
end;
if length(varargin)>3
    midRangePercent=varargin{4};% Percent of values to be placed in the mid and lower range (cumulative)
else
    midRangePercent = 1;% Default settings use only one partition
end;
if length(varargin)>4
    lowEndClip=varargin{5};% clipped minimum for intensity
else
    lowEndClip = .001;% Default setting does not clip the shadow
end;
if length(varargin)>5
    highEndClip=varargin{6};% clipped maximum intensity
else
    highEndClip = 0.70;% Default setting does not clip the highlight
end;



M = abs(M);% Convert from imaginary to intensity only values
M = M - min(min(M));% Scale values to range between 0  and 1
M = M / max(max(M));

% Create a histogram of the image intensities.  Rescale later based on
% values corresponding to a particular percent of image pixels being below
% a specified value.
[counts,x] = imhist(M);
sumCounts = cumsum(counts)/sum(counts);

% Max low-range intensity before rescale
clipBot = x(find(sumCounts>lowerPercent,1,'first'));

% Max mid-range intensity before rescale
clipMid = x(find(sumCounts>=midRangePercent,1,'first'));


% % 2-part rescaling scheme:
% M(M >= clipBot) = lowRangeMax + (1 - lowRangeMax) * (M(M >= clipBot) ...
%     - clipBot) / (1 - clipBot);
% 
% M(M < clipBot) = lowRangeMax * M(M < clipBot) / clipBot;

%==========================================================================
% 3-Part rescaling scheme:
%==========================================================================
% First determine if the mid-range is getting larger or smaller.  This will
% determine the order in which the sections are rescaled.

% change in size = width of range (initial) - width of range (final)
midRangeDifference = (clipMid-clipBot) - (midRangeMax - lowRangeMax);

% If the mid-range is being compressed, then compress the mid-range and
% expand the high-range data.
if midRangeDifference > 0
    % Expanding the mid-range and compressing the high range
    % First expand the mid range intensities:
    % Isolate the subset to be compressed:
    %      subset = M(M >= clipBot & M <= clipTop)
    % Scale subset to be between 0 and 1:  subset/subsetWidth
    % Rescale subset to be between 0 and new subset max
    %      subset = newMax*subset/subsetWidth
    % Add max value of lower group (background) to make results continuous:
    %      scaledSubset = scaledSubset + lowRangeMax
    M(M >= clipBot & M <= clipMid) = lowRangeMax + ...
        (midRangeMax - lowRangeMax) * (M(M >= clipBot & M <= clipMid) - clipBot) ...
        /(clipMid - clipBot);

    % Now rescale upper-range with a similar equation:
    M(M > clipMid) = midRangeMax + (1 - midRangeMax) * (M(M > clipMid) ...
        - clipMid) / (1 - clipMid);
elseif midRangeDifference <= 0
    %Scale the upper-range first, then the mid-range.
    M(M > clipMid) = midRangeMax + (1 - midRangeMax) * (M(M > clipMid) ...
        - clipMid) / (1 - clipMid);
    % Scaling mid-range data
    M(M >= clipBot & M <= clipMid) = lowRangeMax + ...
        (midRangeMax - lowRangeMax) * (M(M >= clipBot & M <= clipMid) - clipBot) ...
        /(clipMid - clipBot);
end


% Now expand intensities for the average bottom return to show bottom
% detail.  Same procedure as above example.
M(M < clipBot) = lowRangeMax * M(M < clipBot) / clipBot;

% Now perform the final clip
M(M<lowEndClip) = lowEndClip;
M(M>highEndClip) = highEndClip;
M = (M - lowEndClip)/(highEndClip - lowEndClip);

end