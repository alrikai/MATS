function [snippet, xbounds, ybounds] = make_snippet_alt(x, y, snipwidth, snipheight, img)
% Extract a snippet from a given position.  Suspected targets are located
% in the center of the snippet, unless the position is close to the edge of
% the image, in which case the object shifts to avoid spilling over the
% bounds of the image.  No padding is used.

width_buff = (snipwidth-1)/2;
height_buff = (snipheight-1)/2;
[numy, numx] = size(img);

% Find outer-most snippet centers
minx = ceil(width_buff) + 1;      % left-most valid center
miny = ceil(height_buff) + 1;     % top-most valid center
maxx = numx - floor(width_buff);   % right-most valid center
maxy = numy - floor(height_buff);  % bottom-most valid center

% Adjust center position if near an edge of the image
x = max( min(x, maxx), minx);
y = max( min(y, maxy), miny);

left = x - ceil(width_buff);
right = x + floor(width_buff);
top = y - ceil(height_buff);
bottom = y + floor(height_buff);

% Extract snippet from image
xbounds = [left,right];
ybounds = [top,bottom];
snippet = img(top:bottom, left:right);

end