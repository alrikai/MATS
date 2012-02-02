 
function [latXY,lngXY] = geolocate(lat0,lng0,heading,dx,dy,altitude)
% double lat0,			// radians and translating by dx (along track)
%  double lng0,			// and dy (across track) meters.
%  double heading,		// vehicle heading
%  double dx,			// Along track diff [m]
%  double dy)			// Across track diff [m]

%lat0 lng0 are vehicle coords at center of track where it happens to be (in
%radians)



  M_PI = 3.1415926535897932384626433832795;
  Rearth = 6368941.0;% earth radius in meters
  if abs (altitude) <= abs (dy) 
    dy = sqrt (dy * dy - altitude * altitude)* dy/abs(dy);
  
  else 
    dy = 0.0;
  end
  %double cosH, sinH,_cos_lat0;		// cos() & sin() of heading
  %double xN, yE;		// coords in earth system



  latXY = mod (lat0, M_PI);
  if latXY < -M_PI / 2.0 
      latXY = latXY + M_PI;
  end
  if latXY > M_PI / 2.0 
      latXY = latXY - M_PI;
  end
  lngXY = mod (lng0, 2.0 * M_PI);
  if lngXY < -M_PI
      lngXY = lngXY+  M_PI * 2.0;
  end
  if lngXY > M_PI
      lngXY = lngXY- M_PI * 2.0;
  end
  cos_lat0 = cos (latXY);

  if dx == 0.0 && dy == 0.0 %Short circuit
    return;
  end
  

  % Rotate
  cosH = cos (heading);
  sinH = sin (heading);
  xN = cosH * dx - sinH * dy;
  yE = sinH * dx + cosH * dy;

  % Translate
  latXY = latXY + xN / Rearth;
  lngXY = lngXY + yE / Rearth / cos_lat0;
end
