/*log file*/
proc printto log='/home/u63774111/Project/Log files/v_ex.log';

/*Created file*/
libname mysdtm '/home/u63774111/Project/Output';

/*Validation dm file*/
libname sasval "/home/u63774111/Project/Project_2/xpt_sas_val";


/*Comparison Summary*/
options nodate nonumber;
ods pdf file='/home/u63774111/Project/Output/compare_ex.pdf';
proc compare base=mysdtm.ex compare=sasval.ex;
run;
ods pdf close;

proc printto;
run;