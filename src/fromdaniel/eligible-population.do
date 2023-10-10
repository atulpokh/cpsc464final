// Daniel Waldinger
// 2019-03-25

// Code to extract eligible households from the ACS

// Similar to JMP code, but with a few modifications:
//		- Takes arbitrary geographic units
//		- Reads in matching area median incomes for appropriate years
//		- Marks *which* housing a household is eligible for

clear
pause on
set more off

local acsdata = "../Data/ACS"
local othdata = "../Data/Other"
local matdata = "../Data/Matlab"

local pha = "CHA"

// Min and max year of sample
local min_year = 2010
local max_year = 2014

// Geographic code for living/working in the jurisdiction
local works_criterion = "max(pwpuma00==3200)"
local lives_criterion = "max(city==930)"

// Name of sample

use `acsdata'/ACS_2006_2017, clear

	// Would have priority: veteran, lives in juris, or works in juris
	bys year serial: egen works_in_juris = `works_criterion'		// someone works in juris
	bys year serial: egen lives_in_juris = `lives_criterion'		// lives in juris
	bys year serial: egen veteran = max(vetstat == 2)					// someone is a veteran
	
	keep if (lives_in_juris | works_in_juris) & year >= `min_year' & year <= `max_year'
		
	// separate potential elderly applicants from rest of family in 3+ generation households

	// Who is eligible?
	gen person_eligible = lives_in_juris==1 | works_in_juris==1
	gen person_elderly = age >= 58
	gen person_disabled = diffrem==2 | diffphys==2 | diffmob==2 | diffcare==2 | diffsens==2 | diffeye==2 | diffhear==2
	gen person_student = age <= 30 & age >= 18 & empstat==3 & ~person_disabled
	bys year serial: egen elderly_eligible = max(person_eligible * (person_elderly | person_disabled))
	
	bys year serial (relate): gen mark = _n==1
	gen hhid = sum(mark)
		
	// separate from rest of family if relevant
	gen separate_elderly = person_elderly * elderly_eligible  // marks individuals who could comprise a separate elderly family
	bys year serial separate_elderly: gen sep_mark = _n==1
	gen id = sum(sep_mark)
		
	// assets, income
	replace inctot = 0 if inctot == 9999999
	bys id: egen income = total(inctot)
	replace income = 0 if income < 0 	// bottom-coding, since CHA also does
	
	// # adults, children, and elderly
	bys id: gen n_person = _N
	bys id: egen n_children = total(age < 18)
	bys id: egen min_age = min(age)
	bys id: egen max_age = max(age)
	bys id: egen head_age = max((relate==1) * age)
	bys id: egen n_elderly = total(person_elderly)
	bys id: egen n_disabled = total(person_disabled)
	bys id: egen n_student = total(person_student)
	gen n_adult = n_person - n_children
	
	// determine head of household	
	gen is_head = relate==1
	gsort id -is_head -age    // first heads, then oldest member who is not head
	by id: gen pseudo_head = _n==1
	by id: egen has_head = max(pseudo_head==1)
	assert has_head==1
	
	// child and adult genders
	by id: egen n_adult_male = total(age>=18 & sex==1)
	by id: egen n_child_male = total(age<18 & sex==1)
	gen n_adult_female = n_adult - n_adult_male
	gen n_child_female = n_children - n_child_male
	
	// race
	gen white_head = pseudo_head==1 & race==1
	gen black_head = pseudo_head==1 & racblk==2
	gen hispanic_head = pseudo_head==1 & hispan!=0
	bys id: egen head_male = max(pseudo_head==1 & sex==1)
	bys id: egen head_is_white = max(white_head)
	bys id: egen head_is_black = max(black_head)
	bys id: egen head_is_hispanic = max(hispanic_head)

	rename head_is_black black
	rename head_is_hispanic hispanic
	
	// more on age: HUD PIC definition of age is older of head and spouse
	by id: egen elderly = max((age>=62)*(relate==1|relate==2|pseudo_head==1))
	by id: egen young = max((age<=50)*(relate==1|relate==2|pseudo_head==1))
	by id: egen disabled = max(person_disabled*(relate==1|relate==2|pseudo_head==1))
	
	// more on disability: 
	
	// merge in AMI
	gen n_members = n_person
	replace n_members = 8 if n_members > 8 // the AMI tables only go up to 8
	merge m:1 year n_members using `othdata'/ami, keep(master match)
	gen pct_ami = 100 * income / ami
	
	keep if pct_ami <= 80  	// only households with incomes below 80% are eligible
		
	// divide weights by 5 (using one-year weights but combined for five-year sample)
	gen weight = hhwt/5
	gen single_adult = n_members - n_children == 1
	
	keep id year weight n_members n_child* n_adult* n_elderly n_disabled lives_in_juris works_in_juris /// 
		n_student single_adult pct_ami income elderly_eligible head_is_* head_age head_male ///
		min_age max_age rent rentgrs ownershp ownershpd elderly young black hispanic disabled

	duplicates drop
		
	gen children = n_children > 0 & n_children ~= .
	gen non_students = n_members - n_student
		
	// Determine which program the household could apply for, and # bedrooms
	gen program = "Elderly LIPH" if n_elderly > 0 | n_disabled > 0
	replace program = "Family LIPH" if program == "" ///
						& ((n_children > 0 & n_member > 1) | (n_children==0 & non_students>0))
	gen bedrooms = min(n_adult_male,n_adult_female) + abs(n_adult_male-n_adult_female) ///
				   + ceil(n_child_male/2) + ceil(n_child_female/2)
	replace bedrooms = 0 if n_members==1 & program == "Elderly LIPH" // studios for one person elderly/disabled households
	replace head_age = max_age if head_age == 0
	// rename n_members members
		
	keep if program ~= ""
	tab bedrooms program, m
	
	encode program, generate(type)
	drop program
	
	pause
	
save `matdata'/eligible_population_`pha'.dta, replace
export delimited using `matdata'/eligible_population_`pha'.txt, delimiter("|") nolabel replace
