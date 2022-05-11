/* Creates various figures and tables for the suppl appendix */
set scheme s1color

/* eMethods 1 Table 1. */
frame change default
use data/star_data_2021, clear

desc, f

cap frame drop em1_tab1
frame create em1_tab1

frame em1_tab1 {
	set obs 49
	gen domain = ""
	gen measure_name = ""
	gen measure_type = ""
	gen perc_missing = ""
	gen prop_missing = .
	
	label var domain "Domain"
	label var measure_name "Measure name"
	label var measure_type "Measure type"
	label var perc_missing "% missing (all 3,339 hospitals)"
}

local i = 0
set trace off
set tracedepth 2
foreach var of varlist mortality_1-timely_15 {
	local ++i
	
	di strrpos("`var'","_")
	local domain = substr("`var'", 1, `=strrpos("`var'","_")-1')
	
	local chk = 0
	if "`domain'" == "readm" {
		local domain = "Readmission"
		local chk = 1
	}
	if "`domain'" == "ptexp" {
		local domain = "Patient experience"
		local chk = 1
	}
	if "`domain'" == "timely" {
		local domain = "Timely and effective care"
		local chk = 1
	}
	if `chk' == 0 {
		local domain = proper("`domain'")
	}
	
	frame em1_tab1: replace domain = "`domain'" in `i'
	
	local label : var label `var'
	frame em1_tab1: replace measure_name = "`label'" in `i'
	
	gen byte missing = missing(`var')
	summ missing, meanonly
	frame em1_tab1: replace prop_missing = r(mean) in `i'
	drop missing
	
}

frame em1_tab1 {
	replace measure_type = "Proportion" in 1/7
	replace measure_type = "Rate ratio" in 8/13
	replace measure_type = "Proportion" in 14
	replace measure_type = "Rate" in 15
	replace measure_type = "Rate" in 16/26
	replace measure_type = "Proportion" in 27/34
	replace measure_type = "Proportion" in 35/43
	replace measure_type = "Time-to-event" in 44/46
	replace measure_type = "Proportion" in 47/49
	
	replace perc_missing = strofreal(prop_missing*100, "%03.1f")
	replace perc_missing = perc_missing+"%"
	drop prop_missing
}

frame em1_tab1: list
frame em1_tab1: export excel using results/suppl_tables.xlsx, sheet(em1_tab1, replace) firstrow(varl)


/* em3_tab1 */
frame change em1_tab1

keep domain measure_name
gen domain_alt = ""

replace domain_alt = "Patient experience" in 27/34

replace domain_alt = "Readmission" in 16
replace domain_alt = "Readmission" in 18/24
replace domain_alt = "Readmission" in 8 /* safety 1 */
replace domain_alt = "Readmission" in 12 /* safety 5 */
replace domain_alt = "Readmission" in 14 /* safety 7 */
replace domain_alt = "Readmission" in 49 /* timely 15 */

replace domain_alt = "Mortality" in 1
replace domain_alt = "Mortality" in 3/7

replace domain_alt = "ED quality" in 9/11
replace domain_alt = "ED quality" in 13
replace domain_alt = "ED quality" in 15
replace domain_alt = "ED quality" in 36/37 /* timely 2 3 */
replace domain_alt = "ED quality" in 41/42 /* timely 7 8 */ 
replace domain_alt = "ED quality" in 44 /* timely 10 */ 
replace domain_alt = "ED quality" in 46 /* timely 12 */ 

replace domain_alt = "OP quality" in 23
replace domain_alt = "OP quality" in 25/26
replace domain_alt = "OP quality" in 35
replace domain_alt = "OP quality" in 38/40
replace domain_alt = "OP quality" in 43
replace domain_alt = "OP quality" in 45
replace domain_alt = "OP quality" in 47/48

replace domain_alt = "CABG outcomes" in 2
replace domain_alt = "CABG outcomes" in 17 

label var domain "CMS (2021) Domain"
label var measure_name "Measure name"
label var domain_alt "Domain from exploratory factor analysis"
order measure_name domain domain_alt

frame em1_tab1: export excel using results/suppl_tables.xlsx, sheet(em3_tab1, replace) firstrow(varl)

clear
frame change default
frame drop em1_tab1


/******************************************************************************/
/* eMethods 2 Figure 1								  */
use data/star_data_2021.dta, clear


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

graph combine t12 t10 t11  , cols(2) l1title("Standardised score") altshrink
graph export results/suppl_em2_fig1.png, width(1000) replace


/******************************************************************************/
/* Plot of weights - em4_fig1 */

clear
local obs 1000
set obs `obs'
gen x = logit((_n-.5)/`obs')
gen dist1 = normalden(x,logit(0.22),1.5)
gen dist2 = normalden(x,logit(0.12),1.5)

*twoway line dist1 x, sort(x)

gen x_prob = invlogit(x)

#delimit ;
twoway 	(line dist1 x_prob, sort(x_prob) lcol(blue)	)  
		(line dist2 x_prob, sort(x_prob) lcol(red)	)  
		,	xlabel(0(0.2)1, format(%02.1f)) 
			ylabel(0(0.1)0.3, format(%02.1f) angle(h) tl(0))
			xline(0.22, lpattern(dash) lcol(blue%20))
			xline(0.12, lpattern(dash) lcol(red%20))
			xtitle("Measure weight")
			ytitle("Density")
			plotregion(margin(b=0))
			legend(
				subtitle("Distribution of measure weights")
				order(
					1 "Outcome domains"
					2 "Process domains"
				)
				ring(0) pos(2) cols(1)
			)
			text( 0 0.11 "0.12", place(se) size(vsmall) )
			text( 0 0.21 "0.22", place(se) size(vsmall) )
			name(om_density, replace)
		;
#delimit cr
graph export results/em4_fig1.png, width(1000) replace

gen cdf1 = sum(dist1)
egen t1 = total(dist1)
replace cdf1 = cdf1/t1

gen cdf2 = sum(dist2)
egen t2 = total(dist2)
replace cdf2 = cdf2/t2

list if cdf1 >= 0.024 & cdf1 <= 0.026
list if cdf1 >= 0.974 & cdf1 <= 0.976
* x = -2.933962 // .0505 
* x = +1.446765 // .8095

list if cdf2 >= 0.02 & cdf2 <= 0.03
list if cdf2 >= 0.974 & cdf2 <= 0.976
* x = -4.291474	// 0.0115
* x = +.4368156 // 0.6075


