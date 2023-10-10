// Daniel Waldinger
// 2019-03-25


clear
pause on
set more off

local acsdata = "../Data/ACS"
local othdata = "../Data/Other"
local matdata = "../Data/Matlab"
local results = "../results/Descriptive"

local pha = "CHA"
local year = 2012

local picdata = "../Data/HUD-PIC/`year'"
local filter = `" states=="MA Massachusetts" & program_label=="Public Housing" & std_city=="Cambridge" "'


clear
/*
// HUD PIC Data

import delimited using `picdata'/PROJECT_2012.csv, delimiter(",") clear
keep if `filter'

	// code variables to be used in structural model
	gen elderly = pct_age62plus/100
	gen disabled = (pct_disabled_ge62*pct_age62plus + pct_disabled_lt62*(100-pct_age62plus))/10000
	gen black = pct_black/100
	gen hispanic = pct_hispanic/100
	gen young = (100 - pct_age62plus - pct_age51_61)/100
	gen children = (pct_1adult + pct_2adults) / 100
	
	replace tpoverty = tpoverty/100
	replace tminority = tminority/100
	
	rename total_units size
	rename hh_income income
//	rename people_per_unit members
	
	gen program_type = "Family LIPH"
	replace program_type = "Elderly LIPH" if inlist(name,"Daniel F Burns Apts","Lyndon B Johnson Apts","Millers River Apts","Leonard J. Russell Apartments","Frank J. Manning Apartments","J F Kennedy Apts","Norfolk Street")
	
save `picdata'/PIC-`pha', replace
pause

//if "`pha'"=="CHA"{

import delimited using `othdata'/CHA-projects.csv, delimiter(",") clear

	rename units units_cha
	rename listname name
	rename program type
	
	replace name = "Daniel F Burns Apts" if name == "Burns Apts"
	replace name = "Lyndon B Johnson Apts" if name == "L B Johnson"
	replace name = "Millers River Apts" if name == "Miller's River"
	replace name = "Leonard J. Russell Apartments" if name == "Russell Apts"
	replace name = "Frank J. Manning Apartments" if name == "Manning"
	replace name = "J F Kennedy Apts" if name == "J F Kennedy"
	replace name = "Roosevelt Towers" if name == "Roosevelt Mid-Rise" | name == "Roosevelt Low-Rise"
	replace name = "Woodrow Wilson Court" if name == "Woodrow Wilson"
	
	// convert waiting time to months to be compatible with HUD data
	rename avgwaityears months_waited
	replace months_waited = months_waited*12
	
	// Combine Roosevelt Mid-Rise and Low-Rise into "Roosevelt Towers"
	sort name
	collapse (first) type (sum) units_cha months_waited housed, by(name)
	save `othdata'/waiting-times-CHA, replace
	
	// Merge with HUD PIC data
	merge 1:1 name using `picdata'/PIC-`pha', keep(match using) nogen
	
	// Fill in mean waiting time for Norfolk Street
	egen tot_time_elderly = total(months_waited*(type=="Elderly LIPH"))
	egen tot_elderly_proj = total(type=="Elderly LIPH")
	gen mean_elderly_time = tot_time_elderly/tot_elderly_proj
	replace type = "Elderly LIPH" if name=="Norfolk Street"
	replace months_waited = mean_elderly_time if name=="Norfolk Street"
	drop tot_time_elderly tot_elderly_proj mean_elderly_time
	gen family = type=="Family LIPH"
	
	// Drop Cambridgeport Commons and Family Condominiums, which are too small to have tenants reported
	drop if months_waited == .
	
save `matdata'projects-ready-`pha', replace
export delimited using `matdata'/projects-ready-`pha'.txt, delimiter("|") nolabel replace
*/
//}

// Table 2: how are tenants sorted across developments

// Development characteristics: tract poverty rate, tract minority rate, development size
	// vacancy rate, waiting time
// Tenant characteristics: br size, hh head age, any children, black, hispanic, elderly, disabled, income, ami, rent

use `matdata'projects-ready-`pha', clear

sort type name
gen pop = round(size * pct_occupied/100)

keep type name pop pct_age25_50 pct_age51_61 pct_age62plus ///
	elderly disabled black hispanic children ///
	pct_bed1 pct_bed2 pct_bed3 income pct_median rent_per_month ///
	tpoverty tminority months_waited months_from_movein
	
order type name rent_per_month income pct_median ///
	children pct_age25_50 pct_age51_61 pct_age62plus ///
	elderly disabled black hispanic ///
	pct_bed1 pct_bed2 pct_bed3 ///
	pop tpoverty tminority months_waited months_from_movein
	
save `results'/pic_by_development, replace

pause

xpose, clear varname
order _varname
export excel using `results'/development_characteristics.xls, sheet("raw") sheetreplace
