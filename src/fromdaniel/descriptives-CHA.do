// Descriptive Stats
// Summarize descriptive stats for eligible population and PH tenants
// 2019-04-05


// Setup

clear all
prog drop _all
capture log close
set more off

local datadir = "../data"
local outdir = "../results"

local pha = "CHA"


// Read in Data from ACS

use `datadir'/Matlab/eligible_population_`pha'.dta, clear


// Generate Dummies for Breakdowns of Vars

bys id: gen avg_weight = sum(weight)/5

gen has_children = n_children>0

gen head_age_lt24 = head_age<=24
gen head_age_25_50 = head_age>24 & head_age<=50
gen head_age_51_61 = head_age>50 & head_age<=61
gen head_age_gt62 = head_age>=62

gen member_1 = n_member==1
gen member_2 = n_member==2
gen member_34 = n_member>=3 & n_member<=4
gen member_5p = n_member>=5

gen owned = ownershp==1
gen rented = ownershp==2

gen owned_nomort = ownershpd==12
gen owned_mort = ownershpd==13
gen rented_nocash = ownershpd==21
gen rented_cash = ownershpd==22

gen bedrooms_0_1 = bedrooms<=1
gen bedrooms_2 = bedrooms==2
gen bedrooms_3p = bedrooms>=3

replace rentgrs = . if owned==1


// Create Summary Statistics

preserve

collapse (mean) mean_rent=rentgrs lives_in_juris works_in_juris ///
n_children has_children min_age max_age elderly disabled black hispanic ///
head_male head_age head_age_lt24 head_age_25_50 head_age_51_61 head_age_gt62 ///
owned rented owned_nomort owned_mort rented_nocash rented_cash ///
n_members member_1 member_2 member_34 member_5 ///
bedrooms bedrooms_0_1 bedrooms_2 bedrooms_3p ///
(p50) median_inc=income median_inc_pct_ami=pct_ami ///
(sum) sum_weight = avg_weight [pw = avg_weight] 

save `outdir'/Descriptive/acs_descriptive_`pha'.dta, replace

xpose, clear varname
order _varname v1
export excel using `outdir'/Descriptive/descriptive_table_auto.xls, sheet("ACS All") sheetreplace

restore

collapse (mean) mean_rent=rentgrs lives_in_juris works_in_juris ///
n_children has_children min_age max_age elderly disabled black hispanic ///
head_male head_age head_age_lt24 head_age_25_50 head_age_51_61 head_age_gt62 ///
owned rented owned_nomort owned_mort rented_nocash rented_cash ///
n_members member_1 member_2 member_34 member_5 ///
bedrooms bedrooms_0_1 bedrooms_2 bedrooms_3p ///
(p50) median_inc=income median_inc_pct_ami=pct_ami ///
(sum) sum_weight = avg_weight [pw = avg_weight], by(type)

drop type
gen type = "Elderly" if _n==1
replace type = "Family" if _n==2
save `outdir'/Descriptive/acs_descriptive_`pha'_bytype.dta, replace

xpose, clear varname
order _varname v1
export excel using `outdir'/Descriptive/descriptive_table_auto.xls, sheet("ACS by Type") sheetreplace


// Read in Data from PIC

use `datadir'/HUD-PIC/2012/PIC-`pha'.dta, clear

//Filter Out Properties that have Missing Data

drop if people_per_unit==-4

gen head_male = (100-pct_female_head)/100
gen has_children = (pct_1adult + pct_2adults)/100
replace head_male = head_male/100
replace pct_bed1 = pct_bed1/100
replace pct_bed2 = pct_bed2/100
replace pct_bed3 = pct_bed3/100
replace pct_lt24_head = pct_lt24_head/100
replace pct_age25_50 = pct_age25_50/100
replace pct_age51_61 = pct_age51_61/100
replace pct_age62plus = pct_age62plus/100

//Create Sumamry Statistics

preserve

collapse (mean) rent_per_month income pct_median people_per_unit ///
pct_lt24_head pct_age25_50 pct_age51_61 pct_age62plus has_children ///
elderly disabled black hispanic head_male pct_bed1 pct_bed2 pct_bed3 ///
pct_occupied months_from_movein [pw = number_reported]

save `outdir'/Descriptive/pic_descriptive_`pha'.dta, replace

xpose, clear varname
order _varname v1
export excel using `outdir'/Descriptive/descriptive_table_auto.xls, sheet("PIC All") sheetreplace

restore, preserve

collapse (mean) rent_per_month income pct_median people_per_unit ///
pct_lt24_head pct_age25_50 pct_age51_61 pct_age62plus has_children ///
elderly disabled black hispanic head_male pct_bed1 pct_bed2 pct_bed3 ///
pct_occupied months_from_movein [pw = number_reported], by(program_type)

drop program_type
gen type = "Elderly" if _n==1
replace type = "Family" if _n==2
save `outdir'/Descriptive/pic_descriptive_`pha'_bytype.dta, replace

xpose, clear varname
order _varname v1
export excel using `outdir'/Descriptive/descriptive_table_auto.xls, sheet("PIC by Type") sheetreplace

restore

collapse (sum) number_reported, by(program_type)

save `outdir'/Descriptive/pic_counts_`pha'_bytype.dta, replace
