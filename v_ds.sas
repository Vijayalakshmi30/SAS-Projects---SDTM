/*log file*/
proc printto log='/home/u63774111/Project/Log files/v_ds.log';

/*Created file*/
libname mysdtm '/home/u63774111/Project/Output';

/*Validation dm file*/
libname sasval "/home/u63774111/Project/Project_2/xpt_sas_val";


/*Comparison Summary*/
options nodate nonumber;
ods pdf file='/home/u63774111/Project/Output/compare_ds.pdf';
proc compare base=mysdtm.ds compare=sasval.ds;
run;
ods pdf close;

proc printto;
run;