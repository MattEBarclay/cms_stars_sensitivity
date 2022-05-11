/******************************************************************************/
/* 	LOAD DATA CMS
	
	This file loads data from the 2021 CSVs, including hospital information
	and the overall star rating.
	
	Matthew Barclay
	2022-02-21
*/

clear
cap log c


/******************************************************************************/
/* Load data 																  */


********************************************************************************
* Hospital names and real star rating 
*import delimited using raw_data/Hospital_General_Information.csv, clear stringcols(_all) 
import delimited using "../CMS Stars 2021 underlying data\hospitals_04_2021/Hospital_General_Information.csv", clear stringcols(_all) 

keep facilityid facilityname state hospitaltype hospitaloverallrating
replace facilityname = proper(facilityname)
replace hospitaloverallrating = "" if hospitaloverallrating == "Not Available"
destring hospitaloverallrating, replace

rename (facilityname hospitaltype hospitaloverallrating) (name type real_rating)

replace name = subinstr(name, " Of ", " of ", .)
replace name = subinstr(name, " The ", " the ", .)
replace name = subinstr(name, " And ", " and ", .)
replace name = subinstr(name, "Usa ", "USA ", .)
replace name = subinstr(name, "Llc", "LLC", .)
save data/star_data_2021, replace


********************************************************************************
* Mortality measures
*import delimited using raw_data/Complications_and_Deaths-Hospital.csv, clear stringcols(_all) 
import delimited using "../CMS Stars 2021 underlying data\hospitals_archive_10_2020/ynj2-r877.csv", clear stringcols(_all) 

keep facilityid measureid score

keep if substr(measureid,1,5) == "MORT_" | measureid == "PSI_4_SURG_COMP"
replace score = "" if score == "Not Available"
destring score, replace

replace measureid = "1" if measureid == "MORT_30_AMI"
replace measureid = "2" if measureid == "MORT_30_CABG"
replace measureid = "3" if measureid == "MORT_30_COPD"
replace measureid = "4" if measureid == "MORT_30_HF"
replace measureid = "5" if measureid == "MORT_30_PN"
replace measureid = "6" if measureid == "MORT_30_STK"
replace measureid = "7" if measureid == "PSI_4_SURG_COMP"
destring measureid, replace

rename score mortality_
reshape wide mortality_ , i(facilityid) j(measureid)

label var mortality_1 "Death rate for heart attack patients"
label var mortality_2 "Death rate for CABG surgery patients"
label var mortality_3 "Death rate for COPD patients"
label var mortality_4 "Death rate for heart failure patients"
label var mortality_5 "Death rate for pneumonia patients"
label var mortality_6 "Death rate for stroke patients"
label var mortality_7 "Deaths among Patients with Serious Treatable Complications after Surgery"

merge 1:1 facilityid using data/star_data_2021
drop if _merge == 1 /* master only */
drop _merge
save data/star_data_2021, replace
 

********************************************************************************
* Safety measures
* also muwa-iene.csv - PSI-90 components
tempfile s1 s2

* file 1
*import delimited using raw_data/Healthcare_Associated_Infections-Hospital.csv, clear stringcols(_all) 
import delimited using "../CMS Stars 2021 underlying data\hospitals_archive_10_2020/77hc-ibv8.csv", clear stringcols(_all) 
keep facilityid measureid score

keep if inlist(measureid, "HAI_1_SIR", "HAI_2_SIR", "HAI_3_SIR", "HAI_4_SIR", "HAI_5_SIR", "HAI_6_SIR")
replace score = "" if score == "Not Available"
destring score, replace

replace measureid = "1" if measureid == "HAI_1_SIR"
replace measureid = "2" if measureid == "HAI_2_SIR"
replace measureid = "3" if measureid == "HAI_3_SIR"
replace measureid = "4" if measureid == "HAI_4_SIR"
replace measureid = "5" if measureid == "HAI_5_SIR"
replace measureid = "6" if measureid == "HAI_6_SIR"
destring measureid, replace

rename score safety_
reshape wide safety_ , i(facilityid) j(measureid)

label var safety_1 "Central line-associated bloodstream infections (CLABSI)"
label var safety_2 "Catheter-associated urinary tract infections (CAUTI)"
label var safety_3 "Surgical site infections from colon surgery (SSI: Colon)"
label var safety_4 "Surgical site infections from abdominal hysterectomy (SSI: Hysterectomy)"
label var safety_5 "MRSA bloodstream infections"
label var safety_6 "C. diff bloodstream infections"
save `s1'

* file 2
*import delimited using raw_data/Complications_and_Deaths-Hospital.csv, clear stringcols(_all) 
import delimited using "../CMS Stars 2021 underlying data\hospitals_archive_10_2020/ynj2-r877.csv", clear stringcols(_all) 

keep facilityid measureid score

keep if inlist(measureid, "COMP_HIP_KNEE", "PSI_90_SAFETY")
replace score = "" if score == "Not Available"
destring score, replace

replace measureid = "7" if measureid == "COMP_HIP_KNEE"
replace measureid = "8" if measureid == "PSI_90_SAFETY"
destring measureid, replace

rename score safety_
reshape wide safety_ , i(facilityid) j(measureid)

label var safety_7 "Rate of complications for hip/knee replacement patients"
label var safety_8 "Serious complications (PSI 90)"
save `s2'

use `s1'
merge 1:1 facilityid using `s2'
assert _merge == 3
drop _merge
merge 1:1 facilityid using data/star_data_2021
drop if _merge == 1 /* master only */
drop _merge
save data/star_data_2021, replace


********************************************************************************
* Readmission measures
*import delimited using raw_data/Unplanned_Hospital_Visits-Hospital.csv, clear stringcols(_all) 
import delimited using "../CMS Stars 2021 underlying data\hospitals_archive_10_2020/632h-zaca.csv", clear stringcols(_all) 

keep facilityid measureid measurename score

replace score = "" if score == "Not Available"
destring score, replace

drop if inlist(measureid, "EDAC_30_AMI", "EDAC_30_HF", "EDAC_30_PN")

replace measureid =  "1" if measureid == "READM_30_AMI"
replace measureid =  "2" if measureid == "READM_30_CABG"
replace measureid =  "3" if measureid == "READM_30_COPD"
replace measureid =  "4" if measureid == "READM_30_HF"
replace measureid =  "5" if measureid == "READM_30_HIP_KNEE"
replace measureid =  "6" if measureid == "READM_30_PN"
replace measureid =  "7" if measureid == "READM_30_HOSP_WIDE"
replace measureid =  "8" if measureid == "OP_32"
replace measureid =  "9" if measureid == "OP_35_ADM"
replace measureid = "10" if measureid == "OP_35_ED"
replace measureid = "11" if measureid == "OP_36"
destring measureid, replace

drop measurename

rename score readm_
reshape wide readm_ , i(facilityid) j(measureid)

label var readm_1 "Acute Myocardial Infarction (AMI) 30-Day Readmission Rate"
label var readm_2 "Rate of readmission for CABG"
label var readm_3 "Rate of readmission for chronic obstructive pulmonary disease (COPD) patients"
label var readm_4 "Heart failure (HF) 30-Day Readmission Rate"
label var readm_5 "Rate of readmission after hip/knee replacement"
label var readm_6 "Pneumonia (PN) 30-Day Readmission Rate"
label var readm_7  "Rate of readmission after discharge from hospital (hospital-wide)"
label var readm_8  "Rate of unplanned hospital visits after colonoscopy (per 1,000 colonoscopies)"
label var readm_9  "Rate of inpatient admissions for patients receiving outpatient chemotherapy"
label var readm_10 "Rate of emergency department (ED) visits for patients receiving outpatient chemotherapy"
label var readm_11 "Ratio of unplanned hospital visits after hospital outpatient surgery"

merge 1:1 facilityid using data/star_data_2021
drop if _merge == 1 /* master only */
drop _merge
save data/star_data_2021, replace
 

********************************************************************************
* Patient experience measures
*import delimited using raw_data/HCAHPS-Hospital.csv, clear stringcols(_all) 
import delimited using "../CMS Stars 2021 underlying data\hospitals_archive_10_2020/dgck-syfz.csv", clear stringcols(_all) 
keep facilityid hcahpsmeasureid hcahpsanswerpercent
rename hcahpsmeasureid measureid
rename hcahpsanswerpercent score

replace measureid = "1" if measureid == "H_COMP_1_A_P"
replace measureid = "2" if measureid == "H_COMP_2_A_P"
replace measureid = "3" if measureid == "H_CALL_BUTTON_A_P"
replace measureid = "4" if measureid == "H_COMP_5_A_P"
replace measureid = "5" if measureid == "H_CLEAN_HSP_A_P" | measureid == "H_QUIET_HSP_A_P"
replace measureid = "6" if measureid == "H_COMP_6_Y_P"
replace measureid = "7" if measureid == "H_COMP_7_A" | measureid == "H_COMP_7_SA"
replace measureid = "8" if measureid == "H_HSP_RATING_9_10" | measureid == "H_RECMND_DY"
keep if inlist(measureid, "1" , "2", "3", "4", "5", "6", "7", "8")
destring measureid, replace

replace score = "" if score == "Not Available"
destring score, replace
gen score2 = score
gen miss = missing(score)
collapse (mean) score (sum) score2 miss, by(measureid facilityid)
replace score  = . if miss >= 1
replace score2 = . if miss == 2
replace score = score2 if measureid == 7
drop score2 miss

rename score ptexp_
reshape wide ptexp_ , i(facilityid) j(measureid)

label var ptexp_1 "Patients who reported that their nurses communicated well"
label var ptexp_2 "Patients who reported that their doctors communicated well"
label var ptexp_3 "Patients who reported that they received help as soon as they wanted"
label var ptexp_4 "Patients who reported that staff explained about medicines before giving it to them"
label var ptexp_5 "Cleanliness and quietness"
label var ptexp_6 "Patients who reported that they were given information about what to do during their recovery at home"
label var ptexp_7 "Patients who understood their care when they left the hospital"
label var ptexp_8 "Rating and recommendation"

merge 1:1 facilityid using data/star_data_2021
drop if _merge == 1 /* master only */
drop _merge
save data/star_data_2021, replace
 

********************************************************************************
* Timely and effective care measures
tempfile s1 s2

* file 1
*import delimited using raw_data/Timely_and_Effective_Care-Hospital.csv, clear stringcols(_all) 
import delimited using "../CMS Stars 2021 underlying data\hospitals_archive_10_2020/yv7e-xc69.csv", clear stringcols(_all) 

keep facilityid measureid score

replace measureid =  "1" if measureid == "IMM_3"
replace measureid =  "2" if measureid == "OP_22"
replace measureid =  "3" if measureid == "OP_23" 
replace measureid =  "4" if measureid == "OP_29"
replace measureid =  "5" if measureid == "OP_30" 
replace measureid =  "6" if measureid == "PC_01" 
replace measureid =  "7" if measureid == "SEP_1"
replace measureid =  "8" if measureid == "OP_2"
replace measureid =  "9" if measureid == "OP_33"
replace measureid = "10" if measureid == "ED_2b" 
replace measureid = "11" if measureid == "OP_3b"
replace measureid = "12" if measureid == "OP_18b"

keep if inlist(measureid, "1" , "2", "3", "4", "5", "6", "7", "8", "9") |  inlist(measureid, "10" , "11", "12", "13", "14", "15")

destring measureid, replace
replace score = "" if score == "Not Available"
destring score, replace

rename score timely_
reshape wide timely_ , i(facilityid) j(measureid)

label var timely_1  "Percentage of healthcare workers given influenza vaccination"
label var timely_2  "Percentage of patients who left the emergency department before being seen"
label var timely_3  "Percentage of patients who came to the emergency department with stroke symptoms who received brain scan results within 45 minutes of arrival"
label var timely_4  "Percentage of patients receiving appropriate recommendation for follow-up screening colonoscopy"
label var timely_5  "Percentage of patients with history of polyps receiving follow-up colonoscopy in the appropriate timeframe"
label var timely_6  "Percentage of mothers whose deliveries were scheduled too early (1-2 weeks early), when a scheduled delivery was not medically necessary"
label var timely_7  "Percentage of patients who received appropriate care for severe sepsis and septic shock."
label var timely_8  "Percentage of outpatients with chest pain or possible heart attack who got drugs to break up blood clots within 30 minutes of arrival"
label var timely_9  "Percentage of patients receiving appropriate radiation therapy for cancer that has spread to the bone"
label var timely_10 "Average (median) time patients spent in the emergency department, after the doctor decided to admit them as an inpatient before leaving the emergency department for their inpatient room"
label var timely_11 "Average (median) number of minutes before outpatients with chest pain or possible heart attack who needed specialized care were transferred to another hospital"
label var timely_12 "Average (median) time patients spent in the emergency department before leaving from the visit"

save `s1'


* file 2
*import delimited using raw_data/Outpatient_Imaging_Efficiency-Hospital.csv, clear stringcols(_all) 
import delimited using "../CMS Stars 2021 underlying data\hospitals_archive_10_2020/wkfw-kthe.csv", clear stringcols(_all) 

keep facilityid measureid score

replace score = "" if score == "Not Available"
destring score, replace

replace measureid = "13" if measureid == "OP-8"
replace measureid = "14" if measureid == "OP-10"
replace measureid = "15" if measureid == "OP-13"
keep if inlist(measureid, "1" , "2", "3", "4", "5", "6", "7", "8", "9") |  inlist(measureid, "10" , "11", "12", "13", "14", "15")

destring measureid, replace

rename score timely_
reshape wide timely_ , i(facilityid) j(measureid)

label var timely_13 "% o/p with low-back pain who had MRI w/o trying recommended treatments first"
label var timely_14 "% o/p CT scans of the abdomen that were combination (double) scans"
label var timely_15 "% o/p who got cardiac imaging stress tests before low-risk outpatient surgery"

save `s2'

use `s1'
merge 1:1 facilityid using `s2'
assert _merge == 3 | _merge == 1 /* a few missing */
drop _merge
merge 1:1 facilityid using data/star_data_2021
drop if _merge == 1 /* master only */
drop _merge

order facilityid name state type real_rating mortality* safety* readm* ptexp* timely*
compress
label data "January 2021 star ratings data"

* discard if no real star rating
keep if !missing(real_rating)

save data/star_data_2021, replace

