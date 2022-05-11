/******************************************************************************/
/* 	Monte Carlo simulation to examine the sensitivty of the CMS Star Ratings
	to methodological choices in even more detail.
	
	2020-11-25
	Version 1.0
*/

/******************************************************************************/
* Set random number seed
set seed 4334


/******************************************************************************/
* Number of simulations to do each time
local sims 100

* Total number of times to run
local sims_repeat 100

/******************************************************************************/
/* Load simulation program */
do mc_weights_cms.do


/******************************************************************************/
/* Prepare data */
tempfile file1 file2 file3 file4
use "data\std_method1_grp_pol", clear
rename 	(mortality_m1 safety_m1 readm_m1 ptexp_m1 timely_m1) ///
		(	std0_grp0_measure1 /// 
			std0_grp0_measure2 /// 
			std0_grp0_measure3 /// 
			std0_grp0_measure4 /// 
			std0_grp0_measure5 /// 
			)
save `file1'

use "data\std_method1_grp_efa", clear
rename (f1 f2 f3 f4 f5 f6) /// 
		(	std0_grp1_measure1 /// 
			std0_grp1_measure2 /// 
			std0_grp1_measure3 /// 
			std0_grp1_measure4 /// 
			std0_grp1_measure5 /// 
			std0_grp1_measure6 )
* f4 and f6 are 'process'
save `file2'

use "data\std_method2_grp_pol", clear
rename 	(mortality_m2 safety_m2 readm_m2 ptexp_m2 timely_m2 ) ///
		(	std1_grp0_measure1 /// 
			std1_grp0_measure2 /// 
			std1_grp0_measure3 /// 
			std1_grp0_measure4 /// 
			std1_grp0_measure5 /// 
			)
save `file3' 

use "data\std_method2_grp_efa", clear
rename (f1 f2 f3 f4 f5 f6) /// 
		(	std1_grp1_measure1 /// 
			std1_grp1_measure2 /// 
			std1_grp1_measure3 /// 
			std1_grp1_measure4 /// 
			std1_grp1_measure5 /// 
			std1_grp1_measure6 )
* g4 and g6 are 'process'
save `file4'

use `file1', clear
merge 1:1 facilityid using `file2', assert(3) nogenerate
merge 1:1 facilityid using `file3', assert(3) nogenerate
merge 1:1 facilityid using `file4', assert(3) nogenerate

egen nm = rownonmiss(std0_grp0_*)
keep if nm >= 3 & (!missing(std0_grp0_measure1) | !missing(std0_grp0_measure2) | !missing(std0_grp0_measure3))
drop nm

egen missing_domains = rowmiss(std0_grp0_*)
label var missing_domains "Number of missing domains"

compress
label data "Data for Monte Carlo simulations"

save data/final_cms_simulation_basedata, replace


/******************************************************************************/
/* CMS simulation - WEIGHTS AND GROUPS AND STANDARDISATION */
forval rotation = 1/`sims_repeat' {
	di as text _newline _col(2) "Set `rotation' of `sims_repeat'" 
	frame change default
	qui use data/final_cms_simulation_basedata, clear

	set trace off
	set tracedepth 1

	mc_cms, std_sim(1) grp_sim(1) sims(`sims') sim_rotate(`rotation') save(cms_weights_std1_grp1_sims`rotation')
}

frame change default
use simdata/cms_weights_std1_grp1_sims1.dta, clear
erase simdata/cms_weights_std1_grp1_sims1.dta
forval rotation = 2/`sims_repeat' {
	append using simdata/cms_weights_std1_grp1_sims`rotation'
	erase simdata/cms_weights_std1_grp1_sims`rotation'.dta
}
save simdata/cms_weights_std1_grp1_sims, replace

egen sd_between = sd(wtd_summary_rank), by(sim)
gen var_between = sd_between^2

#delimit ;
collapse 	(mean) 	mean		= wtd_summary_score 
			(min)	min  		= wtd_summary_score 
			(p25)  	lb 			= wtd_summary_score 
			(p75) 	ub 			= wtd_summary_score
			(max) 	max  		= wtd_summary_score
			(sd)  	sd_within 	= wtd_summary_rank
			(mean) 	var_between = var_between
			(mean) 	mean_rank	= wtd_summary_rank 
			(min)	min_rank	= wtd_summary_rank 
			(p25)  	lb_rank		= wtd_summary_rank 
			(p75) 	ub_rank		= wtd_summary_rank
			(max) 	max_rank	= wtd_summary_rank
			(mean) 	mean_star	= stars 
			(min)	min_star	= stars 
			(p25)  	lb_star		= stars 
			(p75) 	ub_star		= stars
			(max) 	max_star	= stars
			, 	by(facilityid) fast
			;
#delimit cr

save data/cms_weights_std1_grp1, replace
