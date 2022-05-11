/******************************************************************************/
/* 	Group
	
	Original groups are well-defined. This uses factor analysis (ML) to identify 
	groups from the Z-scored and reference-grouped data.
	
	2020-11-25
	Version 1.0
*/

clear
cap log c


log using StarRatings_efa_log.smcl, replace

/******************************************************************************/
/* Find groups in Z-scored data 											  */
use data/std_method1.dta, clear

keep 	facilityid /// 
		mortality_? /// 
		safety_? ///
		readm_* ///
		ptexp_?  /// 
		timely_* ///

/*
graph matrix mortality*	, name(mortality, replace)	msymb(oh) mcolor(gs0%10)
graph matrix safety*	, name(safety, replace)		msymb(oh) mcolor(gs0%10)
graph matrix readm*		, name(readm, replace)		msymb(oh) mcolor(gs0%10)
graph matrix ptexp*		, name(ptexp, replace)		msymb(oh) mcolor(gs0%10)
graph matrix timely*	, name(timely, replace)		msymb(oh) mcolor(gs0%10)
*/	

* perform factor analysis with incomplete data
* see:
*	https://stats.idre.ucla.edu/stata/faq/how-can-i-do-factor-analysis-with-missing-data-in-stata/
mi set mlong

* ignore v high missing variables
mi misstable summarize
rename (timely_8) ignore_=


* can now get a "cc" correlation matrix (based on 80 observations!)
/*
corr	mortality_? /// 
		safety_? ///
		readm_* ///
		ptexp_?  /// 
		timely_1-timely_7 timely_9-timely_15 ///
		,	cov
		
summ mortality_? /// 
		safety_? ///
		readm_* ///
		ptexp_?  /// 
		timely_* 
*/

* register as imputed
mi register imputed mortality_? /// 
					safety_? ///
					readm_* ///
					ptexp_?  /// 
					timely_* 
		

* calculate ML covariance matrix using expectation-maximisation
mi impute mvn 	mortality_? /// 
				safety_? ///
				readm_* ///
				ptexp_?  /// 
				timely_* ///
				,	emonly(iter(100000)) 
				
matrix cov_em_method1 = r(Sigma_em)
matrix list cov_em_method1

* how many?
factormat cov_em_method1, n(`=_N') ml 
screeplot

* argues for 6 or 7 in the elbow?
* argues for 6 based on eigenvalues > 1
* 7 factors explain >0.8 of the variance

factormat cov_em_method1, n(`=_N') ml factors(6)
rotate, promax normalize 

* see excel file for details of factor assignments

/******************************************************************************/
/* Find groups in reference-standardised data								  */

/* Let's just use the groups from the Z-score data */

log close
