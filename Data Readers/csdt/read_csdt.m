% read a csdt file; csdt ==> (c)ommon (s)onar (d)ata (t)ype
% function [sonar_port0, sonar_stbd0, data1, data2, error_code = csdt_read(filename)
% filename = string = path and filename of csdt file.
% sonar_port0(# range_samples_port, num_lines) = 2D array = port image data.
% sonar_stbd0(# range_samples_stbd, num_lines) = 2D array = stbd image data.
% data1 = data structure for header data (see comments below).
% data2 = data structure for line header data (see comments below).
% error_code = error code (currently set to zero; there is no error checking)
function [sonar_port0, sonar_stbd0, data1, data2, error_code] = read_csdt(filename)
% written by Gerry Dobeck, Oct 09
%
error_code = 0;

fid = fopen(filename, 'r');
%disp(['csdt_read: reading ', filename, '...']);

data1 = [];
data2 = [];
sonar_port = [];
sonar_stbd = [];

data1.csdt_label = fread(fid, 4, 'uchar');
data1.revision   = fread(fid, 1, 'uint32');
data1.file_size  = fread(fid, 1, 'int64');
data1.num_lines  = fread(fid, 1, 'uint32');
% %%%
% start time of file
year1        = fread(fid, 1, 'uint16'); % year
month1       = fread(fid, 1, 'uchar');  % month
day1         = fread(fid, 1, 'uchar');  % day
hour1        = fread(fid, 1, 'uchar');  % hour
minute1      = fread(fid, 1, 'uchar');  % minute
millisecond1 = fread(fid, 1, 'uint16'); % milliseconds
% %%%
% end time of file
year2        = fread(fid, 1, 'uint16'); % year
month2       = fread(fid, 1, 'uchar');  % month
day2         = fread(fid, 1, 'uchar');  % day
hour2        = fread(fid, 1, 'uchar');  % hour
minute2      = fread(fid, 1, 'uchar');  % minute
millisecond2 = fread(fid, 1, 'uint16'); % milliseconds
% %%%
data1.sonar_type = fread(fid, 1, 'uint32');
max_lat          = fread(fid, 1, 'float64'); % max latitude (radians)
min_lat          = fread(fid, 1, 'float64'); % min latitude (radians)
max_lng          = fread(fid, 1, 'float64'); % max longitude (radians)
min_lng          = fread(fid, 1, 'float64'); % min longitude (radians)
% %%%
for k = 1:data1.num_lines
    
    data2(k).ping_count  = fread(fid, 1,  'uint32'); % ping count
    data2(k).year        = fread(fid, 1,  'uint16'); % year
    data2(k).month       = fread(fid, 1,  'uchar');  % month
    data2(k).day         = fread(fid, 1,  'uchar');	 % day
    data2(k).hour        = fread(fid, 1,  'uchar');	 % hour
    data2(k).minute      = fread(fid, 1,  'uchar');	 % minute
    data2(k).millisecond = fread(fid, 1,  'uint16'); % milliseconds
    %%%
    data2(k).track_res = fread(fid, 1,  'float32'); % track resolution (m)
    data2(k).lat       = fread(fid, 1,  'float64'); % lat (radians)
    data2(k).lng       = fread(fid, 1,  'float64'); % lng (radians)
    data2(k).head      = fread(fid, 1,  'float64'); % heading (radians)
    data2(k).roll      = fread(fid, 1,  'float64'); % roll (radians)
    data2(k).pitch     = fread(fid, 1,  'float64'); % pitch (radians)
    data2(k).altitude  = fread(fid, 1,  'float32'); % altitude (m)
    data2(k).depth     = fread(fid, 1,  'float32'); % depth (m)
    %%%
    
    data2(k).range_port = fread(fid, 1,  'uint32');    % range_port (m)
    data2(k).bps_port   = fread(fid, 1,  'uint32');    % bits per sample
    data2(k).spl_port   = fread(fid, 1,  'uint32');    % samples per line (port)
    %%%
    data2(k).range_stbd = fread(fid, 1,  'uint32');    % range_stbd (m)
    data2(k).bps_stbd   = fread(fid, 1,  'uint32');    % bits per sample
    data2(k).spl_stbd   = fread(fid, 1,  'uint32');    % samples per line (stbd)
    
    %% line data
    if data2(k).spl_port > 0
        if data2(k).bps_port == 8,
            sonar_port(k).x = fread(fid, data2(k).spl_port, 'uchar');   % port sonar data
        elseif data2(k).bps_port == 16,
            sonar_port(k).x = fread(fid, data2(k).spl_port, 'ushort');  % port sonar data
        elseif data2(k).bps_port == 32,
            sonar_port(k).x = fread(fid, data2(k).spl_port, 'float32'); % port sonar data
        else
            error_code = 30;
            break
        end
    end
    if data2(k).spl_stbd > 0
        if data2(k).bps_stbd == 8,
            sonar_stbd(k).x = fread(fid, data2(k).spl_stbd, 'uchar');   % stbd sonar data
        elseif data2(k).bps_stbd == 16,
            sonar_stbd(k).x = fread(fid, data2(k).spl_stbd, 'ushort');  % stbd sonar data
        elseif data2(k).bps_stbd == 32,
            sonar_stbd(k).x = fread(fid, data2(k).spl_stbd, 'float32'); % stbd sonar data
        else
            error_code = 40;
            break
        end
    end

end % end of for k = 1:numlines

fclose(fid);

if error_code > 0;
  sonar_port0 = [];
  sonar_stbd0 = [];
  data1 = [];
  data2 = [];
else
    if ~isempty(sonar_port)
        range_samples = length(sonar_port(1).x);
        for k=1:data1.num_lines
            range_samples = max(length(sonar_port(k).x),range_samples);
        end
        sonar_port0=zeros(range_samples, data1.num_lines);
        for k=1:data1.num_lines
            sonar_port0(1:length(sonar_port(k).x), k) = sonar_port(k).x';
        end
    end
    if ~isempty(sonar_stbd)
        range_samples = length(sonar_stbd(1).x);
        for k=1:data1.num_lines
            range_samples = max(length(sonar_stbd(k).x),range_samples);
        end
        sonar_stbd0=zeros(range_samples, data1.num_lines);
        for k=1:data1.num_lines
            sonar_stbd0(1:length(sonar_stbd(k).x), k) = sonar_stbd(k).x';
        end
    end
end

end % end of csdt_read
