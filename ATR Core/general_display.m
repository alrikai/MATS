function general_display(input, contact_list, TB_params, od)
% Display the image with highlights

% TB_params.PLOT_OPTIONS = [1/0 (det), 1/0 (class), 1/0 (gt)]

%% Data
if  ~isempty(input.hf)
    image = abs(input.hf);
    band_tag = 'HF';
elseif ~isempty(input.bb)
    image = abs(input.bb);
    band_tag = 'BB';
else 
    error('No data input to general display function')
end
range_resolution = input.hf_cres;
track_resolution = input.hf_ares;
side = input.side;
filename = input.fn;
gt = input.gtimage;
switch input.sensor
    case {'ONR SSAM','ONR SSAM2','MK 18 mod 2'}
        roix = 25;
        roiy = 35;
    case 'MUSCLE'
        roix = 15;
        roiy = 70;
    otherwise
        error('Sensor not recognized')
end

%% Display Image
[m_track,n_range] = size(image);

range_axis=[0, n_range*range_resolution];
track_axis=[0, m_track*track_resolution];

[img_axes, img_alt] = display_image(image, range_axis, track_axis,...
    [filename,'  ',side,' ',band_tag],100);

%% Prep Vectors
gt_x = []; gt_y = []; dets_x = []; dets_y = []; clss_x = []; clss_y = [];
if ~isempty(contact_list)
    fmatch = strcmp({contact_list.fn}, filename) & strcmp({contact_list.side},side);
    in_this_file = contact_list(fmatch);
else
    in_this_file = [];
end

if ~isempty(in_this_file)
    dets_x = [in_this_file.x] * range_resolution;
    dets_y = [in_this_file.y] * track_resolution;
    mines = in_this_file([in_this_file.class] == 1);
    if ~isempty(mines)
        clss_x = [mines.x] * range_resolution;
        clss_y = [mines.y] * track_resolution;
    end
end

if ~isempty(gt)
    gt_x = gt.x * range_resolution;
    gt_y = gt.y * track_resolution;
end

axes(img_axes); lab_colors = {'Black'; 'Black'; 'Black'};

%% Mark Targets
if(TB_params.PLOT_OPTIONS(3) > 0) % GT
    if ~isempty(gt)
        % x is track; y is range
        xsize=fix(size(image,1)/(roix+5))* range_resolution;
        ysize=fix(size(image,2)/(roiy+5))* track_resolution;
        for ii = 1:length(gt_x)
            line([gt_x(ii)+xsize gt_x(ii)+xsize],[gt_y(ii)-ysize gt_y(ii)+ysize],'LineWidth',3,'Color','b');
            line([gt_x(ii)-xsize gt_x(ii)-xsize],[gt_y(ii)-ysize gt_y(ii)+ysize],'LineWidth',3,'Color','b');
            line([gt_x(ii)-xsize gt_x(ii)+xsize],[gt_y(ii)-ysize gt_y(ii)-ysize],'LineWidth',3,'Color','b');
            line([gt_x(ii)-xsize gt_x(ii)+xsize],[gt_y(ii)+ysize gt_y(ii)+ysize],'LineWidth',3,'Color','b');
        end
    end
    lab_colors{3} = 'Blue';
end

if(TB_params.PLOT_OPTIONS(1) > 0) % DET
    % x is track; y is range
    xsize=fix(size(image,1)/roix)* range_resolution;
    ysize=fix(size(image,2)/roiy)* track_resolution;
    for ii = 1:length(dets_x)
        line([dets_x(ii)+xsize dets_x(ii)+xsize],[dets_y(ii)-ysize dets_y(ii)+ysize],'LineWidth',3,'Color','g');
        line([dets_x(ii)-xsize dets_x(ii)-xsize],[dets_y(ii)-ysize dets_y(ii)+ysize],'LineWidth',3,'Color','g');
        line([dets_x(ii)-xsize dets_x(ii)+xsize],[dets_y(ii)-ysize dets_y(ii)-ysize],'LineWidth',3,'Color','g');
        line([dets_x(ii)-xsize dets_x(ii)+xsize],[dets_y(ii)+ysize dets_y(ii)+ysize],'LineWidth',3,'Color','g');
        text(dets_x(ii), dets_y(ii)-ysize,num2str(ii),'Color','white');
    end
    lab_colors{1} = 'Green';
end

if(TB_params.PLOT_OPTIONS(2) > 0) % CLASS
    % x is track; y is range
    xsize=fix(size(image,1)/roix)* range_resolution;
    ysize=fix(size(image,2)/roiy)* track_resolution;
    for ii = 1:length(clss_x)
        line([clss_x(ii)+xsize clss_x(ii)+xsize],[clss_y(ii)-ysize clss_y(ii)+ysize],'LineWidth',3,'Color','r');
        line([clss_x(ii)-xsize clss_x(ii)-xsize],[clss_y(ii)-ysize clss_y(ii)+ysize],'LineWidth',3,'Color','r');
        line([clss_x(ii)-xsize clss_x(ii)+xsize],[clss_y(ii)-ysize clss_y(ii)-ysize],'LineWidth',3,'Color','r');
        line([clss_x(ii)-xsize clss_x(ii)+xsize],[clss_y(ii)+ysize clss_y(ii)+ysize],'LineWidth',3,'Color','r');
    end
    lab_colors{2} = 'Red';
end

% Legend
h = get(img_axes,'Parent');
uicontrol(h, 'Style', 'Text', 'String', 'Detections',...
    'ForegroundColor', lab_colors{1}, 'BackgroundColor', 'Black',...
    'Position', [202,2,80,16], 'FontWeight', 'bold');
uicontrol(h, 'Style', 'Text', 'String', 'Classifications',...
    'ForegroundColor', lab_colors{2}, 'BackgroundColor', 'Black',...
    'Position', [292,2,90,16], 'FontWeight', 'bold');
uicontrol(h, 'Style', 'Text', 'String', 'Ground truth',...
    'ForegroundColor', lab_colors{3}, 'BackgroundColor', 'Black',...
    'Position', [392,2,100,16], 'FontWeight', 'bold');
drawnow

% Save image w/ highlights and legend, if desired
if TB_params.SAVE_IMAGE == 1
    saveas(gcf,[od,filesep,input.fn,'_',input.side,'.jpg']);
%     imwrite(img_alt, 'test.jpg', 'jpg');    % for Jesse/Harbor Suite
end

% Continue button
if TB_params.PLOT_PAUSE_ON == 1
    uicontrol(h, 'Style','pushbutton',...
        'String','Press to continue...',...
        'Units','pixels','Position',[2,2,140,18],'Callback',{@btn_clbk});
    go = 0;
    while go == 0
        pause(1)
    end
end

    function btn_clbk(junk,junk2)
        go = 1;
    end
end

function [img_axes, image_data] = display_image(image_data, x_axis, y_axis, filename, fig_num)

color_map = change_cmap;

f = figure(fig_num);
clf
set(fig_num,'Name',filename);

colormap(color_map);

image_data = clip_image(image_data);
image_data = imadjust(image_data,[0.001 0.70],[],1);
%%% test
axis_panel = uipanel(f,'Position',[0,0,1,1],...
    'BackgroundColor','black');
img_axes = axes('Parent',axis_panel);
%%%
imagesc(image_data, 'XData',x_axis,'Ydata',y_axis,'Parent',img_axes);
title(filename,'Interpreter', 'none');
colorbar;
set(gca,'YDir','normal');
set(gcf,'Color','black');
set(gcf,'inverthardcopy','off');
set(gca,'XColor','white','YColor','white');
set(get(gca,'Title'),'Color','white');
xlabel('Range (m)');
ylabel('Along-Track (m)');
axis image;
axis xy;
end

function cm2 = change_cmap
%
% cm2(i, 1:3) = [R, G, B] of ith color in color map
% i = 1, 2, ..., ncolors2

cm1 = load('mstl_colors_ascii.txt', '-ASCII');

ncolors1 = size(cm1, 1);

% Boost or decrease RED
cm_scale = 0.95;

if cm_scale < 0, cm_scale = 0; end
if cm_scale > 2, cm_scale = 2; end

for i=2:ncolors1-1
    if cm_scale <= 1
        % Decrease RED
        cm1(i,1)=cm_scale*cm1(i,1);
    else
        % Boost RED
        cm1(i,1) = cm1(i,1) + (cm_scale - 1)*(1-cm1(i,1));
    end
end

% Boost or decrease GREEN
cm_scale = 1.1;

if cm_scale < 0, cm_scale = 0; end
if cm_scale > 2, cm_scale = 2; end

for i=2:ncolors1-1
    if cm_scale <= 1
        % Decrease GREEN
        cm1(i,2)=cm_scale*cm1(i,2);
    else
        % Boost GREEN
        cm1(i,2) = cm1(i,2) + (cm_scale - 1)*(1-cm1(i,2));
    end
end
%
% interpolation section
%
% interpolation parameters:
%           intensity     color_fraction
% p(1,:) = [  inten_1,     color_frac_1;
% p(2,:) = [  inten_2,     color_frac_2;
%          :
% p(num_nodes, :) = [inten_num_nodes,     color_frac_num_nodes]
%
% WARNING: p(i,1) must be strictly less than p(i+1,1)

p = [0.00 0.00; 1.00 0.25; 1.01 0.25; 1.02 0.25; 8.00 1.00];

num_nodes = size(p,1);
ncolors2 = 256;

intensity = p(1,1) + (0:ncolors2-1)*((p(end,1)-p(1,1))/(ncolors2-1));
intensity(ncolors2) = p(end,1);

cm2 = zeros(ncolors2, 3);

for i2=1:ncolors2
    for j=2:num_nodes
        if intensity(i2) <= p(j,1),
            color_value = p(j-1,2) + (p(j,2) - p(j-1,2))/(p(j,1) - p(j-1,1))*(intensity(i2) - p(j-1,1));
            n1 = max( 1, min( ncolors1, 1.5 + (ncolors1-1)*color_value ) );
            i1 = fix(n1);
            frac_n1 = n1 - i1;
            i1p1 = min(i1 + 1, ncolors1);
            cm2(i2,:) = (1-frac_n1)*cm1(i1,:) + frac_n1*cm1(i1p1,:);
            break
        end
    end
end

end

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