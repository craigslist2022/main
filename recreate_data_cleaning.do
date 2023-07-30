*** Recreate Clean Data Sets ***
/* Code to reproducte the main datasets used in the paper "Did Craigslist's Erotic Services Reduce Female Homicide and Rape?" by Scott Cunningham, Gregory DeAngelo, and John Tripp. */

/* To recreate the main figures and tables from the paper, please execute the recreate_main_tables.do after executing this do file. */

/* Make sure to have installed the following commands: sg30, csdid, reghdfe, drdid, missings, event_plot, estout, avar, ftools, github, eventstudyinteract, coefplott, moremata, twowayfeweights, carryforward, outreg2, stutex, cmogram, ddtiming, _gwtmean, and fect (from https://raw.githubusercontent.com/xuyiqing/fect_stata/master/). */

/* You will need to indicate the directory where the data are saved. If you encounter an error in the code that is not resolved by installing an additional command, please reach out via github and the authors will work to address the concern. */

cd ""

*****
{/* Create Clean Craigslist & SHR Combined Data Sets -- ers_shr_combined.dta */
*** Dataset used in the following:
*** Tables 1, 4, 6, & 7
*** Figure 1 & 3
*** Appendicies 1, 2, & 3
* Load and Clean ERS Date information 
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

* Merge in the date Craigslist entered into a given city and state.
use ../data/citystate_raw.dta, replace
	gen  year=substr(cldate,6,4)
	gen  temp=substr(cldate,3,3)
	gen  month=1 if temp=="jan"
	replace month=2 if temp=="feb"
	replace month=3 if temp=="mar"
	replace month=4 if temp=="apr"
	replace month=5 if temp=="may"
	replace month=6 if temp=="jun"
	replace month=7 if temp=="jul"
	replace month=8 if temp=="aug"
	replace month=9 if temp=="sep"
	replace month=10 if temp=="oct"
	replace month=11 if temp=="nov"
	replace month=12 if temp=="dec"
	destring year, replace force
	drop temp cldate
	
	gen cldate=ym(year,month)
	format cldate %tm
	keep agname stname cldate
	sort agname stname
	
	tempfile cldate
	save "`cldate'", replace


use "`raw'", replace
	merge agname stname using "`cldate'"
	keep if _merge==3
	drop _merge
	sort agname stname

	tempfile raw
	save "`raw'", replace

* Merge in the ERSDATE to the main murders dataset
use ../data/shr_raw.dta, replace
	
	sort agname stname
	merge agname stname using "`raw'"
	keep if _merge==3
	drop _merge
	
	collapse (sum) m_all f_all pop f_acq f_strangle f_white f_black f_asian f_dv f_unknown (max) ersdate cldate, by(year month date agname stname)

	
* Generate Per capita measures
	foreach x of varlist f_all f_acq m_all f_white f_black f_asian f_dv f_unknown {
		gen `x'_pc=`x'/pop * 100000
		gen ln`x'_pc = ln(`x'_pc)
	}
	egen id=group(agname stname)
	tsset id date

/* The following five lines address the questionable population values.  We do this by replacing all observations with missing for whom the year to year change was extreme.  We then later below impute the missing values through linear interpolation. */
	bysort id: egen popmean=mean(pop)
	replace pop=. if pop==0
	bysort id: gen diff=pop[_n] - pop[_n-1]
	bysort id: gen ratio=diff/popmean
	bysort id: replace pop=. if ratio<-0.5
	bysort id: replace pop=. if ratio<0.1 & ratio>-0.1 & pop[_n-1]==.

* Create a balanced panel
	tsfill, full

* Start over, rewriting treatment dates for the balanced panel.
	cap n drop treat* ers

* Fill in the missing state names
	bysort id: replace agname=agname[_n-1] if agname==""
	bysort id: replace agname=agname[_n+1] if agname==""
	bysort id: replace stname=stname[_n-1] if stname==""
	bysort id: replace stname=stname[_n+1] if stname==""

* Create new year and month variables
	drop year month
	gen year=yofd(dofm(date))
	sort id date
	bysort id year: gen month=_n

* Fill in the missing ersdate (missing because of tsfill)
	bysort id: replace ersdate=ersdate[_n-1] if ersdate==.
	bysort id: replace ersdate=ersdate[_n+1] if ersdate==.

* Impute missing population values 
	bysort id: ipolate pop date, gen(pop2) 

* Drop cities whose max population over the panel was less than 100,000
	bysort id: carryforward pop2, gen(pop3)
	bysort id year: egen pop4=max(pop3)
	bysort id: drop if pop4<100000

* Define treatment categories	
	gen	treat_ersdate=date-ersdate
	gen treat_cldate=date-cldate
	gen ers_all=(treat_ersdate>0 & treat_ersdate!=.)
	gen ers_10mo=(treat_ersdate>0 & treat_ersdate<=10 & treat_ersdate!=.)
	gen ers_10plus=(treat_ersdate>10 & treat_ersdate!=.)
	gen cl_all=(treat_cldate>0 & treat_cldate!=.)
	gen cl_10mo = (treat_cldate>0 & treat_cldate<=10 & treat_cldate!=.)
	gen cl_10plus = (treat_cldate>10 & treat_cldate!=.)
	
* Robustness treatment variables
	gen ers_6mo=(treat_ersdate>0 & treat_ersdate<=6 & treat_ersdate!=.)
	gen ers_6plus=(treat_ersdate>6 & treat_ersdate!=.)
	gen ers_9mo=(treat_ersdate>0 & treat_ersdate<=9 & treat_ersdate!=.)
	gen ers_9plus=(treat_ersdate>9 & treat_ersdate!=.)
	gen ers_12mo=(treat_ersdate>0 & treat_ersdate<=12 & treat_ersdate!=.)
	gen ers_12plus=(treat_ersdate>12 & treat_ersdate!=.)

* Here we drop cities that are not reporting for some time period.
	gen one=1
	bysort agname stname: egen count=total(one)
	drop if count<168
	drop if count>180

	sort id date
	bysort id: gen trend=_n

* Handling missing values in main outcomes of interest.
	replace f_all=0 if f_all==.
	replace f_all_pc = 0 if f_all_pc==.
	gen 	f_all_zeroes = f_all
	replace f_all_zeroes=0.5 if f_all==0
	gen 	f_all_zeroes_pc = f_all_zeroes/pop3 * 100000
	gen 	lnf_all_zeroes_pc = ln(f_all_zeroes_pc)
	gen 	qt_f_all = f_all_pc^0.25
	gen 	f_all_sine = ln(f_all_pc^2 + sqrt(f_all_pc^2 + 1))

	replace f_dv=0 if f_dv==.
	replace f_dv_pc = 0 if f_dv_pc==.
	gen 	f_dv_zeroes = f_dv
	replace f_dv_zeroes=0.5 if f_dv==0
	gen 	f_dv_zeroes_pc = f_dv_zeroes/pop3 * 100000
	gen 	lnf_dv_zeroes_pc = ln(f_dv_zeroes_pc)
	gen 	qt_f_dv = f_dv_pc^0.25
	gen 	f_dv_sine = ln(f_dv_pc^2 + sqrt(f_dv_pc^2 + 1))

	replace f_acq=0 if f_acq == .
	replace f_acq_pc = 0 if f_acq_pc == .
	gen 	f_acq_zeroes = f_acq
	replace f_acq_zeroes = 0.5 if f_acq==0
	gen 	f_acq_zeroes_pc = f_acq_zeroes/pop3*10000
	gen 	lnf_acq_zeroes_pc = ln(f_acq_zeroes_pc)

	gen 	f_acquaintance = f_acq + f_dv
	gen 	f_acquaintance_pc = f_acquaintance/pop3 * 100000
	replace f_acquaintance=0 if f_acquaintance == .
	replace f_acquaintance_pc = 0 if f_acquaintance_pc == .
	gen 	f_acquaintance_zeroes = f_acq
	replace f_acquaintance_zeroes = 0.5 if f_acquaintance==0
	gen 	f_acquaintance_zeroes_pc = f_acquaintance_zeroes/pop3*10000
	gen 	lnf_acquaintance_zeroes_pc = ln(f_acquaintance_zeroes_pc)

	replace m_all=0 if m_all==.
	replace m_all_pc = 0 if m_all_pc == .
	gen 	m_all_zeroes=m_all
	replace m_all_zeroes=.5 if m_all==0
	gen 	m_all_zeroes_pc = m_all_zeroes/pop3*100000
	gen 	lnm_all_zeroes_pc = ln(m_all_zeroes_pc)

	replace f_white=0 if f_white==.
	replace f_white_pc = 0 if f_white_pc == .
	gen 	f_white_zeroes=f_white
	replace f_white_zeroes=.5 if f_white==0
	gen 	f_white_zeroes_pc = f_white_zeroes/pop3*100000
	gen 	lnf_white_zeroes_pc = ln(f_white_zeroes_pc)

	replace f_black=0 if f_black==.
	replace f_black_pc = 0 if f_black_pc == .
	gen 	f_black_zeroes=f_black
	replace f_black_zeroes=.5 if f_black==0
	gen 	f_black_zeroes_pc = f_black_zeroes/pop3*100000
	gen 	lnf_black_zeroes_pc = ln(f_black_zeroes_pc)

* Creating Lags and Leads
	gen 	lag1=0
	replace lag1=1 if treat_ersdate<=0 & treat_ersdate>-10
	gen 	lag2=0
	replace lag2=1 if treat_ersdate<=-10 & treat_ersdate>-20
	gen 	lag3=0
	replace lag3=1 if treat_ersdate<=-20 & treat_ersdate>-30
	gen 	lag4=0
	replace lag4=1 if treat_ersdate<=-30 & treat_ersdate>-40
	gen 	lag5=0
	replace lag5=1 if treat_ersdate<=-40 & treat_ersdate>-50
	gen 	lag6=0
	replace lag6=1 if treat_ersdate<=-50 
	label variable lag1 "0-9 months pre"
	label variable lag2 "10-19 months pre"
	label variable lag3 "20-29 months pre"
	label variable lag4 "30-39 months pre"
	label variable lag5 "40-49 months pre"
	label variable lag6 "50+ months pre"


	gen dd=0
	replace dd=treat_ersdate if treat_ersdate>0
	gen 	dd1=0
	replace dd1=1 if dd>0 & dd<10
	gen 	dd2=0
	replace dd2=1 if dd>=10 & dd<20
	gen 	dd3=0
	replace dd3=1 if dd>=20 & dd<30
	gen 	dd4=0
	replace dd4=1 if dd>=30 & dd<40
	gen 	dd5=0
	replace dd5=1 if dd>=40  & dd<50
	gen 	dd6=0
	replace dd6=1 if dd>=50 & dd<60
	gen 	dd7=0
	replace dd7=1 if dd>=60 & dd<70
	gen 	dd8=0
	replace dd8=1 if dd>=70 
	label variable dd1 "0-9 months post"
	label variable dd2 "10-19 months post"
	label variable dd3 "20-29 months post"
	label variable dd4 "30-39 months post"
	label variable dd5 "40-49 months post"
	label variable dd6 "50-59 months post"
	label variable dd7 "60-69 months post"
	label variable dd8 "70+ months post"
	
	gen treat=0
	replace treat=1 if treat_ersdate>=0
	
	bysort id: gen n=_N
	sort ersdate
	save ../data/ers_shr_combined.dta, replace 
}
*****
{/* Create Clean Craigslist & UCR Combined Data Sets -- ers_ucr_crimes_combined.dta & ers_ucr_arrests_combined.dta */
**
{/* ers_ucr_arrests_combined.dta */
*** Dataset used in the following:
*** Tables 1 & 3
* Load and Clean ERS Date information.
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
	
* Merge in the date Craigslist entered into a given city and state.
use ../data/citystate_raw.dta, replace
	
	gen  year=substr(cldate,6,4)
	gen  temp=substr(cldate,3,3)
	gen  month=1 if temp=="jan"
	replace month=2 if temp=="feb"
	replace month=3 if temp=="mar"
	replace month=4 if temp=="apr"
	replace month=5 if temp=="may"
	replace month=6 if temp=="jun"
	replace month=7 if temp=="jul"
	replace month=8 if temp=="aug"
	replace month=9 if temp=="sep"
	replace month=10 if temp=="oct"
	replace month=11 if temp=="nov"
	replace month=12 if temp=="dec"
	destring year, replace force
	drop temp cldate
	
	gen cldate=ym(year,month)
	format cldate %tm
	keep agname stname cldate
	sort agname stname
	
	tempfile cldate
	save "`cldate'", replace


use "`raw'", replace
	merge agname stname using "`cldate'"
	keep if _merge==3
	drop _merge
	sort agname stname

	tempfile raw
	save "`raw'", replace

* Merge with UCR Arrest dataset.	
use ../data/ucr_arrests_raw.dta, replace
	cap n drop lag* dd* ersdate treat_ersdate ers
	sort agname stname
	merge agname stname using "`raw'"
	keep if _merge==3
	drop _merge
	drop if date==.
	
	ren YEAR year
	ren MONTH month

	collapse (sum) male_pro female_pro pop (max) ersdate, by(year month date agname stname)
	
* Create new treatment dates
	egen 	id=group(agname stname)
	gen	treat_ersdate=date-ersdate
	gen 	ers=(treat_ersdate>0 & treat_ersdate!=.)
	sort 	id date
	bysort 	id: egen popmean=mean(pop)
	sort 	id date

/* The following five lines address the questionable population values.  We do this by replacing all observations with missing for whom the year to year change was extreme.  We then later below impute the missing values through linear interpolation. */
	replace pop=. if pop==0
	bysort id: gen diff=pop[_n] - pop[_n-1]
	bysort id: gen ratio=diff/popmean
	bysort id: replace pop=. if ratio<-0.5
	bysort id: replace pop=. if ratio<0.1 & ratio>-0.1 & pop[_n-1]==.

* More robust measurements that account for zeroes
	tsset id date
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

* Here we drop cities that are not reporting for some time period.
	gen one=1
	bysort agname stname: egen count=total(one)
	drop if count<168

	gen	treat_ersdate=date-ersdate
	gen 	ers_all=(treat_ersdate>0 & treat_ersdate!=.)
	gen 	ers_10mo=(treat_ersdate>0 & treat_ersdate<=10 & treat_ersdate!=.)
	gen 	ers_10plus=(treat_ersdate>10 & treat_ersdate!=.)
	sort id date
	bysort id: gen trend=_n
	keep if year<2010

* Prostitution arrests.
	replace male_pro=0 if male_pro==.
	gen	male_pro_pc = male_pro/pop3 * 100000
	replace male_pro_pc = 0 if male_pro_pc == .
	gen 	male_pro_zeroes=male_pro
	replace male_pro_zeroes=.5 if male_pro==0
	gen 	male_pro_zeroes_pc = male_pro_zeroes/pop3*100000
	gen 	lnmale_pro_zeroes_pc = ln(male_pro_zeroes_pc)

	replace female_pro=0 if female_pro==.
	gen	female_pro_pc = female_pro/pop3 * 100000
	replace female_pro_pc = 0 if female_pro_pc == .
	gen 	female_pro_zeroes=female_pro
	replace female_pro_zeroes=.5 if female_pro==0
	gen 	female_pro_zeroes_pc = female_pro_zeroes/pop3*100000
	gen 	lnfemale_pro_zeroes_pc = ln(female_pro_zeroes_pc)


* Create Lags and Leads
	cap n drop lag*

	gen 	lag1=0
	replace lag1=1 if treat_ersdate<=0 & treat_ersdate>-10
	gen 	lag2=0
	replace lag2=1 if treat_ersdate<=-10 & treat_ersdate>-20
	gen 	lag3=0
	replace lag3=1 if treat_ersdate<=-20 & treat_ersdate>-30
	gen 	lag4=0
	replace lag4=1 if treat_ersdate<=-30 & treat_ersdate>-40
	gen 	lag5=0
	replace lag5=1 if treat_ersdate<=-40 & treat_ersdate>-50
	gen 	lag6=0
	replace lag6=1 if treat_ersdate<=-50 & treat_ersdate>-85
	label variable lag1 "0-9 months pre"
	label variable lag2 "10-19 months pre"
	label variable lag3 "20-29 months pre"
	label variable lag4 "30-39 months pre"
	label variable lag5 "40-49 months pre"
	label variable lag6 "50-85 months pre"


	gen dd=0
	replace dd=treat_ersdate if treat_ersdate>0
	gen 	dd1=0
	replace dd1=1 if dd>0 & dd<10
	gen 	dd2=0
	replace dd2=1 if dd>=10 & dd<20
	gen 	dd3=0
	replace dd3=1 if dd>=20 & dd<30
	gen 	dd4=0
	replace dd4=1 if dd>=30 & dd<40
	gen 	dd5=0
	replace dd5=1 if dd>=40  & dd<50
	gen 	dd6=0
	replace dd6=1 if dd>=50 & dd<60
	gen 	dd7=0
	replace dd7=1 if dd>=60 & dd<70
	gen 	dd8=0
	replace dd8=1 if dd>=70 & dd<80
	gen 	dd9=0
	replace dd9=1 if dd>=80 & dd<=85
	label variable dd1 "0-9 months post"
	label variable dd2 "10-19 months post"
	label variable dd3 "20-29 months post"
	label variable dd4 "30-39 months post"
	label variable dd5 "40-49 months post"
	label variable dd6 "50-59 months post"
	label variable dd7 "60-69 months post"
	label variable dd8 "70-79 months post"
	label variable dd9 "80-85 months post"
	
save ../data/ers_ucr_arrests_combined.dta, replace}
**
{/* ers_ucr_crimes.dta */
*** Dataset used in the following:
*** Tables 1, 4, & 7
*** Figure 1 & 3
*** Appendicies 2 & 3
* Load and Clean ERS Date information 
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

* Merge in the date Craigslist entered into a given city and state.
use ../data/citystate_raw.dta, replace
	gen  year=substr(cldate,6,4)
	gen  temp=substr(cldate,3,3)
	gen  month=1 if temp=="jan"
	replace month=2 if temp=="feb"
	replace month=3 if temp=="mar"
	replace month=4 if temp=="apr"
	replace month=5 if temp=="may"
	replace month=6 if temp=="jun"
	replace month=7 if temp=="jul"
	replace month=8 if temp=="aug"
	replace month=9 if temp=="sep"
	replace month=10 if temp=="oct"
	replace month=11 if temp=="nov"
	replace month=12 if temp=="dec"
	destring year, replace force
	drop temp cldate
	
	gen cldate=ym(year,month)
	format cldate %tm
	keep agname stname cldate
	sort agname stname
	
	tempfile cldate
	save "`cldate'", replace


use "`raw'", replace
	merge agname stname using "`cldate'"
	keep if _merge==3
	drop _merge
	sort agname stname

	tempfile raw
	save "`raw'", replace
	
* Clean UCR Crimes Data Set. 
use ../data/ucr_crime_raw.dta, replace
	bysort year ori: gen i=_n
	ta i
	drop if i==2

* Create Crime Variables of Interest.
gen rape1=c1f4_1
gen rape2=c1f4_2
gen rape3=c1f4_3
gen rape4=c1f4_4
gen rape5=c1f4_5
gen rape6=c1f4_6
gen rape7=c1f4_7
gen rape8=c1f4_8
gen rape9=c1f4_9
gen rape10=c1f4_10
gen rape11=c1f4_11
gen rape12=c1f4_12

gen larceny1=c1f21_1
gen larceny2=c1f21_2
gen larceny3=c1f21_3
gen larceny4=c1f21_4
gen larceny5=c1f21_5
gen larceny6=c1f21_6
gen larceny7=c1f21_7
gen larceny8=c1f21_8
gen larceny9=c1f21_9
gen larceny10=c1f21_10
gen larceny11=c1f21_11
gen larceny12=c1f21_12

gen vehicle1=c1f22_1
gen vehicle2=c1f22_2
gen vehicle3=c1f22_3
gen vehicle4=c1f22_4
gen vehicle5=c1f22_5
gen vehicle6=c1f22_6
gen vehicle7=c1f22_7
gen vehicle8=c1f22_8
gen vehicle9=c1f22_9
gen vehicle10=c1f22_10
gen vehicle11=c1f22_11
gen vehicle12=c1f22_12

gen burglary1=c1f17_1
gen burglary2=c1f17_2
gen burglary3=c1f17_3
gen burglary4=c1f17_4
gen burglary5=c1f17_5
gen burglary6=c1f17_6
gen burglary7=c1f17_7
gen burglary8=c1f17_8
gen burglary9=c1f17_9
gen burglary10=c1f17_10
gen burglary11=c1f17_11
gen burglary12=c1f17_12

gen manslaughter1=c1f2_1
gen manslaughter2=c1f2_2
gen manslaughter3=c1f2_3
gen manslaughter4=c1f2_4
gen manslaughter5=c1f2_5
gen manslaughter6=c1f2_6
gen manslaughter7=c1f2_7
gen manslaughter8=c1f2_8
gen manslaughter9=c1f2_9
gen manslaughter10=c1f2_10
gen manslaughter11=c1f2_11
gen manslaughter12=c1f2_12

gen robbery1=c1f6_1
gen robbery2=c1f6_2
gen robbery3=c1f6_3
gen robbery4=c1f6_4
gen robbery5=c1f6_5
gen robbery6=c1f6_6
gen robbery7=c1f6_7
gen robbery8=c1f6_8
gen robbery9=c1f6_9
gen robbery10=c1f6_10
gen robbery11=c1f6_11
gen robbery12=c1f6_12

keep abbr statefip stname year rape* larceny* vehicle* burglary* manslaughter* robbery* agency_name pop*

collapse (sum) rape* larceny* vehicle* burglary* manslaughter* robbery* (max) pop1, by(agency_name year statefip stname)

reshape long rape larceny vehicle burglary manslaughter robbery, i(agency_name statefip year stname) j(month)

* Cleaning Data Time
gen date=ym(year,month)
format date  %tm

* Cleaning Agency
egen id=group(agency_name statefip)
ren agency_name agname
replace agname = "CHARLOTTE" if regexm(agname, "CHARLOTTE")
replace agname = "CHARLESTON" if regexm(agname, "CHARLESTON")
replace agname = "LAS VEGAS" if regexm(agname, "LAS VEGAS")
replace agname = "SAINT LOUIS" if regexm(agname, "SAINT LOUIS") | regexm(agname, "ST. LOUIS")
replace agname = "SAINT PAUL" if regexm(agname, "SAINT PAUL") | regexm(agname, "ST. PAUL")
replace agname = "SAVANNAH" if regexm(agname, "SAVANNAH")

* Merge with Craigslist Data
sort agname stname
merge m:1 agname stname using "`raw'"
keep if _merge==3
drop _merge
drop if date==.

* Collapse adn Clean
drop if year==60 | year==2010

collapse (sum) rape* larceny* vehicle* burglary* manslaughter*  robbery* (max) pop1 ersdate cldate, by(agname year statefip stname month date)

drop if ersdate==.
drop if pop1==0
egen id = group(agname stname)
tsset id date

/* The following five lines address the questionable population values.  We do this by replacing all observations with missing for whom the year to year change was extreme.  We then later below impute the missing values through linear interpolation. */
bysort id: egen popmean=mean(pop1)
replace pop1=. if pop1==0
bysort id: gen diff=pop1[_n] - pop1[_n-1]
bysort id: gen ratio=diff/popmean
bysort id: replace pop1=. if ratio<-0.5
bysort id: replace pop1=. if ratio<0.1 & ratio>-0.1 & pop1[_n-1]==.

* Create a balanced panel
	tsfill, full

* Start over
	cap n drop treat* ers

* Fill in the missing state names
	bysort id: replace agname=agname[_n-1] if agname==""
	bysort id: replace agname=agname[_n+1] if agname==""
	bysort id: replace stname=stname[_n-1] if stname==""
	bysort id: replace stname=stname[_n+1] if stname==""

* Create new year and month variables
	drop year month
	gen year=yofd(dofm(date))
	sort id date
	bysort id year: gen month=_n

* Fill in the missing ersdate (missing because of tsfill)
	bysort id: replace ersdate=ersdate[_n-1] if ersdate==.
	bysort id: replace ersdate=ersdate[_n+1] if ersdate==.

* Impute missing population values 
	bysort id: ipolate pop1 date, gen(pop2) 

* Drop cities whose max population over the panel was less than 100,000
	bysort id: carryforward pop2, gen(pop3)
	bysort id year: egen pop4=max(pop3)
	bysort id: drop if pop4<100000

* Define treatment categories	
	gen	 	treat_ersdate=date-ersdate
	gen 	treat_cldate=date-cldate
	gen 	ers_all=(treat_ersdate>0 & treat_ersdate!=.)
	gen 	ers_10mo=(treat_ersdate>0 & treat_ersdate<=10 & treat_ersdate!=.)
	gen 	ers_10plus=(treat_ersdate>10 & treat_ersdate!=.)
	gen 	cl_all=(treat_cldate>0 & treat_cldate!=.)
	gen 	cl_10mo = (treat_cldate>0 & treat_cldate<=10 & treat_cldate!=.)
	gen 	cl_10plus = (treat_cldate>10 & treat_cldate!=.)
	
* Robustness treatment variables
	gen 	ers_6mo=(treat_ersdate>0 & treat_ersdate<=6 & treat_ersdate!=.)
	gen 	ers_6plus=(treat_ersdate>6 & treat_ersdate!=.)
	gen 	ers_9mo=(treat_ersdate>0 & treat_ersdate<=9 & treat_ersdate!=.)
	gen 	ers_9plus=(treat_ersdate>9 & treat_ersdate!=.)
	gen 	ers_12mo=(treat_ersdate>0 & treat_ersdate<=12 & treat_ersdate!=.)
	gen 	ers_12plus=(treat_ersdate>12 & treat_ersdate!=.)

* Here we drop cities that are not reporting for some time period.
	gen one=1
	bysort agname stname: egen count=total(one)
	drop if count<168
	drop if count>180

	sort id date
	bysort id: gen trend=_n

* Per capita measures
foreach x of varlist rape larceny vehicle burglary manslaughter robbery {
	gen `x'_pc = `x'/pop1 * 100000
}
	
* Create Lags and Leads
gen 	lag1=0
replace lag1=1 if treat_ersdate<=0 & treat_ersdate>-10
gen 	lag2=0
replace lag2=1 if treat_ersdate<=-10 & treat_ersdate>-20
gen 	lag3=0
replace lag3=1 if treat_ersdate<=-20 & treat_ersdate>-30
gen 	lag4=0
replace lag4=1 if treat_ersdate<=-30 & treat_ersdate>-40
gen 	lag5=0
replace lag5=1 if treat_ersdate<=-40 & treat_ersdate>-50
gen 	lag6=0
replace lag6=1 if treat_ersdate<=-50 & treat_ersdate>-85
label variable lag1 "0-9 months pre"
label variable lag2 "10-19 months pre"
label variable lag3 "20-29 months pre"
label variable lag4 "30-39 months pre"
label variable lag5 "40-49 months pre"
label variable lag6 "50-85 months pre"

gen dd=0
replace dd=treat_ersdate if treat_ersdate>0
gen 	dd1=0
replace dd1=1 if dd>0 & dd<10
gen 	dd2=0
replace dd2=1 if dd>=10 & dd<20
gen 	dd3=0
replace dd3=1 if dd>=20 & dd<30
gen 	dd4=0
replace dd4=1 if dd>=30 & dd<40
gen 	dd5=0
replace dd5=1 if dd>=40  & dd<50
gen 	dd6=0
replace dd6=1 if dd>=50 & dd<60
gen 	dd7=0
replace dd7=1 if dd>=60 & dd<70
gen 	dd8=0
replace dd8=1 if dd>=70 & dd<80
gen 	dd9=0
replace dd9=1 if dd>=80 & dd<=85
label variable dd1 "0-9 months post"
label variable dd2 "10-19 months post"
label variable dd3 "20-29 months post"
label variable dd4 "30-39 months post"
label variable dd5 "40-49 months post"
label variable dd6 "50-59 months post"
label variable dd7 "60-69 months post"
label variable dd8 "70-79 months post"
label variable dd9 "80-85 months post"

gen treat = 0
replace treat = 1 if treat_ersdate>=1 

* Manage Missing Values.
replace rape_pc = 0 if rape_pc == .
gen 	rape_pc_zeroes=rape_pc
replace rape_pc_zeroes=.5 if rape_pc==0
gen 	rape_pc_zeroes_pc = rape_pc_zeroes/pop1*100000
gen 	lnrape_pc_zeroes_pc = ln(rape_pc_zeroes_pc)

replace larceny_pc = 0 if larceny_pc == .
gen 	larceny_pc_zeroes=larceny_pc
replace larceny_pc_zeroes=.5 if larceny_pc==0
gen 	larceny_pc_zeroes_pc = larceny_pc_zeroes/pop1*100000
gen 	lnlarceny_pc_zeroes_pc = ln(larceny_pc_zeroes_pc)

replace vehicle_pc = 0 if vehicle_pc == .
gen 	vehicle_pc_zeroes=vehicle_pc
replace vehicle_pc_zeroes=.5 if vehicle_pc==0
gen 	vehicle_pc_zeroes_pc = vehicle_pc_zeroes/pop1*100000
gen 	lnvehicle_pc_zeroes_pc = ln(vehicle_pc_zeroes_pc)

replace burglary_pc = 0 if burglary_pc == .
gen 	burglary_pc_zeroes=burglary_pc
replace burglary_pc_zeroes=.5 if burglary_pc==0
gen 	burglary_pc_zeroes_pc = burglary_pc_zeroes/pop1*100000
gen 	lnburglary_pc_zeroes_pc = ln(burglary_pc_zeroes_pc)

replace manslaughter_pc = 0 if manslaughter_pc == .
gen 	manslaughter_pc_zeroes=manslaughter_pc
replace manslaughter_pc_zeroes=.5 if manslaughter_pc==0
gen 	manslaughter_pc_zeroes_pc = manslaughter_pc_zeroes/pop1*100000
gen 	lnmanslaughter_pc_zeroes_pc = ln(manslaughter_pc_zeroes_pc)

replace robbery_pc = 0 if robbery_pc == .
gen 	robbery_pc_zeroes=robbery_pc
replace robbery_pc_zeroes=.5 if robbery_pc==0
gen 	robbery_pc_zeroes_pc = robbery_pc_zeroes/pop1*100000
gen 	lnrobbery_pc_zeroes_pc = ln(robbery_pc_zeroes_pc)

save ../data/ers_ucr_crimes_combined.dta,replace
}
}
*****
{/* Create Clean Craiglist and Vital Statistics Data Set -- ers_vs_clean.dta */
*** Dataset used in the following:
*** Table 5

** Starting from a Raw Merge with the ERS DATA and the Vital Statistics data, taken from Center for Disease Control (https://www.cdc.gov/nchs/nvss/index.htm).
use ../data/ers_vs_raw_merge.dta, replace
compress

* Recreate the ersdate variable.
split ersdate, p("/")
ren ersdate1 ersmo
ren ersdate2 ersday
ren ersdate3 ersyear
destring ersmo, force replace
destring ersyear, force replace

drop ersdate
gen ersdate=ym(ersyear,ersmo)
format ersdate %tm

gen date=ym(year,month)
format date %tm

/* Here we drop counties that are seem to not be reporting for some time period. This is not identical to our UCR or SHR sample, but it does balance the panel. */
gen one=1
capture drop n

ta st_fips
* With this selection, we drop to 89 counties, across 33 states.

* Create Clean State and County variables.
ren state_fipsy state
ren county county_name
gen county=string(county_fips,"%03.0f")
gen county_group = county + state
egen id = group(county_group)

bysort id: egen n=sum(one)
drop if n>180

* This resulting exercise yields only 88 counties.

tsset id date
sort id date

* Drop cities whose max population over the panel was less than 100,000
	replace population = population * 100
	bysort id year: egen pop4=mean(population)
	drop if pop4<100000 

gen f_all_pc = female_homicide/population*100000

tsset id date
drop if date==.

* Create a balanced panel
	tsfill, full

* Here we drop cities that seem to not be reporting for some time period.
	gen two=1
	bysort id: egen count=total(two)
	drop if count<168
	
* Fill in the missing state names
	bysort id: replace id=id[_n-1] if id==.
	bysort id: replace id=id[_n+1] if id==.
	bysort id: replace st_fips=st_fips[_n-1] if st_fips==.
	bysort id: replace st_fips=st_fips[_n+1] if st_fips==.

* Create new year and month variables
	drop year month
	gen year=yofd(dofm(date))
	sort id date
	bysort id year: gen month=_n

* Fill in the missing ersdate (missing because of tsfill)
	bysort id: replace ersdate=ersdate[_n-1] if ersdate==.
	bysort id: replace ersdate=ersdate[_n+1] if ersdate==.

* Define treatment categories	
	gen	treat_ersdate=date-ersdate
	gen 	ers_10mo=(treat_ersdate>0 & treat_ersdate<=10 & treat_ersdate!=.)
	gen 	ers_10plus=(treat_ersdate>10 & treat_ersdate!=.)
	
* Robustness treatment variables
	gen 	ers_6mo=(treat_ersdate>0 & treat_ersdate<=6 & treat_ersdate!=.)
	gen 	ers_6plus=(treat_ersdate>6 & treat_ersdate!=.)
	gen 	ers_9mo=(treat_ersdate>0 & treat_ersdate<=9 & treat_ersdate!=.)
	gen 	ers_9plus=(treat_ersdate>9 & treat_ersdate!=.)
	gen 	ers_12mo=(treat_ersdate>0 & treat_ersdate<=12 & treat_ersdate!=.)
	gen 	ers_12plus=(treat_ersdate>12 & treat_ersdate!=.)
	
	gen treat = 0
	replace treat = 1 if treat_ersdate>=1 
	
* Create Leads and Lags 
	gen 	lag1=0
	replace lag1=1 if treat_ersdate<=0 & treat_ersdate>-10
	gen 	lag2=0
	replace lag2=1 if treat_ersdate<=-10 & treat_ersdate>-20
	gen 	lag3=0
	replace lag3=1 if treat_ersdate<=-20 & treat_ersdate>-30
	gen 	lag4=0
	replace lag4=1 if treat_ersdate<=-30 & treat_ersdate>-40
	gen 	lag5=0
	replace lag5=1 if treat_ersdate<=-40 & treat_ersdate>-50
	gen 	lag6=0
	replace lag6=1 if treat_ersdate<=-50 
	label variable lag1 "0-9 months pre"
	label variable lag2 "10-19 months pre"
	label variable lag3 "20-29 months pre"
	label variable lag4 "30-39 months pre"
	label variable lag5 "40-49 months pre"
	label variable lag6 "50+ months pre"

	gen dd=0
	replace dd=treat_ersdate if treat_ersdate>0
	gen 	dd1=0
	replace dd1=1 if dd>0 & dd<10
	gen 	dd2=0
	replace dd2=1 if dd>=10 & dd<20
	gen 	dd3=0
	replace dd3=1 if dd>=20 & dd<30
	gen 	dd4=0
	replace dd4=1 if dd>=30 & dd<40
	gen 	dd5=0
	replace dd5=1 if dd>=40  & dd<50
	gen 	dd6=0
	replace dd6=1 if dd>=50 & dd<60
	gen 	dd7=0
	replace dd7=1 if dd>=60 & dd<70
	gen 	dd8=0
	replace dd8=1 if dd>=70 

	label variable dd1 "0-9 months post"
	label variable dd2 "10-19 months post"
	label variable dd3 "20-29 months post"
	label variable dd4 "30-39 months post"
	label variable dd5 "40-49 months post"
	label variable dd6 "50-59 months post"
	label variable dd7 "60-69 months post"
	label variable dd8 "70+ months post"

save ../data/vs_clean.dta, replace
}
*****
{/* Create Clean TER Data Set -- ter_clean.dta */
* Dataset used in the following:
* Tables 2 & 8.
use ../data/ter_raw.dta, replace

* Merge with ERS Data
merge m:1 city using ../data/ers_by_city_raw.dta
keep if _merge==3
drop _merge

* Reformat Date Time Variables
ren 	ersdate temp1
gen 	ersdate=mofd(temp1)
format 	ersdate %tm
gen 	date = date(review_date, "YMD")
drop 	ddate year
gen 	ddate = date(review_date, "YMD")
gen 	month = month(ddate)
gen 	year = year(ddate)
ren 	date temp
gen 	date=ym(year,month)
format 	date %tm
drop 	temp

drop if year>2009

* Create Treatment variables
gen 	treat_ersdate=date-ersdate
gen 	ers_all=(treat_ersdate>0 & treat_ersdate!=.)
gen 	ers_10mo=(treat_ersdate>0 & treat_ersdate<=10 & treat_ersdate!=.)
gen 	ers_20mo=(treat_ersdate>10 & treat_ersdate<=20 & treat_ersdate!=.)
gen 	ers_30mo=(treat_ersdate>20 & treat_ersdate<=30 & treat_ersdate!=.)
gen 	ers_40mo=(treat_ersdate>30 & treat_ersdate<=40 & treat_ersdate!=.)
gen 	ers_50mo=(treat_ersdate>40 & treat_ersdate<=50 & treat_ersdate!=.)
gen 	ers_50plus=(treat_ersdate>50 & treat_ersdate!=.)
gen 	ers_10plus=(treat_ersdate>10 & treat_ersdate!=.)


* Measures of screening
foreach x in screen refer prefer verification identification p411 quad {
	* appointment disclaimer 
	gen `x' = regexm(general_details, "`x'")
	gen `x'1 = regexm(juicy_details, "`x'")
}
gen overall_screen =0
foreach x in screen refer prefer identification p411 quad {
	* appointment disclaimer
	replace overall_screen = 1 if (`x'==1|`x'1==1)
}
label variable overall_screen "Screening or references"

* Measures of managers
foreach x in pimp manager {
	* appointment disclaimer 
gen 	`x' = regexm(general_details, "`x'")
gen 	`x'1 = regexm(juicy_details, "`x'")
}

gen 	officemanager = regexm(general_details, "office manager")
gen 	officemanager_1 = regexm(juicy_details, "office manager")

gen overall_pimp = 0
foreach x in pimp manager {
	* appointment disclaimer
replace overall_pimp = 1 if (`x'==1|`x'1==1)
}
replace overall_pimp = 1 if (officemanager==1 | officemanager_1 == 1)
label variable overall_pimp "Pimp mention"

* Clean Outcome Variables
replace overall_screen = 0 if prefer==1 | prefer1==1
replace refer = 0 if prefer==1 | prefer1==1
gen 	dc1 = regexm(general_details, "date check")
gen 	dc2 = regexm(juicy_details, "date check")
gen 	date_check = 1 if dc1==1|dc2==1
replace overall_screen = 1 if dc1==1 | dc2==1

encode city, gen(city_id)

gen 	independent=0
replace independent = 1 if agency=="independent"
gen 	agency1 = 0
replace agency1 = 1 if agency=="agency"
rename 	agency agency2
rename 	agency1 agency
gen 	outcall = 0
replace outcall = regexm(incall_outcall, "outcall")
gen 	incall = 0
replace incall = regexm(incall_outcall, "incall")

label variable independent "Independent sex worker"
label variable agency "Employed by an agency"
label variable outcall "Makes outcalls to clients"
label variable incall "Provides incalls to clients"

gen 	repeat1=regexm(general_details, "repeat")
gen 	repeat2 = regexm(juicy_details, "repeat")
gen 	reg1=regexm(general_details, "regular")
gen 	reg2 = regexm(juicy_details, "regular")
gen 	repeat = 0
replace repeat = 1 if repeat1==1|repeat2==1|reg1==1|reg2==1

label variable repeat "Repeat customer mention"

gen 	street1=regexm(general_details, "street")
gen 	street2=regexm(juicy_details, "street")
gen 	street=0
replace street=1 if street1==1 | street2==1
label variable street "Street mention"

gen 	pimp3=regexm(general_details, "pimp")
gen 	pimp4=regexm(juicy_details, "pimp")
gen 	pimp5=0
replace pimp5=1 if pimp3==1 | pimp4==1
label variable pimp5 "Pimp mention"

* Extracting ethnicity 
gen 	white=regexm(ethnicity, "white")
gen 	black=regexm(ethnicity, "frican")

label variable white "White ethnicity"
label variable black "Black ethnicity"

* Examining looks, performance, and hourly price
destring performance_rating, replace
destring looks_rating, replace
destring average_price_per_hour, force replace

label variable performance_rating "Performance rating"
label variable looks_rating "Looks rating"
label variable average_price_per_hour "Average price per hour"

* What are the effects over time?
gen diff = date-ersdate
bysort provider_id: gen n=_n

bysort provider_id: egen max_review = max(n)

gen pre_ers = 0
replace pre_ers = 1 if diff<0 & n==max_review
bysort provider_id: egen pre_ers_m = max(pre_ers) 

gen post_ers = 0
replace post_ers = 1 if diff>0 & n==1
bysort provider_id: egen post_ers_m = max(post_ers) 

gen both_ers = 0
gen before = 0
replace before = 1 if diff<0& n==1
gen after = 0
replace after =1 if diff>0 & n==max_review
bysort provider_id: egen after_m = max(after)
bysort provider_id: egen before_m = max(before) 
replace both_ers=1 if before_m==1&after_m==1

gen check = pre_ers_m+post_ers_m+both
replace pre_ers_m = 1 if check==0&diff<0
replace post_ers_m = 1 if check==0&diff>0
replace pre_ers_m = 1 if check==0&diff==0

rename both_ers both
gen post = 0
replace post = 1 if diff>0
gen both_ers = 0
replace both_ers = both*post

* Start creating our measures of compositional vs incumbent effects.
gen 	one =1
sort 	provider_id date
bysort 	provider_id: gen tot_review = sum(one) 					// creates a series of integers corresponding to each additional review
bysort 	provider_id: egen tot_screen = sum(overall_screen)		// create a variable equalling the total number of screens that occurred
gen 	first_screen = 0										
replace first_screen = 1 if overall_screen==1&tot_review==1 	// create an indicator for the first review and a screen

gen p_ers_10mo=0
bysort provider_id: replace p_ers_10mo=1 if (diff>0 & diff<=10 & diff!=. & n==1)
bysort provider_id: egen p_ers_m=max(p_ers_10mo)
replace p_ers_10mo=ers_10plus*p_ers_m

gen p_ers_10plus=0
bysort provider_id: replace p_ers_10plus=1 if (diff>10 & diff!=. & n==1)
bysort provider_id: egen p_ers_10plus_m=max(p_ers_10plus)
replace p_ers_10plus=ers_10plus*p_ers_10plus_m

gen post_ers_10mo = 0
bysort provider_id: replace post_ers_10mo = 1 if (diff>0 & diff < 10 & n==1)
bysort provider_id: egen post_ers_10mo_m = max(post_ers_10mo)
replace post_ers_10mo = ers_10mo*post_ers_10mo_m

gen post_ers_20mo = 0
bysort provider_id: replace post_ers_20mo = 1 if (diff>=10 & diff < 20 & n==1)
bysort provider_id: egen post_ers_20mo_m = max(post_ers_20mo)
replace post_ers_20mo = ers_20mo*post_ers_20mo_m

gen post_ers_30mo = 0
bysort provider_id: replace post_ers_30mo = 1 if (diff>=20 & diff < 30 & n==1)
bysort provider_id: egen post_ers_30mo_m = max(post_ers_30mo)
replace post_ers_30mo = ers_30mo*post_ers_30mo_m

gen post_ers_40mo = 0
bysort provider_id: replace post_ers_40mo = 1 if (diff>=30 & diff < 40 & n==1)
bysort provider_id: egen post_ers_40mo_m = max(post_ers_40mo)
replace post_ers_40mo = ers_40mo*post_ers_40mo_m

gen post_ers_50mo = 0
bysort provider_id: replace post_ers_50mo = 1 if (diff>=40 & diff < 50 & n==1)
bysort provider_id: egen post_ers_50mo_m = max(post_ers_50mo)
replace post_ers_50mo = ers_50mo*post_ers_50mo_m

gen post_ers_50post = 0
bysort provider_id: replace post_ers_50post = 1 if (diff>=50 & n==1)
bysort provider_id: egen post_ers_50post_m = max(post_ers_50post)
replace post_ers_50post = post_ers_50post*post_ers_50post_m

gen pre_ers_10mo = 0
bysort provider_id: replace pre_ers_10mo = 1 if (diff<0 & diff > -10 & n==1)
bysort provider_id: egen pre_ers_10mo_m = max(pre_ers_10mo)
replace pre_ers_10mo = ers_10mo*pre_ers_10mo_m

gen pre_ers_20mo = 0
bysort provider_id: replace pre_ers_20mo = 1 if (diff<=-10 & diff > -20 & n==1)
bysort provider_id: egen pre_ers_20mo_m = max(pre_ers_20mo)
replace pre_ers_20mo = ers_20mo*pre_ers_20mo_m

gen pre_ers_30mo = 0
bysort provider_id: replace pre_ers_30mo = 1 if (diff<=-20 & diff > -30 & n==1)
bysort provider_id: egen pre_ers_30mo_m = max(pre_ers_30mo)
replace pre_ers_30mo = ers_30mo*pre_ers_30mo_m

gen pre_ers_40mo = 0
bysort provider_id: replace pre_ers_40mo = 1 if (diff<=-30 & diff > -40 & n==1)
bysort provider_id: egen pre_ers_40mo_m = max(pre_ers_40mo)
replace pre_ers_40mo = ers_40mo*pre_ers_40mo_m

gen pre_ers_50mo = 0
bysort provider_id: replace pre_ers_50mo = 1 if (diff<=-40 & diff > -50 & n==1)
bysort provider_id: egen pre_ers_50mo_m = max(pre_ers_50mo)
replace pre_ers_50mo = ers_50mo*pre_ers_50mo_m

gen pre_ers_50pre = 0
bysort provider_id: replace pre_ers_50pre = 1 if (diff<=-50 & n==1)
bysort provider_id: egen pre_ers_50pre_m = max(pre_ers_50pre)
replace pre_ers_50pre = pre_ers_50pre*pre_ers_50pre_m

gen delivered=(services_delivered_as_promised=="yes")
gen photo=regexm(real_photo, "yes")

pwd 

* Create leads and lags.
gen dd1 = 0 
replace dd1 = 1 if diff>=1 & diff<=10

gen dd2 = 0
replace dd2 = 1 if diff>10 & diff<=20

gen dd3 = 0
replace dd3 = 1 if diff>20 & diff<=30

gen dd4 = 0
replace dd4 = 1 if diff>30 & diff<=40

gen dd5 = 0
replace dd5 = 1 if diff>40 & diff<=50

gen dd6 = 0 
replace dd6 = 1 if diff>50 & diff<=60

gen dd7 = 0
replace dd7 = 1 if diff>60 & diff~=.

gen lead1 = 0
replace lead1 = 1 if diff<=0 & diff>=-10

gen lead2 = 0
replace lead2 = 1 if diff<-10 & diff>=-20

gen lead3 = 0
replace lead3 = 1 if diff<-20 & diff>=-30

gen lead4 = 0
replace lead4 = 1 if diff<-30 & diff>=-40

gen lead5 = 0
replace lead5 = 1 if diff<-40 & diff>=-50

gen lead6 = 0
replace lead6 = 1 if diff<-50 & diff>=-60

gen lead7 = 0
replace lead7 = 1 if diff<-60 & diff!=.


save ../data/ter_clean.dta, replace 


}
	
	