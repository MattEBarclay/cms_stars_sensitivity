/* Pulls together numbers from the various files to populate tables and figures */


*
/*
Hospitals

All				Count Rank (min-max)	5* 4-2* 1*
Five
Four
Three
*/


/******************************************************************************/
* convenience program for binomial CIs
cap program drop ci_prop
program ci_prop, rclass
	ci proportions `1', wilson
	local bin_prop = r(proportion)
	local lb = r(lb)
	local ub = r(ub)
	local ci = "(" + strofreal(100*`lb',"%03.1f") + "%, " + strofreal(100*`ub', "%03.1f") + "%)"
	return local ci = "`ci'"
	return scalar bin_prop = `bin_prop'
end

/******************************************************************************/
/* Changes associated with individual shifts */
use data/approaches_combined.dta, clear

keep  facilityid grp1_cat real_rating std1_grp1_wt1_* std2_grp1_wt1_* std1_grp2_wt1_* std1_grp1_wt2_* 
order facilityid grp1_cat real_rating std1_grp1_wt1_* std2_grp1_wt1_* std1_grp2_wt1_* std1_grp1_wt2_* 

foreach thing of varlist *_rank {
	
	local thing2 = subinstr("`thing'","_rank","",.)+"_score"
	egen count = count(`thing2'), by(grp1_cat)
	
	replace `thing' = 1 + count - `thing'
	replace `thing' = 100*`thing'/count
	
	drop count
}

foreach thing in score rank stars {
	local label = proper("`thing'")
	if "`thing'" == "rank" {
		local label = "% rank"
	}
	label var std1_grp1_wt1_`thing' "`label', CMS approach"
	label var std2_grp1_wt1_`thing' "`label', alternative standardization"
	label var std1_grp2_wt1_`thing' "`label', alternative domains"
	label var std1_grp1_wt2_`thing' "`label', alternative weights"
}
desc

sort std1_grp2_wt1_rank
summ *_rank
sort std1_grp2_wt1_rank

gen pct_rank_change_std = abs(std1_grp1_wt1_rank-std2_grp1_wt1_rank)
gen pct_rank_change_grp = abs(std1_grp1_wt1_rank-std1_grp2_wt1_rank)
gen pct_rank_change_wt  = abs(std1_grp1_wt1_rank-std1_grp1_wt2_rank)

bys grp1_cat: summ pct_rank_change*

tab std1_grp1_wt1_stars std2_grp1_wt1_stars 
tab std1_grp1_wt1_stars std1_grp2_wt1_stars 
tab std1_grp1_wt1_stars std1_grp1_wt2_stars 

keep facilityid grp1_cat *_rank *stars pct_rank_change_*

foreach thing in rank stars {
	rename std1_grp1_wt1_`thing' baseline_`thing'
	rename std2_grp1_wt1_`thing' `thing'_std
	rename std1_grp2_wt1_`thing' `thing'_grp
	rename std1_grp1_wt2_`thing' `thing'_wt
}

reshape long rank_ stars_ pct_rank_change_, i(facilityid) j(type) string

gen byte type2 = .
replace type2 = 1 if type == "std"
replace type2 = 2 if type == "grp"
replace type2 = 3 if type == "wt"

label define grp1_cat 	0 "All five domains reported" ///
						1 "Four domains reported" ///
						2 "Three domains reported" ///
						,	replace
label values grp1_cat grp1_cat

label define type2 	1 "Alternative standardization (external reference)" ///
					2 "Alternative domain grouping (factor analysis)" ///
					3 "Alternative domain weights (equal weights)" ///
					, replace
label values type2 type2

order facilityid type2 grp1_cat baseline_stars stars baseline_rank rank pct_rank_change
drop type

gen star_change = baseline_stars != stars_

/* Table showing changes */
preserve
list in 1/5

gen count = !missing(rank)

forval i = 1/5 {
	gen byte star_`i' = stars == `i' if count
}


expand 2, gen(expanded)
replace baseline_stars = 0 if expanded
drop expanded
label define baseline_stars 0 "All hospitals" 1 "1 star" 2 "2 star" 3 "3 star" 4 "4 star" 5 "5 star", replace
label values baseline_stars baseline_stars

rename (pct_rank_change star_change) (change_pct_rank change_star)
#delimit ;
table (type2 baseline_stars) ()
	, 	stat(freq) 
		stat(mean star_1)
		stat(mean star_2)
		stat(mean star_3)
		stat(mean star_4)
		stat(mean star_5)
		command(_r_b _r_ci: regress change_pct_rank)
		command(r(bin_prop) r(ci): ci_prop change_star) 
		nototal 
		listwise
		name(tab2_1) replace
		nformat("%9.0fc" Frequency)
		nformat("%03.2f" mean bin_prop)
		nformat("%03.1f" _r_b _r_ci )
		sformat("(%s)" _r_ci)
		cidelimiter(", ")
	;
#delimit cr
collect export results/table2_2022-03-18.xlsx, replace

restore

/* figure - do we want to use this? */
set scheme s1color

bys grp1_cat type2: summ rank_ if stars == 1
bys grp1_cat type2: summ rank_ if stars == 2
bys grp1_cat type2: summ rank_ if stars == 3
bys grp1_cat type2: summ rank_ if stars == 4
bys grp1_cat type2: summ rank_ if stars == 5

* stars boundaries for plot
forval type = 1/3 {
	cap drop one_alt
	bys grp1_cat type2 stars (rank_): gen one_alt = _n == 1
	cap drop one_base
	bys grp1_cat type2 baseline_stars (baseline_rank): gen one_base = _n == 1

	levelsof baseline_rank if one_base == 1 & type2 == `type' & !inlist(baseline_stars,1) & grp1_cat == 0, local(stars_base)
	levelsof rank_         if one_alt  == 1 & type2 == `type' & !inlist(stars         ,1) & grp1_cat == 0, local(stars_alt)

	local i = 0
	local last_lab = 0
	foreach xlab in `stars_base' 100 {
		local ++i
		local xlab_adj = `last_lab' + (`xlab'-`last_lab')/2
		local xlab`i' `"`xlab_adj' "`i' star""'
		local last_lab = `xlab'
	}

	local i = 0
	local last_lab = 0
	foreach ylab in `stars_alt' 100 {
		local ++i
		local ylab_adj = `last_lab' + (`ylab'-`last_lab')/2
		local ylab`i' `"`ylab_adj' "`i' star""'
		local last_lab = `ylab'
	}


	#delimit ;
	twoway		(scatter rank_ baseline_rank if grp1_cat == 0 & type2 == `type', msymb(oh) mcol(gs8%30) ) 
				,	by(
						type2
						, 	cols(1) 
							note("")
							legend(pos(1))
					)
					xtitle("")
					xsc(r(0 100))
					xlabel(`xlab1' `xlab2' `xlab3' `xlab4' `xlab5', angle(h) tl(0) )
					xtick(`stars_base', grid)
					ytitle("")
					ysc(r(0 100))
					ylabel(`ylab1' `ylab2' `ylab3' `ylab4' `xlab5', angle(h) tl(0) )
					ytick(`stars_alt', grid)
					subtitle(, fcolor(gs0) color(gs16) pos(11))
					plotregion(margin(0 0 0 0))
					name(fig2_`type', replace)
					legend(
								cols(1)
								region(lstyle(none))
								order(
									1 "Line showing no change"
								)
								size(vsmall)
								symxs(*.3)
								ring(0)
							)
			;
	#delimit cr
}

graph combine fig2_1 fig2_2 fig2_3, cols(1) l1title("Star rating and rank order" "under each alternative specification") b1title("Star rating and rank order under" "current (2021) CMS specification") imargin(0 0 0 0) name(panel_a, replace) title("A. Comparison of rating and ranks", span pos(11))

replace rank_ = rank_-baseline_rank

#delimit ;
twoway		(function y= 50		, lstyle(grid) range(0   50) )
			(function y=  0		, lstyle(grid) range(0   99.9) )
			(function y=-50   	, lstyle(grid) range(50  99.9) )
			(function y=-   x, lcol(gs0) range(0   99.9) )
			(function y=100-x, lcol(gs0) range(0  99.9) )
			(scatter rank_ baseline_rank if grp1_cat == 0, msymb(oh) mcol(gs8%30) ) 
			,	 by(
					type2
					, 	cols(1) 
						legend( off )
						note("")
						title("B. Centile change vs current centile", span pos(11))
				)
				xtitle("Centile under current (2021)" "CMS specification")
				xlabel(0 50 100, angle(h) nogrid tl(0) )
				xtick(50, grid tl(0) )
				ytitle("Centile under alternative specification" "minus centile under current (2021) CMS specification")
				ysc(r(-10 10))
				ylabel(-100(50)100, angle(h))
				subtitle(, fcolor(gs0) color(gs16) pos(11))
				plotregion(margin(0 0 0 0))
				name(panel_b, replace)
				legend(
							cols(1)
							region(lstyle(none))
							order(
								/*3 "All 5 domains"
								4 "4 of 5 domains"
								5 "3 of 5 domains"*/
								4 "Min/Max possible change"
							)
							size(vsmall)
							symxs(*.3)
						)
		;
#delimit cr

graph combine panel_a panel_b, altshrink

graph export results/individual_changes_both.png, width(1000) replace
graph export results/figure1_new.pdf, replace xsize(10) ysize(8)


/******************************************************************************/
/* Ranks etc on baseline data */
* Load in useful data
use data/approaches_combined.dta, clear

keep facilityid std1_grp1_wt1* grp1_cat grp1_missing

label list grp_cat

replace grp1_cat = 2 if grp1_cat == 3
label define grp_cat 	-1 "All hospitals" /// 
						0 "All five domains reported" ///
						1 "Four domains reported" ///
						2 "Three domains reported" /// 
						, modify

keep if !missing(std1_grp1_wt1_score)
gen five  = std1_grp1_wt1_star == 5
gen four  = std1_grp1_wt1_star == 4
gen three = std1_grp1_wt1_star == 3
gen two   = std1_grp1_wt1_star == 2
gen one   = std1_grp1_wt1_star == 1

gen any = 1

* fix ranks


collapse	(sum) any five four three two one ///
			(median) p50 = std1_grp1_wt1_rank ///
			(p25) p25 = std1_grp1_wt1_rank (p75) p75 = std1_grp1_wt1_rank ///
			(min) min = std1_grp1_wt1_rank (max) max = std1_grp1_wt1_rank ///
			, by( grp1_cat )

expand 2, gen(exp)
replace grp1_cat = -1 if exp

order grp1_cat any five four three two one p50 p25 p75 min max
list, clean noobs

expand 6
sort grp1_cat
by grp1_cat: gen order = _n

gen hospitals_receiving = "Any rating" if order == 1
replace hospitals_receiving = "5 stars" if order == 2
replace hospitals_receiving = "4 stars" if order == 3
replace hospitals_receiving = "3 stars" if order == 4
replace hospitals_receiving = "2 stars" if order == 5
replace hospitals_receiving = "1 stars" if order == 6

gen N = any if order == 1
replace N = five if order == 2
replace N = four if order == 3
replace N = three if order == 4
replace N = two if order == 5
replace N = one if order == 6
gen percent = N/any

gen median_rank = strofreal(p50) if order == 1
gen iqr_rank = "(" + strofreal(p25) + ", " + strofreal(p75) + ")"

list

keep grp1_cat hospitals_receiving N percent median_rank iqr_rank
list, sepby(grp1_cat)

export excel using results/Table3_Data.xlsx, replace firstrow(var)


/******************************************************************************/
/* Star ratings and ranks in individual simulations */
* baseline performance
use data/approaches_combined.dta, clear

keep facilityid real_rating std1_grp1_wt1* grp1_cat grp1_missing
rename std1_grp1_wt1_score baseline_score
rename std1_grp1_wt1_rank baseline_rank
tab *_stars
table *_stars, stat(max baseline_rank)
rename *_stars baseline_stars

keep facilityid baseline_score baseline_rank baseline_stars real_rating
compress
save paper_data/paper_baselines, replace

* rating in each sim
use simdata/cms_weights_std1_grp1_sims.dta, clear
merge m:1 facilityid using paper_data/paper_baselines, assert(2 3)
drop if _merge == 2 // not enough data to assign star rating, basically
count if sim == 1 // 3726 good
drop _merge

/* needs correcting within missing data groups */
**# Bookmark #1
egen count = count(wtd_summary_score), by(sim missing_domains)
/*
replace wtd_summary_rank = /*3726*/ count-wtd_summary_rank+1
*/
gen pct_rank = 100*wtd_summary_rank/count
replace pct_rank = 100-pct_rank
gen baseline_pct_rank = 100*baseline_rank/count
drop count
save paper_data/rankdata, replace
 
tab real_rating    baseline_stars if sim == 45
tab real_rating             stars if sim == 45
tab baseline_stars          stars if sim == 45

* flags for each star rating...
use paper_data/rankdata, clear

forval i = 1/5 {
	gen byte stars`i' = cond(!missing(wtd_summary_score), stars == `i', .)
}

gen abs_pct_rank_change = abs(baseline_pct_rank-pct_rank)

label define missing_domains 	-1 "All hospitals" /// 
							     0 "All five domains reported" ///
							     1 "Four domains reported" ///
							     2 "Three domains reported" /// 
						, modify
label values missing_domains missing_domains


* predictive value of baseline star ratings
preserve
* get to one row per hospital
gen change_star = baseline_stars != stars

collapse 	(mean) stars? ///
			(mean) abs_pct_rank_change change_star ///
			, 	by(missing_domains baseline_stars facilityid) fast
expand 2, gen(expanded)
replace missing_domains = -1 if expanded
drop expanded

expand 2, gen(expanded)
replace baseline_stars = 9 if expanded

* get to one row per missing data category
gen count = 1
collapse (sum) count (mean) stars? abs_pct_rank_change* change_star*, by(missing_domains baseline_stars) fast

order missing_domains baseline_stars
gsort missing_domains -baseline_stars
order missing_domains baseline_s count abs_pct_rank_change stars5 stars4 stars3 stars2 stars1
list, sepby(missing_domains)

export excel using results/Table4_Data.xlsx, replace firstrow(var)
restore


/* In each simulation, calculate:
	Frequency by type
	Proportion changing to each stars
	abs pct rank change (mean)
	Proportion changing star
*/

preserve
keep sim facilityid missing_domains baseline_stars stars stars? abs_pct_rank_change

gen change_star = baseline_stars != stars

expand 2, gen(expanded)
replace missing_domains = -1 if expanded
drop expanded

expand 2, gen(expanded)
replace baseline_stars = 9 if expanded

gen count = 1

collapse 	(sum) count /// 
			(mean) stars? ///
			(mean) abs_pct_rank_change change_star ///
			, 	by(missing_domains baseline_stars sim) fast


collapse 	(mean) count /// 
			(mean) stars? ///
			(mean) abs_pct_rank_change change_star ///
			(p25) abs_pct_rank_change_p25 = abs_pct_rank_change change_star_p25 = change_star ///
			(p75) abs_pct_rank_change_p75 = abs_pct_rank_change change_star_p75 = change_star ///
			, 	by(missing_domains baseline_stars) fast
			
order missing_domains baseline_stars count stars? abs_pct_rank_change* change_star*
list, sepby(missing_domains)

order missing_domains baseline_stars
gsort missing_domains -baseline_stars
order missing_domains baseline_s count stars5 stars4 stars3 stars2 stars1 change_star* abs_pct_rank_change*
list, sepby(missing_domains)


export excel using results/Table4_Data_New.xlsx, replace firstrow(var)

restore

/******************************************************************************/
/* Scatter plot of random simulations */
* scatter plot
preserve
keep if inlist(sim, 514, 2857, 2969, 3588)
list sim wt_d* in 1
set scheme s1color

#delimit ;
label define sim	514 "A. Simulation 514"
					2857 "B. Simulation 2857"
					2969 "C. Simulation 2969"
					3588 "D. Simulation 3588"
	;
#delimit cr
label values sim sim

#delimit ;
twoway	(
	scatter wtd_summary_rank baseline_rank if baseline_stars == 5 & missing_domains  == 2
	, 	msymb(oh) mcol(gs4%50)
	)
	(
	scatter wtd_summary_rank baseline_rank if baseline_stars == 5 & missing_domains  == 0
	, 	msymb(o ) mcol(red%40) 
	)
	(
	scatter wtd_summary_rank baseline_rank if baseline_stars == 5 & missing_domains  == 1
	, 	msymb(d ) mcol(blue%40)
	)
	
	,	by(sim, note(""))
		legend(
			order(
				2 "All five domains reported" 
				3 "Four domains reported"
				1 "Three domains reported"
			)
			symxs(*5)
			region(lstyle(none))
			cols(3)
			size(small)
		)
		subtitle(
			,	pos(11)
				fcolor(gs0)
				color(gs16)
		)
		ylabel(
			 80    "5 star"
			705.5  "4 star"
			1843   "3 star"
			2964.5 "2 star"
			3700   "1 star"
			,	angle(h)
				tl(0)
				nogrid
		)
		ytick(
			225
			1186
			2500
			3429
			,	tl(0)
				grid
		)
		ysc(noline r(1 3726))
		xlabel(1 75 150 225)
		xsc(noline)
		xtitle("Rank under 2020 CMS approach")
		ytitle("Rank and star rating under alternative approach")
		
;
#delimit cr
graph export results/figure1_paper.tif, width(1000) replace
graph export results/figure1_paper.pdf, xsize(8) ysize(6) replace
restore


/******************************************************************************/
/* Some additional quantities for the text */

/* Means and IQRs for:
	- '% of five-star hospitals receiving 3-stars or fewer'
	- '4/5star as 4/5star'
	- '3 star as 3 star'
	- '1/2star as 1/2star'

	Means and CI for 'percent into non-adjacent category under alt standard'
*/

/* Means and IQRs for:
	- '% of five-star hospitals receiving 3-stars or fewer'
*/
use paper_data/rankdata, clear

keep sim stars baseline_stars
gen stars3 = stars <= 3
collapse (mean) stars3, by(baseline_stars sim)
collapse (mean) stars3 (p25) q1_stars = stars3 (p75) q3_stars = stars3, by(baseline_stars)
list

/* Means and IQRs for:
	- '4/5star as 4/5star'
*/
use paper_data/rankdata, clear

keep sim stars baseline_stars
gen star_class = inlist(stars, 4, 5)
gen byte baseline_class = 5 if inlist(baseline_stars, 4, 5)
replace  baseline_class = 3 if inlist(baseline_stars, 3)
replace  baseline_class = 1 if inlist(baseline_stars, 1, 2)

collapse (mean) star_class, by(baseline_class sim)
collapse (mean) star_class (p25) q1_stars = star_class (p75) q3_stars = star_class, by(baseline_class)

format star_class q1_stars q3_stars %9.3fc
list

/* Means and IQRs for:
	- '3 star as 3 star'
*/
use paper_data/rankdata, clear

keep sim stars baseline_stars
gen star_class = inlist(stars, 3)
gen byte baseline_class = 5 if inlist(baseline_stars, 4, 5)
replace  baseline_class = 3 if inlist(baseline_stars, 3)
replace  baseline_class = 1 if inlist(baseline_stars, 1, 2)

collapse (mean) star_class, by(baseline_class sim)
collapse (mean) star_class (p25) q1_stars = star_class (p75) q3_stars = star_class, by(baseline_class)

format star_class q1_stars q3_stars %9.3fc
list

/* Means and IQRs for:
	- '1/2star as 1/2star'
*/
use paper_data/rankdata, clear

keep sim stars baseline_stars
gen star_class = inlist(stars, 1, 2)
gen byte baseline_class = 5 if inlist(baseline_stars, 4, 5)
replace  baseline_class = 3 if inlist(baseline_stars, 3)
replace  baseline_class = 1 if inlist(baseline_stars, 1, 2)

collapse (mean) star_class, by(baseline_class sim)
collapse (mean) star_class (p25) q1_stars = star_class (p75) q3_stars = star_class, by(baseline_class)

format star_class q1_stars q3_stars %9.3fc
list

/* 	Means and CI for 'percent into non-adjacent category under alt standard'
*/
use data/approaches_combined.dta, clear

keep facilityid std1_grp1_wt1_stars std2_grp1_wt1_stars
gen nonadj = abs(std1_grp1_wt1_stars-std2_grp1_wt1_stars) >= 2

ci proportions nonadj, wilson

