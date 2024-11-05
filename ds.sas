/*log file*/
proc printto log='/home/u63774111/Project/Log files/ds.log';

libname raw "/home/u63774111/Project/Project_2/Raw_CRF";

/*Using 3 datasets:
1. enr data for INFORMED CONSENT records
2. ds data for END OF STUDY records
3. dsdd data for STUDY DISCONTINUATION records
4. se data for EPOCH*/


/*Enrollment data for INFORMED CONSENT*/
data data1;
label STUDYID='Study Identifier'
      DOMAIN='Domain Abbreviation'
      DSTERM='Reported Term for the Disposition Event'
      DSDECOD='Standardized Disposition Term'
      DSCAT='Category for Disposition Event'
      DSSTDTC='Start Date/Time of Disposition Event'
      DSSCAT='Subcategory for Disposition Event';
length USUBJID $40 DSSCAT $26;
Keep SUBJECT STUDYID DOMAIN DSTERM DSDECOD DSCAT DSSCAT DSSTDTC USUBJID;
set raw.enr;
STUDYID='CMP135';
DOMAIN='DS';
USUBJID=catx('-',STUDYID,SUBJECT);
if DATAPAGENAME='System Enrollment' then do;
   DSSTDTC= put(datepart(CNSTDTN), yymmdd10.);
   DSTERM= 'INFORMED CONSENT OBTAINED';
   DSDECOD= 'INFORMED CONSENT OBTAINED';
   DSCAT= 'PROTOCOL MILESTONE';
   DSSCAT= 'INFORMED CONSENT';
   end;
run; 


/*Disposition data for END OF STUDY*/

data data2;
label STUDYID='Study Identifier'
      DOMAIN='Domain Abbreviation'
      DSDECOD='Standardized Disposition Term'
      DSCAT='Category for Disposition Event'
      DSSTDTC='Start Date/Time of Disposition Event'
      DSSCAT='Subcategory for Disposition Event';
length USUBJID $40 DSSCAT $26;
Keep SUBJECT STUDYID DOMAIN DSTERM DSDECOD DSCAT DSSCAT DSSTDTC USUBJID;
set raw.ds;
STUDYID='CMP135';
DOMAIN='DS';
USUBJID=catx('-',STUDYID,SUBJECT);
if DATAPAGENAME='Subject Disposition (End of Study)' then do;
   DSSTDTC= put(datepart(DSSTDAT), yymmdd10.);
   DSTERM= 'COMPLETED';
   DSDECOD= 'COMPLETED';
   DSCAT= 'DISPOSITION EVENT';
   DSSCAT= 'END OF STUDY';
   end;
run;


/*dsdd data for STUDY DISCONTINUATION*/
data data3;
label STUDYID='Study Identifier'
      DOMAIN='Domain Abbreviation'
      DSDECOD='Standardized Disposition Term'
      DSCAT='Category for Disposition Event'
      DSSTDTC='Start Date/Time of Disposition Event'
      DSSCAT='Subcategory for Disposition Event';
length USUBJID $40 DSSCAT $26;
Keep SUBJECT STUDYID DOMAIN DSTERM DSDECOD DSCAT DSSCAT DSSTDTC USUBJID;
set raw.dsdd;
STUDYID='CMP135';
DOMAIN='DS';
USUBJID=catx('-',STUDYID,SUBJECT);
if DATAPAGENAME='Study Drug Discontinuation' then do;
   DSSTDTC= put(datepart(DSSTDTN), yymmdd10.);
   DSTERM= 'ADVERSE EVENT';
   DSDECOD= 'ADVERSE EVENT';
   DSCAT= 'DISPOSITION EVENT';
   DSSCAT= 'STUDY DRUG DISCONTINUATION';
   end;
run;

/*Concatenating 3 datasets*/
data data4;
set data1 data2 data3;
run;


/*Determining baseline date (Date of first drug dose)*/
data data5;
set raw.ex;
if exdose>0;
run;

proc sort data=data5 out=sort_data5;
by SUBJECT EXSTDTN;
run;

data data6(keep=SUBJECT date_baseline);
set sort_data5;
by SUBJECT EXSTDTN;
if first.SUBJECT;
date_baseline=datepart(EXSTDTN);
run;


/*Merging data4 and data6*/
proc sort data=data4 out=sort_data4;
by SUBJECT;
run;

proc sort data=data6 out=sort_data6;
by SUBJECT;
run;

data data7;
merge sort_data4(in=a) sort_data6(in=b);
by SUBJECT;
if a;
run;


/*DSSTDY*/
data data8;
label DSSTDY='Study Day of Start of Disposition Event';
set data7;
if input(DSSTDTC, yymmdd10.)>=date_baseline then DSSTDY=(input(DSSTDTC,yymmdd10.)-date_baseline+1);
else DSSTDY=(input(DSSTDTC,yymmdd10.)-date_baseline);
run;


/*EPOCH*/
data data9;
set raw.se;
run;

/*Transposing Start Dates*/
proc transpose data=data9 out=transp_data9(drop=_:) prefix=ST_;
by USUBJID;
id ETCD;
var SESTDTC;
run;

/*Transposing End Dates*/
proc transpose data=data9 out=transp1_data9(drop=_:) prefix=EN_;
by USUBJID;
id ETCD;
var SEENDTC;
run;

/*Get EPOCH from SE domain by checking dates of DSSTDTC between SESTDTC and SEENDTC*/
data data10;
label EPOCH='Epoch';
length USUBJID $40 EPOCH $11;
merge data8 transp_data9 transp1_data9;
by USUBJID;
/*EPOCH is derived for records with DSCAT NE PROTOCOL MILESTONE i.e. Disposition event*/
if DSCAT NE 'PROTOCOL MILESTONE' then do;
     if input(ST_FU, yymmdd10.) <= input(DSSTDTC, yymmdd10.) <= input(EN_FU, yymmdd10.) then EPOCH='FOLLOW-UP';
     else if input(ST_P3, yymmdd10.) <= input(DSSTDTC, yymmdd10.) <= input(EN_P3, yymmdd10.) then EPOCH='MAINTENANCE';
     else if input(ST_P2, yymmdd10.) <= input(DSSTDTC, yymmdd10.) <= input(EN_P2, yymmdd10.) then EPOCH='TITRATION';
     else if input(ST_P1, yymmdd10.) <= input(DSSTDTC, yymmdd10.) <= input(EN_P1, yymmdd10.) then EPOCH='INDUCTION';
     else if input(ST_SCRN, yymmdd10.) <= input(DSSTDTC, yymmdd10.) <= input(EN_SCRN, yymmdd10.) then EPOCH='SCREENING';
     end;
run;


/*DSSEQ*/
proc sort data=data10 out=sort_data10;
by STUDYID USUBJID DSDECOD DSSTDTC;
run;

data data11;
label DSSEQ='Sequence Number';
set sort_data10;
by STUDYID USUBJID DSDECOD DSSTDTC;
if first.USUBJID then DSSEQ=0;
DSSEQ+1;
run;


/*SDTM data for DS*/
libname mysdtm '/home/u63774111/Project/Output';

data mysdtm.ds;
retain STUDYID DOMAIN DSSEQ DSTERM DSDECOD DSCAT DSSCAT EPOCH DSSTDTC DSSTDY USUBJID;
keep STUDYID DOMAIN DSSEQ DSTERM DSDECOD DSCAT DSSCAT EPOCH DSSTDTC DSSTDY USUBJID;
set data11;
run;

proc contents data=mysdtm.ds varnum;
run;

proc print data=mysdtm.ds;
run;


proc printto;
run;

/*REFERENCE:
Working SDTM-Spec-v1.xls
ds.xpt
Reference Code
*/
