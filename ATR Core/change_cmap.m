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