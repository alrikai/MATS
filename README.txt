  *******************************************************************
  ***  INFORMATION ABOUT Modular ATR Testing Suite (MATS) v1.0    ***
  *******************************************************************
                      20 October 2011

The Modular Algorithm Testing Suite (MATS) is a software package for the development and 
testing of automatic target recognition (ATR) algorithms.  It employs an open, modular
architecture to provide ATR developers with a quick and easy way to test and compare
algorithms.

***Required Software - MATLAB version 2009b or later and the Image Processing Toolbox***

We would appreciate it if you would acknowledge NSWC - Panama City Division, 
Panama City, Florida, as the source of the software in any publication 
where you use this software. Additionally, we request you send us a copy
of any publication or report that uses the software via mail at:

Naval Surface Warfare Center 
Panama City Division - Code X13
110 Vernon Ave
Panama City, FL 32407 
Attn: Derek Kolacinski / Michael Rowe

or via email at to one of the addresses in the following paragraph.

Refer questions to Derek Kolacinski NSWC Panama City Division, Code X13 (850)-230-7218 
derek.kolacinski@navy.mil, (850) 235-5277 (secretary), (850) 235-5374 (FAX),

or

Michael Rowe NSWC Panama City Division, Code X13 (850)-235-5579 
michael.a.rowe@navy.mil, (850) 235-5277 (secretary), (850) 235-5374 (FAX)

Also, if you produce any new features or functions for MATS we would appreciate
that you send the files to the individuals listed above.  That way any future 
releases of MATS can include any new features or functions that have been developed.  

DISTRIBUTION STATEMENT A. Approved for public release; distribution is unlimited.


Below is a full list of files that should be on the MATS CD.  If any of these files 
are missing contact the individuals above. 

You should copy the MATS v1.0 folder over to your computer before running the software.

MATS V1.0:
   README.txt
   atr_testbed_altfb.m
   dev_clean.m
   run_cont_correlation.m
   testbed_gui.m
   write_calls_file.m

   AC Prep:
      acprep.m
      modDeps.m

      local:
         imapContact.m
         istolt.m
         secant.m
         stolt.m

   ATR Core:
      calcdistbear.m
      delete_flag.m
      detsub_contact_fill.m
      detsub_gt.m
      feature_snippet.m
      find_last_locked.m
      find_last_viewed.m
      general_display.m
      geolocate.m
      load_old_results.m
      make_bg_snippet.m
      make_snippet_alt.m
      mstl_colors_ascii.txt
      normalize_images.m
      overwrite_backups.m
      read_backups.m
      read_contacts.m
      read_feedback.m
      read_lock_index.m
      reset_opfile_cnt.m
      sort_contacts.m
      wait_if_flag.m
      write_backups.m
      write_contacts.m
      write_flag.m

   Classifiers:

      Test:
         about.txt
         cls_Test.m
         data_bogus_default.mat

   Contact Correlation:

      Test:
         cor_Test.m

   Data Readers:
      bravo_gt_reader.m
      csdt_reader.m
      gen_input_struct_bravo.m
      hdf5_gt_reader.m
      hdf5_reader.m
      mat_reader.m
      mats_struct_reader.m
      mymat_gt_reader.m
      mymat_reader.m
      nswc_gt_reader.m
      nswc_reader.m
      nurc_gt_reader.m
      nurc_reader.m
      pcswat_gt_reader.m
      pcswat_reader.m
      pond_reader.m
      scrub_gt_reader.m
      scrub_reader.m

      common:
         calc_sweetspot.m

      csdt:
         read_csdt.m

      hdf5:
         calcNominalHeading.m
         readHDF5_mcmSpec.m

      mymat:
         calcpingimg.m
         default.m
         drillstruct.m
         header.m
         location.m
         myload.m
         mysave.m
         translate.m

   Detectors:

      Test:
         about.txt
         det_Test.m

   Docs:
      Testbed IO chart.pdf

      MATS_Manual:
         MATS_Manual.pdf

   Features:

      No_extra:
         about.txt
         feat_No_extra.m

   Feedback:
      append_feedback.m
      append_opgen_contact.m
      opfeedback_stub.m

   GUI:
      abbrev_string.m
      bravo_input_sim.m
      compare_results.m
      compare_roc.m
      confusion_series.m
      fuf.m
      gen_file_list.m
      gen_proc_file_list.m
      get_format_dlg.m
      import_classdata.m
      import_modules.m
      load_prep.m
      read_desc_file.m
      retrain_prep.m
      roc_series.m
      update_cls_desc_params.m
      update_det_desc_params.m
      update_feat_desc_params.m

      DB_Tool:
         add_contacts.m
         check_fields.m
         filter_db.m
         load_db.m
         save_db.m
         scan_contacts.m
         show_db.m
         sort_db.m

   Misc:
      searchfile.m
      searchfolder.m
      whereis.m

   Performance Estimation:

      Test:
         perf_Test.m

   description:

      description:



 
 