***** Table & Figure Reconstruction *****

/* Code to reproducte the main tables and figures in the paper "Did Craigslist's Erotic Services Reduce Female Homicide and Rape?" by Scott Cunningham, Gregory DeAngelo, and John Tripp. */

/* To recreate the datasets called in this script, please execute the recreate_data_cleaning.do first. */

/* Make sure to have installed the following commands: sg30, csdid, reghdfe, drdid, missings, event_plot, estout, avar, ftools, github, eventstudyinteract, coefplott, moremata, twowayfeweights, carryforward, outreg2, stutex, cmogram, ddtiming, _gwtmean, and fect (from https://raw.githubusercontent.com/xuyiqing/fect_stata/master/). */

/* You will need to indicate the directory where the data are saved. If you encounter an error in the code that is not resolved by installing an additional command, please reach out via github and the authors will work to address the concern. */

cd ""

***** Tables *****
{/* Table 1 -- Summary Statistics for the Craigslist sample (1995-2009).*/ 
/* Note: All variables are measured at the ORI-month level for crime variables and market-month for TER variables. */
***** Block 1 ******
use ../data/ers_shr_combined.dta, replace
sum f_all_pc /* Female Homicides per 100,000 */

use ../data/ers_ucr_arrests_combined.dta, replace
sum male_pro_pc /* Male Prostitution Arrests per 100,000 */ 
sum female_pro_pc /* Female Prostituation Arrests per 100,000 */

use ../data/ers_ucr_crimes_combined.dta, replace
sum rape_pc /* Female Rape Offenses per 100,000 */
sum burglary_pc /* Burglary Offenses per 100,000 */


***** Block 2 ******
use ../data/ter_clean.dta, replace
preserve
	bysort provider_id: gen providers=_n
	replace providers=. if providers>1
	gen reviews = 1
	collapse (sum) reviews providers, by(date city_id)
	sum review /* Total Reviews */
	sum providers /* Total Providers */
restore

preserve 
	bysort provider_id: drop if _n>1
	sum craigslist /* Craigslist Email */
	sum independent /* Independent */
	sum agency /* Agency */
	sum incall /* Incall */
restore

sum average_price_per_hour /* Hourly Price */
sum overall_screen /* Screening */
sum repeat  /* Repeat */ 
sum looks_rating /* Looks Rating */ 
sum street /* Street */ 


***** Block 3 *****
use ../data/ers_shr_combined.dta, replace
sum f_acq_pc /* Female homicides from acquaintance killer per 100,000 */
sum m_all_pc /* Male homicides per 100,000 */

use ../data/ers_ucr_crimes_combined.dta, replace
sum manslaughter_pc /* Manslaughters per 100,000 */
}
*****
{/* Table 2 -- The effect of Craigslist's erotic services openings on production and intermediary characteristics */ 

/* Columns 1-3 */
use ../data/ter_clean.dta, replace
bysort provider_id: drop if _n>1

cap n local specname=`specname'+1
xi: quietly reg craigslist i.city_id i.date ers_10mo ers_10plus, robust cluster(city_id)
cap n estadd ysumm
cap n estimates store dd_`specname'

cap n local specname=`specname'+1
xi: quietly reg independent i.city_id i.date ers_10mo ers_10plus, robust cluster(city_id)
cap n estadd ysumm
cap n estimates store dd_`specname'

cap n local specname=`specname'+1
xi: quietly reg agency i.city_id i.date ers_10mo ers_10plus, robust cluster(city_id)
cap n estadd ysumm
cap n estimates store dd_`specname'

/* Columns 4-5 */
use ../data/ter_clean.dta, replace
bysort provider_id: gen providers=_n
replace providers=. if providers>1
gen reviews = 1
collapse (sum) providers reviews (max) treat_ersdate ersdate , by(date city_id)
tsset city_id date
gen ers_10mo=(treat_ersdate>0 & treat_ersdate<=10 & treat_ersdate!=.)
gen ers_10plus=(treat_ersdate>10 & treat_ersdate!=.)

cap n local specname=`specname'+1
xi: quietly reg reviews i.city_id i.date ers_10mo ers_10plus, robust cluster(city_id)
cap n estadd ysumm
cap n estimates store dd_`specname'

cap n local specname=`specname'+1
xi: quietly reg providers i.city_id i.date ers_10mo ers_10plus, robust cluster(city_id)
cap n estadd ysumm
cap n estimates store dd_`specname'

/* Table Output */
#delimit ;
	cap n estout * using ../tbl2.tex, 
	style(tex) label notype margin 
	cells((b(star fmt(%9.3f) pvalue(p))) (se(fmt(%9.3f)par))) 		
	stats(N ymean,
		labels("N" "Mean of dependent variable")
		fmt(%9.0fc 2))
	keep(ers_10mo ers_10plus)
	order(ers_10mo ers_10plus)
	varlabels(ers_10mo "ERS (first 10 months)" ers_10plus "ERS (post-10 months)")
	replace noabbrev starlevels(* 0.10 ** 0.05 *** 0.01) 
	title(The Effect of Craigslist's ERS Opening on Provider Profiles)   
	collabels(none) eqlabels(none) mlabels(none) mgroups(none) 
	prehead("\begin{table}[htbp]\centering" "\footnotesize" "\caption{@title}" "\label{screening}" "\begin{center}" "\begin{threeparttable}" "\begin{tabular}{l*{@E}{c}}"
"\toprule"
"\multicolumn{1}{l}{Dep var: }&"
"\multicolumn{1}{c}{\textbf{Craigslist}}&"
"\multicolumn{1}{c}{\textbf{Independent}}&"
"\multicolumn{1}{c}{\textbf{Agency}}&"
"\multicolumn{1}{c}{\textbf{Reviews}&"
"\multicolumn{1}{c}{\textbf{Providers}}\\")
	posthead("\midrule")
	prefoot("\\" "\midrule")  
	postfoot("\bottomrule" "\end{tabular}" "\begin{tablenotes}" "\tiny" "\item Models control for market and date fixed effects. Robust standard errors clustered within market in parenthesis.  * p$<$0.10, ** p$<$0.05, *** p$<$0.01" "\end{tablenotes}" "\end{threeparttable}" "\end{center}" "\end{table}");
#delimit cr
cap n estimates clear
}
*****
{/* Table 3 -- Estimates of the effect of erotic services openings on prostitution arrests per 100,000 */ 
use ../data/ers_ucr_arrests_combined.dta, replace
	cap n local specname=`specname'+1
	xi: quietly reg male_pro_pc i.id i.date   ers_10mo ers_10plus, cluster(id) 
	cap n estadd ysumm
	cap n estimates store dd_`specname'

	cap n local specname=`specname'+1
	xi: quietly poisson male_pro_pc i.id i.date  ers_10mo ers_10plus, cluster(id) 
	cap n estadd ysumm
	cap n estimates store dd_`specname'

	cap n local specname=`specname'+1
	xi: quietly reg female_pro_pc i.id i.date  ers_10mo ers_10plus, cluster(id) 
	cap n estadd ysumm
	cap n estimates store dd_`specname'

	cap n local specname=`specname'+1
	xi: quietly poisson female_pro_pc i.id i.date  ers_10mo ers_10plus, cluster(id) 
	cap n estadd ysumm
	cap n estimates store dd_`specname'

/* Table Output */
#delimit ;
	cap n estout * using ../tbl3.tex, 
		style(tex) label notype margin 
		cells((b(star fmt(%9.3f) pvalue(p))) (se(fmt(%9.3f)par))) 		
		stats(N ymean,
			labels("N" "Mean of dependent variable")
			fmt(%9.0fc 2))
		keep(ers_10mo ers_10plus)
		order(ers_10mo ers_10plus)
		varlabels(ers_10mo "ERS (first 10 months)" ers_10plus "ERS (post-10 months)")
		replace noabbrev starlevels(* 0.10 ** 0.05 *** 0.01) 
		title(Estimates of the effect of erotic services openings on male prostitution arrests per 100,000)   
		collabels(none) eqlabels(none) mlabels(none) mgroups(none) 
		prehead("\begin{table}[htbp]\centering" "\footnotesize" "\caption{@title}" "\label{tb:dd_v1d}" "\begin{center}" "\begin{threeparttable}" "\begin{tabular}{l*{@E}{c}}"
	"\toprule"
	"\multicolumn{1}{l}{Dep var:}&"
	"\multicolumn{2}{c}{\textbf{Male arrests}}&"
	"\multicolumn{2}{c}{\textbf{Female arrests}}\\")
		posthead("\midrule")
		prefoot("\\" "\midrule")  
		postfoot("\bottomrule" "\end{tabular}" "\begin{tablenotes}" "\tiny" "\item Models control for city, year, and month fixed effects.  Robust standard errors clustered within agency in parenthesis.  * p$<$0.10, ** p$<$0.05, *** p$<$0.01" "\end{tablenotes}" "\end{threeparttable}" "\end{center}" "\end{table}");
	#delimit cr
cap n estimates clear	
}
*****
{/* Table 4 -- TWFE and Poisson estimates of the effect of erotic services openings on female murders and forcible female rape offenses per 100,000 */
estimates clear
/* Panel A */	
use ../data/ers_shr_combined.dta, replace
	
	/* OLS */
	cap n local specname=`specname'+1
	xi: quietly xtreg f_all_pc  i.date ers_10mo ers_10plus, cluster(id) fe 
	cap n estadd ysumm
	cap n estimates store dd_`specname'
	lincom _b[ers_10plus]/0.1313425

	cap n local specname=`specname'+1
	xi: quietly xtreg f_all_pc  i.date i.stname*i.year ers_10mo ers_10plus, cluster(id) fe
	cap n estadd ysumm
	cap n estimates store dd_`specname'
	lincom _b[ers_10plus]/0.1313425

	cap n local specname=`specname'+1
	xi: quietly xtreg f_all_pc  i.date i.stname*i.year pop3 ers_10mo ers_10plus, cluster(id) fe
	cap n estadd ysumm
	cap n estimates store dd_`specname'
	lincom _b[ers_10plus]/0.1313425
	
	/* Poisson */
	cap n local specname=`specname'+1
	xi: quietly poisson f_all_pc i.id i.date ers_10mo ers_10plus, cluster(id)  
	cap n estadd ysumm
	cap n estimates store dd_`specname'

	cap n local specname=`specname'+1
	xi: quietly poisson f_all_pc i.id i.date i.stname*i.year ers_10mo ers_10plus, cluster(id) 
	cap n estadd ysumm
	cap n estimates store dd_`specname'

	cap n local specname=`specname'+1
	xi: quietly poisson f_all_pc i.id i.date i.stname*i.year pop3 ers_10mo ers_10plus, cluster(id) 
	cap n estadd ysumm
	cap n estimates store dd_`specname'
	
/* Table Output */
#delimit ;
	cap n estout * using ../tbl4_panelA.tex, 
	style(tex) label notype margin 
	cells((b(star fmt(%9.3f) pvalue(p))) (se(fmt(%9.3f)par))) 		
	stats(N ymean,
		labels("N" "Mean of dependent variable")
		fmt(%9.0fc 2))
	keep(ers_10mo ers_10plus)
	order(ers_10mo ers_10plus)
	varlabels(ers_10mo "ERS (first 10 months)" ers_10plus "ERS (post-10 months)")
	replace noabbrev starlevels(* 0.10 ** 0.05 *** 0.01) 
	title(FE estimates of the effect of erotic services openings on female murders per 100,000)   
	collabels(none) eqlabels(none) mlabels(none) mgroups(none) 
	prehead("\begin{table}[htbp]\centering" "\footnotesize" "\caption{@title}" "\label{tb:fe_murder}" "\begin{center}" "\begin{threeparttable}" "\begin{tabular}{l*{@E}{c}}"
	"\toprule"
	"\multicolumn{1}{l}{Dep var:}&"
	"\multicolumn{6}{c}{\textbf{Female Murders}}\\"
	"\multicolumn{1}{c}{}&"
	"\multicolumn{1}{c}{1}&"
	"\multicolumn{1}{c}{2}&"
	"\multicolumn{1}{c}{3}&"
	"\multicolumn{1}{c}{4}&"
	"\multicolumn{1}{c}{5}&"
	"\multicolumn{1}{c}{6}\\")
			posthead("\midrule")
			prefoot("\midrule")  
			postfoot("\midrule"
			"Estimation method		 		& OLS  & OLS  & OLS  & Poisson  & Poisson & Poisson \\"
			"ORI FE							& Yes & Yes & Yes & Yes & Yes & Yes  \\"
			"Month-Year FE	 				& Yes & Yes & Yes & Yes & Yes & Yes  \\"
			"State-Year FE		 			& No & Yes & Yes & No & Yes & Yes  \\"
			"Population						& No & No & Yes & No & No & Yes  \\"
			"\bottomrule" "\end{tabular}" "\begin{tablenotes}" "\tiny" "\item Outcome variable comes from the Supplemental Homicide Reports.  Cluster robust standard errors by ORI are shown in parenthesis.  * p$<$0.10, ** p$<$0.05, *** p$<$0.01" "\end{tablenotes}" "\end{threeparttable}" "\end{center}" "\end{table}") ;
#delimit cr
cap n estimates clear

/* Panel B */
use ../data/ers_ucr_crimes_combined.dta, replace 
	
	/* OLS */
	estimates clear
	cap n local specname=`specname'+1
	xi: quietly xtreg rape_pc  i.date ers_10mo ers_10plus, cluster(id) fe 
    lincom _b[ers_10plus]/2.93
	cap n estadd ysumm
	cap n estimates store dd_`specname'

	cap n local specname=`specname'+1
	xi: quietly xtreg rape_pc  i.date i.stname*i.year ers_10mo ers_10plus, cluster(id) fe
	lincom _b[ers_10plus]/2.93
	cap n estadd ysumm
	cap n estimates store dd_`specname'

	cap n local specname=`specname'+1
	xi: quietly xtreg rape_pc  i.date i.stname*i.year pop3 ers_10mo ers_10plus, cluster(id) fe
	lincom _b[ers_10plus]/2.93
	cap n estadd ysumm
	cap n estimates store dd_`specname'

	/* Poisson */
	cap n local specname=`specname'+1
	xi: quietly poisson rape_pc i.id i.date ers_10mo ers_10plus, cluster(id)  
	cap n estadd ysumm
	cap n estimates store dd_`specname'

	cap n local specname=`specname'+1
	xi: quietly poisson rape_pc i.id i.date i.stname*i.year ers_10mo ers_10plus, cluster(id) 
	cap n estadd ysumm
	cap n estimates store dd_`specname'

	cap n local specname=`specname'+1
	xi: quietly poisson rape_pc i.id i.date i.stname*i.year pop3 ers_10mo ers_10plus, cluster(id) 
	cap n estadd ysumm
	cap n estimates store dd_`specname'

/* Table Output */
#delimit ;
	cap n estout * using ../tbl4_panelB.tex, 
		style(tex) label notype margin 
		cells((b(star fmt(%9.3f) pvalue(p))) (se(fmt(%9.3f)par))) 		
		stats(N ymean,
			labels("N" "Mean of dependent variable")
			fmt(%9.0fc 2))
		keep(ers_10mo ers_10plus)
		order(ers_10mo ers_10plus)
		varlabels(ers_10mo "ERS (first 10 months)" ers_10plus "ERS (post-10 months)")
		replace noabbrev starlevels(* 0.10 ** 0.05 *** 0.01) 
		title(FE estimates of the effect of erotic services openings on female rapes per 100,000)   
		collabels(none) eqlabels(none) mlabels(none) mgroups(none) 
		prehead("\begin{table}[htbp]\centering" "\footnotesize" "\caption{@title}" "\label{tb:fe_murder}" "\begin{center}" "\begin{threeparttable}" "\begin{tabular}{l*{@E}{c}}"
	"\toprule"
	"\multicolumn{1}{l}{Dep var:}&"
	"\multicolumn{6}{c}{\textbf{Female Rapes}}\\"
	"\multicolumn{1}{c}{}&"
	"\multicolumn{1}{c}{1}&"
	"\multicolumn{1}{c}{2}&"
	"\multicolumn{1}{c}{3}&"
	"\multicolumn{1}{c}{4}&"
	"\multicolumn{1}{c}{5}&"
	"\multicolumn{1}{c}{6}\\")
		posthead("\midrule")
		prefoot("\midrule")  
		postfoot("\midrule"
		"Estimation method		 		& OLS  & OLS  & OLS  & Poisson  & Poisson & Poisson \\"
		"ORI FE							& Yes & Yes & Yes & Yes & Yes & Yes  \\"
		"Month-Year FE	 				& Yes & Yes & Yes & Yes & Yes & Yes  \\"
		"State-Year FE		 			& No & Yes & Yes & No & Yes & Yes  \\"
		"Population						& No & No & Yes & No & No & Yes  \\"
		"\bottomrule" "\end{tabular}" "\begin{tablenotes}" "\tiny" "\item Outcome variable comes from the raw FBI Uniform Crime Reports Summary Part I files at https://eml.berkeley.edu/~jmccrary/UCR/index.html.  Cluster robust standard errors by ORI are shown in parenthesis.  * p$<$0.10, ** p$<$0.05, *** p$<$0.01" "\end{tablenotes}" "\end{threeparttable}" "\end{center}" "\end{table}") ;
#delimit cr
cap n estimates clear
}	
*****
{/* Table 5 -- TWFE and Poisson estimates of the effect of ERS openings on female homicides per 100,000 from the Vital Statistics */
use ../data/vs_clean.dta, replace
	estimates clear
	
	/* OLS */
	cap n local specname=`specname'+1
	xi: quietly xtreg f_all_pc i.date ers_10mo ers_10plus, cluster(id) fe 
	cap n estadd ysumm
	cap n estimates store dd_`specname'

	cap n local specname=`specname'+1
	xi: quietly xtreg f_all_pc i.date i.st_fips*i.year ers_10mo ers_10plus, cluster(id) fe
	cap n estadd ysumm
	cap n estimates store dd_`specname'

	cap n local specname=`specname'+1
	xi: quietly xtreg f_all_pc i.date i.st_fips*i.year population ers_10mo ers_10plus, cluster(id) fe
	cap n estadd ysumm
	cap n estimates store dd_`specname'
	
	/* Poisson */
	cap n local specname=`specname'+1
	xi: quietly poisson f_all_pc i.id i.date ers_10mo ers_10plus, cluster(id)  
	cap n estadd ysumm
	cap n estimates store dd_`specname'

	cap n local specname=`specname'+1
	xi: quietly poisson f_all_pc i.id i.date i.st_fips*i.year ers_10mo ers_10plus, cluster(id) 
	cap n estadd ysumm
	cap n estimates store dd_`specname'

	cap n local specname=`specname'+1
	xi: quietly poisson f_all_pc i.id i.date i.st_fips*i.year population ers_10mo ers_10plus, cluster(id) 
	cap n estadd ysumm
	cap n estimates store dd_`specname'

/* Table Output */ 
#delimit ;
	cap n estout * using ../tbl5.tex, 
		style(tex) label notype margin 
		cells((b(star fmt(%9.3f) pvalue(p))) (se(fmt(%9.3f)par))) 		
		stats(N ymean,
			labels("N" "Mean of dependent variable")
			fmt(%9.0fc 2))
		keep(ers_10mo ers_10plus)
		order(ers_10mo ers_10plus)
		varlabels(ers_10mo "ERS (first 10 months)" ers_10plus "ERS (post-10 months)")
		replace noabbrev starlevels(* 0.10 ** 0.05 *** 0.01) 
		title(TWFE and poisson estimates of the effect of ERS openings on female homicides per 100,000)   
		collabels(none) eqlabels(none) mlabels(none) mgroups(none) 
		prehead("\begin{table}[htbp]\centering" "\footnotesize" "\caption{@title}" "\label{tab:vs_h}" "\begin{center}" "\begin{threeparttable}" "\begin{tabular}{l*{@E}{c}}"
	"\toprule"
	"\multicolumn{1}{l}{Dep var:}&"
	"\multicolumn{6}{c}{\textbf{Female Homicides}}\\"
	"\multicolumn{1}{c}{}&"
	"\multicolumn{1}{c}{1}&"
	"\multicolumn{1}{c}{2}&"
	"\multicolumn{1}{c}{3}&"
	"\multicolumn{1}{c}{4}&"
	"\multicolumn{1}{c}{5}&"
	"\multicolumn{1}{c}{6}\\")
		posthead("\midrule")
		prefoot("\midrule")  
		postfoot("\midrule"
		"Estimation method		 		& OLS  & OLS  & OLS  & Poisson  & Poisson & Poisson \\"
		"County FE					& Yes & Yes & Yes & Yes & Yes & Yes  \\"
		"Month-Year FE	 				& Yes & Yes & Yes & Yes & Yes & Yes  \\"
		"State-Year FE		 			& No & Yes & Yes & No & Yes & Yes  \\"
		"Population					& No & No & Yes & No & No & Yes  \\"
		"\bottomrule" "\end{tabular}" "\begin{tablenotes}" "\tiny" "\item Outcome variable comes from the raw Vital Statistics.  Cluster robust standard errors by county are shown in parenthesis.  * p$<$0.10, ** p$<$0.05, *** p$<$0.01" "\end{tablenotes}" "\end{threeparttable}" "\end{center}" "\end{table}") ;
#delimit cr
cap n estimates clear
}
*****
{/* Table 6 -- Matrix completion estimation of ERS on female homicide rates and forcible female rape offenses per 100,000 */

use ../data/ers_shr_combined.dta, replace 

/* Column 1 -- Female Homicides */
fect f_all_pc, treat(treat) unit(id) time(date) method("mc") nlambda(10) se nboots(1000)
mat list e(ATT)
/* ATT = -0.023 (SD 0.001) */

use ../data/ers_ucr_crimes_combined.dta,replace

/* Column 2 -- Female Reported Rape Offenses */
fect rape_pc, treat(treat) unit(id) time(date) method("mc") nlambda(10) se nboots(1000)
mat list e(ATT)
/* ATT = -0.296, (SD 0.124) */
}

*****
{/* Table 7 -- OLS falsification estimates of the effect of Craigslist erotic services openings on male homicides, manslaughters and burglaries per 100,000*/
estimates clear	
/* Column 1 - Male Homicides */
use ../data/ers_shr_combined.dta, replace
	cap n local specname=`specname'+1
	xi: quietly xtreg m_all_pc  i.date i.stname*i.year ers_10mo ers_10plus, cluster(id) fe
	cap n estadd ysumm
	cap n estimates store dd_`specname'

/* Column 2 - Manslaughter & Burglary */
use ../Submissions/JHR/Githubdata/ers_ucr_crimes_combined.dta, replace
	cap n local specname=`specname'+1
	xi: quietly xtreg manslaughter_pc  i.date i.stname*i.year ers_10mo ers_10plus, cluster(id) fe
	cap n estadd ysumm
	cap n estimates store dd_`specname'
	
	cap n local specname=`specname'+1
	xi: quietly xtreg burglary_pc  i.date i.stname*i.year ers_10mo ers_10plus, cluster(id) fe
	cap n estadd ysumm
	cap n estimates store dd_`specname'
	
/* Table Output */
#delimit ;
	cap n estout * using ../tbl7.tex, 
		style(tex) label notype margin 
		cells((b(star fmt(%9.3f) pvalue(p))) (se(fmt(%9.3f)par))) 		
		stats(N ymean,
			labels("N" "Mean of dependent variable")
			fmt(%9.0fc 2))
		keep(ers_10mo ers_10plus)
		order(ers_10mo ers_10plus)
		varlabels(ers_10mo "ERS (first 10 months)" ers_10plus "ERS (post-10 months)")
		replace noabbrev starlevels(* 0.10 ** 0.05 *** 0.01) 
		title(OLS estimates of the effect of erotic services openings on non-female deaths and burglary per 100,000)   
		collabels(none) eqlabels(none) mlabels(none) mgroups(none) 
		prehead("\begin{table}[htbp]\centering" "\footnotesize" "\caption{@title}" "\label{tb:dd_v1d}" "\begin{center}" "\begin{threeparttable}" "\begin{tabular}{l*{@E}{c}}"
	"\toprule"
	"\multicolumn{1}{l}{Dep var:}&"
	"\multicolumn{1}{c}{\textbf{Males}}\\")
	posthead("\midrule")
	prefoot("\midrule")  
	postfoot("\midrule"
			"Estimation method		 		& OLS  \\"
			"ORI FE						    & Yes  \\"
			"Month-Year FE	 				& Yes  \\"
			"State-Year FE		 			& Yes  \\"
			"Population						& Yes  \\"
						"\bottomrule" "\end{tabular}" "\begin{tablenotes}" "\tiny" "\item Outcome variable comes from the Supplemental Homicide Reports.  Cluster robust standard errors by ORI are shown in parenthesis.  * p$<$0.10, ** p$<$0.05, *** p$<$0.01" "\end{tablenotes}" "\end{threeparttable}" "\end{center}" "\end{table}") ;
#delimit cr
cap n estimates drop
}
*****
{/* Table 8 -- The effect of Craigslist's erotic services openings on characteristics of providers. */
cap n estimates clear

/* Panel A */ 
use ../data/ter_clean.dta, replace
	cap n local specname=`specname'+1
	xi: quietly reg repeat i.city_id i.date ers_10mo ers_10plus, robust cluster(city_id)
	cap n estadd ysumm
	cap n estimates store dd_`specname'

	cap n local specname=`specname'+1
	xi: quietly reg looks_rating i.city_id i.date ers_10mo ers_10plus, robust cluster(city_id)
	cap n estadd ysumm
	cap n estimates store dd_`specname'

	cap n local specname=`specname'+1
	xi: quietly reg performance_rating i.city_id i.date ers_10mo ers_10plus, robust cluster(city_id)
	cap n estadd ysumm
	cap n estimates store dd_`specname'

	cap n local specname=`specname'+1
	xi: quietly reg street i.city_id i.date ers_10mo ers_10plus, robust cluster(city_id)
	cap n estadd ysumm
	cap n estimates store dd_`specname'

	preserve
		bysort provider_id: drop if _n>1
		cap n local specname=`specname'+1
		xi: quietly reg average_price_per_hour i.city_id i.date ers_10mo ers_10plus, robust cluster(city_id)
		cap n estadd ysumm
		cap n estimates store dd_`specname'

		cap n local specname=`specname'+1
		xi: quietly reg incall i.city_id i.date ers_10mo ers_10plus, robust cluster(city_id)
		cap n estadd ysumm
		cap n estimates store dd_`specname'
	restore

	cap n local specname=`specname'+1
	xi: quietly reg overall_pimp i.city_id i.date ers_10mo ers_10plus, robust cluster(city_id)
	cap n estadd ysumm
	cap n estimates store dd_`specname'

/* Table Output */
#delimit ;
	cap n estout * using ../tbl8_panelA.tex, 
		style(tex) label notype margin 
		cells((b(star fmt(%9.3f) pvalue(p))) (se(fmt(%9.3f)par))) 		
		stats(N ymean,
			labels("N" "Mean of dependent variable")
			fmt(%9.0fc 2))
		keep(ers_10mo ers_10plus)
		order(ers_10mo ers_10plus)
		varlabels(ers_10mo "ERS (first 10 months)" ers_10plus "ERS (post-10 months)")
		replace noabbrev starlevels(* 0.10 ** 0.05 *** 0.01) 
		title(The effect of Craigslist's erotic services openings on screening)   
		collabels(none) eqlabels(none) mlabels(none) mgroups(none) 
		prehead("\begin{sidewaystable}[htbp]\centering" "\footnotesize" "\caption{@title}" "\label{screening}" "\begin{center}" "\begin{threeparttable}" "\begin{tabular}{l*{@E}{c}}"
"\toprule"
"\multicolumn{1}{l}{Dep var: }&"
"\multicolumn{1}{c}{\textbf{Repeat}}&"
"\multicolumn{1}{c}{\textbf{Looks}}&"
"\multicolumn{1}{c}{\textbf{Performance}}&"
"\multicolumn{1}{c}{\textbf{Street}}&"
"\multicolumn{1}{c}{\textbf{Pimp}}&"
"\multicolumn{1}{c}{\textbf{Incall}}&"
"\multicolumn{1}{c}{\textbf{Hourly Price}}&"
"\multicolumn{1}{c}{\textbf{Pimp}}&")
		posthead("\midrule")
		prefoot("\\" "\midrule")  
		postfoot("\bottomrule" "\end{tabular}" "\begin{tablenotes}" "\tiny" "\item Models control for city and date fixed effects. Robust standard errors clustered within city in parenthesis.  * p$<$0.10, ** p$<$0.05, *** p$<$0.01" "\end{tablenotes}" "\end{threeparttable}" "\end{center}" "\end{sidewaystable}");
#delimit cr
cap n estimates clear

/* Panel B */ 
use ../data/ter_clean.dta, replace
	cap n local specname=`specname'+1
	xi: quietly reg repeat i.city_id i.date ers_10mo-ers_50plus post_ers_10mo post_ers_20mo post_ers_30mo post_ers_40mo post_ers_50mo post_ers_50post, robust cluster(city_id)
	cap n estadd ysumm
	cap n estimates store dd_`specname'

	cap n local specname=`specname'+1
	xi: quietly reg looks_rating i.city_id i.date ers_10mo-ers_50plus post_ers_10mo post_ers_20mo post_ers_30mo post_ers_40mo post_ers_50mo post_ers_50post, robust cluster(city_id)
	cap n estadd ysumm
	cap n estimates store dd_`specname'

	cap n local specname=`specname'+1
	xi: quietly reg performance_rating i.city_id i.date ers_10mo-ers_50plus post_ers_10mo post_ers_20mo post_ers_30mo post_ers_40mo post_ers_50mo post_ers_50post, robust cluster(city_id)
	cap n estadd ysumm
	cap n estimates store dd_`specname'

	cap n local specname=`specname'+1
	xi: quietly reg street i.city_id i.date ers_10mo-ers_50plus post_ers_10mo post_ers_20mo post_ers_30mo post_ers_40mo post_ers_50mo post_ers_50post, robust cluster(city_id)
	cap n estadd ysumm
	cap n estimates store dd_`specname'

	preserve
	bysort provider_id: drop if _n>1
		cap n local specname=`specname'+1
		xi: quietly reg incall i.city_id i.date ers_10mo-ers_50plus post_ers_10mo post_ers_20mo post_ers_30mo post_ers_40mo post_ers_50mo post_ers_50post, robust cluster(city_id)
		cap n estadd ysumm
		cap n estimates store dd_`specname'

		cap n local specname=`specname'+1
		xi: quietly reg average_price_per_hour i.city_id i.date ers_10mo-ers_50plus post_ers_10mo post_ers_20mo post_ers_30mo post_ers_40mo post_ers_50mo post_ers_50post, robust cluster(city_id)
		cap n estadd ysumm
		cap n estimates store dd_`specname'
	restore

	cap n local specname=`specname'+1
	xi: quietly reg overall_pimp i.city_id i.date ers_10mo-ers_50plus post_ers_10mo post_ers_20mo post_ers_30mo post_ers_40mo post_ers_50mo post_ers_50post, robust cluster(city_id)
	cap n estadd ysumm
	cap n estimates store dd_`specname'

/* Table Output */
#delimit ;
	cap n estout * using ../tbl8_panelB.tex, 
		style(tex) label notype margin 
		cells((b(star fmt(%9.3f) pvalue(p))) (se(fmt(%9.3f)par))) 		
		stats(N ymean,
			labels("N" "Mean of dependent variable")
			fmt(%9.0fc 2))
		keep(post_ers_10mo post_ers_20mo post_ers_30mo post_ers_40mo post_ers_50mo post_ers_50post)
		order(post_ers_10mo post_ers_20mo post_ers_30mo post_ers_40mo post_ers_50mo post_ers_50post)
		varlabels(post_ers_10mo "Entrant 0-10mo post ERS" post_ers_20mo "Entrant 11-20mo post ERS" post_ers_30mo "Entrant 21-30mo post ERS" post_ers_40mo "Entrant 31-40mo post ERS" post_ers_50mo "Entrant 41-50mo post ERS" post_ers_50post "Entrant 50mo post ERS")
		replace noabbrev starlevels(* 0.10 ** 0.05 *** 0.01) 
		title(The effect of Craigslist's erotic services openings on characteristics of entrants)   
		collabels(none) eqlabels(none) mlabels(none) mgroups(none) 
		prehead("\begin{sidewaystable}[htbp]\centering" "\footnotesize" "\caption{@title}" "\label{screening}" "\begin{center}" "\begin{threeparttable}" "\begin{tabular}{l*{@E}{c}}"
"\toprule"
"\multicolumn{1}{l}{Dep var: }&"
"\multicolumn{1}{c}{\textbf{Repeat}}&"
"\multicolumn{1}{c}{\textbf{Looks}}&"
"\multicolumn{1}{c}{\textbf{Performance}}&"
"\multicolumn{1}{c}{\textbf{Street}}&"
"\multicolumn{1}{c}{\textbf{Pimp}}&"
"\multicolumn{1}{c}{\textbf{Incall}}&"
"\multicolumn{1}{c}{\textbf{Hourly Price}}&"
"\multicolumn{1}{c}{\textbf{Pimp}}&")
		posthead("\midrule")
		prefoot("\\" "\midrule")  
		postfoot("\bottomrule" "\end{tabular}" "\begin{tablenotes}" "\tiny" "\item Models control for city and date fixed effects. Robust standard errors clustered within city in parenthesis.  * p$<$0.10, ** p$<$0.05, *** p$<$0.01" "\end{tablenotes}" "\end{threeparttable}" "\end{center}" "\end{sidewaystable}");
#delimit cr
cap n estimates drop
}

***** Figures ****** 
{/* Figure 1 -- Number of cities represented in our sample relative to the time of treatment. The x-axis depicts the number of months until or after the introduction of ERS. The y-axis presents the number of cities that appear in our panel with the recentered treatment value of the x-axis. */
use ../data/ers_shr_combined.dta, replace
cap n estimates clear
gen column=1
collapse (sum) column, by(treat_ersdate)
twoway (spike column treat_ersdate, sort), ytitle(Total number of cities) ylabel(, grid) xtitle(Recentered treatment date) xline(0) title(Number of cities by treatment date)
graph save Graph ../fig1.gph
graph export ../fig1.pdf, replace
}
*****
{/* Figure 2 -- Conditional binned means of characteristics of providers at TER before and after the date where Craigslist refreshed its front page with ERS. Bins are approximately equal to a month; there are 48 bins to the left of the cutoff and 52 to the right. */
use ../data/ter_clean.dta, replace
sort provider_id date
bysort provider_id: drop if _n>1

foreach x of varlist craigslist independent agency {
	quietly cmogram `x' treat_ersdate if treat_ersdate>-50 & treat_ersdate<50, scatter line(0) cut(0) qfitci
	graph save "_graph0" "../fig2_`x'.gph", replace
	graph export ../fig2_`x'.pdf, replace
}
}
********************************************************************************
{/* Figure 3 -- Event study plots from equation 2 for female murders using TWFE */
use ../data/ers_shr_combined.dta, replace
cap n estimates clear
xi: quietly xtreg f_all_pc i.id i.date i.stname*i.year lag6 lag5 lag4 lag3 lag2 dd1-dd8, fe cluster(id) 
outreg2 using "../temp.xls", replace keep(lag6 lag5 lag4 lag3 lag2 dd1-dd8) noparen noaster 

/* Pull in the Event Study Coeffficients */
xmluse "../temp.xls", clear cells(A3:B32) first
replace VARIABLES = subinstr(VARIABLES,"lag","",.)	
replace VARIABLES = subinstr(VARIABLES,"dd","",.)	
drop in 28/29
quietly destring _all, replace ignore(",") force
replace VARIABLES = -6 in 2
replace VARIABLES = -5 in 4
replace VARIABLES = -4 in 6
replace VARIABLES = -3 in 8
replace VARIABLES = -2 in 10
replace VARIABLES = 0 in 12
replace VARIABLES = 1 in 14
replace VARIABLES = 2 in 16
replace VARIABLES = 3 in 18
replace VARIABLES = 4 in 20
replace VARIABLES = 5 in 22
replace VARIABLES = 6 in 24
replace VARIABLES = 7 in 26
drop in 1
compress
quietly destring _all, replace ignore(",")
compress

ren VARIABLES exp
gen b = exp<.
replace exp = -6 in 2
replace exp = -5 in 4
replace exp = -4 in 6
replace exp = -3 in 8
replace exp = -2 in 10
replace exp = 0 in 12
replace exp = 1 in 14
replace exp = 2 in 16
replace exp = 3 in 18
replace exp = 4 in 20
replace exp = 5 in 22
replace exp = 6 in 24
replace exp = 7 in 26

/* Expand the dataset by one more observation so as to include the comparison year. */
local obs =_N+1
set obs `obs'
for var _all: replace X = 0 in `obs'
replace b = 1 in `obs'
replace exp = 0 in `obs'
keep exp f_all_pc b 
set obs 28
foreach x of varlist f_all_pc b {
	replace `x'=0 in 27
	replace `x'=0 in 28
	}
replace exp=-1 in 27
replace exp=-1 in 28
replace b = 1 in 27
replace b = 0 in 28
reshape wide f_all_pc, i(exp) j(b)

/* Create the confidence intervals */
cap drop *lb* *ub*
gen lb = f_all_pc1 - 1.96*f_all_pc0 
gen ub = f_all_pc1 + 1.96*f_all_pc0 

/* Figure Output */
set scheme s2color
#delimit ;
twoway (scatter f_all_pc1 ub lb exp , 
		lpattern(solid dash dash dot dot solid solid) 
		lcolor(gray gray gray red blue) 
		lwidth(thick medium medium medium medium thick thick)
		msymbol(i i i i i i i i i i i i i i i) msize(medlarge medlarge)
		mcolor(gray black gray gray red blue) 
		c(l l l l l l l l l l l l l l l) 
		cmissing(n n n n n n n n n n n n n n n n) 
		xline(-1, lcolor(black) lpattern(solid))
		yline(0, lcolor(black)) 
		xlabel(-6 -5 -4 -3 -2 -1 0 1 2 3 4 5 6 7, labsize(medium))
		ylabel(, nogrid labsize(medium))
		xsize(7.5) ysize(5.5) 			
		legend(off)
		xtitle("10-month periods before and after ERS", size(medium))
		ytitle("Female homicides per 100,000 ", size(medium))
		graphregion(fcolor(white) color(white) icolor(white) margin(zero))
		)
		;
#delimit cr;
graph export ../fig3.pdf, replace

}
********************************************************************************
{/* Figure 4 -- Event study plots from equation 2 for female forcible rape offenses using TWFE */

cap n estimates clear
use ../data/ers_ucr_crimes_combined, replace
xi: xtreg rape_pc i.id i.date i.stname*i.year lag6 lag5 lag4 lag3 lag2 dd1-dd8, fe cluster(id) 
outreg2 using "../temp1.xls", replace keep(lag6 lag5 lag4 lag3 lag2 dd1-dd8) noparen noaster 

*Pull in the Event Study Coefficients
xmluse "../temp1.xls", clear cells(A3:B32) first
replace VARIABLES = subinstr(VARIABLES,"lag","",.)	
replace VARIABLES = subinstr(VARIABLES,"dd","",.)	
drop in 28/29
quietly destring _all, replace ignore(",") force
replace VARIABLES = -6 in 2
replace VARIABLES = -5 in 4
replace VARIABLES = -4 in 6
replace VARIABLES = -3 in 8
replace VARIABLES = -2 in 10
replace VARIABLES = 0 in 12
replace VARIABLES = 1 in 14
replace VARIABLES = 2 in 16
replace VARIABLES = 3 in 18
replace VARIABLES = 4 in 20
replace VARIABLES = 5 in 22
replace VARIABLES = 6 in 24
replace VARIABLES = 7 in 26
drop in 1
compress
quietly destring _all, replace ignore(",")
compress
ren VARIABLES exp
gen b = exp<.
replace exp = -6 in 2
replace exp = -5 in 4
replace exp = -4 in 6
replace exp = -3 in 8
replace exp = -2 in 10
replace exp = 0 in 12
replace exp = 1 in 14
replace exp = 2 in 16
replace exp = 3 in 18
replace exp = 4 in 20
replace exp = 5 in 22
replace exp = 6 in 24
replace exp = 7 in 26

/* Expand the dataset by one more observation so as to include the comparison year */
local obs =_N+1
set obs `obs'
for var _all: replace X = 0 in `obs'
replace b = 1 in `obs'
replace exp = 0 in `obs'
keep exp rape_pc b 
set obs 28
foreach x of varlist rape_pc b {
	replace `x'=0 in 27
	replace `x'=0 in 28
	}
replace exp=-1 in 27
replace exp=-1 in 28
replace b = 1 in 27
replace b = 0 in 28
reshape wide rape_pc, i(exp) j(b)

/* Create the confidence intervals */
cap drop *lb* *ub*
gen lb = rape_pc1 - 1.96*rape_pc0 
gen ub = rape_pc1 + 1.96*rape_pc0 

/* Create the figure */
set scheme s2color
#delimit ;
twoway (scatter rape_pc1 ub lb exp , 
		lpattern(solid dash dash dot dot solid solid) 
		lcolor(gray gray gray red blue) 
		lwidth(thick medium medium medium medium thick thick)
		msymbol(i i i i i i i i i i i i i i i) msize(medlarge medlarge)
		mcolor(gray black gray gray red blue) 
		c(l l l l l l l l l l l l l l l) 
		cmissing(n n n n n n n n n n n n n n n n) 
		xline(-1, lcolor(black) lpattern(solid))
		yline(0, lcolor(black)) 
		xlabel(-6 -5 -4 -3 -2 -1 0 1 2 3 4 5 6 7, labsize(medium))
		ylabel(, nogrid labsize(medium))
		xsize(7.5) ysize(5.5) 			
		legend(off)
		xtitle("10-month periods before and after ERS", size(medium))
		ytitle("Female rapes per 100,000 ", size(medium))
		graphregion(fcolor(white) color(white) icolor(white) margin(zero))
		)
		;

#delimit cr;

graph export ../fig4.pdf, replace
}

***** Appendicies *****
{/* Table A.1 -- Relationship between Treatment Status & Socioeconomic Covariates. */
use ../data/ers_shr_combined.dta, replace
drop if agname==""
merge m:1 agname stname year month using ../data/cps_data_month.dta, force gen(cps_merge)
drop if cps_merge==2

/* Fill in CPS data for missing years. */
foreach x in age_0 age_5 age_10 age_15 age_20 age_25 age_30 age_35 age_40 age_45 age_50 age_55 age_60 age_65 age_70 adult armed_forces child latin employed less_hs hs coll_less_four bachelor educ_more_four {
    bysort agname stname: egen mean_perc_`x' = mean(perc_`x')
	replace perc_`x' = mean_perc_`x' if perc_`x'==.
}

replace dd = 1 if dd>0

gen perc_young = perc_age_0+perc_age_5+perc_age_10+perc_age_15+perc_age_20
gen perc_mid_age = perc_age_25+perc_age_30+perc_age_35+perc_age_40+perc_age_45
gen perc_over_50 = perc_age_50+perc_age_55+perc_age_60+perc_age_65+perc_age_70


foreach x in young mid_age over_50 adult armed_forces child latin employed less_hs hs coll_less_four bachelor educ_more_four {
	cap n local specname=`specname'+1
	xi: quietly xtreg perc_`x' i.id i.stname i.year dd, cluster(id) fe 
	cap n estadd ysumm
	cap n estimates store dd_`specname'
}

foreach x in pop4 { 	
	cap n local specname=`specname'+1
	xi: quietly xtreg `x' i.id i.stname i.year dd, cluster(id) fe 
    cap n estadd ysumm
	cap n estimates store dd_`specname'
}

/* Table Output */ 
#delimit ;
	cap n estout * using ../appendix_1.tex,
	style(tex) label notype margin 
	cells((b(star fmt(%9.3f) pvalue(p))) (se(fmt(%9.3f)par))) 		
	keep(dd)
	varlabels(dd "Test")
	replace noabbrev starlevels(* 0.10 ** 0.05 *** 0.01) 
	title(Test of Independence Assumption)   
	collabels(none) eqlabels(none) mlabels(none) mgroups(none) 
	prehead("\begin{table}[htbp]\centering" "\footnotesize" "\caption{@title}" "\label{screening}" "\begin{center}" "\begin{threeparttable}" "\begin{tabular}{l*{@E}{c}}"
"\toprule"
"\multicolumn{1}{l}{Dep var: }&"
"\multicolumn{1}{c}{\textbf{Ages 0 - 25}}&"
"\multicolumn{1}{c}{\textbf{Ages 25 - 50}}&"
"\multicolumn{1}{c}{\textbf{Ages 50+}}&"
"\multicolumn{1}{c}{\textbf{Adult}}&"
"\multicolumn{1}{c}{\textbf{Child}}&"
"\multicolumn{1}{c}{\textbf{Armed Forces}}&"
"\multicolumn{1}{c}{\textbf{Latino}}&"
"\multicolumn{1}{c}{\textbf{Employed}}&"
"\multicolumn{1}{c}{\textbf{Less HS Educ}}&"
"\multicolumn{1}{c}{\textbf{Some College}}&"
"\multicolumn{1}{c}{\textbf{4 Year Degree}}&"
"\multicolumn{1}{c}{\textbf{Beyond 4 Year Degree}}&"
"\multicolumn{1}{c}{\textbf{Population}}\\")
	posthead("\midrule")
	prefoot("\\" "\midrule")  
	postfoot("\bottomrule" "\end{tabular}" "\begin{tablenotes}" "\tiny" "\item .  Socioeconomic covariates are sourced from the American Community Survey and are aggregated at the ORI mean level. Each row is a separate regression. Cluster robust standard errors at the ORI level are presented in parentheses. * p$<$0.10, ** p$<$0.05, *** p$<$0.01" "\end{tablenotes}" "\end{threeparttable}" "\end{center}" "\end{table}");
#delimit cr
cap n estimates clear

}
*****
{/* Table A.2 -- TWFE and Poisson estimates of the effect of erotic services openings on female murders and forcible female rape offenses per 100,000 using varying windows */ 
cap n estimates clear

/* Female Homicides per 100,000 */
use ../data/ers_shr_combined.dta, replace 
/* Robustness of the treatment indicators (6 mo, 9 mo, 12 mo) 8 */
/** Linear **/
	cap n local specname=`specname'+1
	* 6-month treatment indicator
	xi: quietly xtreg f_all_pc  i.date i.stname*i.year ers_6mo ers_6plus , cluster(id) fe 
	cap n estadd ysumm
	cap n estimates store dd_`specname'

	cap n local specname=`specname'+1
	* 9-month treatment indicator
	xi: quietly xtreg f_all_pc i.date i.stname*i.year ers_9mo ers_9plus , cluster(id)  fe 
	cap n estadd ysumm
	cap n estimates store dd_`specname'

	cap n local specname=`specname'+1
	* 12-month treatment indicator
	xi: quietly xtreg f_all_pc  i.date i.stname*i.year ers_12mo ers_12plus , cluster(id)  fe 
	cap n estadd ysumm
	cap n estimates store dd_`specname'

/** Poisson **/
	cap n local specname=`specname'+1
	* 6-month treatment indicator
	xi: quietly poisson f_all_pc i.id i.date i.stname*i.year ers_6mo ers_6plus , cluster(id) 
	cap n estadd ysumm
	cap n estimates store dd_`specname'

	cap n local specname=`specname'+1
	* 9-month treatment indicator
	xi: quietly poisson f_all_pc i.id i.date i.stname*i.year ers_9mo ers_9plus , cluster(id) 
	cap n estadd ysumm
	cap n estimates store dd_`specname'

	cap n local specname=`specname'+1
	* 12-month treatment indicator
	xi: quietly poisson f_all_pc i.id i.date i.stname*i.year ers_12mo ers_12plus , cluster(id)  
	cap n estadd ysumm
	cap n estimates store dd_`specname'

/* Table Output */	
#delimit ;
		cap n estout * using ../appendix_2a.tex, 
			style(tex) label notype margin 
			cells((b(star fmt(%9.3f) pvalue(p))) (se(fmt(%9.3f)par))) 		
			stats(N ymean,
				labels("N" "Mean of dependent variable")
				fmt(%9.0fc 2))
			keep(ers_6mo ers_6plus ers_9mo ers_9plus ers_12mo ers_12plus)
			order(ers_6mo ers_6plus ers_9mo ers_9plus ers_12mo ers_12plus)
			varlabels(ers_6mo "ERS (first 6 months)" ers_6plus "ERS (post-6 months)"
					ers_9mo "ERS (first 9 months)" ers_9plus "ERS (post-9 months)"
					ers_12mo "ERS (first 12 months)" ers_12plus "ERS (post-12 months)")
			replace noabbrev starlevels(* 0.10 ** 0.05 *** 0.01) 
			title(FE estimates of the effect of erotic services openings on female murders per 100,000 using varying windows)   
			collabels(none) eqlabels(none) mlabels(none) mgroups(none) 
			prehead("\begin{table}[htbp]\centering" "\footnotesize" "\caption{@title}" "\label{tb:fe_windows}" "\begin{center}" "\begin{threeparttable}" "\begin{tabular}{l*{@E}{c}}"
	"\toprule"
	"\multicolumn{1}{l}{Dep var:}&"
	"\multicolumn{6}{c}{\textbf{Female Murders}}\\"
	"\multicolumn{1}{c}{}&"
	"\multicolumn{1}{c}{1}&"
	"\multicolumn{1}{c}{2}&"
	"\multicolumn{1}{c}{3}&"
	"\multicolumn{1}{c}{4}&"
	"\multicolumn{1}{c}{5}&"
	"\multicolumn{1}{c}{6}\\")
			posthead("\midrule")
			prefoot("\midrule")  
			postfoot("\midrule"
			"Estimation method		 		& OLS  & OLS  & OLS  & Poisson  & Poisson & Poisson \\"
			"ORI FE						& Yes & Yes & Yes & Yes & Yes & Yes  \\"
			"Month-Year FE	 				& Yes & Yes & Yes & Yes & Yes & Yes  \\"
			"State-Year FE		 			& Yes & Yes & Yes & Yes & Yes & Yes  \\"
			"Population					& Yes & Yes & Yes & Yes & Yes & Yes  \\"
			"\bottomrule" "\end{tabular}" "\begin{tablenotes}" "\tiny" "\item Outcome variable comes from the Supplemental Homicide Reports.  Cluster robust standard errors by ORI are shown in parenthesis.  * p$<$0.10, ** p$<$0.05, *** p$<$0.01" "\end{tablenotes}" "\end{threeparttable}" "\end{center}" "\end{table}") ;
	#delimit cr
cap n estimates clear

/* Female Forcible Rapes per 100,000 */
use ../data/ers_ucr_crimes_combined.dta, replace 
/* Robustness of the treatment indicators (6 mo, 9 mo, 12 mo) */
/** Linear **/
		cap n local specname=`specname'+1
		* 6-month treatment indicator
		xi: quietly xtreg rape_pc  i.date i.stname*i.year ers_6mo ers_6plus , cluster(id) fe 
		cap n estadd ysumm
		cap n estimates store dd_`specname'

		cap n local specname=`specname'+1
		* 9-month treatment indicator
		xi: quietly xtreg rape_pc i.date i.stname*i.year ers_9mo ers_9plus , cluster(id)  fe 
		cap n estadd ysumm
		cap n estimates store dd_`specname'

		cap n local specname=`specname'+1
		* 12-month treatment indicator
		xi: quietly xtreg rape_pc  i.date i.stname*i.year ers_12mo ers_12plus , cluster(id)  fe 
		cap n estadd ysumm
		cap n estimates store dd_`specname'

/** Poisson **/
		cap n local specname=`specname'+1
		* 6-month treatment indicator
		xi: quietly poisson rape_pc i.id i.date i.stname*i.year ers_6mo ers_6plus , cluster(id) 
		cap n estadd ysumm
		cap n estimates store dd_`specname'

		cap n local specname=`specname'+1
		* 9-month treatment indicator
		xi: quietly poisson rape_pc i.id i.date i.stname*i.year ers_9mo ers_9plus , cluster(id) 
		cap n estadd ysumm
		cap n estimates store dd_`specname'

		cap n local specname=`specname'+1
		* 12-month treatment indicator
		xi: quietly poisson rape_pc i.id i.date i.stname*i.year ers_12mo ers_12plus , cluster(id)  
		cap n estadd ysumm
		cap n estimates store dd_`specname'
		
/* Table Output */ 
		#delimit ;
			cap n estout * using ../appendix_2b.tex, 
				style(tex) label notype margin 
				cells((b(star fmt(%9.3f) pvalue(p))) (se(fmt(%9.3f)par))) 		
				stats(N ymean,
					labels("N" "Mean of dependent variable")
					fmt(%9.0fc 2))
				keep(ers_6mo ers_6plus ers_9mo ers_9plus ers_12mo ers_12plus)
				order(ers_6mo ers_6plus ers_9mo ers_9plus ers_12mo ers_12plus)
				varlabels(ers_6mo "ERS (first 6 months)" ers_6plus "ERS (post-6 months)"
						ers_9mo "ERS (first 9 months)" ers_9plus "ERS (post-9 months)"
						ers_12mo "ERS (first 12 months)" ers_12plus "ERS (post-12 months)")
				replace noabbrev starlevels(* 0.10 ** 0.05 *** 0.01) 
				title(FE estimates of the effect of erotic services openings on forcible female rapes per 100,000 using varying windows)   
				collabels(none) eqlabels(none) mlabels(none) mgroups(none) 
				prehead("\begin{table}[htbp]\centering" "\footnotesize" "\caption{@title}" "\label{tb:fe_windows}" "\begin{center}" "\begin{threeparttable}" "\begin{tabular}{l*{@E}{c}}"
		"\toprule"
		"\multicolumn{1}{l}{Dep var:}&"
		"\multicolumn{6}{c}{\textbf{Female Rapes}}\\"
		"\multicolumn{1}{c}{}&"
		"\multicolumn{1}{c}{1}&"
		"\multicolumn{1}{c}{2}&"
		"\multicolumn{1}{c}{3}&"
		"\multicolumn{1}{c}{4}&"
		"\multicolumn{1}{c}{5}&"
		"\multicolumn{1}{c}{6}\\")
				posthead("\midrule")
				prefoot("\midrule")  
				postfoot("\midrule"
				"Estimation method		 		& OLS  & OLS  & OLS  & Poisson  & Poisson & Poisson \\"
				"ORI FE						& Yes & Yes & Yes & Yes & Yes & Yes  \\"
				"Month-Year FE	 				& Yes & Yes & Yes & Yes & Yes & Yes  \\"
				"State-Year FE		 			& Yes & Yes & Yes & Yes & Yes & Yes  \\"
				"\bottomrule" "\end{tabular}" "\begin{tablenotes}" "\tiny" "\item Outcome variable comes from the UCR Summary Reports.  Cluster robust standard errors by ORI are shown in parenthesis.  * p$<$0.10, ** p$<$0.05, *** p$<$0.01" "\end{tablenotes}" "\end{threeparttable}" "\end{center}" "\end{table}") ;
		#delimit cr
cap n estimates clear
}
*****
{/* Table A.3 -- Bacon decomposition of TWFE estimates of ERS on female homicides and forcible female rape offenses per 100,000 */ 

//  Bacon Decomposition Code 
// 	net install ddtiming, from(https://tgoldring.com/code/)

/* Female Homicides per 100,000 */
use ../data/ers_shr_combined.dta, replace 
estimates clear
	quietly eststo: xi: xtreg f_all_pc  i.date ers_10mo ers_10plus, cluster(id) fe
	quietly ddtiming f_all_pc ers_10plus, i(id) t(date)

	matrix wt_e=e(wt_sum_e)
	matrix dd_e=e(dd_avg_e)
	matrix row1 = wt_e, dd_e

	matrix wt_l=e(wt_sum_l)
	matrix dd_l=e(dd_avg_l)
	matrix row2 = wt_l, dd_l

	matrix wt_u=e(wt_sum_u)
	matrix dd_u=e(dd_avg_u)
	matrix row3 = wt_u, dd_u

	matrix estimates = row1 \ row2 \row3
	matrix colnames estimates = Weight DD
	matrix rownames estimates = r1 r2 r3
	ereturn list

/* Table Output */
#delimit ;
esttab matrix(estimates, fmt(%9.3f)) using ../appendix_3a.tex,
		noobs replace
		style(tex) label notype
		varlabels(r1 "Earlier T vs Later C" r2 "Later T vs. Earlier C" r3 "T vs Never Treated")
		title(Bacon decomposition of TWFE estimates of ERS on female homicides per 100,000)   
		collabels(none) eqlabels(none) mlabels(none) mgroups(none)
		prehead("\begin{table}[htbp]\centering" "\label{dd}" "\scriptsize" "\caption{@title}" "\begin{center}" "\begin{threeparttable}" "\begin{tabular}{l*{@E}{c}}"
"\toprule"
"\multicolumn{1}{l}{\textbf{DD Comparison:}}&"
"\multicolumn{1}{c}{\textbf{Weight}}&"
"\multicolumn{1}{l}{\textbf{Avg DD Est:}}\\")
		prefoot("\midrule")  
		postfoot("\midrule"
		"\bottomrule" "\end{tabular}" "\begin{tablenotes}" "\tiny" "\item These are TWFE regressions using the Uniform Crime Reports Summary Parti I.  Controls include city and date fixed effects." "\end{tablenotes}" "\end{threeparttable}" "\end{center}" "\end{table}");
#delimit cr
cap n estimates clear

/* Female Forcible Rapes per 100,000 */
use ../data/ers_ucr_crimes_combined.dta, replace 
	estimates clear
	quietly eststo: xi: xtreg rape_pc  i.date ers_10mo ers_10plus, cluster(id) fe
	quietly ddtiming rape_pc ers_10plus, i(id) t(date)


	matrix wt_e=e(wt_sum_e)
	matrix dd_e=e(dd_avg_e)
	matrix row1 = wt_e, dd_e
	
	matrix wt_l=e(wt_sum_l)
	matrix dd_l=e(dd_avg_l)
	matrix row2 = wt_l, dd_l
	
	matrix wt_u=e(wt_sum_u)
	matrix dd_u=e(dd_avg_u)
	matrix row3 = wt_u, dd_u

	matrix estimates = row1 \ row2 \row3
	matrix colnames estimates = Weight DD
	matrix rownames estimates = r1 r2 r3

	ereturn list

/* Table Output */
#delimit ;
	esttab matrix(estimates, fmt(%9.3f)) using ../appendix_3b.tex,
			noobs replace
			style(tex) label notype
			varlabels(r1 "Earlier T vs Later C" r2 "Later T vs. Earlier C" r3 "T vs Never Treated")
			title(Bacon decomposition of TWFE estimates of ERS on forcible female rape offenses per 100,000)   
			collabels(none) eqlabels(none) mlabels(none) mgroups(none)
			prehead("\begin{table}[htbp]\centering" "\label{dd}" "\scriptsize" "\caption{@title}" "\begin{center}" "\begin{threeparttable}" "\begin{tabular}{l*{@E}{c}}"
	"\toprule"
	"\multicolumn{1}{l}{\textbf{DD Comparison:}}&"
	"\multicolumn{1}{c}{\textbf{Weight}}&"
	"\multicolumn{1}{l}{\textbf{Avg DD Est:}}\\")
			prefoot("\midrule")  
			postfoot("\midrule"
			"\bottomrule" "\end{tabular}" "\begin{tablenotes}" "\tiny" "\item These are TWFE regressions using the Uniform Crime Reports Summary Parti I.  Controls include city and date fixed effects." "\end{tablenotes}" "\end{threeparttable}" "\end{center}" "\end{table}");
#delimit cr
cap n estimates clear	
}
*****
{/* Table A.4 -- OLS estimates of the effect of erotic services opening on female murders and forcible female rape offenses, randomization inference with 1000 draws */ 

{/* Panel A -- Female Homicides */
use ../data/craigslist_raw.dta, replace 

gen year=year(ersdate)
gen month=month(ersdate)
drop ersdate

gen ersdate=ym(year,month)
format ersdate  %tm
keep agname stname ersdate
sort agname stname

tempfile raw
save "`raw'", replace

/* Create a thousand datasets. */

forvalues i = 1/1000  {
	
/* Create the city dataset */
use "`raw'", replace

drop ersdate
set seed `i'
generate random_`i' = runiform()
sort random_`i'
gen one=_n
drop random*
sort one

tempfile one
save "`one'", replace

/* Create the randomized date dataset */
use "`raw'", replace
keep ersdate
gen one=_n
sort one
merge one using "`one'"
ta _merge
drop _merge one
sort agname stname
tempfile permute`i'
save "`permute`i''", replace

/* Merge in the placebo ERSDATE to the SHR dataset */
use ../data/shr_raw.dta, replace

/* Merge */
sort agname stname
merge agname stname using "`permute`i''"
keep if _merge==3
drop _merge

collapse (sum) f_all pop (max) ersdate, by(year month date agname stname)

/* Create Per capita measures. */
foreach x of varlist f_all {
	gen `x'_pc=`x'/pop * 100000
	gen ln`x'_pc = ln(`x'_pc)
}

egen id=group(agname stname)
tsset id date

/* Create Treatment dates */ 
gen	 	treat_ersdate=date-ersdate
gen 	ers=(treat_ersdate>0 & treat_ersdate!=.)
sort id date

/* The following five lines address the questionable population values.  We do this by replacing all observations with missing for whom the year to year change was extreme.  We then later below impute the missing values through linear interpolation.  */
bysort id: egen popmean=mean(pop)
replace pop=. if pop==0
bysort id: gen diff=pop[_n] - pop[_n-1]
bysort id: gen ratio=diff/popmean
bysort id: replace pop=. if ratio<-0.5
bysort id: replace pop=. if ratio<0.1 & ratio>-0.1 & pop[_n-1]==.

tsfill, full
cap n drop treat* ers
bysort id: replace agname=agname[_n-1] if agname==""
bysort id: replace agname=agname[_n+1] if agname==""
bysort id: replace stname=stname[_n-1] if stname==""
bysort id: replace stname=stname[_n+1] if stname==""
drop year month
gen year=yofd(dofm(date))
sort id date
bysort id year: gen month=_n
bysort id: replace ersdate=ersdate[_n-1] if ersdate==.
bysort id: replace ersdate=ersdate[_n+1] if ersdate==.
bysort id: ipolate pop date, gen(pop2) 
bysort id: carryforward pop2, gen(pop3)
bysort id year: egen pop4=max(pop)
bysort id: drop if pop4<100000
gen	 	treat_ersdate=date-ersdate

/* Drop cities that are seem to not be reporting for some time period. */
gen one=1
bysort agname stname: egen count=total(one)
drop if count<168
drop if count>180

sort id date
bysort id: gen trend=_n

/* Handle Missing Values. */
replace f_all=0 if f_all==.
replace f_all_pc = 0 if f_all_pc==.

gen 	ers_all=(treat_ersdate>0 & treat_ersdate!=.)
gen 	ers_10mo=(treat_ersdate>0 & treat_ersdate<=10 & treat_ersdate!=.)
gen 	ers_10plus=(treat_ersdate>10 & treat_ersdate!=.)

/* Robustness treatment variables */
gen 	ers_6mo=(treat_ersdate>0 & treat_ersdate<=6 & treat_ersdate!=.)
gen 	ers_6plus=(treat_ersdate>6 & treat_ersdate!=.)

gen 	ers_9mo=(treat_ersdate>0 & treat_ersdate<=9 & treat_ersdate!=.)
gen 	ers_9plus=(treat_ersdate>9 & treat_ersdate!=.)

gen 	ers_12mo=(treat_ersdate>0 & treat_ersdate<=12 & treat_ersdate!=.)
gen 	ers_12plus=(treat_ersdate>12 & treat_ersdate!=.)

di "BEGINNING iteration # `i' of 1,000. Time: "c(current_time)

qui xi: areg f_all_pc i.stname*i.year i.date ers_10mo ers_10plus, cluster(id) a(id)
gen ers_1=_b[ers_10mo]
gen ers_2=_b[ers_10plus]
gen ers_n1=e(N)

collapse (mean) ers_1 ers_2 ers_n1

gen iteration=`i'

save ../data/appendix_4/permute_ols_`i'.dta, replace
}

/* Append Simulated Data Sets Together */
use ../data/appendix_4/permute_ols_1.dta, replace
forvalues i=2/1000 {				
	append using ../data/appendix_4/permute_ols_`i'.dta
   	}
save ../data/appendix_4_permute_ols.dta, replace


/* Add in the true effect */
use ../data/craigslist_raw.dta, replace 

gen year=year(ersdate)
gen month=month(ersdate)
drop ersdate

gen ersdate=ym(year,month)
format ersdate  %tm
keep agname stname ersdate
sort agname stname

tempfile raw
save "`raw'", replace

use ../data/shr_raw.dta, replace

/* Merge */
sort agname stname
merge agname stname using "`raw'"
keep if _merge==3
drop _merge

collapse (sum) f_all pop (max) ersdate, by(year month date agname stname)

/* Create Per capita measures. */ 
foreach x of varlist f_all {
	gen `x'_pc=`x'/pop * 100000
}

egen id=group(agname stname)
tsset id date

/* Create treatment dates. */
gen	 	treat_ersdate=date-ersdate
gen 	ers=(treat_ersdate>0 & treat_ersdate!=.)
sort id date

/* The following five lines address the questionable population values.  We do this by replacing all observations with missing for whom the year to year change was extreme.  We then later below impute the missing values through linear interpolation. */
bysort id: egen popmean=mean(pop)
replace pop=. if pop==0
bysort id: gen diff=pop[_n] - pop[_n-1]
bysort id: gen ratio=diff/popmean
bysort id: replace pop=. if ratio<-0.5
bysort id: replace pop=. if ratio<0.1 & ratio>-0.1 & pop[_n-1]==.

/* Create Balanced Panel */
tsfill, full
cap n drop treat* ers
bysort id: replace agname=agname[_n-1] if agname==""
bysort id: replace agname=agname[_n+1] if agname==""
bysort id: replace stname=stname[_n-1] if stname==""
bysort id: replace stname=stname[_n+1] if stname==""
drop year month
gen year=yofd(dofm(date))
sort id date
bysort id year: gen month=_n
bysort id: replace ersdate=ersdate[_n-1] if ersdate==.
bysort id: replace ersdate=ersdate[_n+1] if ersdate==.
bysort id: ipolate pop date, gen(pop2) 
bysort id: carryforward pop2, gen(pop3)
bysort id year: egen pop4=max(pop)
bysort id: drop if pop4<100000
gen	 	treat_ersdate=date-ersdate

/* Drop cities that are seem to not be reporting for some time period. */
gen one=1
bysort agname stname: egen count=total(one)
drop if count<168
drop if count>180

sort id date
bysort id: gen trend=_n

/* Handling Missing Values */ 
replace f_all=0 if f_all==.
replace f_all_pc = 0 if f_all_pc==.

gen 	ers_all=(treat_ersdate>0 & treat_ersdate!=.)
gen 	ers_10mo=(treat_ersdate>0 & treat_ersdate<=10 & treat_ersdate!=.)
gen 	ers_10plus=(treat_ersdate>10 & treat_ersdate!=.)

/* Robustness treatment variables */
gen 	ers_6mo=(treat_ersdate>0 & treat_ersdate<=6 & treat_ersdate!=.)
gen 	ers_6plus=(treat_ersdate>6 & treat_ersdate!=.)
gen 	ers_9mo=(treat_ersdate>0 & treat_ersdate<=9 & treat_ersdate!=.)
gen 	ers_9plus=(treat_ersdate>9 & treat_ersdate!=.)
gen 	ers_12mo=(treat_ersdate>0 & treat_ersdate<=12 & treat_ersdate!=.)
gen 	ers_12plus=(treat_ersdate>12 & treat_ersdate!=.)

/* Create 1001st simulated data */
preserve
quietly xi: areg f_all_pc i.stname*i.year i.date ers_10mo ers_10plus, cluster(id) a(id)

gen ers_1=_b[ers_10mo]
gen ers_2=_b[ers_10plus]
gen ers_n1=e(N)

collapse (mean) ers_1 ers_2 ers_n1

gen iteration=1001

save ../data/appendix_4/permute_ols_1001.dta, replace
use ../data/appendix_4_permute_ols.dta, replace
append using ../data/appendix_4/permute_ols_1001.dta
save ../data/appendix_4_permute_ols.dta, replace

restore

/* Analysis Begins. */ 
quietly xi: quietly areg f_all_pc  i.stname*i.year i.date ers_10mo ers_10plus, cluster(id) a(id)

preserve

/* Randomization inference */
	local specname = `specname'+1
	use ../data/appendix_4_permute_ols.dta, replace

/* True effect */
	qui sum ers_1 if iteration==1001 		/* get the true value */
	local beta=r(mean)						/* store this scalar as a macro */
	estadd scalar beta=`beta'			
	
/* Count from regression */
	local specname=`specname'+1
	qui sum ers_n1 if iteration==1001		/* Use summarize to get the mean value for true effects */
	local cl_N=r(mean)
	estadd scalar cl_N=`cl_N'				/* stored as a scalar */

/* Percentiles */
	qui sum ers_1 if iteration!=1001, de		/* ditto */
	local p95= r(p95)
	local p5 = r(p5)
	estadd scalar p95 = `p95'
	estadd scalar p5 =`p5'
	return list

/* P-value */
	qui sort ers_1
	qui gen rank=_n
	qui su rank if iteration==1001
	qui local pvalue=(`r(mean)'/1000)
	estadd scalar pvalue=`pvalue'
 	estimates store results_`specname'
	local specname = `specname'+1
	
/** ERS 2 **/
restore

qui xi: areg f_all_pc i.stname*i.year i.date ers_10mo ers_10plus, cluster(id) a(id)

/* Randomization inference */
	local specname = `specname'+1
	use ../data/appendix_4_permute_ols.dta, replace

	qui sum ers_2 if iteration==1001 		/* get the true value */
	local beta=r(mean)						/* store this scalar as a macro */
	estadd scalar beta=`beta'			
	
/* Count from regression */
	local specname=`specname'+1
	qui sum ers_n1 if iteration==1001		/* Use summarize to get the mean value for true effects */
	local cl_N=r(mean)
	estadd scalar cl_N=`cl_N'				/* stored as a scalar */

/* Percentiles */
	qui sum ers_2 if iteration!=1001, de		/* ditto */
	local p95= r(p95)
	local p5 = r(p5)
	estadd scalar p95 = `p95'
	estadd scalar p5 =`p5'
	return list

/* P-value */
	qui sort ers_2
	qui gen rank=_n
	qui su rank if iteration==1001
	qui local pvalue=(`r(mean)'/1000)
	estadd scalar pvalue=`pvalue'
 	estimates store results_`specname'
	local specname = `specname'+1
	
/* Table Output */	
#delimit ;
	cap n estout * using ../appendix_4a.dta.tex, 
		style(tex) label notype
		cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) 		
		stats(beta  p5 p95  pvalue cl_N, 
			labels("True effect" "5th percentile" "95th percentile" "Two-tailed test p-value" "N")
			fmt(3 3 3 2 0))	
		replace noabbrev
		drop(ers* _*) 
		title(Estimated effect of Craigslist entry on female homicides per 100,000 using linear FE)   
		collabels(none) eqlabels(none) mlabels(none) mgroups(none) substitute(_ \_)
		prehead("\begin{table}[htbp]\centering" "\label{dd}" "\scriptsize" "\caption{@title}" "\begin{center}" "\begin{threeparttable}" "\begin{tabular}{l*{@E}{c}}"
"\toprule"
"\multicolumn{1}{l}{\textbf{Dependent variable:}}&"
"\multicolumn{1}{c}{\textbf{Female homicides per 100,000}}\\"
"\multicolumn{1}{l}{\textbf{Coefficient:}}&"
"\multicolumn{1}{l}{\textbf{0-10 months}}&"
"\multicolumn{1}{c}{\textbf{10+ months}}\\")
		prefoot("\midrule")  
		postfoot("\midrule"
		"\bottomrule" "\end{tabular}" "\begin{tablenotes}" "\tiny" "\item These are FE regressions using the Supplemental Homicide Reports.  The model is linear fixed effects with 1,000 randomized permutations for creating the sampling distribution. Controls include city fixed effects, year fixed effects and state-year fixed effects.  The panel presents 5th and 95th percentile confidence intervals from permutations tests and p-values from a two-tailed test. * p$<$0.10, ** p$<$0.05, *** p$<$0.01" "\end{tablenotes}" "\end{threeparttable}" "\end{center}" "\end{table}");
#delimit cr
	cap n estimates clear
}
***
{/* Panel B -- Female Rapes */
/* Reformat the Craigslist Dates */
use ../data/craigslist_raw.dta, replace 

gen year=year(ersdate)
gen month=month(ersdate)
drop ersdate

gen ersdate=ym(year,month)
format ersdate  %tm
keep agname stname ersdate
sort agname stname

tempfile raw
save "`raw'", replace

/* Merge in the ERSDATE to the UCR Crimes data set. */
use ../data/ers_ucr_crimes_combined.dta,replace 

/* Merge */
sort agname stname
quietly merge m:1 agname stname using "`raw'"
keep if _merge==3
drop _merge
drop if date==.
cap drop id popmean diff ratio 
egen id = group(agname stname)
tsset id date

/* The following five lines address the questionable population values.  We do this by replacing all observations with missing for whom the year to year change was extreme.  We then later below impute the missing values through linear interpolation. */ 
bysort id: egen popmean=mean(pop1)
replace pop1=. if pop1==0
bysort id: gen diff=pop1[_n] - pop1[_n-1]
bysort id: gen ratio=diff/popmean
bysort id: replace pop1=. if ratio<-0.5
bysort id: replace pop1=. if ratio<0.1 & ratio>-0.1 & pop1[_n-1]==.

/* Create a balanced panel */
	tsfill, full

/* Start over */
	cap n drop treat* ers

/* Fill in the missing state names */
	bysort id: replace agname=agname[_n-1] if agname==""
	bysort id: replace agname=agname[_n+1] if agname==""
	bysort id: replace stname=stname[_n-1] if stname==""
	bysort id: replace stname=stname[_n+1] if stname==""

/* Create new year and month variables */
	drop year month count 
	gen year=yofd(dofm(date))
	sort id date
	bysort id year: gen month=_n

/* Fill in the missing ersdate (missing because of tsfill) */
	bysort id: replace ersdate=ersdate[_n-1] if ersdate==.
	bysort id: replace ersdate=ersdate[_n+1] if ersdate==.

/* Impute missing population values */
	cap drop pop2 pop3 pop4 trend
	bysort id: ipolate pop1 date, gen(pop2) 

/* Drop cities whose max population over the panel was less than 100,000 */
	bysort id: carryforward pop2, gen(pop3)
	bysort id year: egen pop4=max(pop3)
	bysort id: drop if pop4<100000

/* Drop cities that are seem to not be reporting for some time period. */
bysort agname stname: egen count=total(one)
drop if count<168
drop if count>180

sort id date
bysort id: gen trend=_n

drop treat_ersdate ers_10mo ers_10plus 
gen	 	treat_ersdate=date-ersdate
gen 	ers_10mo=(treat_ersdate>0 & treat_ersdate<=10 & treat_ersdate!=.)
gen 	ers_10plus=(treat_ersdate>10 & treat_ersdate!=.)

save ../data/appendix_4b_TEMP.dta, replace

gen 	treat = 0
replace treat = 1 if ers_10plus==1
bysort id: gen n=_N

****************************
* ESTIMATION OF TRUE EFFECT
****************************

quietly xi: areg rape_pc i.date i.stname*i.year ers_10mo ers_10plus, a(id) cluster(id)
gen ers_1=_b[ers_10mo]
gen ers_2=_b[ers_10plus]
gen ers_n1=e(N)

/* Saving point estimates */
collapse (mean) ers_1 ers_2 ers_n1

gen iteration=1001

tempfile rape1001
save "`rape1001'", replace

****************************
* START RANDOMIZATION
****************************

/* appendix_4b_TEMP.dta will be the main data file from which all randomization and true estimation takes place. */

use ../data/appendix_4b_TEMP.dta, clear
drop ers* treat*
sort id
tempfile main
save "`main'", replace


/* Create the fake treatment profiles */
quietly {
noisily _dots 0, title(Loop running) reps(4)

quietly forvalues i = 2/4 {

	use ../data/craigslist_raw.dta, replace 
	
	gen year=year(ersdate)
	gen month=month(ersdate)
	drop ersdate
	
	gen ersdate=ym(year,month)
	format ersdate  %tm
	keep agname stname ersdate
	sort agname stname
	gen n=_n
	
	tempfile temp
	save "`temp'", replace
	
	/* Create the ers file */
	keep ersdate
	gen random_`i'=rnormal()
	sort random_`i'
	gen n=_n
	drop random_`i'
	sort n
	
	tempfile ers
	save "`ers'", replace
	
	use "`temp'", replace
	drop ersdate
	sort n
	merge 1:1 n using "`ers'"
	drop _merge n
	sort agname stname
	egen id = group(agname stname)
	sort id
	
	save "`ers'", replace
	
	use "`main'", replace
	merge m:1 id using "`ers'"
	keep if _merge==3
	drop _merge

	gen	 	treat_ersdate=date-ersdate
	gen 	ers_10mo=(treat_ersdate>0 & treat_ersdate<=10 & treat_ersdate!=.)
	gen 	ers_10plus=(treat_ersdate>10 & treat_ersdate!=.)

	/* Estimation */
	xi: areg rape_pc i.date i.stname*i.year ers_10mo ers_10plus, a(id) cluster(id)
	gen ers_1=_b[ers_10mo]
	gen ers_2=_b[ers_10plus]
	gen ers_n1=e(N)

	/* Saving point estimates */
	collapse (mean) ers_1 ers_2 ers_n1

	gen iteration=`i'
	
	tempfile rape`i'
	save "`rape`i''", replace
	noisily _dots `i' 0	
	}
}

use "`rape1001'", replace
/* Append Data Sets */
forvalues i = 2/4 {
	append using "`rape`i''"	
	}

tempfile rape
save "`rape'", replace

save ../data/appendix_4b1.dta, replace

use ../data/appendix_4b1.dta, replace
sort iteration

****************************
* CALCULATE APPROXIMATE P-VALUES
****************************

local specname=`specname'+1
ereturn clear
return clear
/** Randomization inference **/
	local specname = `specname'+1
	use ../data/appendix_4b.dta, clear

/* True effect */
	qui sum ers_1 if iteration==1001 		/* get the true value */
	local beta=r(mean)						/* store this scalar as a macro */
	estadd scalar beta=`beta'
	
/* Count from regression */
	local specname=`specname'+1
	qui sum ers_n1 if iteration==1001		/* Use summarize to get the mean value for true effects */
	local cl_N=r(mean)
	estadd scalar cl_N=`cl_N'				/* stored as a scalar */

/* Percentiles */
	qui sum ers_1 if iteration!=1001, de		/* ditto */
	local p95= r(p95)
	local p5 = r(p5)
	estadd scalar p95 = `p95'
	estadd scalar p5 =`p5'
	return list 

/* P-value */
	qui sort ers_1
	qui gen rank=_n
	qui su rank if iteration==1001
	qui local pvalue=(`r(mean)'/1000)
	estadd scalar pvalue=`pvalue'
 	eststo results_`specname'
	local specname = `specname'+1
	
/** ERS 10+ months **/

/** Randomization inference **/
	local specname = `specname'+1

	qui sum ers_2 if iteration==1001 		/* get the true value */
	local beta2=r(mean)						/* store this scalar as a macro */
	estadd scalar beta2=`beta2'			
	
/* Count from regression */
	local specname=`specname'+1
	qui sum ers_n1 if iteration==1001		/* Use summarize to get the mean value for true effects */
	local cl_N2=r(mean)
	estadd scalar cl_N2=`cl_N2'				/* stored as a scalar */

/* Percentiles */
	qui sum ers_2 if iteration!=1001, de		/* ditto */
	local p952= r(p95)
	local p52 = r(p5)
	estadd scalar p952 = `p952'
	estadd scalar p52 =`p52'
	return list

/* P-value */
	qui sort ers_2
	qui gen rank2=_n
	qui su rank2 if iteration==1001
	qui local pvalue2=(`r(mean)'/1000)
	estadd scalar pvalue2=`pvalue2'
//  	estimates store results_`specname'
	local specname = `specname'+1
	
/* Table Output */	
#delimit ;
	cap n estout * using ../appendix_4b.tex, 
		style(tex) label notype
		cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) 		
		stats(beta  p5 p95  beta2 p52 p952 pvalue cl_N pvalue2 cl_N2, 
			labels("True effect" "5th percentile" "95th percentile" "True effect" "5th percentile" "95th percentile" "Two-tailed test p-value" "N" "Two-tailed test p-value" "N")
			fmt(3 3 3 3 3 3 2 0 2 0))	
		replace noabbrev
		drop(ers* _*) 
		title(Estimated effect of Craigslist entry on female forcible rape offenses per 100,000 using randomization inference using OLS)   
		collabels(none) eqlabels(none) mlabels(none) mgroups(none) substitute(_ \_)
		prehead("\begin{table}[htbp]\centering" "\label{dd}" "\scriptsize" "\caption{@title}" "\begin{center}" "\begin{threeparttable}" "\begin{tabular}{l*{@E}{c}}"
"\toprule"
"\multicolumn{1}{l}{\textbf{Dependent variable:}}&"
"\multicolumn{1}{c}{\textbf{Female homicides per 100,000}}\\"
"\multicolumn{1}{l}{\textbf{Coefficient:}}&"
"\multicolumn{1}{l}{\textbf{0-10 months}}&"
"\multicolumn{1}{c}{\textbf{10+ months}}\\")
		prefoot("\midrule")  
		postfoot("\midrule"
		"\bottomrule" "\end{tabular}" "\begin{tablenotes}" "\tiny" "\item These are FE regressions using the Uniform Crime Reports Summary Parti I.  The model is twoway fixed effects with 1,000 randomized permutations for creating the sampling distribution. Controls include city fixed effects, year fixed effects, state-year fixed effects and population.  The panel presents 5th and 95th percentile confidence intervals from permutations tests and p-values from a two-tailed test. * p$<$0.10, ** p$<$0.05, *** p$<$0.01" "\end{tablenotes}" "\end{threeparttable}" "\end{center}" "\end{table}");
#delimit cr
	cap n estimates clear
}
}
*****
