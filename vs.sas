/*log file*/
proc printto log='/home/u63774111/Project/Log files/vs.log';

libname raw "/home/u63774111/Project/Project_2/Raw_CRF";

data data1;
set raw.vs;
run;

proc format;
value $vstestcd
      'Temperature'='TEMP'
      'Respiratory rate'='RESP'
      'Heart rate'='HR'
      'Weight'='WEIGHT'
      'Height'='HEIGHT'
      'Systolic blood pressure'='SYSBP'
      'Diastolic blood pressure'='DIABP';
value $vsorresu
      'ºC'='C'
      'beats/minut'='BEATS/MIN'
      'breaths/min'='BREATHS/MIN'
      'cm'=' '
      'kg'=' ';
run;


data data2(drop=VSORRES VSTEST VSORRESU rename=(VSORRES1=VSORRES VSTEST1=VSTEST VSORRESU1=VSORRESU));
label STUDYID='Study Identifier'
      DOMAIN='Domain Abbreviation'
      USUBJID='Unique Subject Identifier'
      VSTESTCD='Vital Signs Test Short Name'
      VSCAT='Category for Vital Signs'
      VSORRES1='Result or Finding in Original Units'
      VSSTRESC='Character Result/Finding in Std Format'
      VSSTRESN='Numeric Result/Finding in Standard Units'
      VSSTRESU='Standard Units'
      VSSTAT='Completion Status'
      VSBLFL='Baseline Flag'
      VSDTC='Date/Time of Measurements'
      VSTEST1='Vital Signs Test Name'
      VSORRESU1='Original Units';
length VSTESTCD $6 USUBJID $16 VSCAT $23 VSORRESU $11;
set data1;
STUDYID = 'CMP135';
DOMAIN = 'VS';
USUBJID = catx('-',STUDYID,SUBJECT);
VSTESTCD=put(VSTEST,$vstestcd.);
VSCAT=DATAPAGENAME;
VSORRESU1=put(VSORRESU,$vsorresu.);
VSORRES1=strip(put(VSORRES,5.));
VSSTRESC=VSORRES1;
VSSTRESN=round((VSORRES1*0.1), 0.0001);
VSSTRESU=VSORRESU1;
if VSORRES_RAW in ('ND','U','X') then VSSTAT='NOT DONE';
if VSCAT='Vital Signs Day 1' then VSBLFL='Y';
VSDTC=put(datepart(RECORDDATE), yymmdd10.);
VSTEST1=propcase(VSTEST);
run;


/*VSDY*/
data data3;
set raw.ex;
if exdose>0;
run;

proc sort data=data3 out=sort_data3;
by SUBJECT EXSTDTN;
run;

data data4(keep=SUBJECT date_baseline);
set sort_data3;
by SUBJECT;
if first.SUBJECT;
date_baseline=datepart(EXSTDTN);
run;

/*Merging data3 and data5*/
proc sort data=data2 out=sort_data2;
by SUBJECT;
run;

proc sort data=data4 out=sort_data4;
by SUBJECT;
run;

data data5;
merge sort_data2(in=a) sort_data4(in=b);
by SUBJECT;
/*Unschedule visit should be below after schedule at same visit*/
if FOLDER='SRV' or FOLDER='UNS' then ordl=2;
else ordl=0;
run;

proc sort data=data5 out=sort_data5;
by SUBJECT VSTEST VSDTC ordl;
run;

/*VSDY*/
data data6;
label VSDY='Study Day of Vital Signs';
set sort_data5;
by SUBJECT VSTEST VSDTC ordl;
if input(VSDTC,yymmdd10.) >= date_baseline then VSDY=(input(VSDTC,yymmdd10.)-date_baseline+1);
else VSDY=(input(VSDTC,yymmdd10.)-date_baseline);
run;

/*VISIT and VISITNUM*/
data data7;
label VISITNUM='Visit Number'
      VISIT='Visit Name';
set data6;
retain retain_visit;
if first.VSTEST then retain_visit=.;
length VISIT $14;
if FOLDER='SCREENING' then do;
   VISIT='Screening';
   VISITNUM=-1;
   end;
else if index(upcase(FOLDER),'WEEK') then do;
   VISITNUM=input(compress(FOLDER,'','a'),best12.)*7-6;
   VISIT=INSTANCENAME;
   retain_visit=VISITNUM;
   end;
else if index(upcase(FOLDER),'SRV') then do;
   VISITNUM=retain_visit+0.01;
   VISIT='Systemic'||'-'||strip(put(VISITNUM, best12.));
   end;
else if index(upcase(FOLDER),'UNS') then do;
   VISITNUM=retain_visit+0.01;
   VISIT='Unsched'||'-'||strip(put(VISITNUM, best12.));
   end;
   
/*SE data for EPOCH*/
data data8;
set raw.se;
run;

/*Transposing Start dates*/
proc transpose data=data8 out=transp_data8(drop=_:) prefix=ST_;
by USUBJID;
id ETCD;
var SESTDTC;
run;

proc transpose data=data8 out=transp1_data8(drop=_:) prefix=EN_;
by USUBJID;
id ETCD;
var SEENDTC;
run;

/*Get EPOCH from SE domain by checking dates of DSSTDTC between SESTSTC and SEENDTC*/
data data9;
attrib EPOCH label='Epoch' length=$11;
merge data7 transp_data8 transp1_data8;
by USUBJID;
     if input(ST_FU, yymmdd10.) <= input(VSDTC, yymmdd10.) <= input(EN_FU, yymmdd10.) then EPOCH='FOLLOW-UP';
     else if input(ST_P3, yymmdd10.) <= input(VSDTC, yymmdd10.) <= input(EN_P3, yymmdd10.) then EPOCH='MAINTENANCE';
     else if input(ST_P2, yymmdd10.) <= input(VSDTC, yymmdd10.) <= input(EN_P2, yymmdd10.) then EPOCH='TITRATION';
     else if input(ST_P1, yymmdd10.) <= input(VSDTC, yymmdd10.) <= input(EN_P1, yymmdd10.) then EPOCH='INDUCTION';
     else if input(ST_SCRN, yymmdd10.) <= input(VSDTC, yymmdd10.) <= input(EN_SCRN, yymmdd10.) then EPOCH='SCREENING';
run;

/*VSSEQ*/
proc sort data=data9 out=sort_data9;
by STUDYID USUBJID VSTESTCD VISITNUM;
run;

data data10;
label VSSEQ='Sequence Number';
set sort_data9;
by STUDYID USUBJID VSTESTCD VISITNUM;
if first.USUBJID then VSSEQ=0;
VSSEQ+1;
run;


/*SDTM data for VS*/
libname mysdtm '/home/u63774111/Project/Output';

data mysdtm.vs;
retain STUDYID DOMAIN USUBJID VSSEQ VSTESTCD VSTEST VSCAT VSORRES VSORRESU VSSTRESC VSSTRESN VSSTRESU VSSTAT VSBLFL VISITNUM VISIT EPOCH VSDTC VSDY;
keep STUDYID DOMAIN USUBJID VSSEQ VSTESTCD VSTEST VSCAT VSORRES VSORRESU VSSTRESC VSSTRESN VSSTRESU VSSTAT VSBLFL VISITNUM VISIT EPOCH VSDTC VSDY VSDTN;
set data10;
run;

proc contents data=mysdtm.vs varnum;
run;

proc printto;
run;