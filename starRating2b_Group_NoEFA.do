/******************************************************************************/
/* 	Group
	
	This applies the groups identified in factor analysis of the Z-score
	data.
*/

clear
cap log c


/******************************************************************************/
/* Find groups in Z-scored data 											  */
use data/std_method1.dta, clear

keep 	facilityid /// 
		mortality_* /// 
		safety_* ///
		readm_* ///
		ptexp_* ///
		timely_*

* F1 - all patient experience measures
*	readm_11 (readmission ratio) could be f1 or f5. As not ptexp, assigned to f5.
rename (ptexp_*) f1_=

* F2 - largely readmission
rename (readm_*) f2_=
rename (f2_readm_2 f2_readm_8 f2_readm_10 f2_readm_11) (readm_2 readm_8 readm_10 readm_11)

rename (safety_1 safety_5 safety_7 timely_15) f2_=

* F3 - safety and some timeliness
rename ( /// 
	safety_2 /// 
	safety_3 /// 
	safety_4 /// 
	safety_6 /// 
	safety_8 /// 
	timely_2 /// 
	timely_3 /// 
	timely_7 /// 
	timely_10 /// /* FOR NOW */
	timely_12 /// 
	) f3_=

* set timely_8 to f3 as about ED
rename timely_8 f3_timely_8
	
* F4 - mortality
rename (mortality_*) f4_=
rename f4_mortality_2 mortality_2

* F5 - scattered measures
rename ( /// 
	readm_8 /// 
	readm_10 /// 
	readm_11 /// 
	timely_1 /// 
	timely_4 /// 
	timely_5 /// /* FOR NOW */
	timely_6 /// 
	timely_9 /// 
	timely_11 /// 
	timely_13 /// 
	timely_14 ///
	) f5_=
	
* F6 - CABG outcomes
rename ( /// 
	mortality_2 /// 
	readm_2 /// 
	) f6_=
	exit 1
* based on hospital compare, only calculate group score if 3+ measures
* (do not apply to f6, as only two measures)
qui forval i = 1/5 {
	egen nm_f`i' = rownonmiss(f`i'_*)
	foreach var of varlist f`i'_* {
		replace `var' = . if nm_f`i' < 3
	}
}

* generate group summary scores
egen f1 = rowmean(f1_*)
egen f2 = rowmean(f2_*)
egen f3 = rowmean(f3_*)
egen f4 = rowmean(f4_*)
egen f5 = rowmean (f5_*)
egen f6 = rowmean (f6_*)

* How shall we think of these factors?
desc f1_*
desc f2_*
desc f3_*
desc f4_*
desc f5_*
desc f6_*

label var f1 "Patient experience"
label var f2 "Readmission" // reflects ED? Operational safety?
label var f3 "ED quality"
label var f4 "Mortality"
label var f5 "OP quality"
label var f6 "CABG outcomes"

keep facilityid f1-f6

label data "Standardisation by Z-scores, group by EFA"
save data/std_method1_grp_efa.dta, replace

/******************************************************************************/
/* Find groups in reference-standardised data								  */
use data/std_method2.dta, clear

keep 	facilityid /// 
		mortality_* /// 
		safety_* ///
		readm_* ///
		ptexp_* ///
		timely_*

* F1 - all patient experience measures
*	readm_11 (readmission ratio) could be f1 or f5. As not ptexp, assigned to f5.
rename (ptexp_*) f1_=

* F2 - largely readmission
rename (readm_*) f2_=
rename (f2_readm_2 f2_readm_8 f2_readm_10 f2_readm_11) (readm_2 readm_8 readm_10 readm_11)

rename (safety_1 safety_5 safety_7 timely_15) f2_=

* F3 - safety and some timeliness
rename ( /// 
	safety_2 /// 
	safety_3 /// 
	safety_4 /// 
	safety_6 /// 
	safety_8 /// 
	timely_2 /// 
	timely_3 /// 
	timely_7 /// 
	timely_10 /// /* FOR NOW */
	timely_12 /// 
	) f3_=

* set timely_8 to f3 as about ED
rename timely_8 f3_timely_8
	
* F4 - mortality
rename (mortality_*) f4_=
rename f4_mortality_2 mortality_2

* F5 - scattered measures
rename ( /// 
	readm_8 /// 
	readm_10 /// 
	readm_11 /// 
	timely_1 /// 
	timely_4 /// 
	timely_5 /// /* FOR NOW */
	timely_6 /// 
	timely_9 /// 
	timely_11 /// 
	timely_13 /// 
	timely_14 ///
	) f5_=
	
* F6 - CABG outcomes
rename ( /// 
	mortality_2 /// 
	readm_2 /// 
	) f6_=
	
* based on hospital compare, only calculate group score if 3+ measures
* (do not apply to f6, as only two measures)
qui forval i = 1/5 {
	egen nm_f`i' = rownonmiss(f`i'_*)
	foreach var of varlist f`i'_* {
		replace `var' = . if nm_f`i' < 3
	}
}

* generate group summary scores
egen f1 = rowmean(f1_*)
egen f2 = rowmean(f2_*)
egen f3 = rowmean(f3_*)
egen f4 = rowmean(f4_*)
egen f5 = rowmean (f5_*)
egen f6 = rowmean (f6_*)

* How shall we think of these factors?
desc f1_*
desc f2_*
desc f3_*
desc f4_*
desc f5_*
desc f6_*

label var f1 "Patient experience"
label var f2 "Readmission" // reflects ED? Operational safety?
label var f3 "ED quality"
label var f4 "Mortality"
label var f5 "OP quality"
label var f6 "CABG outcomes"

keep facilityid f1-f6

label data "Standardisation by Z-scores, group by EFA"
save data/std_method2_grp_efa.dta, replace


/******************************************************************************/
/* Assign groups in Z-scored data 											  */
use data/std_method1.dta, clear

keep 	facilityid /// 
		mortality_* /// 
		safety_* ///
		readm_* ///
		ptexp_* ///
		timely_*
		
* based on hospital compare, only calculate group score if 3+ measures
qui foreach group in mortality safety readm ptexp timely {
	egen nm_`group' = rownonmiss(`group'_*)
	foreach var of varlist `group'_* {
		replace `var' = . if nm_`group' < 3
	}
}

egen mortality_m1 	= rowmean(mortality*)
egen safety_m1 		= rowmean(safety*)
egen readm_m1 		= rowmean(readm*)
egen ptexp_m1 		= rowmean(ptexp*)
egen timely_m1 		= rowmean (timely*)

keep facilityid mortality_m1-timely_m1

label data "Standardisation by Z-score, group by policy"
save data/std_method1_grp_pol.dta, replace

/******************************************************************************/
/* Assign groups in reference data 											  */
use data/std_method2.dta, clear

keep 	facilityid /// 
		mortality_* /// 
		safety_* ///
		readm_* ///
		ptexp_* ///
		timely_*

* based on hospital compare, only calculate group score if 3+ measures
qui foreach group in mortality safety readm ptexp timely {
	egen nm_`group' = rownonmiss(`group'_*)
	foreach var of varlist `group'_* {
		replace `var' = . if nm_`group' < 3
	}
	drop nm_`group' 
}
	
egen mortality_m2 	= rowmean(mortality*)
egen safety_m2 		= rowmean(safety*)
egen readm_m2 		= rowmean(readm*)
egen ptexp_m2 		= rowmean(ptexp*)
egen timely_m2 		= rowmean (timely*)

keep facilityid mortality_m2-timely_m2

label data "Standardisation by reference, group by policy"
save data/std_method2_grp_pol.dta, replace 
 
