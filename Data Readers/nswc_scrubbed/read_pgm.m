%%%%This function reads a P5 pgm file into a matrix

function matrix = read_pgm(filename)

fid = fopen(filename,'r','ieee-le');

magic_number = fgetl(fid);

if isempty(strmatch('P5',magic_number))
    disp('ERROR:  PGM file is not P5 format')
    return
end

width_flag = 0;
maxval_flag = 0;


while width_flag == 0
    
   width_temp = fgetl(fid);
   
   if width_temp(1) ~= '#'
       width_flag = 1;
       [width,height] = strread(width_temp,'%d %d');
   end
   
end

while maxval_flag == 0
    
   maxval = fgetl(fid);
   
   if maxval(1) ~= '#'
       maxval_flag = 1;
   end
   
end

matrix_data = fread(fid,(width*height),'uint8');

matrix = reshape(matrix_data,width,height)';

fclose(fid);