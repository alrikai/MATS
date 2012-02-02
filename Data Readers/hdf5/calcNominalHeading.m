function NThead = calcNominalHeading(lat,lon)
% This function calculates the nominal heading that is used in the 
%  in the motion solution calculations in the NERDS code.
%  - Jonathan King 

lat = lat*pi/180;
lon = lon*pi/180;

latDif = sum(diff(lat))/(length(lat)-1);
lonDif = sum(diff(lon))/(length(lon)-1);

NThead = pi/2 - atan2(latDif, lonDif * cos(lat(1)));

% DK - shift back to degrees
NThead = NThead * 180/pi;
end