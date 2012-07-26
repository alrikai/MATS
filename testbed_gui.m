function testbed_gui(varargin)
% GUI for the ATR Testbed
%
% This GUI serves as a front end to the ATR testbed, facilitating its
% configuration and execution.
%
% Derek Kolacinski, NSWC PC (derek.kolacinski@navy.mil)
% Last update: 29 Feb 2012

% This GUI has been modularized so that it is easy to add another item to
% the GUI if necessary.  To add:
%
% 1) Increment value of ???_numitems.
% 2) Add a call to the appropriate subroutine to make item.
% 3) Restart the GUI.  Everything else should take care of itself.

close all; clearvars -except varargin; tic;

gui_vsn = '1.1.0'; gui_bdate = '29 Feb 2012';

% Valid file formats (listed in drop down menu)
file_formats = {'Old .mat (Bravo)', 'Mymat', 'Scrub .mat', 'NSWC .mat',...
    'HDF5', 'NURC .mat (MUSCLE)','CSDT', 'POND', 'PC SWAT Imagery .mat',...
    'MATS input struct','MSTL .mst'};
% Valid sensor formats (listed in drop down menu)
sensor_formats = {'ONR SSAM', 'ONR SSAM2', 'SSAM III', 'MUSCLE', 'EDGETECH', 'MK 18 mod 2', 'MARINESONIC'};

infilelist = {};

% src_dir = '';               % directory of source images
% out_dir = '';               % directory for output files to be stored
gt_file = '';               % file location of the groundtruth file
sens_init = 1;
sensor = sensor_formats{sens_init};
temp = '';

% Spacing parameters
xspace = 30; yspace = 30;   % Standard spacing quantities

inbuff = 6;                 % space btwn two configuration items
outbuff = 12;               % space btwn configuration item and edge
topbuff = 9;                % extra space for subpanel title

indent_w = 20;              % indention width for dependent components
                            % (e.g., detector module drop-down menu)
                            
scroll_px = 1;              % pixel spacer

% Item dimensions
check_x = 16; check_y = 16; % size of checkbox
button_y = 18;              % height of buttons

% Item subpanel dimensions
param_subp_h = 22;          % height of item in param subpanel
param_numitems = 7;         % # of items in param subpanel
atr_subp_h = 22;            % height of item in atr subpanel
atr_numitems = 9;           % # of items in atr subpanel
io_subp_h = 22;             % height of item in I/O subpanel
io_numitems = 8;            % # of items in I/O subpanel
plot_subp_h = 22;           % height of items in plot options subpanel
plot_numitems = 4;          % # of items in plot options subpanel

% Panel dimensions - heights
parampanel_h = param_numitems*param_subp_h + (param_numitems-1)*inbuff ...
    + 2*outbuff + topbuff;  % height of param panel
atrselpanel_h = atr_numitems*atr_subp_h + (atr_numitems-1)*inbuff ...
    + 2*outbuff + topbuff;  % height of ATR sel. panel
iopanel_h = io_numitems*io_subp_h + (io_numitems-1)*inbuff ...
    + 2*outbuff + topbuff;  % height of I/O panel
plotpanel_h = plot_numitems*plot_subp_h + (plot_numitems-1)*inbuff ...
    + 2*outbuff + topbuff;  % height of plot options panel
sbarpanel_h = 20;           % height of status bar panel

% Super panel + scroll bar dimensions
% (Note: super_w/h no longer refer to a physical superpanel, but still
% indicate what the maximum extent of the GUI would be if given a large
% enough screen.) 
sb_w = 20;
super_w = 450;
super_h = 2*outbuff + plotpanel_h + parampanel_h + atrselpanel_h + ...
    iopanel_h + button_y + 5*inbuff + sbarpanel_h;
win_w = super_w + sb_w;
screen_h = get(0, 'ScreenSize');
% screen_h = [1,1,800,600]; % Uncomment to test small screen handling
if super_h < screen_h(4) - 100 % entire GUI will fit on the screen
    win_h = super_h;
else
    win_h = 780;
end
sb_h = win_h;
win_init = [win_w, win_h];

% Panel dimensions - widths
parampanel_w = super_w-2*outbuff;
atrselpanel_w = super_w-2*outbuff;
iopanel_w = super_w-2*outbuff;
plotpanel_w = super_w-2*outbuff;
sbarpanel_w = super_w-2*outbuff;

% Configuration structure (overrides configuration present in %%%%%%%%%%%%
%   atr_testbed_altfb) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tbr = fileparts(mfilename('fullpath'));
disp(['tbr = ',tbr]);
disp(['pwd = ',pwd]);

% Set directory to testbed root directory.
if ~isdeployed %%%
    cd(tbr);
    addpath(genpath([tbr,filesep,'GUI']));
end

% Module data (displayed in ATR selection panel)
% Detectors 
[det_list, hdet] = import_modules(tbr, 'det');
% Feature generators
[feat_list, hfeat] = import_modules(tbr, 'feat');
% Classifiers
[class_list, hcls] = import_modules(tbr, 'cls');
% Contact correlation algorithms
[corr_list, hcor] = import_modules(tbr, 'cor');
% Performance estimation algorithms
[perf_list, hperf] = import_modules(tbr, 'perf');

if ~isempty(varargin)
    TB_params = varargin{1};
else
% Initialize Testbed parameters
fb_fname = 'feedback.txt';
oa_fname = 'oparchive.txt';
lb_fname = 'bkuplock.txt';
ub_fname = 'bkupedit.txt';
TB_params = struct('TB_HEAVY_TEXT', 0,...
    'DEBUG_MODE', 0,...
    'FLAG_MSGS_ON', 0,...
    'DETECTOR', find( cellfun(@(a) (strcmpi(a,'Test')), det_list) ),...
    'CLASSIFIER', find( cellfun(@(a) (strcmpi(a,'Test')), class_list) ),...
    'PERFORMANCE',find(cellfun(@(a) (strcmpi(a,'Test')), perf_list) ),...
    'DET_HANDLES', {hdet},...
    'CLS_HANDLES', {hcls},...
    'PERF_HANDLES', {hperf},...
    'TB_ROOT', tbr,...
    'SKIP_DETECTOR', 0,...
    'INCR_DETECTOR', 0,...
    'PRE_DET_RESULTS','',...
    'SKIP_PERF_EST', 1,...
    'SKIP_FEEDBACK', 2,...
    'ARCH_FEEDBACK', 0,...
    'TB_FEEDBACK_ON', 1,...
    'OPCONF_MODE', 0,...
    'FEEDBACK_PATH', [tbr,filesep,fb_fname],...
    'OPARCHIVE_PATH', [tbr,filesep,oa_fname],...
    'L_BKUP_PATH', [tbr,filesep,lb_fname],...
    'U_BKUP_PATH', [tbr,filesep,ub_fname],...
    'MAN_ATR_SEL', 0,...
    'CONTCORR_ON', 0,...
    'CONTCORR', find( cellfun(@(a) (strcmpi(a,'Test')), corr_list) ),...
    'CC_HANDLES', {hcor},...
    'DATA_FORMAT', 1,...
    'DATA_RANGE', [1, 1],...
    'PLOTS_ON', 1,...
    'PLOT_OPTIONS', [1, 1, 1],...
    'PLOT_PAUSE_ON', 0,...
    'SAVE_IMAGE', 0,...
    'NSAM_MODE_ON', 0,...
    'FEATURES', find( cellfun(@(a) (strcmpi(a,'No_extra')), feat_list) ),...
    'FEAT_HANDLES',{hfeat},...
    'INV_IMG_ON', 0,...
    'INV_IMG_MODES', {{}},...
    'BG_SNIPPET_ON', 0,...
    'BURIED_MODE', 0,...
    'MULTICLASS', 0,...
    'SRC_DIR','',...
    'OUT_DIR','',...
    'ECD_DIR','',...
    'TEMP_DIR','',...
    'GT_FORMAT', 1);
end

% Classifier data files  (displayed in ATR selection panel)
[TB_params.CDATA_FILES, TB_params.CLASS_DATA] = ...
    import_classdata(TB_params.CLS_HANDLES{TB_params.CLASSIFIER}, TB_params.TB_ROOT);
% Initial description data for detectors
[det_desc_params, TB_params] = update_all_det_desc_params(TB_params, det_list);
% Initial description data for classifiers
[feat_desc_params, TB_params] = update_all_feat_desc_params(TB_params, feat_list);
% Initial description data for classifiers
[cls_desc_params, TB_params] = update_all_cls_desc_params(TB_params, class_list);

if TB_params.TB_HEAVY_TEXT == 1
    fprintf(1,'** Available Modules:\n  Detectors:\n');
    disp(det_list);
    disp('  Classifiers');
    disp(class_list);
    disp('  Contact Correlation');
    disp(corr_list);
end

% GUI frame
f = figure('Visible', 'on', 'Position', [100,160,win_init], 'Tag', 'Static');
if ismac
    set(0,'DefaultUIControlFontSize',12);
    set(0,'DefaultUIPanelFontSize',12);
end

% Background panel - show static background (currently has no visible effect) 
hbground = uipanel('Units', 'pixels','Position', [0,0,win_w,super_h]);

% Scroll panel - All active GUI components are positioned in relation to
% this pixel, which can slide up and down as the user scrolls
hscrpanel = uipanel('Units', 'pixels',...
    'Position', [0,win_h-super_h,scroll_px,scroll_px], 'Clipping', 'off');

% I/O Data (directories, file format, groundtruth file) %%%%%%%%%%%%%%%%%%
hiopanel = uipanel('Units', 'pixels', 'Title', 'I/O Data',...
    'Position', [outbuff, sbarpanel_h+outbuff+button_y+5*inbuff+parampanel_h+atrselpanel_h+plotpanel_h, iopanel_w, iopanel_h],...
    'BackgroundColor', 'white', 'Parent', hscrpanel);
subp_size = [super_w-4*outbuff, io_subp_h];
base_pos = [outbuff, iopanel_h-topbuff-outbuff-subp_size(2), subp_size];
mod_pos = [0, subp_size(2)+inbuff, 0, 0];
% Source directory display field
[junk,hsrcstr] = config_text_panel(hiopanel, base_pos,...
    '*Source directory:', {@inputdir_clbk}, 'io preproc'); %#ok<*ASGLU>
% - File format dropdown menu
[junk,hdropformats] = config_popup_panel(hiopanel, 'DATA_FORMAT',...
        base_pos-mod_pos, 80, 'File format:', file_formats, 0, 1,...
        indent_w, 'io preproc');
% - Sensor formats dropdown menu
[junk,hsensformats] = config_popup_panel_alt(hiopanel, base_pos-2*mod_pos,...
    indent_w, 'Sensor:', sensor_formats, sens_init, {@sensor_clbk}, 'io preproc');
% - File selection dropdown menu
[junk,hfilesel] = config_popup_panel_alt(hiopanel, base_pos-3*mod_pos,...
    indent_w, 'Use file:', {'Use index range...'}, 1, {@range_init}, 'io preproc');
% - + File index range entry fields
[junk,hfrng1, hfrng2] = config_range_panel(hiopanel, base_pos-4*mod_pos,...
    2*indent_w, 'io preproc range');
% Ground truth display field
[junk,hgtstr] = config_text_panel(hiopanel, base_pos - 5*mod_pos,...
    'Groundtruth filename:', {@gtfile_clbk}, 'io');
% - Ground truth format
gt_fmt_strs = {'Native format'; 'Lat/long list'};
[junk,hgtfmt] = config_popup_panel(hiopanel, 'GT_FORMAT',...
    base_pos - 6*mod_pos, 80, 'Format:', gt_fmt_strs, 0, 1, indent_w, 'io'); 
% Output directory display field
[junk,houtstr] = config_text_panel(hiopanel, base_pos - 7*mod_pos,...
    '*Output directory:', {@outputdir_clbk}, 'io');

% Detector/Classifier Selection %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hatrselpanel = uipanel('Units', 'pixels', 'Title', 'ATR Modules',...
    'Position', [outbuff, sbarpanel_h+outbuff+button_y+4*inbuff+parampanel_h+plotpanel_h, atrselpanel_w, atrselpanel_h],...
    'BackgroundColor', 'white', 'Parent', hscrpanel);
subp_size = [super_w-4*outbuff, atr_subp_h]; % size of subpanel
base_pos = [outbuff, atrselpanel_h-topbuff-outbuff-subp_size(2), subp_size];
mod_pos = [0, subp_size(2)+inbuff, 0, 0];
% Manual ATR checkbox
[junk,hboxmansel] = config_chkbox_panel(hatrselpanel, 'MAN_ATR_SEL',...
    base_pos, 'Manual detector/classifier selection', 0, 'atrsel preproc_on');
% - Detector module dropdown menu
[junk,hpopdet] = config_popup_panel(hatrselpanel, 'DETECTOR',...
    base_pos - mod_pos, 80, 'Detector:', det_list, 0,...
    TB_params.DETECTOR, indent_w, 'atrsel MAN_ATR_SEL_sub det');
% - Feature module dropdown menu
[junk,hpopfeat] = config_popup_panel(hatrselpanel, 'FEATURES',...
    base_pos - 2*mod_pos, 80, 'Features:', feat_list, 0,...
    TB_params.FEATURES, indent_w, 'atrsel MAN_ATR_SEL_sub');
% - Classifier module dropdown menu
[junk,hpopclass] = config_popup_panel(hatrselpanel, 'CLASSIFIER',...
    base_pos - 3*mod_pos, 80, 'Classifier:', class_list, 0,...
    TB_params.CLASSIFIER, indent_w, 'atrsel MAN_ATR_SEL_sub');
% - + Classifier data file dropdown menu
[junk,hpopcdata] = config_popup_panel(hatrselpanel, 'CLASS_DATA',...
    base_pos - 4*mod_pos, 120, 'Class. Data File:', TB_params.CDATA_FILES, 0,...
    TB_params.CLASS_DATA, 2*indent_w, 'atrsel MAN_ATR_SEL_sub');
% Skip performance estimation checkbox
[junk,hboxskipperf] = config_chkbox_panel(hatrselpanel, 'SKIP_PERF_EST', ...
    base_pos - 5*mod_pos, 'Skip performance estimation', 0, 'atrsel');
% - Performance estimation module dropdown menu
[junk, hpopperfesti] = config_popup_panel(hatrselpanel, 'PERFORMANCE',...
    base_pos - 6*mod_pos, 140, 'Performance Model:', perf_list, 0,...
    TB_params.PERFORMANCE, indent_w, 'atrsel SKIP_PERF_EST_sub');
% Contact correlation checkbox
[junk,hboxccorron] = config_chkbox_panel(hatrselpanel, 'CONTCORR_ON',...
    base_pos - 7*mod_pos, 'Use contact correlation', 0, '');
% - Contact correlation module dropdown menu
[junk,hpopccorr] = config_popup_panel(hatrselpanel, 'CONTCORR',...
    base_pos - 8*mod_pos, 80, 'Algorithm:', corr_list, 0,...
    TB_params.CONTCORR, indent_w, 'CONTCORR_ON_sub');

% Testbed input parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hparampanel = uipanel('Units', 'pixels',...
    'Title','Testbed Input Parameters',...
    'Position', [outbuff, sbarpanel_h+outbuff+button_y+3*inbuff+plotpanel_h, parampanel_w, parampanel_h],...
    'BackgroundColor', 'white', 'Parent', hscrpanel);
subp_size = [super_w-4*outbuff, param_subp_h]; % size of subpanel
base_pos = [outbuff, parampanel_h-topbuff-outbuff-subp_size(2), subp_size];
mod_pos = [0, subp_size(2)+inbuff, 0, 0];
% Detailed message checkbox
[junk,hboxhvytxt]  = config_chkbox_panel(hparampanel, 'TB_HEAVY_TEXT', ...
    base_pos, 'Show detailed text messages', 0, 'param');
% Save input structure checkbox
[junk,hboxdebug]   = config_chkbox_panel(hparampanel, 'DEBUG_MODE', ...
    base_pos - mod_pos, 'Save input structure with results', 0, 'param');
% Use preprocessed results checkbox
[junk,hboxskipdet]	= config_chkbox_panel(hparampanel, 'SKIP_DETECTOR', ...
    base_pos - 2*mod_pos, 'Use preprocessed detector results', 0, 'param');
% Enable feedback checkbox
[junk,hboxfeedon]  = config_chkbox_panel(hparampanel, 'TB_FEEDBACK_ON', ...
    base_pos - 3*mod_pos, 'Enable feedback architecture', 0, 'param');
% - Feedback mode dropdown menu
[junk,hpopskipfeed]= config_popup_panel(hparampanel, 'SKIP_FEEDBACK',...
    base_pos - 4*mod_pos, 105, 'Feedback Mode:',...
    {'Use feedback GUI (series)', 'Simulate operator feedback w/ archive',...
      'Skip feedback completely', 'Simulate operator feedback w/ GT data',...
      'Use SIG GUI (parallel) [STUB]'}, 1, 3, indent_w, 'param TB_FEEDBACK_ON_sub');
% - Operator mode dropdown menu 
[junk,hpopopconf]  = config_popup_panel(hparampanel, 'OPCONF_MODE',...
    base_pos - 5*mod_pos, 105, 'Operator Mode:',...
    {'Every contact is confirmed/rejected by operator',...
      'Interpret no operator comment as implicit agreement',...
      'Use only explicit operator calls (don''t assume agreement)'}, 1, 1, indent_w, 'param TB_FEEDBACK_ON_sub');
% Operator archive checkbox
[junk,hboxarchfeed] = config_chkbox_panel(hparampanel, 'ARCH_FEEDBACK', ...
    base_pos - 6*mod_pos, 'Archive operator feedback', 0, 'param');

if TB_params.SKIP_DETECTOR == 1     % preproc mode
    tag_hide_show('preproc', 'off');% hide irrelevant I/O fields
    TB_params.MAN_ATR_SEL = 1;      % trigger manual ATR component selection
    set(hboxmansel, 'Value', TB_params.MAN_ATR_SEL); % data and GUI box
    tag_hide_show('preproc_on', 'on'); 
    tag_hide_show('det', 'off');    % hide detector option
else
    if TB_params.MAN_ATR_SEL == 1
        tag_hide_show('det', 'on');
    end
end

% Plot options %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hplotpanel = uipanel('Units', 'pixels',...
    'Title', 'Plot Options',...
    'Position', [outbuff, sbarpanel_h+outbuff+button_y+2*inbuff, plotpanel_w, plotpanel_h],...
    'BackgroundColor', 'white', 'Parent', hscrpanel);
subp_size = [super_w-4*outbuff, plot_subp_h]; % size of subpanel
base_pos = [outbuff, plotpanel_h-topbuff-outbuff-subp_size(2), subp_size];
mod_pos = [0, subp_size(2)+inbuff, 0, 0];
% Enable plots checkbox
[junk,hploton] = config_chkbox_panel(hplotpanel, 'PLOTS_ON', ...
    base_pos, 'Show images with highlights:', 0, 'plot');
% - Image highlight checkboxes 
[junk,hplotvec]= config_plotopts(hplotpanel, 'PLOT_OPTIONS', ...
    base_pos - mod_pos, {'Detections';'Classifications';'Groundtruth'},...
    20, 'plot PLOTS_ON_sub');
% - Pause checkbox
[junk,hplotpause] = config_chkbox_panel(hplotpanel, 'PLOT_PAUSE_ON',...
    base_pos - 2*mod_pos, 'Pause when showing images', indent_w,...
    'plot PLOTS_ON_sub');
% - Save image checkbox
[junk,himgsave] = config_chkbox_panel(hplotpanel, 'SAVE_IMAGE',...
   base_pos - 3*mod_pos, 'Save .jpg image', indent_w,...
    'plot PLOTS_ON_sub');

fix_item_visibility(TB_params);

% Button to start the testbed simulation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hgobutton = uicontrol('Style', 'pushbutton', 'String', 'Start testbed run',...
    'Position',[outbuff, sbarpanel_h+outbuff+inbuff, super_w-2*outbuff, 18],...
    'Callback', {@go_clbk}, 'Enable', 'off', 'Parent', hscrpanel);

% Status bar + message %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hsbarpanel = uipanel('Units', 'pixels',...
    'Position', [outbuff, outbuff, sbarpanel_w, sbarpanel_h],...
    'BorderWidth', 0, 'Parent', hscrpanel);
hprogaxis = axes('Units','pixels',...
    'Position',[2,2,150,sbarpanel_h-2],...
    'XLim',[0 1],'YLim',[0 1],...
    'XTick',[],'YTick',[],...
    'Color','white',...
    'XColor','white','YColor','white', 'Parent', hsbarpanel);
hpatch = patch([0 0 0 0], [0 1 1 0], 'b', 'Parent',hprogaxis, 'EdgeColor', 'none');
hproglabel = uicontrol('Style', 'text', 'String', 'Choose I/O directories above...',...
    'Parent', hsbarpanel, 'Position', [155,2,sbarpanel_w-150-inbuff,16],...
    'HorizontalAlignment', 'left');
sbar.hpatch = hpatch;  sbar.hlabel = hproglabel;

% GUI Menu %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Configuration
hmenu_config = uimenu('Label','Configuration');
uimenu(hmenu_config, 'Label', 'Load Configuration...', 'Callback', {@loadconfig_clbk});
uimenu(hmenu_config, 'Label', 'Save Configuration...', 'Callback', {@saveconfig_clbk});
uimenu(hmenu_config, 'Label', 'Retrain Classifier...', 'Separator', 'on',...
     'Callback', {@train_clbk});
uimenu(hmenu_config, 'Label', 'Use Built-In Config.', 'Separator', 'on',...
    'Checked', 'off', 'Callback', {@nsammode_clbk});
uimenu(hmenu_config, 'Label', 'Buried mode', 'Separator', 'off',...
    'Checked', 'off', 'Callback', {@buried_clbk});
% Analysis
hmenu_analysis = uimenu('Label', 'Analysis');
uimenu(hmenu_analysis, 'Label', 'Ground Truth Analysis...', 'Callback', {@gt_analysis_clbk});
hmenu_roc = uimenu(hmenu_analysis, 'Label', 'ROC Curve Analysis');
uimenu(hmenu_roc, 'Label', 'Generate ROC Curve...', 'Callback', {@roc_clbk});
uimenu(hmenu_roc, 'Label', 'ROC Compare...', 'Callback', {@roc_cmpr});
uimenu(hmenu_analysis, 'Label', 'Generate Confusion Matrix...', 'Callback', {@confusion_clbk});
hmenu_sort = uimenu(hmenu_analysis, 'Label', 'Print Sorted Contact List');
uimenu(hmenu_sort, 'Label', 'Show pixel coordinates...', 'Callback', {@sort_clist_clbk});
uimenu(hmenu_sort, 'Label', 'Show lat/longs...', 'Callback', {@sort_clist_clbk_ll});
% Tools
hmenu_tools = uimenu('Label','Tools');
uimenu(hmenu_tools, 'Label', 'Convert lat/long GT to pixel GT','Callback',{@gt_conv_clbk});
% Help
hmenu_help = uimenu('Label', 'Help');
uimenu(hmenu_help, 'Label', 'MATS Documentation', 'Callback', {@help_clbk});
uimenu(hmenu_help, 'Label', 'About MATS', 'Callback', {@about_clbk});



% Scroll bar
knob_size = win_h/(super_h - win_h);
hscroll = uicontrol('Style', 'slider', 'Position', [super_w, 1, sb_w, sb_h],...
    'Callback', {@scroll_clbk}, 'SliderStep', [.1 knob_size]);
set(hscroll, 'Value', get(hscroll, 'Max')); % init to top position

% Title and display
set(f, 'Name', 'NSWC-PC MATS GUI', 'NumberTitle', 'off', 'Visible', 'on',...
    'MenuBar', 'none');

% GUI Building Subroutines %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Makes subpanel with a static text field, a dynamic text field, and a
% button that prompts the user to choose a file/directory whose value will
% be shown in the dynamic text field
function [subpanel, htext, hbutton] = config_text_panel(parent, position,...
        string, button_clbk, tag)
text_w = 140; button_w = 55;
subpanel = uipanel('Units', 'pixels', 'Parent', parent,...
    'Position', position, 'BorderType', 'none');
uicontrol('Style', 'text', 'String', string,...
    'HorizontalAlignment', 'left', 'Parent', subpanel,...
    'Position', [2, 4, text_w, 16], 'Tag', tag);
htext = uicontrol('Style', 'text', 'String', '',...
    'HorizontalAlignment', 'left', 'Parent', subpanel,...
    'Position', [2+inbuff+text_w, 4, position(3)-2*inbuff-text_w-button_w, 16],...
    'Tag', tag);
hbutton = uicontrol('Style', 'pushbutton',...
    'String', 'Choose', 'Parent', subpanel,...
    'Position',[position(3)-2-button_w,3,button_w,18], 'Callback', button_clbk,...
    'Tag', tag);
end

% Makes a subpanel with a static text field and a drop-drown menu
function [subpanel, pop] = config_popup_panel(parent, fieldname,...
        position, text_w, text_string, pop_strings, offset, initval,...
        indent, tag)
subpanel = uipanel('Units', 'pixels', 'Parent', parent,...
    'Position', position, 'BorderType', 'none');
uicontrol('Style', 'text', 'String', text_string,...
    'HorizontalAlignment', 'left', 'Parent', subpanel,...
    'Position', [indent+2, 4, text_w, 16], 'Tag', tag);
pop = uicontrol('Style', 'popupmenu', 'String', pop_strings,...  
    'Position', [indent+1+inbuff+text_w, 5, position(3)-indent-inbuff-text_w, position(4)-4],...
    'Callback', {@config_popup_clbk, offset}, 'Tag', tag,...
    'UserData', fieldname, 'Parent', subpanel, 'Value', initval);
end

function [subpanel, pop]  = config_popup_panel_alt(parent, position,...
        indent, text_string, pop_strings, initval, clbk, tag)
text_w = 80;
subpanel = uipanel('Units', 'pixels', 'Parent', parent,...
    'Position', position, 'BorderType', 'none');
uicontrol('Style', 'text', 'String', text_string,...
    'HorizontalAlignment', 'left', 'Parent', subpanel,...
    'Position', [indent+2, 4, text_w, 16], 'Tag', tag);
pop = uicontrol('Style', 'popupmenu', 'String', pop_strings,... 
    'Position', [indent+1+inbuff+text_w, 5, position(3)-indent-inbuff-text_w, position(4)-4],...
    'Callback', clbk, 'Parent', subpanel, 'Value', initval, 'Tag', tag);
end

% Makes a subpanel with 3 checkboxes and labels for the plot options
function [subpanel, hvec] = config_plotopts(parent, fieldname,...
        position, strings, indent, tag)
lab_w = [80, 100, 80];
subpanel = uipanel('Units', 'pixels', 'Parent', parent,...
    'Position', position, 'BorderType', 'none');
hvec(1) = uicontrol('Style', 'checkbox',... 
    'Position', [indent + 2, 4, check_x, check_y],...
    'Callback', {@plotopts_clbk, 1}, 'Tag', tag,...
    'UserData', fieldname, 'Parent', subpanel);
uicontrol('Style', 'text', 'String', strings{1}, 'Tag', tag,...
    'HorizontalAlignment', 'left', 'Parent', subpanel,...
    'Position', [indent + 2 + xspace, 4, lab_w(1), 16]);
hvec(2) = uicontrol('Style', 'checkbox',... 
    'Position', [indent + 2*2 + xspace + lab_w(1), 4, check_x, check_y],...
    'Callback', {@plotopts_clbk, 2}, 'Tag', tag,...
    'UserData', fieldname, 'Parent', subpanel);
uicontrol('Style', 'text', 'String', strings{2}, 'Tag', tag,...
    'HorizontalAlignment', 'left', 'Parent', subpanel,...
    'Position', [indent + 2*2 + 2*xspace + lab_w(1), 4, lab_w(2), 16]);
hvec(3) = uicontrol('Style', 'checkbox',... 
    'Position', [indent + 3*2 + 2*xspace + lab_w(1) + lab_w(2), 4, check_x, check_y],...
    'Callback', {@plotopts_clbk, 3}, 'Tag', tag,...
    'UserData', fieldname, 'Parent', subpanel);
uicontrol('Style', 'text', 'String', strings{3}, 'Tag', tag,...
    'HorizontalAlignment', 'left', 'Parent', subpanel,...
    'Position', [indent + 3*2 + 3*xspace + lab_w(1) + lab_w(2), 4, lab_w(3), 16]);
for q = 1:3
    temp = TB_params.(fieldname)(q);
    if temp == 1
        set(hvec(q), 'Value', get(hvec(q), 'Max'));
    elseif temp == 0
        set(hvec(q), 'Value', get(hvec(q), 'Min'));
    end
end
end

% Makes a subpanel with a check box and a static text field
function [subpanel, box] = config_chkbox_panel(parent, fieldname,...
        position, string, indent, tag)
temp = TB_params.(fieldname);
subpanel = uipanel('Units', 'pixels', 'Parent', parent,...
    'Position', position, 'BorderType', 'none');
box = uicontrol('Style', 'checkbox',... 
    'Position', [indent+2, 4, check_x, check_y],...
    'Callback', {@config_chkbox_clbk},...
    'UserData', fieldname, 'Parent', subpanel, 'Tag', tag);
if temp == 1
    set(box, 'Value', get(box, 'Max'));
elseif temp == 0
    set(box, 'Value', get(box, 'Min'));
end
uicontrol('Style', 'text', 'String', string, 'Tag', tag,...
    'HorizontalAlignment', 'left', 'Parent', subpanel,...
    'Position', [2+indent+xspace, 4, position(3)-(2+indent+xspace)-4, 16]);
end

% Makes a subpanel with 2 text boxes
function [subpanel, hf1, hf2] = config_range_panel(parent, position,...
        indent, tag)
w1 = 80; w2 = 50; w3 = 70; w4 = 50;
subpanel = uipanel('Units', 'pixels', 'Parent', parent,...
    'Position', position, 'BorderType', 'none');
uicontrol('Style', 'text', 'String', 'Start index:', 'Parent', subpanel,...
    'HorizontalAlignment', 'left',...
    'Position', [2+indent, 4, w1, 16], 'Tag', tag);
hf1 = uicontrol('Style', 'edit', 'Position', [2*2+indent+w1, 2, w2, 20],...
    'Callback', {@start_index_clbk}, 'Parent', subpanel, 'Tag', tag);
uicontrol('Style', 'text', 'String', 'End index:', 'Parent', subpanel,...
    'HorizontalAlignment', 'left',...
    'Position', [3*2+indent+w1+w2+20, 4, w3, 16], 'Tag', tag);
hf2 = uicontrol('Style', 'edit', 'Position', [4*2+indent+w1+w2+w3+20, 2, w4, 20],...
    'Callback', {@end_index_clbk}, 'Parent', subpanel, 'Tag', tag);
end

%%%%%%%%%%%%%%%%%%%%%%%%% CALLBACK FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Callback for scroll bar
function scroll_clbk(src,junk) %#ok<*INUSD>
y_offset = get(src, 'Value') * (super_h - win_h);
set(hscrpanel, 'Position', [0, 0, [scroll_px,scroll_px]] - [0,y_offset,0,0]);
end

% Initialize the fields for the start and end indices
function range_init(hobj,junk)
% When a file is selected from the file selection dropdown menu, set
% initial file range indices.
val = get(hobj,'Value');
if val == 1 % range selection mode; initialize to all files
    set(hfrng1, 'String', num2str(1));
    set(hfrng2, 'String', num2str(length(infilelist)));
    TB_params.DATA_RANGE = [1, length(infilelist)];
    tag_hide_show('range', 'on');
else        % individual file mode
    tag_hide_show('range', 'off');
    set(hfrng1, 'String', num2str(val-1));
    set(hfrng2, 'String', num2str(val-1));
    TB_params.DATA_RANGE = [val-1, val-1]; % -1 to account for range sel. string
end
end

% Update the start index
function start_index_clbk(hobj, junk)
num = str2double(get(hobj, 'String'));
if ~isnan(num) % is a number
    if num < 1
        % too small, use 1 instead and change displayed value to show this
        TB_params.DATA_RANGE(1) = 1;
        set(hobj, 'String', '1');
  else
        TB_params.DATA_RANGE(1) = num;
    end
end
end

% Update the end index
function end_index_clbk(hobj,junk)
num = str2double(get(hobj, 'String'));
if ~isnan(num) % is a number
    if num > length(infilelist)
        % too big, use max instead and change displayed value to show this
        TB_params.DATA_RANGE(2) = length(infilelist);
        set(hobj, 'String', length(infilelist));
    else
        TB_params.DATA_RANGE(2) = num;
    end
end
end

% Save a configuration file for later use
function saveconfig_clbk(junk, junk2)
    [config_fn, config_path] = uiputfile({'*.mat'});
    if sum(config_fn == 0) == 0
        config_vsn = 2;
        save([config_path, filesep, config_fn],...
            'sensor', 'TB_params', 'config_vsn')
        if TB_params.TB_HEAVY_TEXT == 1
            fprintf(1,'Config. file %s saved.\n', config_fn);
        end
    end
end

% Load a configuration file
function loadconfig_clbk(junk, junk2)
    [config_fn, config_path] = uigetfile({'*.mat'});
    if sum(config_fn == 0) == 0
        new_config = load([config_path, filesep, config_fn]);
        % src_dir, gt_file, out_dir, sensor, and TB_params loaded (v1)
        % gt_file, sensor, TB_params, config_vsn loaded (v2)
        
        TB_params = new_config.TB_params;
        % Update source directory display label, shortening if necessary
        if ~isfield(new_config,'config_vsn') % v1
            TB_params.SRC_DIR = new_config.src_dir;
            TB_params.OUT_DIR = new_config.out_dir;
        else
            % v2 already taken care of
        end
%         src_dir = new_config.src_dir;
        set(hsrcstr,'String', abbrev_string(TB_params.SRC_DIR, 25));
        % Update output directory display label, shortening if necessary
%         out_dir = new_config.out_dir;
        set(houtstr,'String', abbrev_string(TB_params.OUT_DIR, 25));
        % Update gt file display label, shortening if necessary
        gt_file = new_config.gt_file;
        set(hgtstr, 'String', abbrev_string(gt_file, 25));
        % Update sensor string
        sensor = new_config.sensor;
        temp = find( cellfun(@(a) (strcmpi(a,sensor)), sensor_formats) );
        set(hsensformats, 'Value', temp);
        % Update parameters and corresponding GUI fields
        tbr = fileparts(mfilename('fullpath'));
        TB_params.TB_ROOT = tbr;
        [junk,file,ext] = fileparts(TB_params.FEEDBACK_PATH);
        TB_params.FEEDBACK_PATH = [tbr,filesep,file,ext];
        [junk,file,ext] = fileparts(TB_params.OPARCHIVE_PATH);
        TB_params.OPARCHIVE_PATH = [tbr,filesep,file,ext];
        [junk,file,ext] = fileparts(TB_params.L_BKUP_PATH);
        TB_params.L_BKUP_PATH = [tbr,filesep,file,ext];
        [junk,file,ext] = fileparts(TB_params.U_BKUP_PATH);
        TB_params.U_BKUP_PATH = [tbr,filesep,file,ext];
        set(hboxhvytxt, 'Value', TB_params.TB_HEAVY_TEXT);
        set(hboxdebug, 'Value', TB_params.DEBUG_MODE);
        set(hboxskipdet, 'Value', TB_params.SKIP_DETECTOR);
        set(hboxskipperf, 'Value', TB_params.SKIP_PERF_EST);
        set(hpopskipfeed, 'Value', TB_params.SKIP_FEEDBACK+1);
        set(hboxarchfeed, 'Value', TB_params.ARCH_FEEDBACK);
        set(hboxfeedon, 'Value', TB_params.TB_FEEDBACK_ON);
        % Update ATR components for GUI lists - determine the desired
        % component from the old list and then find its position in the new
        % list; this prevents saved config from breaking when components
       % are added to the testbed.
        % Detector
        des_det_hstr = func2str(TB_params.DET_HANDLES{TB_params.DETECTOR});
        [new_det_hstrs, TB_params.DET_HANDLES] = import_modules(tbr, 'det');
        TB_params.DETECTOR = find(strcmp(des_det_hstr(5:end), new_det_hstrs), 1);
        if isempty(TB_params.DETECTOR) % desired file has disappeared
            TB_params.DETECTOR = 1;
        end
        det_desc_params = update_all_det_desc_params(TB_params, new_det_hstrs);
        set(hpopdet, 'String', new_det_hstrs);
        set(hpopdet, 'Value', TB_params.DETECTOR);
        clear des_det_hstr new_det_hstrs;
        % Features
        des_feat_hstr = func2str(TB_params.FEAT_HANDLES{TB_params.FEATURES});
        [new_feat_hstrs, TB_params.FEAT_HANDLES] = import_modules(tbr, 'feat');
        TB_params.FEATURES = find(strcmp(des_feat_hstr(6:end), new_feat_hstrs), 1);
        if isempty(TB_params.FEATURES) % desired file has disappeared
            TB_params.FEATURES = 1;
        end
        feat_desc_params = update_all_feat_desc_params(TB_params, new_feat_hstrs);
        set(hpopfeat, 'String', new_feat_hstrs);
        set(hpopfeat, 'Value', TB_params.FEATURES);
        clear des_feat_hstr new_feat_hstrs;
        % Classifiers
        des_cls_hstr = func2str(TB_params.CLS_HANDLES{TB_params.CLASSIFIER});
        [new_cls_hstrs, TB_params.CLS_HANDLES] = import_modules(tbr, 'cls');
        TB_params.CLASSIFIER = find(strcmp(des_cls_hstr(5:end), new_cls_hstrs), 1);
        if isempty(TB_params.CLASSIFIER) % desired file has disappeared
            TB_params.CLASSIFIER = 1;
        end
        cls_desc_params = update_all_cls_desc_params(TB_params, new_cls_hstrs);
        set(hpopclass, 'String', new_cls_hstrs);
        set(hpopclass, 'Value', TB_params.CLASSIFIER);
        clear des_cls_hstr new_cls_hstrs;
        % Classdata info
        des_cdata_str = TB_params.CDATA_FILES{TB_params.CLASS_DATA};
        [TB_params.CDATA_FILES, TB_params.CLASS_DATA] = ...
    import_classdata(TB_params.CLS_HANDLES{TB_params.CLASSIFIER}, TB_params.TB_ROOT);
        TB_params.CLASS_DATA = find(strcmp(des_cdata_str, TB_params.CDATA_FILES), 1);
        if isempty(TB_params.CLASS_DATA) % desired file has disappeared
            TB_params.CLASS_DATA = 1;
        end
         set(hpopcdata, 'String', TB_params.CDATA_FILES);
        set(hpopcdata, 'Value', TB_params.CLASS_DATA);
        clear des_cdata_str;
        % Performance estimation
        set(hboxskipperf, 'Value', TB_params.SKIP_PERF_EST);
        des_perf_hstr = func2str(TB_params.PERF_HANDLES{TB_params.PERFORMANCE});
        [new_perf_hstrs, TB_params.PERF_HANDLES] = import_modules(tbr, 'perf');
        TB_params.PERFORMANCE = find(strcmp(des_perf_hstr(6:end), new_perf_hstrs), 1);
        if isempty(TB_params.PERFORMANCE) % desired file has disappeared
            TB_params.PERFORMANCE = 1;
        end
        set(hpopperfesti, 'String', new_perf_hstrs);
        set(hpopperfesti, 'Value', TB_params.PERFORMANCE);
        clear des_perf_hstr new_perf_hstrs;
        % Contact correlation
        set(hboxccorron, 'Value', TB_params.CONTCORR_ON);
        des_cor_hstr = func2str(TB_params.CC_HANDLES{TB_params.CONTCORR});
        [new_cor_hstrs, TB_params.CC_HANDLES] = import_modules(tbr, 'cor');
        TB_params.CONTCORR = find(strcmp(des_cor_hstr(5:end), new_cor_hstrs), 1);
        if isempty(TB_params.CONTCORR) % desired file has disappeared
            TB_params.CONTCORR = 1;
        end
        set(hpopccorr, 'String', new_cor_hstrs);
        set(hpopccorr, 'Value', TB_params.CONTCORR);
        clear des_cor_hstr new_cor_hstrs;
        % other fields
        set(hpopopconf, 'Value', TB_params.OPCONF_MODE+1);
        set(hdropformats, 'Value', TB_params.DATA_FORMAT);
        set(hboxmansel, 'Value', TB_params.MAN_ATR_SEL);
        set(hploton, 'Value', TB_params.PLOTS_ON);
        set(hplotpause, 'Value', TB_params.PLOT_PAUSE_ON);
        if ~isfield(TB_params,'SAVE_IMAGE')
            TB_params.SAVE_IMAGE = 0;
        end
        set(himgsave, 'Value', TB_params.SAVE_IMAGE);
        
        if ~isfield(TB_params,'INCR_DETECTOR')
            TB_params.INCR_DETECTOR = 0;
        end
        if ~isfield(TB_params,'BURIED_ONLY')
            TB_params.BURIED_ONLY = 0;
        end
        if ~isfield(TB_params,'MULTICLASS')
            TB_params.MULTICLASS = 0;
        end
         if ~isfield(TB_params,'ECD_DIR')
            TB_params.ECD_DIR = [TB_params.OUT_DIR,filesep,'ecd'];
        elseif isempty(TB_params.ECD_DIR)
            TB_params.ECD_DIR = [TB_params.OUT_DIR,filesep,'ecd'];
        end
        if ~isfield(TB_params,'TEMP_DIR')
            TB_params.TEMP_DIR = [TB_params.OUT_DIR,filesep,'temp'];
        elseif isempty(TB_params.ECD_DIR)
            TB_params.TEMP_DIR = [TB_params.OUT_DIR,filesep,'temp'];
        end
        if ~isfield(TB_params,'GT_FORMAT')
            TB_params.GT_FORMAT = 1;
        end
            
        
        if TB_params.SKIP_DETECTOR == 1
            tag_hide_show('preproc', 'off')
            TB_params.MAN_ATR_SEL = 1;
            set(hboxmansel, 'Value', TB_params.MAN_ATR_SEL);
            tag_hide_show('preproc_on', 'on');
            tag_hide_show('det', 'off');
        else
            tag_hide_show('preproc', 'on');
            if TB_params.MAN_ATR_SEL == 1
                tag_hide_show('det', 'on');
            end
        end
        
        % Make sure that non-applicable options are grayed out properly
        fix_item_visibility(TB_params);
        
        % Populate file selection menu
        populate_filelist(hfilesel, TB_params.SRC_DIR, TB_params.DATA_FORMAT);
        % Initialize file indicies
        if isfield(TB_params, 'DATA_RANGE')
            set(hfrng1, 'String', num2str(TB_params.DATA_RANGE(1)));
            set(hfrng2, 'String', num2str(TB_params.DATA_RANGE(2)));
            tag_hide_show('range', 'on');
        else
            tag_hide_show('range', 'off');
            set(hfrng1, 'String', num2str(1));
            set(hfrng2, 'String', num2str(length(infilelist)));
        end
        % Check if enough data is entered to run ATR
        check_ins(TB_params, hgobutton);
    end
end

% Callback for activating buried mode
function buried_clbk(hobj, junk)
    chk_status = get(hobj, 'Checked');
    if strcmp(chk_status, 'on'); % turning buried mode off
        set(hobj, 'Checked', 'off');
        TB_params.BURIED_MODE = 0;
    else
        set(hobj, 'Checked', 'on');
        TB_params.BURIED_MODE = 1;
    end
    
    if TB_params.BURIED_MODE == 1
        % Filter detector modules
        mask = zeros(1, length(det_desc_params));
        for q = 1:length(mask)
            if isfield(det_desc_params{q},'for_buried')
                temp = bin_equiv(det_desc_params{q}.for_buried);
                mask(q) = max(0, temp); % -1 -> 0
            else    % not specified, assume incompatible
                mask(q) = 0;
            end
        end
        % autoselect module
        if mask(TB_params.DETECTOR) == 1    % selected det is ok
            temp = cumsum(mask);    % use index of this det
            new_ind = temp(TB_params.DETECTOR);
        else                                % selected det removed from list
            new_ind = 1; 
        end
        TB_params.DET_HANDLES = TB_params.DET_HANDLES(mask==1);
        TB_params.DETECTOR = new_ind; 
        set(hpopdet, 'String', det_list(mask==1), 'Value', new_ind);
    else
        % Revert to original detector list
        list_str = get_detlistname(TB_params);
        new_ind = find( cellfun(@(a) (strcmp(a,list_str)), det_list) );
       assert(length(new_ind) == 1);
        TB_params.DET_HANDLES = hdet;
        TB_params.DETECTOR = new_ind;
        set(hpopdet, 'String', det_list, 'Value', new_ind);
    end
    
end

% Callback for activating NSAM mode
function nsammode_clbk(hobj, junk)
    chk_status = get(hobj, 'Checked');
    if strcmp(chk_status, 'on'); % turning NSAM mode off
        set(hobj, 'Checked', 'off');
        TB_params.NSAM_MODE_ON = 0;
    else
        set(hobj, 'Checked', 'on');
        TB_params.NSAM_MODE_ON = 1;
    end

    if TB_params.NSAM_MODE_ON == 1
        % disable manual ATR selection and input parameter configuration
        tag_hide_show('atrsel|param', 'off');
    else
        % enable manual ATR selection and input parameter configuration
        tag_hide_show('atrsel|param', 'on');
        % Make sure only the proper fields are shown
        fix_item_visibility(TB_params)
    end
    
    % Check if enough data is entered to run ATR
    check_ins(TB_params, hgobutton);
end

% Callback for plot options checkboxes
function plotopts_clbk(hobj,junk,index) %#ok<*INUSL>
    val = get(hobj, 'Value');
    param_name = get(hobj, 'UserData');
    TB_params.(param_name)(index) = val;
end

% Callback for drop-down menu
function config_popup_clbk(hobj, junk, offset)
  % On change of file format drop down, determine which one was selected
    % so that the proper reader can be used later
    % offset is used to shift field that can have a zero value, since the
    % indexing of the drop down elements start at 1.
    val = get(hobj, 'Value');
    param_name = get(hobj, 'UserData');
    TB_params.(param_name) = val - offset;
    if strcmp(param_name, 'DATA_FORMAT')
        % Update list of available files in GUI
        populate_filelist(hfilesel, TB_params.SRC_DIR, TB_params.DATA_FORMAT);
        range_init(hfilesel);
    elseif strcmp(param_name, 'DETECTOR')
        % Update description data for detector
        [det_desc_params, TB_params] = update_all_det_desc_params(TB_params, det_list);
    elseif strcmp(param_name, 'FEATURES')
        % Update description data for feature set
        [feat_desc_params, TB_params] = update_all_feat_desc_params(TB_params, feat_list); %#ok<*SETNU>
    elseif strcmp(param_name, 'CLASSIFIER')
        % Update list of available classifier data files in GUI
        populate_datalist(hpopcdata);
        % Update description data for classifier
        [cls_desc_params, TB_params] = update_all_cls_desc_params(TB_params, class_list);
        % Update GUI vars for feedback mode
        temp = TB_params.CLASSIFIER;
        if isfield(cls_desc_params{temp}, 'uses_feedback')
            if cls_desc_params{temp}.uses_feedback == 1
                set(hboxfeedon, 'Value', 1);    % Checkbox on
                tag_hide_show('TB_FEEDBACK_ON_sub','on');
            elseif cls_desc_params{temp}.uses_feedback == 0
                set(hboxfeedon, 'Value', 0);    % Checkbox off
                tag_hide_show('TB_FEEDBACK_ON_sub','off');
            end
        end
    end
    clear param_name val;
end

% Callback for checkboxes
function config_chkbox_clbk(hobj, junk)
    % On selection of checkbox, update checkbox's status and the parameter
    % it represents
    param_name = get(hobj, 'UserData');
    box_stat = get(hobj, 'Value');
    if box_stat == get(hobj, 'Min')     % box is unchecked
        set(hobj, 'Value', 0);
  TB_params.(param_name) = 0;
        % Disable options that do not make sense now that this box has been
        % unchecked
        if strcmp(param_name, 'TB_FEEDBACK_ON') % no feeback
            % disable feedback options
            tag_hide_show('TB_FEEDBACK_ON_sub', 'off');
        end
    elseif box_stat == get(hobj, 'Max')	% box is checked
        set(hobj, 'Value', 1);
        TB_params.(param_name) = 1;
        % Enable options that make sense now that this box has been checked
        if strcmp(param_name, 'TB_FEEDBACK_ON') % no feedback
            % enable feedback options
            tag_hide_show('TB_FEEDBACK_ON_sub', 'on');
        end
    end

    if strcmp(param_name, 'SKIP_DETECTOR') == 1
        if TB_params.SKIP_DETECTOR == 1
            tag_hide_show('preproc', 'off')
            TB_params.MAN_ATR_SEL = 1;
            set(hboxmansel, 'Value', TB_params.MAN_ATR_SEL);
            tag_hide_show('preproc_on', 'on');
            tag_hide_show('MAN_ATR_SEL_sub', 'on');
            tag_hide_show('det', 'off');
        else
            tag_hide_show('preproc', 'on');            
            if TB_params.MAN_ATR_SEL == 1
                tag_hide_show('det', 'on');
            end
        end
        check_ins(TB_params, hgobutton)
    elseif strcmp(param_name, 'MAN_ATR_SEL') == 1
        if TB_params.MAN_ATR_SEL == 1
            % enable manual det./class. selection
            tag_hide_show('MAN_ATR_SEL_sub', 'on');
        else
            % disable manual det./class. selection
            tag_hide_show('MAN_ATR_SEL_sub', 'off');
            % also disable using preprocessed results
            TB_params.SKIP_DETECTOR = 0;
            set(hboxskipdet, 'Value', TB_params.SKIP_DETECTOR);
        tag_hide_show('preproc', 'on');
        end
    elseif strcmp(param_name, 'CONTCORR_ON') == 1
        if TB_params.CONTCORR_ON == 1
            % enable contact correlation selection
            tag_hide_show('CONTCORR_ON_sub', 'on');
        else
            % disable contact coreelation selection
            tag_hide_show('CONTCORR_ON_sub', 'off');
        end
    elseif strcmp(param_name, 'PLOTS_ON') == 1
        if TB_params.PLOTS_ON == 1
            % enable plot options
            tag_hide_show('PLOTS_ON_sub', 'on');
        else
            % disable plot options
            tag_hide_show('PLOTS_ON_sub', 'off');
        end
    elseif strcmp(param_name, 'SKIP_PERF_EST') == 1 
        if TB_params.SKIP_PERF_EST == 1
            %disable performance model option
            tag_hide_show('SKIP_PERF_EST_sub', 'off')
        else
            %enable performance model option
            tag_hide_show('SKIP_PERF_EST_sub','on')
        end
    end
    
end

% Callback for button for getting input directory
function inputdir_clbk(junk, junk2)
    % On press of source directory button, get source directory from the user,
    % generate file of list of input files, and update label string.
    if isempty(TB_params.SRC_DIR)
        init_dir = TB_params.TB_ROOT;
    else
        init_dir = TB_params.SRC_DIR;
    end
    sel_dir = uigetdir(init_dir,'Select directory for image files');
    % If directory string is too long, abbreviate it for the GUI
    if length(sel_dir) > 30   
    temp = [sel_dir(1:12),'...',sel_dir((end-12):end)];
    else
        temp = sel_dir;
    end
    % Update source directory display label
    if ~isnumeric(temp)
        set(hsrcstr,'String', temp);
        TB_params.SRC_DIR = sel_dir;
    end
    % Check to enable go button
    check_ins(TB_params, hgobutton)
    % Populate file selection menu
    populate_filelist(hfilesel, TB_params.SRC_DIR, TB_params.DATA_FORMAT);
    % Optional output
    if TB_params.TB_HEAVY_TEXT == 1
        fprintf(1,'%-25s %-s\n', 'Source images directory: ', TB_params.SRC_DIR);
    end
end

% Callback for button for getting output directory
function outputdir_clbk(junk, junk2)
    % On press of output directory button, get output directory from the user
    % and update label string.
    sel_dir = uigetdir(TB_params.TB_ROOT,'Select directory for storage of output files');
    % If directory string is too long, abbreviate it for the GUI
    if length(sel_dir) > 30
        temp = [sel_dir(1:12),'...',sel_dir((end-12):end)];
    else
        temp = sel_dir;
    end
    % Update source directory display label
    if ~isnumeric(temp)
        set(houtstr,'String', temp);
        TB_params.OUT_DIR = sel_dir;
        TB_params.ECD_DIR = [sel_dir,filesep,'ecd'];
        TB_params.TEMP_DIR = [sel_dir,filesep,'temp'];
    end
    % Check to enable go button
    check_ins(TB_params, hgobutton)
    % Optional output
    if TB_params.TB_HEAVY_TEXT == 1
        fprintf(1,'%-25s %-s\n', 'Output directory:', TB_params.OUT_DIR);
    end
end

% Callback for button for getting ground truth file
function gtfile_clbk(junk, junk2)
    % On press of gt file button, get groundtruth file from the user and
    % update the label string
    if length(TB_params.SRC_DIR) > 1
        [sel_gt_file,PathName,FilterIndex] = uigetfile([TB_params.SRC_DIR,filesep,'*.txt'], ...
            'Select groundtruth file'); %#ok<*NASGU>
    else
        [sel_gt_file,PathName,FilterIndex] = uigetfile([TB_params.TB_ROOT,filesep,'*.txt'], ...
                'Select groundtruth file');
    end
    % If filename is too long, abbreviate it for the GUI
    if length(sel_gt_file) > 30
        temp = [sel_gt_file(1:12),'...',sel_gt_file((end-12):end)];
    else
        temp = sel_gt_file;
    end
    % Update groundtruth file display label
    if ~isnumeric(temp)
        set(hgtstr,'String', temp);
        gt_file = [PathName,sel_gt_file];
        % Check to enable go button
        check_ins(TB_params, hgobutton)
        % Optional output
        if TB_params.TB_HEAVY_TEXT == 1
            fprintf(1,'%-25s %-s\n', 'Groundtruth file:', gt_file);
        end
    end
end

% Callback for sensor field
function sensor_clbk(junk,junk2)
    % On sensor selection, update the sensor string to eventually be
    % inserted into the input structure.
    sensor = sensor_formats{get(hsensformats, 'Value')};    
end

% Callback for button launching testbed
function go_clbk(junk, junk2)
% On press of go button, start the program with the given set of input
% files, detector file, and classifier file
    use_index = get(hfilesel, 'Value');
    all_index = get(hfilesel, 'Max');
    if use_index == 1    % 'use all' case
        use_index = 1:(all_index-1);
    else
        use_index = use_index - 1;
    end
    if ~isdeployed
        % add paths of core folders (paths for detectors, classifiers, etc.
        % will be added later as they are needed to avoid potential file
        % conflicts.
        tic
        addpath(TB_params.TB_ROOT);
        addpath(genpath([TB_params.TB_ROOT,filesep,'ATR Core']));
        addpath(genpath([TB_params.TB_ROOT,filesep,'Data Readers']));
        addpath(genpath([TB_params.TB_ROOT,filesep,'Feedback']));
        addpath(genpath([TB_params.TB_ROOT,filesep,'Performance Estimation']));
        addpath(genpath([TB_params.TB_ROOT,filesep,'AC Prep']));
        toc
    end
    % Start processing loop
    bravo_input_sim(TB_params.SRC_DIR, use_index, gt_file, TB_params.OUT_DIR, sensor, TB_params,sbar);
end

% Launch classifier training function
function train_clbk(junk,junk2)
retrain_prep(TB_params);
end

% Launch GT analysis function
function gt_analysis_clbk(junk, junk2)
% contact list
data_dir = uigetdir(pwd,'Select directory for GT analysis');
if data_dir == 0, return, end
[contacts, flist] = scan_contacts(data_dir);
% output file name
sd_chunks = regexp(data_dir, (filesep), 'split');
time_chunk = cell2mat( regexp(datestr(now), '(-|:)', 'split') );
ofn = [data_dir,filesep,sd_chunks{end},' ',time_chunk,'.txt'];

assert(exist(gt_file,'file') == 2, 'Use GUI to select a ground truth file.')

[fmt_index, ok] = get_format_dlg(file_formats);
if ok
    compare_results(gt_file, contacts, ofn, fmt_index, flist);
end
end

% Launch ROC series function
function roc_clbk(junk,junk2)
roc_series
end

% Launch ROC compare function
function roc_cmpr(junk,junk2)
compare_roc();
end

% Launch confusion matrix function
function confusion_clbk(junk,junk2)
confusion_series
end

% Convert a lat/long-based ground truth file into pixel-based one
function gt_conv_clbk(junk, junk2)
convert_latlong_gt_to_xy
end

% Launch documentation
function help_clbk(junk,junk2)
web(['file://',TB_params.TB_ROOT,filesep,'Docs',filesep,'MATS_Manual',...
    filesep,'MATS_Manual.pdf'],'-browser')
end

% Launch 'about' window
function about_clbk(junk,junk2)
gui_pos = get(f, 'Position');
abt_dim = [320,220];
xx = gui_pos(1) + (gui_pos(3) - abt_dim(1))/2;
yy = gui_pos(2) + (gui_pos(4) - abt_dim(2))/2;
abt_pos = [xx, yy, abt_dim];
af = figure('Position', abt_pos, 'Name','About MATS GUI',...
    'NumberTitle','off', 'MenuBar','none');
dist_stmt = ['DISTRIBUTION STATEMENT A. Approved for public release; distribution is unlimited. ',...
    'NOTE: Modules used in conjunction with MATS may be restricted. (See user manual for more details.)'];
title = 'Modular Algorithm Testbed Suite (MATS) GUI';
vsn_info = ['(v',gui_vsn,', ',gui_bdate,')'];
byline = ['Naval Surface Warfare Center - ',...
    'Panama City (NSWC-PC), 110 Vernon Ave., Panama City, FL 32407-7001.'];
% byline = 'NSWC - Panama City';
uicontrol('Style', 'text', 'Position', [[10,10],abt_dim-20],...
    'String', {title,vsn_info,'',byline,'',dist_stmt});
end

% Launch DB script to sort contacts by classifier confidence (x/y coords)
function sort_clist_clbk(junk,junk2)
    data_dir = uigetdir(TB_params.TB_ROOT,'Select directory output files:');
    if ischar(data_dir)
        savefile = [data_dir,filesep,'sorted_contact_list.txt'];
        c_list = scan_contacts(data_dir);
        show_db('x y class classconf fn side', sort_db('classconf', c_list, 1),savefile);
    end
end

% Launch DB script to sort contacts by classifier confidence (lat/long coords)
function sort_clist_clbk_ll(junk,junk2)
data_dir = uigetdir(TB_params.TB_ROOT,'Select directory output files:');
if ischar(data_dir)
    savefile = [data_dir,filesep,'sorted_contact_list.txt'];
    c_list = scan_contacts(data_dir);
    show_db('lat long class classconf fn side', sort_db('classconf', c_list, 1),savefile);
end
end
%%%%%%%%%%%%%%%%%%%%%%%%% END CALLBACK FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%% HELPER FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Ensure that the proper GUI items are showing
function fix_item_visibility(TB_params)
   if TB_params.TB_FEEDBACK_ON == 1
        tag_hide_show('TB_FEEDBACK_ON_sub', 'on');
    else
        tag_hide_show('TB_FEEDBACK_ON_sub', 'off');
    end
    if TB_params.MAN_ATR_SEL == 1
        tag_hide_show('MAN_ATR_SEL_sub', 'on');
    else
        tag_hide_show('MAN_ATR_SEL_sub', 'off');
        TB_params.SKIP_DETECTOR = 0;
        set(hboxskipdet, 'Value', TB_params.SKIP_DETECTOR);
    end
    if TB_params.CONTCORR_ON == 1
        tag_hide_show('CONTCORR_ON_sub', 'on');
    else
        tag_hide_show('CONTCORR_ON_sub', 'off');
    end
    if TB_params.PLOTS_ON == 1
        tag_hide_show('PLOTS_ON_sub', 'on');
    else
        tag_hide_show('PLOTS_ON_sub', 'off');
    end
    if TB_params.SKIP_PERF_EST == 1
        %disable performance model option
        tag_hide_show('SKIP_PERF_EST_sub', 'off')
    else
        %enable performance model option
        tag_hide_show('SKIP_PERF_EST_sub','on')
    end
    if get(hfilesel, 'Value') == 1
        tag_hide_show('range', 'on');
    else
        tag_hide_show('range', 'off');
    end
end

% Enables or disables fields based on their tag values
function tag_hide_show(oktags, new_enstat)
    % Every handle tagged with one of the 'oktags' will be given a new
    % enable status of 'new_enstat'
    temp = findobj('-regexp', 'Tag', oktags);
    for qq = 1:length(temp)
        set(temp(qq), 'Enable', new_enstat);
    end
end

% Populate 'Use File' dropdown with file items
function populate_filelist(hfilesel, src_dir, data_format)
infilelist = gen_file_list(src_dir, data_format, 1);
set(hfilesel,'String', ['Use index range...';infilelist], 'Value', 1,...
    'Min', 1, 'Max', length(infilelist)+1);
% clear infilelist;
end

% Populate classifier data file dropdown with file items
function populate_datalist(hpopcdata)
[cdata_list, def_index] = import_classdata(...
    TB_params.CLS_HANDLES{TB_params.CLASSIFIER}, TB_params.TB_ROOT);
if isempty(def_index)
    def_index = 1;
end
set(hpopcdata, 'String', cdata_list, 'Value', def_index,...
    'Min', 1, 'Max', length(cdata_list));
TB_params.CDATA_FILES = cdata_list;
TB_params.CLASS_DATA = 1;
clear cdata_list;
end

% Check if the inputs required for running the testbed have been entered
% by the user, and if so, enable the go button 
function check_ins(TB_params, hgo)
ok = (~isempty(TB_params.SRC_DIR) || TB_params.SKIP_DETECTOR == 1) &&...
    ~isempty(TB_params.OUT_DIR);
if ok
    set(hgo , 'Enable', 'on');
    set(sbar.hlabel, 'String', 'Press the start button to begin.');
else
    set(hgo , 'Enable', 'off');
    set(sbar.hlabel, 'String', 'Choose I/O directories above...');
end
end

end
