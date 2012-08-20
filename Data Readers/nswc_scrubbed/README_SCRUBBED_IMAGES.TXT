  ********************************************************
  *** INFORMATION ABOUT SCRUBBED SONAR IMAGE DATA BASE ***
  ********************************************************
                      14 April 2010

Before you use this database you must have a non-disclosure
agreement with Naval Surface Warfare Center - Panama City
(NSWC-PC), Panama City, FL 32407-7001; or have a contract with
the Office of Naval Research.  It is not difficult to obtain 
a non-disclosure agreement (NDA). If you need an NDA, please 
contact Ed Linsenmeyer, Code DPC, 850-234-4161 (office),
edward.linsenmeyer@navy.mil (Email). After the agreement has
been signed, contact Derek Tucker (address is below).

Before you publish any material using this data, you must get
public release approval from us (NSWC-PC, Panama City,
Florida). This is not difficult, but please plan for the
approval process to take 2 weeks. 

Only your agency can use this data base. You are not authorized
to release this database to any other agency. 

We would appreciate it if you would acknowledge NSWC - Panama City Division, 
Panama City, Florida, as the source of the data in any publication 
where you use this data. Additionally, we request you send us a copy
of any publication or report that uses the database via mail at:

Naval Surface Warfare Center Panama City Division
Code X13
110 Vernon Ave
Panama City, FL 32407 
Attn: Derek Tucker

or via email at to one of the addresses in the following paragraph.

Refer questions to Derek Tucker NSWC Panama City Division, Code X13 (850)-636-6090 
james.d.tucker@navy.mil, (850) 235-5277 (secretary), (850) 235-5374 (FAX),

There are 514 image files. 

Image files are standard pgm files.  There are 512 range cells by
1000 cross-range cells.  The ratio of a cell's range dimension
to cross-range dimension is 6:12. 

Images are 8-bit (0-255) gray scale. 

Text file GT_All_SCRUBBED_IMAGES.txt contains the target
location information. Each line has 4 entries: (1) x(range),
(2) y(cross-range), (3) code, and(4) filename.  Ignore the code.
abs(x) is the range index of the target's location in the image.
 If x > 0, then target is in the RIGHT image.  If x < 0, then
target is in the LEFT image. y is the cross-range index of the
target's location in the image. filename is part of the complete
image filename of the file containing the target. If x > 0,
append '_RIGHT.PGM' to filename to obtain the complete image
file name.  If x < 0, append '_LEFT.PGM' to filename to obtain
the complete image filename.  The target sizes are very roughly
about 17 pixels in range by 9 pixels in cross-range.  Some
targets are much smaller, and some are much larger.  The
target's shadow can be quite long in range. 

main_read_disp_pgm.m is a MATLAB script reading a PGM file and
plotting it at the correct axes aspect ratio using a standard
color map.  This routine uses (1) read_pgm.m, (2)
display_image.m, and (3) the ASCII file color_map_ascii.txt.  To
produce the correct aspect ratio of the plot axes, images are
4 times taller than they are wide in the MATLAB display. To
execute, type "main_read_disp_pgm (enter)" from MATLAB. 
A GUI will pop up; browse for PGM file and open it.  Follow the
displayed instructions.  Make sure the location of the three *.m
files and the *.txt file are in the MATLAB pathway. 
