% display_image.m

function display_image(image_data, filename, fig_num, color_map)

% Display left and right images:

% get image dimension
[m_track,n_range] = size(image_data);

figure(fig_num);
colormap(color_map);
brighten(0.5);

imagesc(flipud(image_data));

%set aspect ratio for plot axes
set(gca,'PlotBoxAspectRatio',[6*n_range 12*m_track 1]);

set(gca,'XTick',[]),set(gca,'YTick',[]);

title([filename ' --- Range ---> ']);

