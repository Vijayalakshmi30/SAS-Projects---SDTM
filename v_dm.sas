/*log file*/
proc printto log='/home/u63774111/Project/Log files/v_dm.log';

libname sasval "/home/u63774111/Project/Project_2/xpt_sas_val"; 
libname val xport "/home/u63774111/Project/Project_2/Validation/dm.xpt" access=readonly; 
proc copy inlib=val outlib=sasval; 
run; 

/*Created file*/
libname mysdtm '/home/u63774111/Project/Output';

/*Validation dm file*/
libname sasval "/home/u63774111/Project/Project_2/xpt_sas_val";


/*Comparison Summary*/
options nodate nonumber;
ods pdf file='/home/u63774111/Project/Output/compare_dm.pdf';
proc compare base=mysdtm.dm compare=sasval.dm;
run;
ods pdf close;

/*=====================================================*/

/*Detailed comparison*/
proc compare base=MYSDTM.DM compare=SASVAL.DM out=compare_result outnoequal outbase outcomp outdif;
    id SUBJID;
run;

/* Review the differences */
proc print data=compare_result;
run;

proc printto;
run;