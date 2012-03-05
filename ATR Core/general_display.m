function general_display(input, contact_list, TB_params, od)
% Display the image with highlights

% TB_params.PLOT_OPTIONS = [1/0 (det), 1/0 (class), 1/0 (gt)]

%% Data

side = input.side;
filename = input.fn;
gt = input.gtimage;
[m_hf, n_hf] = size(input.hf); [m_bb, n_bb] = size(input.bb);

if ~isempty(contact_list)
    fmatch = strcmp({contact_list.fn}, filename) & strcmp({contact_list.side},side);
    in_this_file = contact_list(fmatch);
else
    in_this_file = [];
end

split_box = 0;
if ~isempty(TB_params.PRE_DET_RESULTS)
    [junk, f] = fileparts(input.fn);
    roc_fn = [TB_params.PRE_DET_RESULTS,filesep,'ROC_',f,'_',input.side,'.mat'];
    try
        old = load(roc_fn);
        assert(length(old.classes) == length([in_this_file.class]), 'Incorrect ROC file loaded');
        split_box = 1;
    catch ME
        
    end
end

[detname, var] = get_detname(TB_params);
if strcmpi(var, 'BB') == 1      % using BB detector
    if strcmpi(input.sensor, 'SSAM III') && ~isempty(input.lf1)
        image = abs(input.lf1);
        band_tag = 'LF1';
        [m_lf1, n_lf1] = size(input.lf1);
    else
        image = abs(input.bb);
        band_tag = 'BB';
    end
elseif  ~isempty(input.hf)      % using HF detector, or both bands
    % use HF image if available
    image = abs(input.hf);
    band_tag = 'HF';
elseif ~isempty(input.bb)
    image = abs(input.bb);
    band_tag = 'BB';
else 
    error('No data input to general display function')
end

switch band_tag
    case {'HF','hf'}
        range_resolution = input.hf_cres;
        track_resolution = input.hf_ares;
        y_ratio = 1; x_ratio = 1;
        switch input.sensor
            case {'ONR SSAM','ONR SSAM2','MK 18 mod 2'}
                roix = 130;
                roiy = 100;
            case 'MUSCLE'
                roix = 60;
                roiy = 70;
            case 'EDGETECH'
                roix = 201;
                roiy = 10;
            case 'MARINESONIC'
                roix = 20;
                roiy = 20;
            otherwise
                error('Sensor not recognized')
        end
    case {'BB','bb'}
        range_resolution = input.bb_cres;
        track_resolution = input.bb_ares;
        y_ratio = m_hf/m_bb; x_ratio = n_hf/n_bb;
        switch input.sensor
            case {'ONR SSAM','ONR SSAM2','MK 18 mod 2'}
                roix = round(75/x_ratio);
                roiy = round(50/y_ratio);
            case 'MUSCLE'
                roix = round(60/x_ratio);
                roiy = round(70/y_ratio);
            case 'EDGETECH'
                roix = round(2/x_ratio);
                roiy = round(300/y_ratio);              
            otherwise
                error('Sensor not recognized')
        end
    case {'LF1','lf1'}
        range_resolution = input.lf1_cres;
        track_resolution = input.lf1_ares;
        y_ratio = m_hf/m_lf1; x_ratio = n_hf/n_lf1;
        switch input.sensor
            case 'SSAM III'
                roix = round(75/x_ratio);
                roiy = round(50/y_ratio);  
        end
end

spacerx = 5*range_resolution; spacery = 10*track_resolution;

%% Display Image
[m_track,n_range] = size(image);

range_axis=[0, n_range*range_resolution];
track_axis=[0, m_track*track_resolution];

[img_axes, img_alt] = display_image(image, range_axis, track_axis,...
    [filename,'  ',side,' ',band_tag],100);

%% Prep Vectors
gt_x = []; gt_y = []; dets_x = []; dets_y = []; clss_x = []; clss_y = [];
clss_x_old = []; clss_y_old = [];

if ~isempty(in_this_file)
    dets_x = [in_this_file.x]/x_ratio * range_resolution;
    dets_y = [in_this_file.y]/y_ratio * track_resolution;
    con_inds = [in_this_file.class] >= 1;
    mines = in_this_file(con_inds);
    if ~isempty(mines)
        clss_x = [mines.x]/x_ratio * range_resolution;
        clss_y = [mines.y]/y_ratio * track_resolution;
        classes = [mines.class];
    end
    if split_box == 1
        mines_old = in_this_file(old.classes >= 1);
        if ~isempty(mines_old);
            clss_x_old = [mines_old.x]/x_ratio * range_resolution;
            clss_y_old = [mines_old.y]/y_ratio * track_resolution;
            old_classes = old.classes(old.classes >= 1);
        end
    end
end

if ~isempty(gt)
    gt_x = gt.x/x_ratio * range_resolution;
    gt_y = gt.y/y_ratio * track_resolution;
end

axes(img_axes); lab_colors = {'Black'; 'Black'; 'Black'};

%% Mark Targets
if(TB_params.PLOT_OPTIONS(3) > 0) % GT
    if ~isempty(gt)
        % y is track; x is range
        xsize=fix((roix+15))* range_resolution;
        ysize=fix((roiy+15))* track_resolution;
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
    % y is track; x is range
    xsize=fix(roix)* range_resolution;
    ysize=fix(roiy)* track_resolution;
    for ii = 1:length(dets_x)
        line([dets_x(ii)+xsize dets_x(ii)+xsize],[dets_y(ii)-ysize dets_y(ii)+ysize],'LineWidth',3,'Color','g');
        line([dets_x(ii)-xsize dets_x(ii)-xsize],[dets_y(ii)-ysize dets_y(ii)+ysize],'LineWidth',3,'Color','g');
        line([dets_x(ii)-xsize dets_x(ii)+xsize],[dets_y(ii)-ysize dets_y(ii)-ysize],'LineWidth',3,'Color','g');
        line([dets_x(ii)-xsize dets_x(ii)+xsize],[dets_y(ii)+ysize dets_y(ii)+ysize],'LineWidth',3,'Color','g');
        text(dets_x(ii), dets_y(ii)-ysize-spacery,num2str(ii),'Color','white',...
            'VerticalAlignment','top', 'HorizontalAlignment', 'center',...
            'Clipping', 'on');
    end
    lab_colors{1} = 'Green';
end

if(TB_params.PLOT_OPTIONS(2) > 0) % CLASS
    % y is track; x is range
    xsize=fix(roix)* range_resolution;
    ysize=fix(roiy)* track_resolution;
    if split_box == 1   % comparing to previous results
    for ii = 1:length(clss_x_old)   % left side of box (old)
        line([clss_x_old(ii)-xsize clss_x_old(ii)-xsize],[clss_y_old(ii)-ysize clss_y_old(ii)+ysize],'LineWidth',3,'Color','r');
        line([clss_x_old(ii)-xsize clss_x_old(ii)],[clss_y_old(ii)-ysize clss_y_old(ii)-ysize],'LineWidth',3,'Color','r');
        line([clss_x_old(ii)-xsize clss_x_old(ii)],[clss_y_old(ii)+ysize clss_y_old(ii)+ysize],'LineWidth',3,'Color','r');
        % Technically we want the TB_params from the previous run, but those
        % aren't saved.  This is a decent approximation.
        if TB_params.MULTICLASS == 1
        text(clss_x_old(ii)-xsize-spacerx, clss_y_old(ii), ['C=',num2str(old_classes(ii))],'Color','white',...
            'VerticalAlignment','middle','HorizontalAlignment','right',...
            'Clipping', 'on');
        end
    end
    for ii = 1:length(clss_x)       % right side of box (new)
        line([clss_x(ii)+xsize clss_x(ii)+xsize],[clss_y(ii)-ysize clss_y(ii)+ysize],'LineWidth',3,'Color','r');
        line([clss_x(ii) clss_x(ii)+xsize],[clss_y(ii)-ysize clss_y(ii)-ysize],'LineWidth',3,'Color','r');
        line([clss_x(ii) clss_x(ii)+xsize],[clss_y(ii)+ysize clss_y(ii)+ysize],'LineWidth',3,'Color','r');
        if TB_params.MULTICLASS == 1
        text(clss_x(ii)+xsize+spacerx, clss_y(ii), ['C=',num2str(classes(ii))],'Color','white',...
            'VerticalAlignment','middle','HorizontalAlignment','left',...
            'Clipping', 'on');
        end
    end
    else    % no previous comparison
    for ii = 1:length(clss_x)
        line([clss_x(ii)+xsize clss_x(ii)+xsize],[clss_y(ii)-ysize clss_y(ii)+ysize],'LineWidth',3,'Color','r');
        line([clss_x(ii)-xsize clss_x(ii)-xsize],[clss_y(ii)-ysize clss_y(ii)+ysize],'LineWidth',3,'Color','r');
        line([clss_x(ii)-xsize clss_x(ii)+xsize],[clss_y(ii)-ysize clss_y(ii)-ysize],'LineWidth',3,'Color','r');
        line([clss_x(ii)-xsize clss_x(ii)+xsize],[clss_y(ii)+ysize clss_y(ii)+ysize],'LineWidth',3,'Color','r');
        if TB_params.MULTICLASS == 1
        text(clss_x(ii), clss_y(ii)+ysize+spacery, ['C=',num2str(classes(ii))],'Color','white',...
            'VerticalAlignment','bottom', 'HorizontalAlignment', 'center',...
            'Clipping', 'on');
        end
    end
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