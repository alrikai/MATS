% main_read_disp_pgm.m

load -ASCII color_map_ascii.txt

%set initial pathway to start browser
selected_path=pwd;

while (1==1)

clc

% open file with MATLAB GUI:

[fn,selected_path]=uigetfile( [selected_path '\*.pgm'],'Browse for PGM file; Click CANCEL to quit');

if fn==0, break, end

filename=[selected_path fn];
disp(['Mission File: ' filename]);

% extract left image, right image, and max_range 
[image_data] = read_pgm(filename);

% Display image:

display_image(image_data, fn, 1, color_map_ascii);

'HIT SPACEBAR TO CONTINUE'

pause

end
