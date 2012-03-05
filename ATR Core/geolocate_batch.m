 
function [latXY_mat,lngXY_mat] = geolocate_batch(lat0,lng0,heading,dx,dy,altitude)
% double lat0,			// radians and translating by dx (along track)
%  double lng0,			// and dy (across track) meters.
%  double heading,		// vehicle heading
%  double dx,			// Along track diff [m]
%  double dy)			// Across track diff [m]

%lat0 lng0 are vehicle coords at center of track where it happens to be (in
%radians)



  M_PI = 3.1415926535897932384626433832795;
  Rearth = 6368941.0;% earth radius in meters
  
  ones_col = ones(length(lat0), 1);
  ones_row = ones(1, length(dy));

  lat0_mat = lat0' * ones_row;
  lng0_mat = lng0' * ones_row;
  alt_mat = altitude' * ones_row;
  dy_mat = ones_col * dy;
  
  temp_mat = (dy_mat.^2 - alt_mat.^2).^0.5 .* dy_mat./abs(dy_mat);
  mask = abs(alt_mat) <= abs(dy_mat);
  temp_mat = mask .* temp_mat;
  
%   if abs (altitude) <= abs (dy) 
%     dy = sqrt (dy * dy - altitude * altitude)* dy/abs(dy);
%   
%   else 
%     dy = 0.0;
%   end
  %double cosH, sinH,_cos_lat0;		// cos() & sin() of heading
  %double xN, yE;		// coords in earth system
  
  latXY_mat = mod(lat0_mat, M_PI);
  mask1 = latXY_mat < -M_PI/2.0;
  mask2 = latXY_mat > M_PI/2.0;
  latXY_mat = latXY_mat + mask1.*M_PI - mask2.*M_PI;
  
  lngXY_mat = mod(lng0_mat, 2.0*M_PI);
  mask1 = lngXY_mat < -M_PI;
  mask2 = lngXY_mat > M_PI;
  lngXY_mat = lngXY_mat + mask1.*2.0*M_PI - mask2.*2.0*M_PI;
  
  cos_lat0_mat = cos(latXY_mat);
  
  
% % shift lat to range [-pi/2, pi/2]
%   latXY = mod (lat0, M_PI);
%   if latXY < -M_PI / 2.0 
%       latXY = latXY + M_PI;
%   end
%   if latXY > M_PI / 2.0 
%       latXY = latXY - M_PI;
%   end
% % shift long to range [-pi, pi]
%   lngXY = mod (lng0, 2.0 * M_PI);
%   if lngXY < -M_PI
%       lngXY = lngXY+  M_PI * 2.0;
%   end
%   if lngXY > M_PI
%       lngXY = lngXY- M_PI * 2.0;
%   end
%   cos_lat0 = cos (latXY);
% 
%   if dx == 0.0 && dy == 0.0 %Short circuit
%     return;
%   end
  

  % Rotate
  cosH = cos (heading);
  sinH = sin (heading);
  
  % note: this only works because we're only using zero for dx
  xN_mat = cosH * dx - sinH * dy_mat;
  yE_mat = sinH * dx + cosH * dy_mat;
  
%   xN = cosH * dx - sinH * dy;
%   yE = sinH * dx + cosH * dy;

  latXY_mat = latXY_mat + xN_mat / Rearth;
  lngXY_mat = lngXY_mat + yE_mat / Rearth ./ cos_lat0_mat;

%   % Translate
%   latXY_mat = latXY_mat + xN / Rearth;
%   lngXY_mat = lngXY_mat + yE / Rearth / cos_lat0;
end
