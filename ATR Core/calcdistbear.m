function [latnew,lonnew] = calcdistbear(d,bearing,lat0,lon0)

R = 6368941.0;% earth radius in meters
lat2 = asin(sin(pi/180*lat0)*cos(d/R)+cos(pi/180*lat0)*sin(d/R)*cos(pi/180*bearing));
latnew = lat2*180/pi;

lonnew = lon0 + atan2(sin(pi/180*bearing)*sin(d/R)*cos(pi/180*lat0),cos(d/R)-sin(pi/180*lat0)*sin(lat2));