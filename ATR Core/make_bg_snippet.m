function [bg_snippet, bg_offset] = ...
    make_bg_snippet(x, y, snipwidth, snipheight, img, img_contacts)
if isempty(img_contacts)
    return
end
% Extract a background snippet near a given position.  Possible snippets
% are located in adjacent snippet-sized blocks in 8 directions
% (N, S, E, W, and combinations thereof) 
width_buff = round(snipwidth/2);
height_buff = round(snipheight/2);
[numy, numx] = size(img);
xs = arrayfun(@(a) (a.x), img_contacts);
ys = arrayfun(@(a) (a.y), img_contacts);

xdirs = [1,0,-1,0,1,1,-1,-1]; ydirs = [0,1,0,-1,1,-1,-1,1];
oks = [0,0,0,0,0,0,0,0];

for q = 1:length(xdirs)
    % Find center of posible block
    x_q = x + xdirs(q)*snipwidth;
    y_q = y + ydirs(q)*snipheight;
    if (x_q > width_buff) && (x_q <= (numx - width_buff)) && ...
            (y_q > height_buff) && (y_q <= (numy - height_buff))
        x_temp = abs(x_q - xs) < width_buff;
        y_temp = abs(y_q - ys) < height_buff;
        oks(q) = ~any(x_temp & y_temp);
    else
        % Part of snippet lies out of bounds
        oks(q) = 0;
    end
end

done = 0; bg_snippet = []; bg_offset = [0,0];
q = 1;
while ~done && (q <= length(oks))
    if oks(q)
        bg_offset = [xdirs(q)*snipwidth, ydirs(q)*snipheight];
        % Extract snippet from image
        bg_snippet = make_snippet_alt(x+bg_offset(1), y+bg_offset(2),...
            snipwidth, snipheight, img);
        done = 1;
    end
    q = q + 1;
end
end