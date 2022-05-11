/******************************************************************************/
/* 	Combine
	
	Combines the grouped data to produce overall scores and ranks.
	
	2022-03-03
	Version 2.0
*/


/******************************************************************************/
/* Program to assign star ratings											  */
cap program drop assign_stars
program define assign_stars
	syntax varname , gen(string)
	
	tempvar s2 one mcat
	
	gen byte `gen' = .
	
	* gen three 'missing categories' and assign stars within each
	gen byte `mcat' = 0
	replace `mcat' = 1 if grp1_missing == 1
	replace `mcat' = 2 if grp1_missing >= 2
	
	qui forval missing = 0/2 {
		
		* assign groups
		cluster kmeans `varlist' if `mcat' == `missing', k(5) gen(`gen'`missing')

		* put in score order
		gen `s2' = .
		forval i = 1/5 {
			summ `varlist' if `gen'`missing' == `i', meanonly
			replace `s2' = r(mean) if `gen'`missing' == `i'
		}
		sort `mcat' `s2' `varlist' facilityid
		by `mcat' `s2': gen `one' = _n == 1 if !missing(`s2')
		by `mcat': replace `one' = sum(`one') if !missing(`s2')
		replace `gen'`missing' = `one'
		drop `s2' `one' 
		
		replace `gen' = `gen'`missing' if `mcat' == `missing'
		drop `gen'`missing'
		
	}
	

	sort facilityid
	
end

/******************************************************************************/
/* Z scores, assigned groups, approx. policy weights						  */
use data/std_method1_grp_pol.dta, clear

gen mortality_wt 	= 0.22
gen safety_wt 		= 0.22
gen readm_wt 		= 0.22
gen ptexp_wt 		= 0.22
gen timely_wt 		= 0.12

foreach thing in mortality safety readm ptexp timely {
	replace `thing'_wt = . if missing(`thing'_m1)
	
	gen `thing'_wtd = `thing'_m1*`thing'_wt
}

* must have at least 3 groups and at least 1 "outcome" group
egen nm = rownonmiss(*_m1)

preserve
tempfile domain_counts
keep facilityid nm
rename nm missing_domains
compress
save `domain_counts'
restore

egen tot_wt = rowtotal(*_wt)
egen score = rowtotal(*_wtd) if nm >= 3 & (!missing(mortality_m1) | !missing(safety_m1) | !missing(readm_m1))

replace score = score/tot_wt
gen s2 = score

* assign rank
sort score
egen rank = rank(score), by(nm) field
sort rank

* look
list facilityid nm score rank in 1/10

egen grp1_missing = rowmiss(*_m1)

keep facilityid score rank grp1_missing
rename (score rank) (std1_grp1_wt1_score std1_grp1_wt1_rank)

label var std1_grp1_wt1_score 	"Summary score. Z-scores, assigned groups, policy weights"
label var std1_grp1_wt1_rank  	"Summary rank. Z-scores, assigned groups, policy weights"
label var grp1_missing 		  	"Missing groups, as assigned"

* assign star rating using k-means clustering
assign_stars std1_grp1_wt1_score, gen(std1_grp1_wt1_stars)
label var std1_grp1_wt1_stars 	"Star rating. Z-scores, assigned groups, policy weights"

label data "Overall scores. Z-scores, assigned groups, policy weights"
save data/std1_grp1_wt1_overall.dta, replace


/******************************************************************************/
/* Z scores, assigned groups, approx. policy weights						  */
use data/std_method1_grp_pol.dta, clear

gen mortality_wt 	= 0.22
gen safety_wt 		= 0.22
gen readm_wt 		= 0.22
gen ptexp_wt 		= 0.22
gen timely_wt 		= 0.12

foreach thing in mortality safety readm ptexp timely {
	replace `thing'_wt = . if missing(`thing'_m1)
	
	gen `thing'_wtd = `thing'_m1*`thing'_wt
}

* must have at least 3 groups and at least 1 "outcome" group
egen nm = rownonmiss(*_m1)
egen tot_wt = rowtotal(*_wt)
egen score = rowtotal(*_wtd) if nm >= 3 & (!missing(mortality_m1) | !missing(safety_m1) | !missing(readm_m1))

replace score = score/tot_wt
gen s2 = score

* assign rank
sort score
egen rank = rank(score), by(nm) field
sort rank

* look
list facilityid nm score rank in 1/10

egen grp1_missing = rowmiss(*_m1)

keep facilityid score rank grp1_missing
rename (score rank) (std1_grp1_wt1_score std1_grp1_wt1_rank)

label var std1_grp1_wt1_score 	"Summary score. Z-scores, assigned groups, policy weights"
label var std1_grp1_wt1_rank  	"Summary rank. Z-scores, assigned groups, policy weights"
label var grp1_missing 		  	"Missing groups, as assigned"

* assign star rating using k-means clustering
assign_stars std1_grp1_wt1_score, gen(std1_grp1_wt1_stars)
label var std1_grp1_wt1_stars 	"Star rating. Z-scores, assigned groups, policy weights"

label data "Overall scores. Z-scores, assigned groups, policy weights"
save data/std1_grp1_wt1_overall_nowinsor.dta, replace



/******************************************************************************/
/* Reference scores, assigned groups, approx. policy weights				  */
use data/std_method2_grp_pol.dta, clear

gen mortality_wt 	= 0.22
gen safety_wt 		= 0.22
gen readm_wt 		= 0.22
gen ptexp_wt 		= 0.22
gen timely_wt 		= 0.12

foreach thing in mortality safety readm ptexp timely {
	replace `thing'_wt = . if missing(`thing'_m2)
	gen `thing'_wtd = `thing'_m2*`thing'_wt
}

* must have at least 3 groups and at least 1 "outcome" group
egen nm = rownonmiss(*_m2)
egen tot_wt = rowtotal(*_wt)
egen score = rowtotal(*_wtd) if nm >= 3 & (!missing(mortality_m2) | !missing(safety_m2) | !missing(readm_m2))

gen s2 = score
replace score = score/tot_wt
sort score

* assign rank
sort score
egen rank = rank(score), by(nm) field
sort rank

* look
list facilityid nm score rank in 1/10

egen grp1_missing = rowmiss(*_m2)

keep facilityid score rank grp1_missing
rename (score rank) (std2_grp1_wt1_score std2_grp1_wt1_rank)

label var std2_grp1_wt1_score "Summary score. Reference scores, assigned groups, policy weights"
label var std2_grp1_wt1_rank  "Summary rank. Reference scores, assigned groups, policy weights"

* assign star rating using k-means clustering
assign_stars std2_grp1_wt1_score, gen(std2_grp1_wt1_stars)
label var std2_grp1_wt1_stars 	"Star rating. Reference scores, assigned groups, policy weights"

label data "Overall scores. Reference scores, assigned groups, policy weights"
save data/std2_grp1_wt1_overall.dta, replace


/******************************************************************************/
/* Z scores, EFA groups, approx. policy weights								  */
use data/std_method1_grp_efa.dta, clear

keep facilityid f1-f6

gen f1_wt 	= 0.22 // patient experience
gen f2_wt 	= 0.22 // readmission
gen f3_wt 	= 0.06 // ED process
gen f4_wt 	= 0.22 // Mortality
gen f5_wt	= 0.06 // OP process
gen f6_wt 	= 0.22 // CABG

foreach thing in f1 f2 f3 f4 f5 f6 {
	replace `thing'_wt = . if missing(`thing')
	
	gen `thing'_wtd = `thing'*`thing'_wt
}

* must have at least 3 groups and at least 1 "outcome" group
egen nm = rownonmiss(f1-f6)
egen tot_wt = rowtotal(*_wt)
egen score = rowtotal(*_wtd) if nm >= 3 & (!missing(f2) | !missing(f4) | !missing(f6))
replace score = score/tot_wt
sort score

* assign rank
sort score
merge 1:1 facilityid using `domain_counts'
egen rank = rank(score), by(missing_domains) field
sort rank
drop missing_domains

* look
list facilityid nm score rank in 1/10

egen grp2_missing = rowmiss(f1-f6)
merge 1:1 facilityid using data/std1_grp1_wt1_overall.dta, assert(3) nogenerate

keep facilityid score rank grp1_missing grp2_missing
rename (score rank) (std1_grp2_wt1_score std1_grp2_wt1_rank)

label var std1_grp2_wt1_score 	"Summary score. Z-scores, EFA groups, approx. policy weights"
label var std1_grp2_wt1_rank  	"Summary rank. Z-scores, EFA groups, approx. policy weights"
label var grp2_missing 		  	"Missing groups, EFA"

* assign star rating using k-means clustering
assign_stars std1_grp2_wt1_score, gen(std1_grp2_wt1_stars)
label var std1_grp2_wt1_stars 	"Star rating. Z-scores, EFA groups, policy weights"

label data "Overall scores. Z-scores, EFA groups, approx. policy weights"
save data/std1_grp2_wt1_overall.dta, replace


/******************************************************************************/
/* Reference scores, EFA groups, approx. policy weights						  */
use data/std_method2_grp_efa.dta, clear

keep facilityid f1-f6

gen f1_wt 	= 0.22 // patient experience
gen f2_wt 	= 0.22 // readmission
gen f3_wt 	= 0.06 // ED process
gen f4_wt 	= 0.22 // Mortality
gen f5_wt	= 0.06 // OP process
gen f6_wt 	= 0.22 // CABG

foreach thing in f1 f2 f3 f4 f5 f6 {
	replace `thing'_wt = . if missing(`thing')
	gen `thing'_wtd = `thing'*`thing'_wt
}

* must have at least 3 groups and at least 1 "outcome" group
egen nm = rownonmiss(f1-f6)
egen tot_wt = rowtotal(*_wt)
egen score = rowtotal(*_wtd) if nm >= 3 & (!missing(f2) | !missing(f4) | !missing(f6))
replace score = score/tot_wt

* assign rank
sort score
merge 1:1 facilityid using `domain_counts'
egen rank = rank(score), by(missing_domains) field
sort rank
drop missing_domains

* look
list facilityid nm score rank in 1/10

merge 1:1 facilityid using data/std1_grp1_wt1_overall.dta, assert(3) nogenerate

keep facilityid score rank grp1_missing
rename (score rank) (std2_grp2_wt1_score std2_grp2_wt1_rank)

label var std2_grp2_wt1_score "Summary score. Reference scores, EFA groups, approx. policy weights"
label var std2_grp2_wt1_rank  "Summary rank. Reference scores, EFA groups, approx. policy weights"

* assign star rating using k-means clustering
assign_stars std2_grp2_wt1_score, gen(std2_grp2_wt1_stars)
label var std2_grp2_wt1_stars 	"Star rating. Reference scores, EFA groups, approx. policy weights"

label data "Overall scores. Reference scores, EFA groups, approx. policy weights"
save data/std2_grp2_wt1_overall.dta, replace


/******************************************************************************/
/* Z scores, assigned groups, equal weights									  */
use data/std_method1_grp_pol.dta, clear

gen mortality_wt 	= 1
gen safety_wt 		= 1
gen readm_wt 		= 1
gen ptexp_wt 		= 1
gen effic_wt		= 1
gen timely_wt 		= 1
gen effec_wt		= 1

foreach thing in mortality safety readm ptexp timely {
	replace `thing'_wt = . if missing(`thing'_m1)
	
	gen `thing'_wtd = `thing'_m1*`thing'_wt
}

* calculate score
* must have at least 3 groups and at least 1 "outcome" group
egen nm = rownonmiss(*_m1)
egen tot_wt = rowtotal(*_wt)
egen score = rowtotal(*_wtd) if nm >= 3 & (!missing(mortality_m1) | !missing(safety_m1) | !missing(readm_m1))
replace score = score/tot_wt

* assign rank
sort score
egen rank = rank(score), by(nm) field
sort rank

* look
list facilityid nm score rank in 1/10

merge 1:1 facilityid using data/std1_grp1_wt1_overall.dta, assert(3) nogenerate

keep facilityid score rank grp1_missing
rename (score rank) (std1_grp1_wt2_score std1_grp1_wt2_rank)

label var std1_grp1_wt2_score "Summary score. Z-scores, assigned groups, equal weights"
label var std1_grp1_wt2_rank  "Summary rank. Z-scores, assigned groups, equal weights"

* assign star rating using k-means clustering
assign_stars std1_grp1_wt2_score, gen(std1_grp1_wt2_stars)
label var std1_grp1_wt2_stars 	"Star rating. Z-scores, assigned groups, equal weights"

label data "Overall scores. Z-scores, assigned groups, equal weights"
save data/std1_grp1_wt2_overall.dta, replace


/******************************************************************************/
/* Reference scores, assigned groups, equal weights							  */
use data/std_method2_grp_pol.dta, clear

gen mortality_wt 	= 1
gen safety_wt 		= 1
gen readm_wt 		= 1
gen ptexp_wt 		= 1
gen effic_wt		= 1
gen timely_wt 		= 1
gen effec_wt		= 1

foreach thing in mortality safety readm ptexp timely {
	replace `thing'_wt = . if missing(`thing'_m2)
	gen `thing'_wtd = `thing'_m2*`thing'_wt
}

* calculate score
* must have at least 3 groups and at least 1 "outcome" group
egen nm = rownonmiss(*_m2)
egen tot_wt = rowtotal(*_wt)
egen score = rowtotal(*_wtd) if nm >= 3 & (!missing(mortality_m2) | !missing(safety_m2) | !missing(readm_m2))
replace score = score/tot_wt

* assign rank
sort score
egen rank = rank(score), by(nm) field
sort rank

* look
list facilityid nm score rank in 1/10

merge 1:1 facilityid using data/std1_grp1_wt1_overall.dta, assert(3) nogenerate

keep facilityid score rank grp1_missing
rename (score rank) (std2_grp1_wt2_score std2_grp1_wt2_rank)

label var std2_grp1_wt2_score "Summary score. Reference scores, assigned groups, equal weights"
label var std2_grp1_wt2_rank  "Summary rank. Reference scores, assigned groups, equal weights"

* assign star rating using k-means clustering
assign_stars std2_grp1_wt2_score, gen(std2_grp1_wt2_stars)
label var std2_grp1_wt2_stars 	"Star rating. Reference scores,assigned groups, equal weights"

label data "Overall scores. Reference scores, assigned groups, equal weights"
save data/std2_grp1_wt2_overall.dta, replace


/******************************************************************************/
/* Z scores, EFA groups, equal weights										  */
use data/std_method1_grp_efa.dta, clear

keep facilityid f1-f6

gen f1_wt 	= 1    // patient experience
gen f2_wt 	= 1    // safe, timely care
gen f3_wt 	= 1    // readmissions, complications
gen f4_wt 	= 1    // appropriate care
gen f5_wt	= 1    // Mortality
gen f6_wt 	= 1    // CAUTI

foreach thing in f1 f2 f3 f4 f5 f6 {
	replace `thing'_wt = . if missing(`thing')
	
	gen `thing'_wtd = `thing'*`thing'_wt
}

* must have at least 3 groups and at least 1 "outcome" group
egen nm = rownonmiss(f1-f6)
egen tot_wt = rowtotal(*_wt)
egen score = rowtotal(*_wtd) if nm >= 3 & (!missing(f2) | !missing(f4) | !missing(f6))
replace score = score/tot_wt

* assign rank
sort score
merge 1:1 facilityid using `domain_counts'
egen rank = rank(score), by(missing_domains) field
sort rank
drop missing_domains

* look
list facilityid nm score rank in 1/10

merge 1:1 facilityid using data/std1_grp1_wt1_overall.dta, assert(3) nogenerate

keep facilityid score rank grp1_missing
rename (score rank) (std1_grp2_wt2_score std1_grp2_wt2_rank)

label var std1_grp2_wt2_score "Summary score. Z-scores, EFA groups, equal weights"
label var std1_grp2_wt2_rank  "Summary rank. Z-scores, EFA groups, equal weights"

* assign star rating using k-means clustering
assign_stars std1_grp2_wt2_score, gen(std1_grp2_wt2_stars)
label var std1_grp2_wt2_stars 	"Star rating. Z-scores, EFA groups, equal weights"

label data "Overall scores. Z-scores, EFA groups, equal weights"
save data/std1_grp2_wt2_overall.dta, replace


/******************************************************************************/
/* Reference scores, EFA groups, equal weights								  */
use data/std_method2_grp_efa.dta, clear

keep facilityid f1-f6

gen f1_wt 	= 1    // patient experience
gen f2_wt 	= 1    // safe, timely care
gen f3_wt 	= 1    // readmissions, complications
gen f4_wt 	= 1    // appropriate care
gen f5_wt	= 1    // Mortality
gen f6_wt 	= 1    // CAUTI

foreach thing in f1 f2 f3 f4 f5 f6 {
	replace `thing'_wt = . if missing(`thing')
	gen `thing'_wtd = `thing'*`thing'_wt
}

* must have at least 3 groups and at least 1 "outcome" group
egen nm = rownonmiss(f1-f6)
egen tot_wt = rowtotal(*_wt)
egen score = rowtotal(*_wtd) if nm >= 3 & (!missing(f2) | !missing(f4) | !missing(f6))
replace score = score/tot_wt

* assign rank
sort score
merge 1:1 facilityid using `domain_counts'
egen rank = rank(score), by(missing_domains) field
sort rank
drop missing_domains

* look
list facilityid nm score rank in 1/10

merge 1:1 facilityid using data/std1_grp1_wt1_overall.dta, assert(3) nogenerate

keep facilityid score rank grp1_missing
rename (score rank) (std2_grp2_wt2_score std2_grp2_wt2_rank)

label var std2_grp2_wt2_score "Summary score. Reference scores, EFA groups, equal weights"
label var std2_grp2_wt2_rank  "Summary rank. Reference scores, EFA groups, equal weights"

* assign star rating using k-means clustering
assign_stars std2_grp2_wt2_score, gen(std2_grp2_wt2_stars)
label var std2_grp2_wt2_stars 	"Star rating. Reference scores, EFA groups, equal weights"

label data "Overall scores. Reference scores, EFA groups, equal weights"
save data/std2_grp2_wt2_overall.dta, replace


/******************************************************************************/
/* Combine scores/ranks from different approaches							  */
use data/star_data_2021.dta, clear
keep facilityid real_rating

merge 1:1 facilityid using data/std1_grp1_wt1_overall.dta, assert(3) nogenerate
merge 1:1 facilityid using data/std2_grp1_wt1_overall.dta, assert(3) nogenerate
merge 1:1 facilityid using data/std1_grp2_wt1_overall.dta, assert(3) nogenerate
merge 1:1 facilityid using data/std2_grp2_wt1_overall.dta, assert(3) nogenerate
merge 1:1 facilityid using data/std1_grp1_wt2_overall.dta, assert(3) nogenerate
merge 1:1 facilityid using data/std2_grp1_wt2_overall.dta, assert(3) nogenerate
merge 1:1 facilityid using data/std1_grp2_wt2_overall.dta, assert(3) nogenerate
merge 1:1 facilityid using data/std2_grp2_wt2_overall.dta, assert(3) nogenerate

label var std1_grp1_wt1_rank  "Z-scores, assigned groups, policy weights"
label var std1_grp1_wt2_rank  "Z-scores, assigned groups, equal weights"
label var std1_grp2_wt1_rank  "Z-scores, EFA groups, approx. policy weights"
label var std1_grp2_wt2_rank  "Z-scores, EFA groups, equal weights"

label var std2_grp1_wt1_rank  "Reference scores, assigned groups, policy weights"
label var std2_grp1_wt2_rank  "Reference scores, assigned groups, equal weights"
label var std2_grp2_wt1_rank  "Reference scores, EFA groups, approx. policy weights"
label var std2_grp2_wt2_rank  "Reference scores, EFA groups, equal weights"

#delimit ;
order 
	facilityid 
	real_rating
	std1_grp1_wt1_score 
	std1_grp1_wt2_score
	std1_grp2_wt1_score
	std1_grp2_wt2_score
	std2_grp1_wt1_score
	std2_grp1_wt2_score
	std2_grp2_wt1_score
	std2_grp2_wt2_score
	std1_grp1_wt1_rank 
	std1_grp1_wt2_rank
	std1_grp2_wt1_rank
	std1_grp2_wt2_rank
	std2_grp1_wt1_rank
	std2_grp1_wt2_rank
	std2_grp2_wt1_rank
	std2_grp2_wt2_rank
	std1_grp1_wt1_stars 
	std1_grp1_wt2_stars
	std1_grp2_wt1_stars
	std1_grp2_wt2_stars
	std2_grp1_wt1_stars
	std2_grp1_wt2_stars
	std2_grp2_wt1_stars
	std2_grp2_wt2_stars
;
#delimit cr

gen grp1_cat = grp1_missing
replace grp1_cat = 3 if grp1_cat > 3

gen grp2_cat = grp2_missing
replace grp2_cat = 3 if grp2_cat > 3

#delimit ;
label define grp_cat	0 "All domains reported"
						1 "One domain missing"
						2 "Two domains missing"
						3 "Three or more domains missing"
						, replace
						;
#delimit cr

label values grp1_cat grp_cat
label values grp2_cat grp_cat

compress
save data/approaches_combined.dta, replace

tab real_rating std1_grp1_wt1_stars if grp1_cat == 0
tab real_rating std1_grp1_wt1_stars if grp1_cat == 1
tab real_rating std1_grp1_wt1_stars if grp1_cat == 2

graph box std1_grp1_wt1_score , over(real_rating) over(grp1_cat)
graph box std1_grp1_wt1_rank  , over(real_rating) over(grp1_cat)
