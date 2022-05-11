/******************************************************************************/
/* 	Standardise
	
	This file standardises the measures used in the star ratings.
	
	First it does it using the Z-score approach of the current star ratings.
	
	Second it does this using an alternate plausible approach.
	
	Matthew Barclay
	Version 1.0
	2020-11-25
*/

clear
cap log c


/******************************************************************************/
/* Standardise measures scores - CMS approach								  */
use data/star_data_2021.dta, clear

* Standardise
pause off
foreach type in mortality readm safety ptexp timely {
	forval i = 1/15 {
		cap confirm numeric variable `type'_`i' 
		if _rc {
			* skip
		}
		else {
			desc `type'_`i'
			summ `type'_`i'
			replace `type'_`i' = ((`type'_`i')-r(mean))/r(sd)
			count if !missing(`type'_`i')
			local total = r(N)
			count if `type'_`i' >  3 & !missing(`type'_`i')
			di 100*r(N)/`total'
			count if `type'_`i' < -3 & !missing(`type'_`i')
			di 100*r(N)/`total'
			pause
		}
	}
}

* Re-direct measures so higher = better
* mortality
forval i = 1/7 {
	replace mortality_`i' = -mortality_`i'
}

* safety
forval i = 1/8 {
	replace safety_`i' = -safety_`i'
}

* readmission
forval i = 1/11 {
	replace readm_`i' = -readm_`i'
}

* ptexp - higher always already better

* timely
foreach i in 2 6 10 11 12 13 14 15 {
	replace timely_`i' = -timely_`i'
}

* Winsorize
foreach type in mortality safety ptexp readm timely {
	forval i = 1/11 {
		cap confirm numeric variable `type'_`i' 
		if _rc {
			* skip
		}
		else {
			replace `type'_`i' = -3 if `type'_`i' < -3 & !missing(`type'_`i')
			replace `type'_`i' =  3 if `type'_`i' >  3 & !missing(`type'_`i')
		}
	}
}

/* save 																	  */
label data "Standardised using Z-scores"
compress
save data/std_method1.dta, replace


/******************************************************************************/
/* Standardise measures scores - ALTERNATE approach							  */
use data/star_data_2021.dta, clear

/* AIM
	- Get to 0-100 scale
	- Higher = better
*/

* mortality
summ mortality*

* mortality_7 is _deaths per 1000_
replace mortality_7 = mortality_7/10

* these are all now %ages already
forval i = 1/7 {
	summ mortality_`i'
	
	assert r(min) >= 0
	assert r(max) <= 100
	
	replace mortality_`i' = 100-mortality_`i'
}

summ mortality_?

* safety

summ safety_*

* CLABSI and CAUTI are SIRs based on a set prediction
* know that "expected" rate for CLABSI is 25955.01 per 25969931 device-days
* https://www.cdc.gov/hai/data/portal/progress-report.html - 2018 SIR data
* 		- "2018 National and State HAI Progress Report SIR Data - Acure Care Hospitals.xls"
replace safety_1 = 100*(1-safety_1*(25955.01/25969931))

* know that "expected" rate for CAUTI is 27216.774 per 24334827 device-days
* https://www.cdc.gov/hai/data/portal/progress-report.html - 2018 SIR data
* 		- "2018 National and State HAI Progress Report SIR Data - Acure Care Hospitals.xls"
replace safety_2 = 100*(1-safety_2*(27216.774/24334827))

* SSI Colon -  8,255.389 infections per  322,125  procedures
replace safety_3 = 100*(1-safety_3*(8255.389/322125))

* SSI Hysterectomy -  1,950.352  infections per  293,503  procedures
replace safety_4 = 100*(1-safety_4*(1950.352/293503))

* MRSA - 9783.465 per  36801464 admissions
replace safety_5 = 100*(1-safety_5*(9783.465/36801464))

* C Diff - 97962.238 per 33496433 admissions
replace safety_6 = 100*(1-safety_6*(97962.238/33496433))

* complication rate is per cent
replace safety_7 = (100-safety_7)

* PSI 90 is different

* This is:
* - 0.059841 of PSI 03 (rate per 1000)
* - 0.053497 of PSI 06 (rate per 1000)
* - 0.010097 of PSI 08 (rate per 1000)
* - 0.085335 of PSI 09 (rate per 1000)
* - 0.041015 of PSI 10 (rate per 1000)
* - 0.304936 of PSI 11 (rate per 1000)
* - 0.208953 of PSI 12 (rate per 1000)
* - 0.216046 of PSI 13 (rate per 1000)
* - 0.013269 of PSI 14 (rate per 1000)
* - 0.007011 of PSI 15 (rate per 1000)

* so PSI 90 is just a rate per 1000!

replace safety_8 = 100*(1-safety_8/1000)

summ safety_*

* readmission
summ readm_*

* readm_8 is "per 1000 colonoscopies"
replace readm_8 = readm_8/10

* now %s apart from readm_11
forval i = 1/10 {
	replace readm_`i' = 100 - readm_`i'
}

* readm_11 - ratio of unplanned hospital visits
* national rate = 4.8%
* source: https://www.ncbi.nlm.nih.gov/pmc/articles/PMC8291649

replace readm_11 = 4.8*readm_11
replace readm_11 = 100-readm_11

summ readm_*

* timely

* Timely 10 - ED admit decision to departure
summ timely_10, meanonly
gen t10_plot =(_n-1)*(r(max)/`=_N-3')
gen t10 = 100*cond( ///
		t10_plot  <= 30, /// 
		1, /// 
		1+invlogit(-5)-invlogit(-5 + (t10_plot-30)/24 ) /// 
	)
gen timely_10_plot = timely_10/60
replace t10_plot = t10_plot/60

summ timely_10, det
replace timely_10 = 100*cond( ///
		timely_10 <= 30, /// 
		1, /// 
		1+invlogit(-5)-invlogit(-5 + (timely_10-30)/24 ) /// 
	)
summ timely_10, det

summ t10_plot
twoway	(scatter timely_10 timely_10_plot, msymb(oh) mcolor(blue%10) jitter(2) ) ///
		(line t10 t10_plot, sort lc(gs0) lw(*2) ) /// 
		,	xlabel(0 0.5 4 `=round(`=r(max)')', grid) ylabel(,angle(h)) ///
			plotregion(margin(l=0 b=0)) /// 
			ytitle("") ///
			ylabel(0 50 100) /// 
			xtitle("ED - median time admit decision to departure, hours") /// 
			legend(off) /// 
			title("B. ED - median time admit decision to departure", size(medlarge) pos(11) span) /// 
			name(t10, replace)

drop timely_10_plot t10 t10_plot


* Timely 11 - OP time to specialist care
* - Maximum score: 14 days or less
* - dropping off after that
* - minimum score if average wait > 126 days (18 weeks)
summ timely_11, meanonly
gen t11_plot =(_n-1)*(r(max)/`=_N-3')
gen t11 = 100*cond( ///
		t11_plot  <= 30, /// 
		1, /// 
		1+invlogit(-5)-invlogit(-5 + (t11_plot-30)/15 ) /// 
	)
gen timely_11_plot = timely_11

summ timely_11, det
replace timely_11 = 100*cond( ///
		timely_11 <= 30, /// 
		1, /// 
		1+invlogit(-5)-invlogit(-5 + (timely_11-30)/15 ) /// 
	)
summ timely_11, det

summ t11_plot
twoway	(scatter timely_11 timely_11_plot, msymb(oh) mcolor(blue%20) jitter(2) ) ///
		(line t11 t11_plot, sort lc(gs0) lw(*2) ) /// 
		,	xlabel(0 30 120 `=round(`=r(max)')', grid) ylabel(,angle(h)) ///
			plotregion(margin(l=0 b=0)) /// 
			ytitle("") ///
			ylabel(0 50 100) /// 
			xtitle("OP - median time to specialist care, minutes") /// 
			title("C. OP - median time to specialist care", size(medlarge) pos(11) span) /// 
			legend(off) /// 
			name(t11, replace)

drop timely_11_plot t11 t11_plot

* Timely 12 - ED - time arrival to departure
* - Maximum score: 2 hours or less
* - dropping off after that
* - minimum score if average delay > 10 hours
summ timely_12, meanonly
gen t12_plot =(_n-1)*(r(max)/`=_N-3')
gen t12 = 100*cond( ///
		t12_plot <= 120, /// 
		1, /// 
		1+invlogit(-5)-invlogit(-5 + (t12_plot-120)/48 ) /// 
	)
gen timely_12_plot = timely_12/60
replace t12_plot = t12_plot/60

summ timely_12, det
replace timely_12 = 100*cond( ///
		timely_12 <= 120, /// 
		1, /// 
		1+invlogit(-5)-invlogit(-5 + (timely_12-120)/48 ) /// 
	)
summ timely_12, det

summ t12_plot
twoway	(scatter timely_12 timely_12_plot, msymb(oh) mcolor(blue%10) jitter(2) ) ///
		(line t12 t12_plot, sort lc(gs0) lw(*2) ) /// 
		,	xlabel(0 2 10 `=round(`=r(max)')', grid) ylabel(,angle(h)) ///
			plotregion(margin(l=0 b=0)) /// 
			ytitle("") ///
			ylabel(0 50 100) /// 
			xtitle("ED - median time arrival to departure, hours") /// 
			legend(off) /// 
			title("A. ED - median time arrival to departure", size(medlarge) pos(11) span) /// 
			name(t12, replace)

drop timely_12_plot t12 t12_plot

* %s where higher = better
* timely_1 timely_3 timely_4 timely_7 timely_8 timely_9 


* %s where higher = worse
* timely_2 timely_6 timely13-15
foreach thing in 2 6 13 14 15 {
	replace timely_`thing' = 100-timely_`thing'
}

summ timely_*


* checks...
summ mortality_?
summ safety_?
summ readm_?
summ ptexp_? 
summ timely_? timely_??

label data "Standardised using reference points"
compress
save data/std_method2.dta, replace
