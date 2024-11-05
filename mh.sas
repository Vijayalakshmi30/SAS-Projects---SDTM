/*log file*/
proc printto log='/home/u63774111/Project/Log files/mh.log';

libname raw "/home/u63774111/Project/Project_2/Raw_CRF";

/*Initially, 200 rows; 45 columns*/

data data1;
set raw.mh;
run; 
proc print;


/*To see the variable names in raw DM data*/
proc contents data=data1 varnum;
run;

 
/*MHDTC & r_date for MHDY*/
data data2(keep=SUBJECT MHDTC MHENTPT r_date);
label MHDTC='Date/Time of History Collection'
      MHENTPT='End Reference Time Point';
set raw.dov;
where INSTANCENAME='Screening';
MHDTC=put(datepart(VISDTN), yymmdd10.);
MHENTPT=put(datepart(VISDTN), yymmdd10.);
r_date=datepart(RECORDDATE);
run;

/*Merging data1 and data2 on SUBJECT*/
proc sort data=data1 out=sort_data1;
by SUBJECT;
run;

proc sort data=data2 out=sort_data2;
by SUBJECT;
run;

data data3;
merge sort_data1(in=a) sort_data2(in=b);
by SUBJECT;
if a;
run;


/*MHDY*/
/*Finding baseline date ie date of 1st drug dose*/
data data4;
set raw.ex;
if exdose>0;
run;

proc sort data=data4;
by SUBJECT EXSTDTN;
run;

data data5(keep=SUBJECT date_baseline r_date);
set data4;
by SUBJECT EXSTDTN;
if first.SUBJECT;
date_baseline=datepart(EXSTDTN);
run;

/*Merging data3 and data5 by Subject*/
proc sort data=data3;
by SUBJECT;
run;

proc sort data=data5;
by SUBJECT;
run;

data data6;
merge data3(in=a) data5(in=b);
by SUBJECT;
if a;
run;

/*Constructing MHDY variable*/
data data7;
set data6;
label MHDY='Study Day of History Collection';
if r_date >= date_baseline then MHDY=(r_date-date_baseline+1);
else MHDY=(r_date-date_baseline);
run;

/*For MHDY, deriving r_date from dov dataset and baseline_date from ex dataset*/

/* Creating SDTM data: v1 */
data data8;
retain STUDYID DOMAIN MHTERM MHLLTCD MHDECOD MHPTCD MHHLT MHHLTCD MHHLGT MHHLGTCD MHCAT MHBODSYS MHBDSYCD MHSOC MHSOCCD USUBJID;
label STUDYID='Study Identifier'
      DOMAIN='Domain Abbreviation'
      MHTERM='Reported Term for the Medical History'
      MHLLT='Lowest Level Term'
      MHLLTCD='Lowest Level Term Code'
      MHDECOD='Dictionary-Derived Term'
      MHPTCD='Preferred Term Code'
      MHHLT='High Level Term'
      MHHLTCD='High Level Term Code'
      MHHLGT='High Level Group Term'
      MHHLGTCD='High Level Group Term Code'
      MHCAT='Category for Medical History'
      MHBODSYS='Body System or Organ Class'
      MHBDSYCD='Body System or Organ Class Code'
      MHSOC='Primary System Organ Class'
      MHSOCCD='Primary System Organ Class Code'
      MHSTDTC='Start Date/Time of Medical History Event'
      MHENDTC='End Date/Time of Medical History Event'
      MHENRTPT='End Relative to Reference Time Point'
      MHLLT='Lowest Level Term';
length USUBJID $40 MHTERM $64 MHDECOD $40 MHHLT $65 MHHLGT $86 MHBODSYS $67 MHSOC $67 MHLLT $35;
set data7;
STUDYID='CMP135';
DOMAIN='MH';
USUBJID=catx('-',STUDYID, SUBJECT);
MHTERM=strip(MHTERM);
MHLLT=MHTERM_LLT;
MHLLTCD=input(MHTERM_LLT_CODE,best.);
MHDECOD=MHTERM_PT;
MHPTCD=input(MHTERM_PT_CODE,best.);
MHHLT=MHTERM_HLT;
MHHLTCD=input(MHTERM_HLT_CODE,best.);
MHHLGT=MHTERM_HLGT;
MHHLGTCD=input(MHTERM_HLGT_CODE,best.);
MHCAT='GENERAL MEDICAL HISTORY';
MHBODSYS=MHTERM_SOC;
MHBDSYCD=input(MHTERM_SOC_CODE, best.);
MHSOC=MHTERM_SOC;
MHSOCCD=input(MHTERM_SOC_CODE,best.);
MHSTDTC=put(mdy(MHSTDTN_MM,MHSTDTN_DD,MHSTDTN_YY), yymmdd10.);
MHLLT=MHTERM_LLT;
if MHSTDTC=. then do;
MHSTDTC = catx('-', 
                      ifc(not missing(MHSTDTN_YY), put(MHSTDTN_YY, 4.), ''),
                      ifc(not missing(MHSTDTN_MM), put(MHSTDTN_MM, z2.), ''),
                      ifc(not missing(MHSTDTN_DD), put(MHSTDTN_DD, z2.), '')
                      );
    end;
MHENDTC=put(mdy(MHENDTN_MM,MHENDTN_DD,MHENDTN_YY), yymmdd10.);
if MHENDTC=. then do;
MHENDTC = catx('-', 
                      ifc(not missing(MHENDTN_YY), put(MHENDTN_YY, 4.), ''),
                      ifc(not missing(MHENDTN_MM), put(MHENDTN_MM, z2.), ''),
                      ifc(not missing(MHENDTN_DD), put(MHENDTN_DD, z2.), '')
                      );
    end;
if MHONG='1' then MHENRTPT='ONGOING';
else do;
MHENRTPT='';
MHENTPT='';
end;
run;
proc print;


/*MHSEQ*/
proc sort data=data8 out=sort_data8;
by STUDYID USUBJID MHTERM;
run;

data data9;
label MHSEQ='Sequence Number';
set sort_data8;
by STUDYID USUBJID MHTERM;
if first.USUBJID then MHSEQ=0;
MHSEQ+1;
run;


/* Creating SDTM data: v2 */
data mysdtm.mh;
retain STUDYID DOMAIN MHSEQ MHTERM MHLLT MHLLTCD MHDECOD MHPTCD MHHLT MHHLTCD MHHLGT MHHLGTCD MHCAT MHBODSYS MHBDSYCD MHSOC MHSOCCD MHDTC MHSTDTC MHENDTC MHDY MHENRTPT MHENTPT USUBJID;
keep STUDYID DOMAIN USUBJID MHTERM MHLLT  MHLLTCD MHDECOD MHPTCD MHHLT MHHLTCD MHHLGT MHHLGTCD MHCAT MHBODSYS MHBDSYCD MHSOC MHSOCCD MHDTC MHSTDTC MHENDTC MHENRTPT MHDY MHSEQ MHENTPT;
set data9;
run;
PROC PRINT;

proc contents data=mysdtm.mh varnum;
run;


proc printto;
run;

/*Reference:
  =========
Working SDTM-Spec-v1.xls
ex.xpt
Reference Code
*/