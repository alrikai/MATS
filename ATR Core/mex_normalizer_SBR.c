/*
REVISED 4/18/07: Fixed memory allocation and memory freeing problem associated with ravg
file: mex_normalizer_SBR.c
(1) This routine performs the Serpentine or Cross-Range Forward-Backward Filter image normalizer (see Dobeck, Proceedings of SPIE05).
(2) It uses depth to remove the surface bounce reflecton.
(3) It removes acoustic transmission artifacts.
 
Ported to C Nov 2004 (revised 12/22/2006)
Algorithm developed by Gerry Dobeck, NSWC-PC Code R24, July 2004.
Algorithm ported to C with MATLAB gateway by Tory Cobb and Gerry Dobeck, November 2004.
 
To use in MATLAB, compile in MATLAB as follows:
   >> mex -setup  %the user should reply by selecting the C compiler
   >> mex mex_normalizer_SBR.c  %this compiles the C-code that must include the MATLAB gateway routine
   
This creates a dll file mex_normalizer_SBR.dll that the user calls in MATLAB. 
   
To execute in MATLAB, at the MATLAB prompt enter:
   
   >> [rout, error_code] = mex_normalizer_SBR(rin, dx, dy, blanked_out_range, depth, ioption);
   
   where
         rout = (output) smoothed output image;
                         pixels normailzed between 0.0 and 8.0 with mean level about 1.0.
              = double real array with dimension rout(M, N) where
                          M = no. of range cells (across track)
                          N = no of cross-range cells (along track)
         error_code = (output) 0 for no error; otherwise an error was detected (double real scalar)
                                       
         rin = (input) input image
             = double real array with dimension rin(M, N);
          dx = (input) range resolution in cm (a double real scalar)
          dy = (input) cross-range resolution in cm (a double real scalar)
          blanked_out_range = (input) initial range in cm over which the normalized image
                            is banked out; i.e., set to 1 (a double real scalar)
          depth = (input) array of UUV depths in meters; array length is N;  where
                  depth(i) = UUV depth when image data rin(:,i) was collected. 
                = double real array with dimension depth(N)
               NOTE: depth is used to remove the surface bounce artifact in the REMUS/MSTL-900 sonar.
                     If depth is not available or the sonar is not REMUS/MSTL-900, then set depth = zeros(N,1).
          ioption = (input) Normalizer selection option (a double real scalar)
                  = 0 for Serpentine Normalizer
                  = 1 for Cross-Range Normalizer

    ******************************************************************************
    ABOUT THE 2D arrays used in this C routine:

    To be compatible with MATLAB, the arrays rin and rout are double precision real arrays.
    Therefore one should note, because of the way these arrays are stored in memory and
    the different ways they are referenced by MATLAB and C, that the memory location for rin(i,j) in MATLAB is the same as
    rin[j][i] in C. 

    rin[][] holds the input inage and these routines do not modify its contents.
        -- rin[][] refers to the same memory as the MATLAB input image.
        -- If these routine are changed to modify the contents of rin[][], the input image in MATLAB will also be changed.
    rout[][] temporarily holds the de-spiked image; when execution completes, it will hold the normalized image.
        -- rout[][] refers to same memory as the MATLAB output image.
    r[][] is tempory memory that will hold the de-spiked and smoothed image.
    f[][] is tempory memory that will hold the smooth background image from the forward filter.
    b[][] is tempory memory that will hold the smooth background image from the backward filter.
    ********************************************************************************
*/ 
#include "mex.h"
#include "math.h"
#include "string.h"
#include "stdio.h"
/*

This is an ANSI C version of the Serpentine Normalizer.

(1) This routine normalizes the imput image using Serpentine Forward-Backward Filter.
(2) It uses depth to remove the surface bounce.
(3) It removes acoustic tansmission artifacts.
 
Algorithm developed by Gerry Dobeck, NSWC-PC Code R24, July 2004, See Proceedings of SPIE 2005 (Dobeck).
Also removes acoustic spikes and surface bounce (provided vehicle depth is available).
*/

void fbrl_normalizer_SBR( float *rin1, int *nmax, int *n1, int *m1,
                      int *irow1, int *irow2, float *dx1, float *dy1,
                      float *blanked_out_range, float *depth, int *fbrl_normalizer_error_code)

/*
***********************************************************************************************************

 rin1 = (input) float pointer to original image (stored range-wise as rin1[(*m1)*(*n1)])
      = (output) float pointer to normalized image (normalized between 0.0 and 8.0 with mean about 1.0)
 nmax = (input) integer pointer to max number of range cells
        -- For FORTRAN calling program: first array dimension of rin1 in the 
           dimension statement of the calling FORTRAN program rin1(*nmax,?).
        -- For C calling program: set *nmax = *n1.
 n1 = (input) integer pointer to number of range cells.
 m1 = (input) integer pointer to number of cross-range cells.
 irow1 = (output) integer pointer to first good range-cell index
          ==> *irow1=1; used for compatibility
 irow2 = (output) integer pointer to last good range-cell index
          ==> *irow2=*n; used for compatibility
 dx1 = (input) float pointer to range resolution in cm.
 dy1 = (input) float pointer to cross-range resolution in cm.
 blanked_out_range = (input) float pointer to range in cm to blank out (350.0f cm)
 depth = (input) float pointer to vehicle depth (m); depth[j] corresponds to ping j of sonar image;
                 i.e., the jth cross-range cell of the image.
 fbrl_normalizer_error_code = (output) integer pointer to error code
                            =0 for no error;
                            >0 for error.
                            
 **********************************************************************************************************
    ABOUT THE 2D arrays used in this C routine:
    
    (Note: n = no. of range cells; m = no. of cross-range cells;)

    rin[m][n] a 2D float array that accesses the same memory as pointer rin1.  
              The original image is replaced by the despiked image.  Then, for output,
              the despiked image is replaced by the normalized image.
    r[n][m] is tempory 2D float array that holds the smoothed despiked image.
    f[n][m] is tempory 2D float array that holds the smooth background image from the forward filter.
    b[n][m] is tempory 2D float array that holds the smooth background image from the backward filter.
    
    
    NOTE the switch of 1st and 2nd dimension sizes of rin as compared to r, f, and, b
 *********************************************************************************************************
    Other tempory arrays are:
    
    int arrays: iff[n][m], ibb[n][m], irf[n], irb[n];
    float arrays: rf[n], rb[n]; 
                           
 *********************************************************************************************************
*/
{
    /* Local variables */
    float fabsf(float);
    float ref, bref, fref, sum, rmed, rmean, dx, dy;
    float a, d0, c1, c2, rlimit, image_mean, max_scale;
    float b1, f1, f2, b2, wt, tem1, tem2, tem3;
    float **rin, **r, *rc, **f, **b, *rb, *rf, *ravg;

    int length_thr = 4;
    int n, m, nsum, mmask, nmask, mavg, jdelay, iref;
    int i, j, k, i1, i2, j1, j2, jb, jf, ii, jj;
    int **iff, **ibb;
    int *irf, *irb;
    
    *fbrl_normalizer_error_code=0;
  
    *irow1=*blanked_out_range/(*dx1); *irow2=*n1;
    if (*irow1<1) {*irow1=1;}
    if (*irow1>*n1) {*irow1=1;}
    n=*n1; m=*m1; dx=*dx1; dy=*dy1;
    
    /*
    mexPrintf("fbrl_normalizer_SBR: START\n");
    mexPrintf("fbrl_normalizer_SBR: n(rows)=%d m(columns)=%d\n",n,m);
    */
    
/*dynamically allocate pointers rin[m][*nmax]
 allocate m float * pointers. */
    if (!(rin = (float **) malloc (m*sizeof(float *)))) {
       /* mexPrintf("\n Error rin: Malloc  fails! \n"); */
       *fbrl_normalizer_error_code=100;
       return;
    }
    for (j = 0; j < m; ++j) {rin[j] = rin1 + *nmax*j;}

/*dynamically allocate memory for r[n][m]
allocate n float * pointers. */
    if (!(r = (float **) malloc (n*sizeof(float *)))) {
       /* mexPrintf("\n Error r: Malloc  fails! \n"); */
       *fbrl_normalizer_error_code=1;
        return;
    }

   if (!(rc = (float *) malloc (n*m*sizeof(float)))) {
       /* mexPrintf("\n Error rc: Malloc  fails! \n"); */
       *fbrl_normalizer_error_code=2;
       return;
    }
    for (i = 0; i < n; ++i) {r[i] = rc + m*i;}

/* remove surface bounce reflection */
	
    for (j=0; j<m; ++j) {
        
        for (i=0; i<n; ++i) {r[i][j]=rin[j][i];}
   
        ii=depth[j]*100.0f/dx;
        i=200.0f/dx+0.5f;
        i1=ii-i; if (i1<0) {i1=0;} if (i1>n-1) {i1=n-1;}
        i2=ii+i; if (i2<0) {i2=0;} if (i2>n-1) {i2=n-1;}
        
        j1=j-3; if(j1<0){j1=0;}
        j2=j+3; if(j2>m-1){j2=m-1;}
        
        rmean=0.0f; wt=0.0f;
        for (jj=j1; jj<j2+1; ++jj){
            for (i=i1; i<i2+1; ++i){
                wt+=rin[jj][i]*rin[jj][i];
                rmean += rin[jj][i]*rin[jj][i]*i;
            }
        }
        
        ii=rmean/wt +0.5f;
        i=150.0f/dx+0.5f;
        i1=ii-i; if (i1<0) {i1=0;} if (i1>n-1) {i1=n-1;}
        i2=ii+i; if (i2<0) {i2=0;} if (i2>n-1) {i2=n-1;}
     
        rlimit=0.0f; rmean=0.0f;
        for (i=i1; i<i2+1; ++i){
            rmean += rin[j][i];
            if (rin[j][i]>rlimit){rlimit=rin[j][i];}
        }
        rmean /= (i2-i1+1);
        rlimit=0.95f*rmean+0.05f*rlimit;
        k=0;
        rmean=0.0f;
        for (i=i1; i<i2+1; ++i){
            if (rin[j][i]<rlimit){rmean += rin[j][i]; k++;}
        }
        if (k>0) {
            rmean /= k;
            for (i=i1; i<i2+1; ++i){
                if (rin[j][i]>=rlimit){r[i][j]=rmean;}
            }
        }
    
    }



/*dynamically allocate memory for irf[n] */
    if (!(irf = (int *) malloc (n*sizeof(int)))) {
       /* mexPrintf("\n Error irf: Malloc  fails! \n"); */
       *fbrl_normalizer_error_code=3;
       return;
    }
/*dynamically allocate memory for rf[n] */

    if (!(rf = (float *) malloc (n*sizeof(float)))) {
       /* mexPrintf("\n Error rf: Malloc  fails! \n"); */
       *fbrl_normalizer_error_code=9;
       return;
    }

/*dynamically allocate memory for ravg[n] */
    if (!(ravg = (float *) malloc (n*sizeof(float)))) {
       /* mexPrintf("\n Error ravg: Malloc  fails! \n"); */
       *fbrl_normalizer_error_code=91;
       return;
    }
    

/* Remove spikes with row-wise length of "length_thr" pixels or more */

	
    
    for (j = 0; j < m; ++j) {
	     for (i = 0; i < n ; ++i) {
             rin[j][i] = r[i][j];
         }
    }
    
    ref=0.0f;
    
    for (j = 1; j < (m-1); ++j) {

	   nsum = 0;
       for (i = 0; i < n; ++i) {
          irf[i] = 0;
          if (((r[i][j] - r[i][j-1]) >= ref) &&
              ((r[i][j] - r[i][j+1]) >= ref)) {
             ++nsum;
          }
          else {
              if (nsum >= length_thr) {
                 for (k = i - nsum; k < i; ++k) {
                    irf[k] = 1;
                 }
              }
              nsum = 0;
          }
       }
       if (nsum >= length_thr) {
          for (k = n - nsum; k < n; ++k) {
             irf[k] = 1;
          }
       }
       for (i = 0; i < n; ++i) {
          if (irf[i] == 1) {
             rin[j][i] = ((r[i][j-1] + r[i][j+1])*0.5f);
          }
       }
    }



/* save despiked rin with surface bounced removed in r matrix */
    for (i = 0; i < n; ++i) {
       for (j = 0; j < m; ++j) {
           r[i][j] = rin[j][i]; 
       }
    }
    
/* smooth the depiked image, r(i,j) by averaging with a */
/* 2D mask of size (2*nmask+1) x (2*mmask+1). */
    nmask = 1;
    mmask = 1;

  conv_gjd(r, n, m, nmask, mmask);

  image_mean=0.0f;
  for (i=0; i<n; ++i){
      ravg[i]=0.0f;
      for (j=0; j<m; ++j){
          ravg[i] += r[i][j];
      }
      image_mean += ravg[i];
      ravg[i] /= m;
  }
  image_mean /= (n*m);
  if(image_mean>0.0f){
      max_scale=2.0f/image_mean;
  }else{
      max_scale=0.0f;
  }

    
    
/* set 2nd order filter coefficients */
    a = (float) exp( (double)(-dy/195.0f) );
   
    
    /* mexPrintf("fbrl_normalizer_SBR: exp(-dy/195) = %f\n",a); */

    d0 = (1.0f-a); d0=d0*d0;
    c1 = 2.0f*a;
    c2 = -a*a;

    jdelay = 150.0f/dy + 0.5f;

    /* mexPrintf("fbrl_normalizer_SBR: jdelay = %d\n",jdelay); */


    mavg = 3;
    /*mavg = min(mavg,m)*/
    if (m < mavg) {mavg = m;}
    /* mexPrintf("fbrl_normalizer_SBR: mavg = %d\n",mavg); */

/*dynamically allocate memory for f[n][m]*/

    if (!(f = (float **) malloc (n*sizeof(float *)))) {
       /* mexPrintf("\n Error f: Malloc  fails! \n"); */
       *fbrl_normalizer_error_code=4;
       return;
    }
    for (i = 0; i < n; ++i) {

    if (!(f[i] = (float *) malloc (m*sizeof(float)))) {
       /* printf("\n Error f[i]: Malloc  fails! for i = %d \n",i); */
       *fbrl_normalizer_error_code=5;
       return;
       }
    }

/*dynamically allocate memory for iff[n][m]*/

    if (!(iff = (int **) malloc (n*sizeof(int *)))) {
       /* mexPrintf("\n Error iff: Malloc  fails! \n"); */
       *fbrl_normalizer_error_code=6;
       return;
    }
    for (i = 0; i < n; ++i) {

    if (!(iff[i] = (int *) malloc (m*sizeof(int)))) {
       /* printf("\n Error iff[i]: Malloc  fails! for i = %d \n",i); */
       *fbrl_normalizer_error_code=7;
       return;
       }
    }

/*dynamically allocate memory for irb[n] */

    if (!(irb = (int *) malloc (n*sizeof(int)))) {
       /* mexPrintf("\n Error irb: Malloc  fails! \n"); */
       *fbrl_normalizer_error_code=10;
       return;
    }

/*dynamically allocate memory for rb[n] */

    if (!(rb = (float *) malloc (n*sizeof(float)))) {
       /* mexPrintf("\n Error rb: Malloc  fails! \n"); */
       *fbrl_normalizer_error_code=11;
       return;
    }

/* compute forward filter f[i][j] */
/* Initialize forward filter */
    for (i = 0; i < n; ++i) {
       sum = 0.0f;
       for (j = 0; j < mavg; ++j) {
          sum += r[i][j];
       }

       sum /= mavg;
       f[i][0] = sum;
       f[i][1] = sum;
       iff[i][0] = i;
       iff[i][1] = i;
    }
/* migrate from bott om to top: j = 2 to m-1 */

    for (j = 2; j < m; ++j) {
       j1 = j - 1;  
       j2 = j - 2;  
/* migrate from left to right: i = 0 to n-1 */
       f1 = f[0][j1];
       f2 = f[iff[0][j1]][j2];
       irf[0] = 0;
       rf[0] = c1 * f1 + c2 * f2 + d0 * r[0][j];

       for (i = 1; i < n; ++i) {
          i1 = i - 1;
          rmed = r[i][j];
          
          tem1=c1*f[i1]     [j1] + c2*f[iff[i1]     [j1]][j2] + d0*rmed;
          tem2=c1*f[i ]     [j1] + c2*f[iff[i ]     [j1]][j2] + d0*rmed;
          tem3=c1*f[irf[i1]][j1] + c2*f[iff[irf[i1]][j1]][j2] + d0*rmed;
          
           if ((fabsf(tem1 - rmed)) < (fabsf(tem2 - rmed))) {
             fref = tem1;
             iref = i1;
          }
          else {
             fref = tem2;
             iref = i;
          }
          if ((fabsf(tem3 - rmed)) < (fabsf(fref - rmed))) {
             fref = tem3;
             iref = irf[i1];
          }
          irf[i] = iref;
          rf[i] = fref;

       }

/* migrate from right to left:  i = n-1 to 0 */
       f1 = f[n-1][j1];
       f2 = f[iff[n-1][j1]][j2];
       irb[n-1] = n-1;
       rb[n-1] = c1 * f1 + c2 * f2 + d0 * r[n-1][j];
       for (i = n - 2; i > -1; --i) {
          i1 = i + 1;
          rmed = r[i][j];
          
          tem1=c1*f[i1]     [j1] + c2*f[iff[i1]     [j1]][j2] + d0*rmed;
          tem2=c1*f[i ]     [j1] + c2*f[iff[i ]     [j1]][j2] + d0*rmed;
          tem3=c1*f[irb[i1]][j1] + c2*f[iff[irb[i1]][j1]][j2] + d0*rmed;
          
           if ((fabsf(tem1 - rmed)) < (fabsf(tem2 - rmed))) {
             fref = tem1;
             iref = i1;
          }
          else {
             fref = tem2;
             iref = i;
          }
          if ((fabsf(tem3 - rmed)) < (fabsf(fref - rmed))) {
             fref = tem3;
             iref = irb[i1];
          }
          irb[i] = iref;
          rb[i] = fref;

       }
/* set forward filter entries */

       for (i = 0; i < n; ++i) {
/* select right filter value, rf(i), or left filter value, rb[i]. */

          if ((fabsf(rf[i] - r[i][j])) < (fabsf(rb[i] - r[i][j]))) {
             f[i][j] = rf[i];
             iff[i][j] = irf[i];
          }
          else {
             f[i][j] = rb[i];
             iff[i][j] = irb[i];
          }
       }
    }
/*dynamically allocate memory for b[n][m]*/

    if (!(b = (float **) malloc (n*sizeof(float *)))) {
       /* mexPrintf("\n Error b: Malloc  fails! \n"); */
       *fbrl_normalizer_error_code=12;
       return;
    }
    for (i = 0; i < n; ++i) {

    if (!(b[i] = (float *) malloc (m*sizeof(float)))) {
       /* printf("\n Error b[i]: Malloc  fails! for i = %d \n",i); */
       *fbrl_normalizer_error_code=13;
       return;
       }
    }    
/*dynamically allocate memory for ibb[n][m]*/

    if (!(ibb = (int **) malloc (n*sizeof(int *)))) {
       /* mexPrintf("\n Error ibb: Malloc  fails! \n"); */
       *fbrl_normalizer_error_code=14;
       return;
    }
    for (i = 0; i < n; ++i) {
    if (!(ibb[i] = (int *) malloc (m*sizeof(int)))) {
       /* printf("\n Error ibb[i]: Malloc  fails! for i = %d \n",i); */
       *fbrl_normalizer_error_code=15;
       return;
       }
    }
/* compute backward filter b[i][j] */
/* Initialize backward filter */

    for (i = 0; i < n; ++i) {
       sum = 0.0f;

       for (j = m - mavg; j < m; ++j) {
          sum += r[i][j];
       }
       sum /= mavg;
       b[i][m-1] = sum;
       b[i][m-2] = sum;
       ibb[i][m-1] = i;
       ibb[i][m-2] = i;
    }
/* migrate from top to bottom:  j = m-3 to 0 */

    for (j = m - 3; j > -1; --j) {
       j1 = j + 1;
       j2 = j + 2;

/* migrate from left to right: i = 0 to n-1 */
       b1 = b[0][j1];
       b2 = b[ibb[0][j1]][j2];
       irf[0] = 0;
       rf[0] = c1 * b1 + c2 * b2 + d0 * r[0][j];

       for (i = 1; i < n; ++i) {
          i1 = i - 1;
          rmed = r[i][j];

          tem1=c1*b[i1]     [j1] + c2*b[ibb[i1]     [j1]][j2] + d0*rmed;
          tem2=c1*b[i ]     [j1] + c2*b[ibb[i ]     [j1]][j2] + d0*rmed;
          tem3=c1*b[irf[i1]][j1] + c2*b[ibb[irf[i1]][j1]][j2] + d0*rmed;
          
           if ((fabsf(tem1 - rmed)) < (fabsf(tem2 - rmed))) {
             bref = tem1;
             iref = i1;
          }
          else {
             bref = tem2;
             iref = i;
          }
          if ((fabsf(tem3 - rmed)) < (fabsf(bref - rmed))) {
             bref = tem3;
             iref = irf[i1];
          }
          irf[i] = iref;
          rf[i] = bref;
          
       }
/* migrate from right to left: i = n-1 to 0 */
       b1 = b[n-1][j1];
       b2 = b[ibb[n-1][j1]][j2];
       irb[n-1] = n-1;
       rb[n-1] = c1 * b1 + c2 * b2 + d0 * r[n-1][j];
       
       for (i = n - 2; i > -1; --i) {
          i1 = i + 1;

          rmed = r[i][j];
          
          tem1=c1*b[i1]     [j1] + c2*b[ibb[i1]     [j1]][j2] + d0*rmed;
          tem2=c1*b[i ]     [j1] + c2*b[ibb[i ]     [j1]][j2] + d0*rmed;
          tem3=c1*b[irb[i1]][j1] + c2*b[ibb[irb[i1]][j1]][j2] + d0*rmed;
          
           if ((fabsf(tem1 - rmed)) < (fabsf(tem2 - rmed))) {
             bref = tem1;
             iref = i1;
          }
          else {
             bref = tem2;
             iref = i;
          }
          if ((fabsf(tem3 - rmed)) < (fabsf(bref - rmed))) {
             bref = tem3;
             iref = irb[i1];
          }
          irb[i] = iref;
          rb[i] = bref;
         
       }
/* set backward filter entries */
       for (i = 0; i < n; ++i) {
/* select right filter value, rf[i], or left filter value, rb[i]. */

          if ((fabsf(rf[i] - r[i][j])) < (fabsf(rb[i] - r[i][j]))) {
             b[i][j] = rf[i];
             ibb[i][j] = irf[i];
          }
          else {
             b[i][j] = rb[i];
             ibb[i][j] = irb[i];
          }
       }
    }
/* use range-direction forward/backward filter output to to compute */
/* background level */
    for (i = 0; i < n; ++i) {
       for (j = 0; j < m; ++j) {

/* find forward filter delay index for f[i][j] */
          jf = j - jdelay;
          if (jf < 0) {jf = 0;}
          if (j > jf) {
             ii = i;
             for (jj = j; jj > jf; --jj) {
                ii = iff[ii][jj];
             }
             fref = f[ii][jf];
          }
          else {
             fref = f[i][j];
          }
/* find backward filter delay index for b[i][j] */
          jb = j + jdelay;
          if (jb > m - 1) {jb = m - 1;}
          if (j < jb) {
             ii = i;
             for (jj = j; jj < jb; ++jj) {
                ii = ibb[ii][jj];
             }
             bref = b[ii][jb];
          }
          else {
             bref = b[i][j];
          }
/* select forward of backwards filter value for normalization. */
          if ((fabsf(r[i][j] - fref)) < (fabsf(r[i][j] - bref))) {
             rmean = fref;
          }
          else {
             rmean = bref;
          }
          
          if ((fabsf(r[i][j] - ravg[i])) < (fabsf(r[i][j] - rmean))) {
             rmean = ravg[i];
          }

          wt = rmean;
          rmed=rin[j][i];
          
          if (wt>0.0f) {
              tem1=1.0f/wt;
              if(tem1>max_scale){tem1=max_scale;}
              rmed=tem1*(rmed-wt)+1.0f;
          }else{
              rmed=1.0f;
          }
          
          if (rmed > 8.0f) {rmed = 8.0f;}

          rin[j][i]=rmed;
       }
    }

/* if *irow>1, then blank out image for i=0,...,*irow1-2 */    
if (*irow1>1) {
   for (j=0; j<m; ++j) {
       for (i=0; i<*irow1-1; ++i) {
           rin[j][i]=1.0f;
       }
   }
}

/*Free memory allocated to rin[m]*/
          free(rin);
/*Free memory allocated to r[n][m]*/
          free(r); free(rc);
/*Free memory allocated to f[n][m]*/
          for (i=0; i<n; ++i) { free(f[i]);}
          free(f);
/*Free memory allocated to iff[n][m]*/
          for (i=0; i<n; ++i) { free(iff[i]);}
          free(iff);
/*Free memory allocated to irf[n]*/
          free(irf);

/*Free memory allocated to rf[n] and ravg[n]*/
          free(rf); free(ravg);
/*Free memory allocated to irb[n]*/
          free(irb);
/*Free memory allocated to rb[n]*/
          free(rb);
/*Free memory allocated to b[n][m]*/
          for (i=0; i<n; ++i) { free(b[i]);}
          free(b);
/*Free memory allocated to ibb[n][m]*/
          for (i=0; i<n; ++i) { free(ibb[i]);}
          free(ibb);

    /* mexPrintf("fbrl_normalizer_SBR: END\n"); */

    return;
}

/************************************************************************************
*************************************************************************************
************************************************************************************/
/*

This is an ANSI C version of the Cross-Range Normalizer.

(1) This routine normalizes the imput image using Cross-Range Forward-Backward Filter.
(2) It uses depth to remove the surface bounce.
(3) It removes acoustic tansmission artifacts.
 
Algorithm developed by Gerry Dobeck, NSWC-PC Code R24, July 2004, See Proceedings of SPIE 2005 (Dobeck).
Also removes acoustic spikes and surface bounce (provided vehicle depth is available).
*/

void CR_normalizer_SBR( float *rin1, int *nmax, int *n1, int *m1,
                      int *irow1, int *irow2, float *dx1, float *dy1,
                      float *blanked_out_range, float *depth, int *CR_normalizer_error_code)

/*
***********************************************************************************************************

 rin1 = (input) float pointer to original image (stored range-wise as rin1[(*m1)*(*n1)])
      = (output) float pointer to normalized image (normalized between 0.0 and 8.0 with mean about 1.0)
 nmax = (input) integer pointer to max number of range cells
        -- For FORTRAN calling program: first array dimension of rin1 in the 
           dimension statement of the calling FORTRAN program rin1(*nmax,?).
        -- For C calling program: set *nmax = *n1.
 n1 = (input) integer pointer to number of range cells.
 m1 = (input) integer pointer to number of cross-range cells.
 irow1 = (output) integer pointer to first good range-cell index
          ==> *irow1=1; used for compatibility
 irow2 = (output) integer pointer to last good range-cell index
          ==> *irow2=*n; used for compatibility
 dx1 = (input) float pointer to range resolution in cm.
 dy1 = (input) float pointer to cross-range resolution in cm.
 blanked_out_range = (input) float pointer to range in cm to blank out (350.0f cm)
 depth = (input) float pointer to vehicle depth (m); depth[j] corresponds to ping j of sonar image;
                 i.e., the jth cross-range cell of the image.
 CR_normalizer_error_code = (output) integer pointer to error code
                            =0 for no error;
                            >0 for error.
                                                     
 **********************************************************************************************************
 */
{
    /* Local variables */
    float fabsf(float);
    float ref, bref, fref, sum, rmed, rmean, dx, dy;
    float a, d0, c1, c2, rlimit, image_mean, max_scale;
    float wt, tem1;
    float **rin, **r, *rc, *f, *b, *ravg;

    int length_thr = 4;
    int n, m, nsum, mmask, nmask, mavg, jdelay;
    int i, j, k, i1, i2, j1, j2, jb, jf, ii, jj;
    int *irf;
    
    *CR_normalizer_error_code=0;
  
    *irow1=*blanked_out_range/(*dx1); *irow2=*n1;
    if (*irow1<1) {*irow1=1;}
    if (*irow1>*n1) {*irow1=1;}
    n=*n1; m=*m1; dx=*dx1; dy=*dy1;
    
    /*
    mexPrintf("CR_normalizer_SBR: START\n");
    mexPrintf("CR_normalizer_SBR: n(rows)=%d m(columns)=%d\n",n,m);
    */
    
/*dynamically allocate pointers rin[m][*nmax] */

    if (!(rin = (float **) malloc (m*sizeof(float *)))) {
       /* mexPrintf("\n Error rin: Malloc  fails! \n"); */
       *CR_normalizer_error_code=100;
       return;
    }
    for (j = 0; j < m; ++j) {rin[j] = rin1 + *nmax*j;}

/*dynamically allocate memory for r[n][m]*/

    if (!(r = (float **) malloc (n*sizeof(float *)))) {
       /* mexPrintf("\n Error r: Malloc  fails! \n"); */
       *CR_normalizer_error_code=1;
        return;
    }

   if (!(rc = (float *) malloc (n*m*sizeof(float)))) {
       /* mexPrintf("\n Error rc: Malloc  fails! \n"); */
       *CR_normalizer_error_code=2;
       return;
    }
    for (i = 0; i < n; ++i) {r[i] = rc + m*i;}


/* remove surface bounce reflection */
	

    for (j=0; j<m; ++j) {
        
        for (i=0; i<n; ++i) {r[i][j]=rin[j][i];}
   
        ii=depth[j]*100.0f/dx;
        i=200.0f/dx+0.5f;
        i1=ii-i; if (i1<0) {i1=0;} if (i1>n-1) {i1=n-1;}
        i2=ii+i; if (i2<0) {i2=0;} if (i2>n-1) {i2=n-1;}
        
        j1=j-3; if(j1<0){j1=0;}
        j2=j+3; if(j2>m-1){j2=m-1;}
        
        rmean=0.0f; wt=0.0f;
        for (jj=j1; jj<j2+1; ++jj){
            for (i=i1; i<i2+1; ++i){
                wt+=rin[jj][i]*rin[jj][i];
                rmean += rin[jj][i]*rin[jj][i]*i;
            }
        }
        
        ii=rmean/wt +0.5f;
        i=150.0f/dx+0.5f;
        i1=ii-i; if (i1<0) {i1=0;} if (i1>n-1) {i1=n-1;}
        i2=ii+i; if (i2<0) {i2=0;} if (i2>n-1) {i2=n-1;}
     
        rlimit=0.0f; rmean=0.0f;
        for (i=i1; i<i2+1; ++i){
            rmean += rin[j][i];
            if (rin[j][i]>rlimit){rlimit=rin[j][i];}
        }
        rmean /= (i2-i1+1);
        rlimit=0.95f*rmean+0.05f*rlimit;
        k=0;
        rmean=0.0f;
        for (i=i1; i<i2+1; ++i){
            if (rin[j][i]<rlimit){rmean += rin[j][i]; k++;}
        }
        if (k>0) {
            rmean /= k;
            for (i=i1; i<i2+1; ++i){
                if (rin[j][i]>=rlimit){r[i][j]=rmean;}
            }
        }
    
    }


/*dynamically allocate memory for irf[n] */
    if (!(irf = (int *) malloc (n*sizeof(int)))) {
       /* mexPrintf("\n Error irf: Malloc  fails! \n"); */
       *CR_normalizer_error_code=3;
       return;
    }


/*dynamically allocate memory for ravg[n] */

    if (!(ravg = (float *) malloc (n*sizeof(float)))) {
       /* mexPrintf("\n Error ravg: Malloc  fails! \n"); */
       *CR_normalizer_error_code=91;
       return;
    }
    

/* Remove spikes with row-wise length of "length_thr" pixels or more */

	
    for (j = 0; j < m; ++j) {
	     for (i = 0; i < n ; ++i) {
             rin[j][i] = r[i][j];
         }
    }
    
    ref=0.0f;
    
    for (j = 1; j < (m-1); ++j) {

	   nsum = 0;
       for (i = 0; i < n; ++i) {
          irf[i] = 0;
          if (((r[i][j] - r[i][j-1]) >= ref) &&
              ((r[i][j] - r[i][j+1]) >= ref)) {
             ++nsum;
          }
          else {
              if (nsum >= length_thr) {
                 for (k = i - nsum; k < i; ++k) {
                    irf[k] = 1;
                 }
              }
              nsum = 0;
          }
       }
       if (nsum >= length_thr) {
          for (k = n - nsum; k < n; ++k) {
             irf[k] = 1;
          }
       }
       for (i = 0; i < n; ++i) {
          if (irf[i] == 1) {
             rin[j][i] = ((r[i][j-1] + r[i][j+1])*0.5f);
          }
       }
    }



/* save despiked rin with surface bounced removed in r matrix */
    for (i = 0; i < n; ++i) {
       for (j = 0; j < m; ++j) {
           r[i][j] = rin[j][i]; 
       }
    }
    
/* smooth the depiked image, r(i,j) by averaging with a */
/* 2D mask of size (2*nmask+1) x (2*mmask+1). */
    nmask = 1;
    mmask = 1;

  conv_gjd(r, n, m, nmask, mmask);

  image_mean=0.0f;
  for (i=0; i<n; ++i){
      ravg[i]=0.0f;
      for (j=0; j<m; ++j){
          ravg[i] += r[i][j];
      }
      image_mean += ravg[i];
      ravg[i] /= m;
  }
  image_mean /= (n*m);
  if(image_mean>0.0f){
      max_scale=2.0f/image_mean;
  }else{
      max_scale=0.0f;
  }

    
    
/* set 2nd order filter coefficients */
    a = (float) exp( (double)(-dy/195.0f) );
    
    
    /* mexPrintf("CR_normalizer_SBR: exp(-dy/195) = %f\n",a); */

    d0 = (1.0f-a); d0=d0*d0;
    c1 = 2.0f*a;
    c2 = -a*a;

    jdelay = 150.0f/dy + 0.5f;

    /* mexPrintf("CR_normalizer_SBR: jdelay = %d\n",jdelay); */


    mavg = 3;
    /*mavg = min(mavg,m)*/
    if (m < mavg) {mavg = m;}
    /* mexPrintf("CR_normalizer_SBR: mavg = %d\n",mavg); */

/*dynamically allocate memory for f[n][m]*/
    if (!(f = (float *) malloc (m*sizeof(float)))) {
       /* mexPrintf("\n Error f: Malloc  fails! \n"); */
       *CR_normalizer_error_code=4;
       return;
    }
    
/*dynamically allocate memory for b[n][m]*/
    if (!(b = (float *) malloc (m*sizeof(float)))) {
       /* mexPrintf("\n Error b: Malloc  fails! \n"); */
       *CR_normalizer_error_code=12;
       return;
    }
   

    for (i = 0; i < n; ++i) {
    
    /* compute forward filter f[j] */
    /* Initialize forward filter */
       sum = 0.0f;
       for (j = 0; j < mavg; ++j) {
          sum += r[i][j];
       }

       sum /= mavg;
       f[0] = sum;
       f[1] = sum;
       
/* migrate from bottom to top: j = 2 to m-1 */

       for (j = 2; j < m; ++j) {
          
          f[j] = c1*f[j-1] + c2*f[j-2] + d0*r[i][j];
          
       }

    /* compute backward filter b[j] */
    /* Initialize backward filter */

       sum = 0.0f;

       for (j = m - mavg; j < m; ++j) {
          sum += r[i][j];
       }
       sum /= mavg;
       b[m-1] = sum;
       b[m-2] = sum;
       
/* migrate from top to bottom:  j = m-3 to 0 */

       for (j = m - 3; j > -1; --j) {
          b[j] = c1*b[j+1] + c2*b[j+2] + d0*r[i][j];
       }
       
/* normalize data */

       for (j = 0; j < m; ++j) {

/* find forward filter delay index for f[j] */
          jf = j - jdelay;
          if (jf < 0) {jf = 0;}
          fref = f[jf];

/* find backward filter delay index for b[j] */
          jb = j + jdelay;
          if (jb > m - 1) {jb = m - 1;}
          bref = b[jb];

/* select forward of backwards filter value for normalization. */
          if ((fabsf(r[i][j] - fref)) < (fabsf(r[i][j] - bref))) {
             rmean = fref;
          }
          else {
             rmean = bref;
          }
          
          if ((fabsf(r[i][j] - ravg[i])) < (fabsf(r[i][j] - rmean))) {
             rmean = ravg[i];
          }

          wt = rmean;
          rmed=rin[j][i];
          
          if (wt>0.0f) {
              tem1=1.0f/wt;
              if(tem1>max_scale){tem1=max_scale;}
              rmed=tem1*(rmed-wt)+1.0f;
          }else{
              rmed=1.0f;
          }
          
          if (rmed > 8.0f) {rmed = 8.0f;}

          rin[j][i]=rmed;
       }
    }

/* if *irow>1, then blank out image for i=0,...,*irow1-2 */    
if (*irow1>1) {
   for (j=0; j<m; ++j) {
       for (i=0; i<*irow1-1; ++i) {
           rin[j][i]=1.0f;
       }
   }
}

/*Free memory allocated to rin[m]*/
          free(rin);

/*Free memory allocated to ravg[n]*/
          free(ravg);
/*Free memory allocated to r[n][m]*/
          free(r); free(rc);
/*Free memory allocated to irf[n]*/
          free(irf);
/*Free memory allocated to f[m]*/
          free(f);
/*Free memory allocated to b[m]*/
          free(b);

/* mexPrintf("CR_normalizer_SBR: END\n"); */

    return;
}

float fabsf(float x)
{
  if(x<0.0f){x=-x;}
  return x;
}
/************************************************************************************
*************************************************************************************
************************************************************************************/

/*FAST CONVOLUTION AVERAGER FOR CONSTANT RECTANGULAR MASK (2*nmask+1) by (2*mmask+1)*/

/* Subroutine */ int conv_gjd(float **r, int n, int m, int nmask, int mmask)
{
    /* Local variables */
    int i, j, ndim;
    float wt, tem, sum, *x;
    
/*dynamically allocate memory for x[max(n,m)] */
    ndim=m; if( n > ndim) {ndim = n;}
    if (!(x = (float *) malloc (ndim*sizeof(float)))) {
       mexPrintf("\n Error: Malloc  fails! \n");
       exit(1);
    }
/*************************************************
******* smooth columns ***************************
*************************************************/

    wt = 2.0f*mmask + 1.0f;

    for (i = 0; i < n; ++i) {
       sum = 0.0f;
       /* Sum values along top rows*/
       for (j = 0; j < (2*mmask); ++j) {
          sum += r[i][j];
       }
       tem = 0.0f;
       /*Sum values from from middle rows and put into
       storage x[j]*/
       for (j = mmask; j < (m-mmask); ++j) {
          sum = (sum - tem) + r[i][j + mmask];
          x[j] = sum;
          tem = r[i][j - mmask];
       }
       sum = 0.0f;
       for (j = 0; j < mmask; ++j) {
          sum += r[i][j];
       }
       for (j = mmask; j < (2*mmask); ++j) {
          sum += r[i][j];
         
          x[j - mmask] = wt * sum/(j + 1);
       }
       sum = 0.0f;
       for (j = (m-1); j >(m - mmask - 1); --j) {
          sum += r[i][j];
       }
       for (j = (m - mmask - 1); j > (m - 2*mmask - 1); --j) {
          sum += r[i][j];
          x[j + mmask] = wt*sum/(m - j);
       }
       for (j = 0; j < m; ++j) {
          r[i][j] = x[j];
       }
    }

/*************************************************
******* smooth columns ***************************
*************************************************/
    wt = 2.0f*nmask+1.0f;

    for (j = 0; j < m; ++j) {

       sum = 0.0f;
       for (i = 0; i < (2*nmask); ++i) {
          sum += r[i][j];
       }
       tem = 0.0f;
       for (i = nmask; i < (n-nmask); ++i) {
          sum = (sum - tem) + r[i + nmask][j];
          x[i] = sum;
          tem = r[i - nmask][j];
       }
       sum = 0.0f;
       for (i = 0; i < nmask; ++i) {
          sum += r[i][j];
       }
       for (i = nmask; i < (2*nmask); ++i) {
          sum += r[i][j];
         
          x[i - nmask] = wt * sum/(i + 1);
       }
       sum = 0.0f;
       for (i = (n - 1); i > (n - nmask - 1); --i) {
          sum += r[i][j];
       }
       for (i = (n - nmask - 1); i > (n - 2*nmask - 1) ; --i) {
          sum += r[i][j];
          x[i + nmask] = wt*sum /(n - i);
       }
       for (i = 0; i < n; ++i) {
          r[i][j] = x[i];
       }
    }
    
    wt = 1.0f/((2.0f*nmask+1.0f)*(2.0f*mmask+1.0f));

    for (j = 0; j < m; ++j) {
       for (i = 0; i < n; ++i) {
          r[i][j] *= wt;
       }
    }
/*deallocate memory*/

free(x);

    return 0;

} /* end of conv_gjd */

/************************************************************************************
*************************************************************************************
************************************************************************************/

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
/*
To use in MATLAB, compile in MATLAB as follows:
   >> mex -setup  %the user should reply by selecting the C compiler
   >> mex mex_normalizer.c  %this compiles the C-code that must include the MATLAB gateway routine
   
To execute in MATLAB, at prompt enter:
   
   >> [rout, error_code] = mex_normalizer_SBR(rin, dx, dy, blanked_out_range, depth, ioption);
   
   where
         rout = (output: lhs[0]) smoothed output image; 
                                 pixels normailzed between 0.0 and 8.0.
                with mean level about 1.0)
              = double real array with dimension rout(M, N) where
                          M = no. of range cells (across track)
                          N = no of cross-range cells (along track)
         error_code = (output: lhs[1]) 0 for no error; otherwise an error was detected (double real scalar)
                                       
         rin = (input: rhs[0]) input image
             = double real array with dimension rin(M, N);
          dx = (input: rhs[1]) range resolution in cm (a double real scalar)
          dy = (input: rhs[2]) cross-range resolution in cm (a double real scalar)
          blanked_out_range = (input: rhs[3]) initial range in cm over which the normalized image
                            is banked out; i.e., set to 1 (a double real scalar)
          depth = (input: rhs[4]) array of UUV depths in meters; array length is N;  where
                  depth(i) = UUV depth when image data rin(:,i) was collected. 
                = double real array with dimension depth(N)
               NOTE: depth is used to remove the surface bounce artifact in the REMUS/MSTL-900 sonar.
                     If depth is not available or the sonar is not REMUS/MSTL-900, then set depth = zeros(N,1).
          ioption = (input: rhs[5]) Normalizer selection option (a double real scalar)
                  = 0 for Serpentine Normalizer
                  = 1 for Cross-Range Normalizer
   
    ******************************************************************************
    ABOUT THE 2D arrays used in this C routine:

    To be compatible with MATLAB, the arrays rin and rout are double precision real arrays.
    Therefore one should note, because of the way these arrays are stored in memory and
    the different ways they are referenced by MATLAB and C, that the memory location for
    rin(i,j) in MATLAB is the same as rin[j][i] in C. 

    rin[][] holds the input image and these routines do not modify its contents.
        -- rin[][] refers to the same memory as the MATLAB input image.
        -- If these routine are changed to modify the contents of rin[][], the input image in MATLAB will also be changed.
    rout[][] temporarily holds the de-spiked image; when execution completes, it will hold the normalized image.
        -- rout[][] refers to same memory as the MATLAB output image.
    r[][] is tempory memory that will hold the de-spiked and smoothed image.
    f[][] or f[] is tempory memory that will hold the smooth background image from the forward filter.
    b[][] or f[] is tempory memory that will hold the smooth background image from the backward filter.
    ********************************************************************************
*/ 
{
    double *rout_pr, *rin_pr, dx, dy, blanked_out_range, *depth_ptr, *error_code_pr, ioption;
    int     i, j, ncross_range_cells, nrange_cells;
    float dxsp, dysp, blanked_out_range_sp, *depth, *rin_sp;
    int irow1, irow2, normalizer_error_code;

/* Get pointer to the data */
    rin_pr = mxGetPr(prhs[0]);

/* Get the size of the input array.  In matlab the array is dimensioned M rows by N columns. */
    nrange_cells = mxGetM(prhs[0]);
    ncross_range_cells = mxGetN(prhs[0]);
    
    mexPrintf("mexFunction for mex_normalizer_SBR: START\n");
    mexPrintf("ncross_range_cells=%d nrange_cells=%d\n",ncross_range_cells,nrange_cells);
    
    dx = mxGetScalar(prhs[1]);
    dy = mxGetScalar(prhs[2]);
    blanked_out_range = mxGetScalar(prhs[3]);
    depth_ptr=mxGetPr(prhs[4]);
    ioption = mxGetScalar(prhs[5]);
    mexPrintf("dx=%f dy=%f blanked_out_range=%f ioption=%f \n",dx,dy,blanked_out_range, ioption);

/* Create memory allocation for MATLAB output image and assign a reference pointer */
    plhs[0] = mxCreateDoubleMatrix(nrange_cells, ncross_range_cells, mxREAL);
    rout_pr = mxGetPr(plhs[0]);
    plhs[1] = mxCreateDoubleMatrix(1, 1, mxREAL);
    error_code_pr = mxGetPr(plhs[1]);
        
    if (!(depth = (float *) malloc (ncross_range_cells*sizeof(float)))) {
       mexPrintf("\n Error rout: Malloc  fails! \n");
       exit(1);
    }
    for (j=0; j<ncross_range_cells; ++j) {depth[j]=depth_ptr[j];}
    
/* dynamically allocate memory for rin_sp */
    if (!(rin_sp = (float *) malloc (ncross_range_cells*nrange_cells*sizeof(float)))) {
       mexPrintf("\n Error rout: Malloc  fails! \n");
       exit(1);
    }
    
    for (i=0; i<ncross_range_cells*nrange_cells; ++i) {*(rin_sp+i) = *(rin_pr+i);}
    
    dxsp=dx; dysp=dy;
    blanked_out_range_sp=blanked_out_range;

    
    if (ioption == 0.0) {
        fbrl_normalizer_SBR(rin_sp, &nrange_cells, &nrange_cells, &ncross_range_cells,
                      &irow1, &irow2, &dxsp, &dysp,
                      &blanked_out_range_sp, depth, &normalizer_error_code);
    }else{                  
        CR_normalizer_SBR(rin_sp, &nrange_cells, &nrange_cells, &ncross_range_cells,
                      &irow1, &irow2, &dxsp, &dysp,
                      &blanked_out_range_sp, depth, &normalizer_error_code);
    }
    
    *error_code_pr = (double) normalizer_error_code;
                
    for (i=0; i<ncross_range_cells*nrange_cells; ++i) {*(rout_pr+i) = *(rin_sp+i);}
                      
    free(depth); free(rin_sp);
    
    mexPrintf("mexFunction for mex_normalizer_SBR: END\n");

    return;
}
