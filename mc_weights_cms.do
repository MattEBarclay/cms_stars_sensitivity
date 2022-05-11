/* 
	Program to do Monte Carlo sim with CMS data
*/

* expand version
cap program drop mc_cms
program define mc_cms
	syntax , std_sim(int) grp_sim(int) sims(real) sim_rotate(real) save(string)
	
	quietly {

		* expand it!
		expand `sims'
		sort facilityid
		by facilityid: gen sim = _n
		sort sim facilityid
		
		if `grp_sim' == 1 {
			* include grouping approach in half of sims
			by sim: gen grp_use =  rbinomial(1,0.5) if _n == 1
			replace grp_use = grp_use[_n-1] if missing(grp_use)
		}
		else {
			* just use the base approach
			gen grp_use = 0
		}
		
		if `std_sim' == 1 {
			* include standardisation approach in half of sims
			by sim: gen std_use =  rbinomial(1,0.5) if _n == 1	
			replace std_use = std_use[_n-1] if missing(std_use)
		}
		else {
			 * just use the base approach
			gen std_use = 0
		}
		
		forval i = 1/6 {
			gen mean_wt_d`i' = .
		}
		
		* gen measures to look at
		forval i = 1/6 {
			gen domain`i' = .
		}
		
		* get domain scores in consistent named variable	
		forval i = 1/5 {
			replace domain`i' = std0_grp0_measure`i' if std_use == 0 & grp_use == 0
			replace domain`i' = std1_grp0_measure`i' if std_use == 1 & grp_use == 0
			replace domain`i' = std0_grp1_measure`i' if std_use == 0 & grp_use == 1
			replace domain`i' = std1_grp1_measure`i' if std_use == 1 & grp_use == 1
		}
		replace domain6 = std0_grp1_measure6 if std_use == 0 & grp_use == 1
		* if groups are different, then no measure 7
		
		* drop irrelevant info
		drop *_measure*
		
		* if looking at alternate groupings...
		replace mean_wt_d1 = 0.22 if grp_use == 1
		replace mean_wt_d2 = 0.22 if grp_use == 1
		replace mean_wt_d3 = 0.06 if grp_use == 1
		replace mean_wt_d4 = 0.22 if grp_use == 1
		replace mean_wt_d5 = 0.06 if grp_use == 1
		replace mean_wt_d6 = 0.22 if grp_use == 1

		* if looking at standard groupings...
		replace mean_wt_d1 = 0.22 if grp_use == 0
		replace mean_wt_d2 = 0.22 if grp_use == 0
		replace mean_wt_d3 = 0.22 if grp_use == 0
		replace mean_wt_d4 = 0.22 if grp_use == 0
		replace mean_wt_d5 = 0.12 if grp_use == 0
		
		* standard deviation of weights
		local sd_wt = 1.5
		
		qui forval i = 1/6 {
			* generate random measure weights for each domain		
			by sim: gen wt_d`i' = invlogit(rnormal(logit(mean_wt_d`i'),`sd_wt')) if _n == 1
			replace wt_d`i' = wt_d`i'[_n-1] if missing(wt_d`i')
			
			* check not missing before we do any blanking
			assert !missing(wt_d`i') | (`i' == 6 & grp_use == 0)
			
			* blank the weight if missing domain
			replace wt_d`i' = . if missing(domain`i')
			
			* generate 'weighted performance'
			gen wtd_d`i' = wt_d`i'*domain`i'
			
		}
		* generate total weight
		egen totwt = rowtotal(wt_d*)

		* generate summary score based on total weights
		egen wtd_summary_score = rowtotal(wtd_d*)
		replace wtd_summary_score = wtd_summary_score/totwt
		
		*assign_stars wtd_summary_score, gen(stars)
		
		keep  sim facilityid missing_domains wt_d* grp std /*stars*/ wtd_summary_score  
		order sim facilityid missing_domains wt_d* grp std /*stars*/ wtd_summary_score 
		list  sim facilityid missing_domains wtd_summary_score in 1/4
		
		egen wtd_summary_rank = rank(wtd_summary_score), by(sim missing_domains) track
		
		* assign stars - need to loop over sims
		tempvar s2 one mcat
		
		gen byte stars = .
		
		* frame for results
		cap frame drop results
		frame create results
		tempfile results_temp
		
		qui forval simulation = 1/`sims' {
			
			if mod(`simulation', 10) == 0 {
				if `simulation' == 10 {
					nois dis as text _col(5)       "`simulation'" _cont
				}
				else {
					nois dis as text _col(5) _cont " ..`simulation'" 
				}
			}
						
			forval missing = 0/2 {
				
				cap frame drop clustering
				frame put if missing_domains == `missing' & sim == `simulation', into(clustering)
				
				/* switch to clustering frame with limited data */
				frame change clustering
				
				cluster kmeans wtd_summary_score if missing_domains == `missing' & sim == `simulation', k(5) gen(stars`missing')

				* put in score order
				gen `s2' = .
				forval i = 1/5 {
					summ wtd_summary_score if stars`missing' == `i' & sim == `simulation', meanonly
					replace `s2' = r(mean) if stars`missing' == `i' & sim == `simulation'
				}
				sort sim missing_domains `s2' wtd_summary_score facilityid
				by   sim missing_domains `s2': gen `one' = _n == 1 if !missing(`s2')
				by   sim missing_domains: replace `one' = sum(`one') if !missing(`s2') & sim == `simulation'
				replace stars`missing' = `one'
				drop `s2' `one' 
				
				replace stars = stars`missing' if missing_domains == `missing' & sim == `simulation'
				drop stars`missing'
				
				save `results_temp', replace
				
				frame change results
				append using `results_temp'
				
				frame change default
				frame drop clustering
				
			}
			
		}	
		
		/* switch back to default to link */
		frame change default 
		frlink 1:1 facilityid sim, frame(results)
		drop stars
		frget stars, from(results)
		
		drop results
		frame drop results
		/**/
	

		sort facilityid
		
		label var sim "Simulation number"
		label var facilityid "Hospital ID"
		label var wt_d1 "Weight given to domain 1"
		label var wt_d2 "Weight given to domain 2"
		label var wt_d3 "Weight given to domain 3"
		label var wt_d4 "Weight given to domain 4"
		label var wt_d5 "Weight given to domain 5"
		label var wt_d6 "Weight given to domain 6"
		label var grp   "Domain grouping used (0 = base, 1 = alternative)"
		label var std	"Standardisation used (0 = base, 1 = alternative)"
		label var stars "Star Rating"
		label var wtd_summary_score "Summary score"
		label var wtd_summary_rank 	"Summary rank"
		
		* update simulation number to reflect rotation
		replace sim = sim + (`sim_rotate'-1)*`sims'
		
		order sim facilityid missing_domains wt_d* grp std stars wtd_summary_score wtd_summary_rank	
	
	}
	
	qui save simdata/`save', replace
	
end
