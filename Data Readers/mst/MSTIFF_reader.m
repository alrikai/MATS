% MSTIFF_read_depth.m
% POC: Gerry Dobeck
%      NSWC/CSS Code HS13
%      Email:  DobeckGJ@ncsc.navy.mil
%      Phone:  850-234-4222
%
%function [left_image, right_image, drng, dcr_rng, depth, error_code] = MSTIFF_read_depth(filename)
% filename = *.MST filename
% left_image = left-side image array (m_track cells by n_range cells)
% right_image = right-side image array (m_track cells by n_range cells)
% drng = range resoluition in cm
% dcr_rng = cross-range resolution in cm
% depth = array of depth measurements(meters) for each sonar ping;
%         depth(i=1:number of cross-range cells)
% error_code = 0  No error
%            = 1  File Open error
%            = 2  Read error for Header MID
%            = 3  Number of File Table entries is bad
%            = 4  File does not contain some key tags

function [left_image, right_image, data1, data2, error_code] = MSTIFF_reader(filename)

error_code=0; left_image=0; right_image=0; max_range=0; drng=0; dcr_rng=0; depth=0;
data1 = [];
data2 = [];
fid=fopen(filename,'r','ieee-le');

if fid==-1
  error('***WARNING*** Error opening file')
  error_code=1;
  return
end

% Read header; MID should = 4C 54 53 4D in hexadecimal format (= 'MSTL' in ASCII)
[~,count_check]=fread(fid,1,'uint32');
if count_check==0, error_code=2; return; end
%MID=dec2hex(MID)

% Read offset from beginning of file to IFD (Image File Directory)
offset=fread(fid,1,'uint32');
fread(fid,offset-8);
num_entries=fread(fid,1,'uint16');
% num_entries = number of entries in IFD
if num_entries < 1 || num_entries > 100, error_code=3; return; end

% Read IFD into matrix
A=zeros(num_entries,4);
for i=1:num_entries
	tag=fread(fid,1,'uint16');
	type=fread(fid,1,'uint16');
	count=fread(fid,1,'uint32');
	voffset=fread(fid,1,'uint32');
	A(i,1:4)=[tag type count voffset];
end

% Set Defaults
description='NO DESCRIPTION';
bitsperbin=8;	   	% bpb (=8 with 2 MSB set to 0)
compression=1;      % no compression
sonarlines=1000;
binsperchannel=512;

% Find rows of matrix A which correspond to relevant data:

descriptag=find(A(:,1)==256);   % Description
comptag=find(A(:,1)==254);      % Compression
bpbtag=find(A(:,1)==258);       % BitsPerBin
sltag=find(A(:,1)==259);        % SonarLines
bpctag=find(A(:,1)==260);       % BitsPerChannel
lctag=find(A(:,1)==263);        % LeftChannel
rctag=find(A(:,1)==264);        % RightChannel
sdinfotag=find(A(:,1)==265);    % SonarDataInfo
navinfocount_tag=find(A(:,1)==266);
fathometercount_tag=find(A(:,1)==286); % Fathometer Count (number of water-depth and vehicle altitude entries)
fathometer2_tag=find(A(:,1)==296); % Fathometer2 data structure (for water-depth and vehicle altitude)
navinfo6_tag=find(A(:,1)==308);

tags=A(:,1);

% find correct tags for sonar data:

if isempty(sdinfotag)==1
      sdinfotag=find(tags==292);
end

if isempty(sdinfotag)==1
      sdinfotag=find(tags==298);
end

if isempty(lctag)==1
      lctag=find(tags==299);
      rctag=find(tags==300);
end

% the following tags are not required to be in the MSTIFF file (defaults are used):
%descriptag
%comptag
%bpbtag
%sltag
%bpctag

if isempty(descriptag)==0
    dcount=A(descriptag,3);
    doffset=A(descriptag,4);
    frewind(fid);
    fread(fid,doffset);
    description=fread(fid,dcount);
end

if isempty(comptag)==0
   compression=A(comptag,4);
end

if isempty(bpbtag)==0
	bitsperbin=A(bpbtag,4);
end

if isempty(sltag)==0
	sonarlines=A(sltag,4);
end

if isempty(bpctag)==0
	binsperchannel=A(bpctag,4);
end
data1.sonar_type = 'MST';
data1.num_lines = sonarlines;
% the following tags are required to be in the MSTIFF file:
% sdinfotag
% lctag
% rctag
% fathometercount_tag
% fathometer2_tag
% navinfocount_tag
% navinfo6_tag

if isempty(sdinfotag)==1
   disp('BAD MSTIFF FILE: no sdinfotag')
   error_code=4;
   return;
end
if isempty(lctag)==1
    disp('BAD MSTIFF FILE: no lctag')
   error_code=4;
   return;
end
if isempty(rctag)==1
    disp('BAD MSTIFF FILE: no rctag')
   error_code=4;
   return;
end 
if isempty(fathometercount_tag)==1
    disp('BAD MSTIFF FILE: no fathometercount_tag')
   error_code=4;
   return;
end
if isempty(fathometer2_tag)==1,
    disp('BAD MSTIFF FILE: no fathometer2_tag') 
   error_code=4;
   return;
end
if isempty(navinfocount_tag)==1
     disp('BAD MSTIFF FILE: no navinfocount_tag')
    error_code=4;
    return;
end
if isempty(navinfo6_tag)==1
     disp('BAD MSTIFF FILE: no navinfo6_tag')
    error_code=4;
    return;
end

ktem=0;
if A(sdinfotag,1) == 265, ktem=10;end
if A(sdinfotag,1) == 292, ktem=12;end
if A(sdinfotag,1) == 298, ktem=44;end

if ktem == 0
        range_mode=0;
else
   sdinfo_offset = A(sdinfotag,4);
   frewind(fid);   
   
% range_mode for the 501-st sonar line
   k=sdinfo_offset + 4 + 500*ktem;
   fread(fid,k);
   range_mode=fread(fid,1,'uint16');
   range_mode=mod(range_mode,16);
   
% range_mode for each sonar line   
%   range_mode_old=-999;
%   k=sdinfo_offset + 4 + 2 - ktem;
%   fread(fid,k);
%
%   for iline=1:1000,
%   
%        fread(fid,ktem-2);
%        range_mode=fread(fid,1,'uint16');
%        range_mode=mod(range_mode,16);
%        
%        if range_mode ~= range_mode_old,
%           range_mode_old=range_mode;
%           [iline,range_mode]
%           pause (0.01)
%        end
%   end

% read timestamp for each sonar line
   frewind(fid);
   fread(fid,sdinfo_offset);
   time_sonar=zeros(sonarlines,1);
   for iline=1:sonarlines,
        time_sonar(iline)=fread(fid,1,'uint32');
        
        fread(fid,ktem-4);
   end

end

max_range=0;
if range_mode == 1, max_range=5; end
if range_mode == 2, max_range=10; end
if range_mode == 3, max_range=20; end
if range_mode == 4, max_range=50; end
if range_mode == 5, max_range=75; end
if range_mode == 6, max_range=100; end
if range_mode == 7, max_range=150; end
if range_mode == 8, max_range=200; end
if range_mode == 9, max_range=300; end
if range_mode == 10, max_range=500; end
if range_mode == 11, max_range=30; end
if range_mode == 12, max_range=40; end

if(max_range==0)
     disp('*** WARNING ***: max_range = 0; max_range reset to 30 meters')
    max_range=30;
end

data1.maxrange=max_range;

% Read Left Image data:
lccount=A(lctag,3);
lcoffset=A(lctag,4);
frewind(fid);
fread(fid,lcoffset);
left_image=fread(fid,lccount,'uint8');
left_image=reshape(left_image,binsperchannel,sonarlines)';
 
% Read Right Image data:
rccount=A(rctag,3);
rcoffset=A(rctag,4);
frewind(fid);
fread(fid,rcoffset);
right_image=fread(fid,rccount,'uint8');
right_image=reshape(right_image,binsperchannel,sonarlines)';

% generate vehicle depth(i=1:sonarlines) by interpolating water-depth minus vehicle altitude

if isempty(fathometer2_tag)==0

   fathometer2_offset=A(fathometer2_tag,4);
   frewind(fid);
   fread(fid,fathometer2_offset);
   fathometercount=A(fathometercount_tag,4);
   time_fath=zeros(fathometercount,1);
   depth2=zeros(fathometercount,1);
   for i=1:fathometercount
       time_fath(i)=fread(fid,1,'uint32');
       water_depth(i)=fread(fid,1,'float');
       vehicle_altitude(i)=fread(fid,1,'float');
       depth2(i)=water_depth(i)-vehicle_altitude(i);
   end
   % NOTE: depth = vehicle depth
   depth=interpolate(time_sonar,time_fath,depth2);

else
   depth=zeros(sonarlines,1);   
end
   data1.depth=depth;
   data1.altitude=vehicle_altitude;
   
if isempty(navinfo6_tag)==0
    navinfo6_offset=A(navinfo6_tag,4);
    frewind(fid);
    fread(fid,navinfo6_offset);
    navinfocount=A(navinfocount_tag,4);
    for i=1:navinfocount
%         sys_time_stamp(i)=fread(fid,1,'uint64');
        sys_time_stamp(i)=fread(fid,1,'uint32');
        latitude(i)=fread(fid,1,'float');
        longitude(i)=fread(fid,1,'float',16);
        heading(i) = fread(fid,1,'float',48);
        %longitude(i)=fread(fid,1,'float',68);
        
    end
    data1.latitude=latitude;
    data1.longitude=longitude;
    data1.heading=heading;
end

drng=100.0*max_range/binsperchannel;
dcr_rng=2.0*drng;

data1.ares=drng;        %along range resolution
data1.cres=dcr_rng;     %cross range resolution

%scale image    
scale=1/mean(mean(left_image));
left_image=scale*left_image;    
scale=1/mean(mean(right_image));
right_image=scale*right_image;

 data2.range_port = max_range;
 data2.range_stbd = max_range;



fclose(fid);
end % end of MSTIFF_read_depth

%**************************************************************************
function [y2]=interpolate(x2,x1,y1)

n2=length(x2);
n1=length(x1);

i1=1;
y2=x2;
for i2=1:n2
    if (x2(i2)>x1(n1))
        y2(i2)=y1(n1);
    else
        while (x2(i2)>x1(i1))
            i1=i1+1;
        end
        if (i1==1)
           y2(i2)=y1(1);
        else
           i1m1=i1-1;
           y2(i2)=y1(i1m1)+(x2(i2)-x1(i1m1))*(y1(i1)-y1(i1m1))/(x1(i1)-x1(i1m1));
        end
    end
end

end % end of interpolate

