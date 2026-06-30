program define datalibweb_v4, rclass	
	version 14, missing
    local verstata : di "version " string(_caller()) ", missing:" 
	syntax [anything] [if] [in] [,                                    ///
		COUNtry(string) Years(string) CIRca(string)                   ///
		PERiod(string) Type(string)  MODule(string)                   ///
		FILEName(string) SURveyid(string) ext(string)                 ///
		DISPLAY REQuest(string)                                       ///
		CLEAR REPLACE NOCPI NOMETA APPEND                             ///
		ppp(numlist) INCppp(string) PLppp(numlist) PLlcu(numlist) 	  ///
		VERMast(string) VERAlt(string)                                ///
		PROject(string) VINTage(string) NATure(string)                ///
		IGNOREerror CONFidential                                      ///
		Working base latesty info                                     ///
		region(string) CPIVINtage(string)                             ///
		merge(string) update(string)                                  ///
		REPOsitory(string) reporoot(string)	repofile(string) 		  /// 
		NET	NOUPDATE FILEServer GUI									  ///
		getfile local localpath(string) cpilocal(string) sh(string) ALLmodules         ///
		]

	local cmdline: copy local 0
	set linesize 186
	_display_logo		// display datlaibweb logo	

	global dlw_update = 0
	local user = c(username)
	global usertmp "/userdata/`user'/tmp/"
	
	// Global datalibweb error code
	global errcode 0
	
	// reset global
	local resetlist hhid pid idmod defmod hhmlist indmlist period root rootname subfolders data doc prog token updateday type base basedeffile cpifile cpic cpiy cpif cpi cpiw rootcpi cpivarw distxt email surveyid
	foreach gl of local resetlist {
		global `gl'
	}
		
	tempfile tempcpi
	global nocpi
	global nometa
	if "`nocpi'"=="nocpi"  global nocpi nocpi
	
	//reset global return
	foreach glb in type_ module_ verm_ vera_ surveyid_ filename_ filename_ idno_ {
		global `glb'
	}
		
	//Country fix to make sure past codes run
	if "`=upper("`country'")'"=="KSV" local country XKX
	
	//check if .do is available	
	local persdir : sysdir PERSONAL
    if "$S_OS"=="Windows" local persdir : subinstr local persdir "/" "\", all
	*if "$S_OS"=="Unix" local persdir : subinstr local persdir "/" "\", all
	
	cap confirm file "`persdir'datalibweb/`=upper("`type'")'.do"
	if _rc==0 { //available and load
		qui do "`persdir'datalibweb/`=upper("`type'")'.do"
	}
	else {
		//display error
		di in red "The type -`type'- you entered is not available. Please check the help file for the list of avaiable types." _new
		global errcode 198
		error 198
	}
	
	// load default or allmodules
	if "`module'"~="" local module `=upper("`module'")'
	global rootcpi1 = subinstr("${rootcpi}","-","",.)
	global rootname1 = subinstr("${rootname}","-","",.)
	
	if `"$cpiw"'~="" {
		//CPIVintage() - new Feb 17 2018
		if ($token~=5 & "$nocpi"=="") { //RAW
			local dl 0
			local code `"cap mata: mata describe ${rootcpi1}_cpidata"' //check data in memory			
			`code'
			global nomatacpi = _rc
			if $nomatacpi==0 {	
				if (date("$S_DATE", "DMY")-date("${${rootcpi1}_cpivindate}", "DMY")) >0 local dl 1
			}
			else local dl 1
				
			qui if `dl'==1 {
				tempfile cattmp2
				dlw_api, option(0) outfile(`cattmp2') query("$cpiw")
				if `dlibrc'==0 {
					if "`dlibFileName'"=="ECAFileinfo.csv" {	
						import delimit using "`cattmp2'" , clear
						split filesharepath, parse("/")
						ren filesharepath2 code
						ren filesharepath4 surveyid
						replace code = upper(code)
						keep if upper(filename)=="`=upper("$cpifile")'"
										
						split surveyid, p("_")
						ren surveyid1 country
						ren surveyid2 year
						ren surveyid3 survey
						ren surveyid4 verm
						replace verm = lower(verm)
						drop surveyid5										
						gen col = "${rootcpi1}"
						cap tostring year, replace
						keep if code=="`=upper("${cpic}")'" & year=="${cpiy}" //as per setting
						bys country year survey (verm): gen l = _n==_N
						cap putmata ${rootcpi1}_cpidata = (code year survey col verm surveyid), replace
						if _rc==0 {
							global ${rootcpi1}_cpivindate $S_DATE
							global nomatacpi 0
						}
						keep if l==1
						global l${rootcpi1}cpivin = surveyid[1]	
						clear					
					}				
					else { //not csv file
						noi dis as error "Not csv file"
						*noi dis as error "Failed to load the CPI data with the defined structure $cpiw"
						*noi dis as error "The CPI data should be publicly available, please inform the collection admins."
					}
				}			
				else {
					noi di as yellow `"Failed to updated the cpivintage data. Using the first vintage: ${cpic}_${cpiy}_CPI_v01_M"' _new
					global l${rootcpi1}cpivin ${cpic}_${cpiy}_CPI_v01_M
					*dlw_message, error(`dlibrc')
				} //dlibrc
			} //end of dl cpivintage	
			
			global r${rootcpi1}cpivin ${l${rootcpi1}cpivin} //use latest
			if `"${cpiw}"'~="" global cpiw ${cpiw}&para1=${r${rootcpi1}cpivin}   
		} //only for harmonized data
	} //cpiw	
	
	filesearchw2, token($token) col($type) country(`country') year(`years') server($rootname) surveyid(`surveyid') filename(`filename') folder($subfolders) para1($para1) para2($para2) para3($para3) para4($para4) `latest' `nometa' `net' 
					
	local rc = _rc
	return local type `r(type)'
	return local module `r(module)'
	return local verm `r(verm)'
	return local vera `r(vera)'
	return local surveyid  `r(surveyid)'
	return local filename `r(filename)'
	return local filedate `r(filedate)'
	return local idno `r(idno)'
	global surveyid  `r(surveyid)'
	global f1name `r(filename)'

	// merge CPI
	qui if "`nocpi'"=="" { // _rc check
		tempfile datafinal cpiuse
		cap save `datafinal', replace
		if _rc==0 { //there is some data to save so it can be merged later			
			tempfile tempcpi
			local cpino = 0
			if "`=lower("`fileserver'")'"=="fileserver" {
				if "$cpi"~="" {
					use "$cpi", clear
					local cpino = 1
				}
			}
			else {
				if `"$cpiw"'~="" { //check vintage of CPI data 
					local dl 0
					local persdir : sysdir PERSONAL
					if "$S_OS"=="Windows" local persdir : subinstr local persdir "/" "\", all										
					
					if "${${rootname1}CPI_date}"~="" {
						if (date("$S_DATE", "DMY")-date("${${rootname1}CPI_date}", "DMY")) <= $updateday {
							cap use "`persdir'datalibweb/data//${rootname}//${cpic}//${cpic}_${cpiy}_CPI//${r${rootcpi1}cpivin}//Data/Stata//${cpifile}", clear	
							if _rc==0 local cpino = 1
							else local dl 1
						}
						else local dl 1						
					}
					else { 
						cap confirm file "`persdir'datalibweb/data//${rootname}//${cpic}//${cpic}_${cpiy}_CPI//${r${rootcpi1}cpivin}//Data/Stata//${cpifile}"
						if _rc==0 {
							cap use "`persdir'datalibweb/data//${rootname}//${cpic}//${cpic}_${cpiy}_CPI//${r${rootcpi1}cpivin}//Data/Stata//${cpifile}", clear
							if _rc==0 {
								local dtadate : char _dta[version]			
								if (date("$S_DATE", "DMY")-date("`dtadate'", "DMY")) > $updateday local dl 1
								else {
									local cpino = 1
									global ${rootname1}CPI_date `dtadate'
								}
							}
							else local dl 1
						}
						else {
							cap mkdir "`persdir'datalibweb/data//${rootname}"
							cap mkdir "`persdir'datalibweb/data//${rootname}//${cpic}"
							cap mkdir "`persdir'datalibweb/data//${rootname}//${cpic}//${cpic}_${cpiy}_CPI"
							cap mkdir "`persdir'datalibweb/data//${rootname}//${cpic}//${cpic}_${cpiy}_CPI//${r${rootcpi1}cpivin}"
							cap mkdir "`persdir'datalibweb/data//${rootname}//${cpic}//${cpic}_${cpiy}_CPI//${r${rootcpi1}cpivin}//Data"
							cap mkdir "`persdir'datalibweb/data//${rootname}//${cpic}//${cpic}_${cpiy}_CPI//${r${rootcpi1}cpivin}//Data/Stata"				
							local dl 1
						}
					}
					
					if `dl'==1 {
						dlw_api, option(0) outfile(`tempcpi') query("$cpiw")
						if `dlibrc'==0 {
							if "`dlibFileName'"~="ECAFileinfo.csv" {			
								use `tempcpi', clear
								char _dta[version] $S_DATE							
								compress
								cap mkdir "`persdir'datalibweb/data//${rootname}"
								cap mkdir "`persdir'datalibweb/data//${rootname}//${cpic}"
								cap mkdir "`persdir'datalibweb/data//${rootname}//${cpic}//${cpic}_${cpiy}_CPI"
								cap mkdir "`persdir'datalibweb/data//${rootname}//${cpic}//${cpic}_${cpiy}_CPI//${r${rootcpi1}cpivin}"
								cap mkdir "`persdir'datalibweb/data//${rootname}//${cpic}//${cpic}_${cpiy}_CPI//${r${rootcpi1}cpivin}//Data"
								cap mkdir "`persdir'datalibweb/data//${rootname}//${cpic}//${cpic}_${cpiy}_CPI//${r${rootcpi1}cpivin}//Data/Stata"	
								saveold "`persdir'datalibweb/data//${rootname}//${cpic}//${cpic}_${cpiy}_CPI//${r${rootcpi1}cpivin}//Data/Stata//${cpifile}", replace	
								local cpino = 1
								global ${rootname1}CPI_date $S_DATE
							}
							else {
								noi dis as error "Failed to load the CPI data with the defined structure $cpiw"
								noi dis as error "The CPI data should be publicly available, please inform the collection admins."
							}
						}
						else {
							noi dis as error "Failed to load the CPI data with the defined structure $cpiw"
							dlw_message, error(`dlibrc')
						}
					}
				}
				else local cpino = 0 //cpiw is empty and user requested CPI
			}
			//Check CPI data is available or not
			if `cpino'==0 use `datafinal', clear	
			if `cpino'==1 {
				save `cpiuse', replace
				
				use `datafinal', clear	
				*cap destring year, replace
				cap gen str code = "`=upper("`country'")'"   //need to be removed later
				cap replace code = upper(code)
				cap drop year
				cap gen year = `years'                        //need to be removed later			
				qui if strpos("$surveyid)","EU-SILC")>0 replace year = year - 1				//EUSILC year
				//datalevel  
				local cpilevel				
				if "`=upper("$type")'"=="GPWG" | "`=upper("$type")'"=="GMD" | "`=upper("$type")'"=="SSAPOV" | "`=upper("$type")'"=="PCN" {	
					foreach vout in _all_ cpi2017 icp2017 cpi2021 icp2021 icpbase ppp {
						cap drop `vout'
					}
					cap drop datalevel
					local cpilevel datalevel survname
					//Apr2024: force to use without urban/rural for IDN, old cpiverion needs to merge manually `=upper("`country'")'"=="IDN" 					
					qui if "`=upper("`country'")'"=="CHN" | "`=upper("`country'")'"=="IND" gen datalevel = urban						
					else gen datalevel = 2						
					//DEC2019: add survey acronym (survname) to the merge as CPIv04 now is unique at the level code year survname datalevel					
					cap drop survname							
					if strpos("$surveyid","_")>0 { //fullsurvey id							
						qui tokenize "$surveyid", p("_")
						cap gen survname = "`=upper("`5'")'"
					}
					else {
						if strpos("$f1name","_")>0 { //filename								
							qui tokenize "$f1name", p("_")
							cap gen survname = "`=upper("`5'")'"
						}
						else cap gen survname = "$surveyid"							
					}
				}
				if "`=upper("$type")'"=="SARMD" { //new Mar 15 17						
					local cpilevel datalevel
					if "`=upper("`country'")'"=="IND" gen datalevel = urban
					else gen datalevel = 2
					*gen urb = urban
					*local cpilevel urban						
				}
				if "`=upper("$type")'"=="EAPPOV" { //new June 6 18						
					local cpilevel datalevel
					//Apr2024: force to use without urban/rural for IDN, old cpiverion needs to merge manually `=upper("`country'")'"=="IDN" 
					gen datalevel = 2						
					*if "`=upper("`country'")'"=="IDN" gen datalevel = urban
					*else gen datalevel = 2						
				}
				//merge CPI   
				if "`=upper("$type")'"=="SEDLAC-03" | "`=upper("$type")'"=="SEDLAC-02" | "`=upper("$type")'"=="SEDLAC-01" {
					cap drop pais
					cap drop ano
					cap gen pais = "`=lower("`country'")'"
					cap gen ano = `year'
					if strpos("$surveyid","_")>0 { //fullsurvey id
						cap drop encuesta							
						qui tokenize "$surveyid", p("_")
						cap gen encuesta = "`=upper("`5'")'"
					}
					else {
						if strpos("$f1name","_")>0 { //filename
							cap drop encuesta							
							qui tokenize "$f1name", p("_")
							cap gen encuesta = "`=upper("`5'")'"
						}
						else cap gen encuesta = "$surveyid"
						
					}
					cap merge m:1 pais ano encuesta using `cpiuse', gen(_mcpi) keepus($cpivarw)	update replace	
					if _rc~=0 noi dis as error "Can't merge with CPI data - please check with the regional team."
				}
				else if "`=upper("$type")'"=="GLAD" { //GLAD March 17 2020
					
					* Brings thresholds triplets defined in dta which should sit in DLW (our version of CPI.dta)
					merge m:1 surveyid idgrade using `cpiuse', keep(master match) nogen
					* Each prefix_threshold is a triplet: prefix_threshold_var, prefix_threshold_val, prefix_threshold_res
					* Loop through all threshold triplets (specifically, prefix_threshold_res but could be val or var)
					ds *_threshold_res
					foreach threshold_res of varlist `r(varlist)' {
						local this_prefix = subinstr("`threshold_res'", "_threshold_res", "", 1)
						* Check if this_prefix was used for this assessment-year, or has all missing obs
						count if missing(`threshold_res')
						if `r(N)'<_N {
						* Not all observations are missing
						* Concatenate list of prefixes used
						local prefixes = "`prefixes' `this_prefix'"
						* Concatenate list of results to be created, in two steps
						* 1. loop through all results used in a prefix
						levelsof `threshold_res', local(resultvars_in_prefix)
						foreach resultvar of local resultvars_in_prefix {
							* 2. Update the list of results (unique entries only)
							local resultvars : list resultvars | resultvar
							* 3. Also store the full FGT family in another list
							local all_this_resultvar "`resultvar' fgt1_`resultvar' fgt2_`resultvar'"
							local all_resultvars : list all_resultvars | all_this_resultvar
						}
						}
						else {
						* All observations are missing
						* Drop the threshold triplet, for it was not used at all
						drop `this_prefix'_threshold_*
						}
					}
					* Value labels for dummy variables of Harmonized Proficiency
					label define lb_hpro 0 "Non-proficient" 1 "Proficient" .a "Missing score/level" .b "Non-harmonized grade", replace
					* Loop creating the FGT0 (resultvar), FGT1 (fgt1_resultvar) and FGT2 (fgt2_resultvar)
					foreach resultvar of local resultvars {
						* FGT0: Generate all result variables as dummies which start empty
						* (labeled as if this grade was not being harmonized)
						gen byte  `resultvar': lb_hpro = .b
						label var `resultvar' "Harmonized proficiency (subject-specific FGT0)"
						char `resultvar'[clo_marker] "dummy"
						* FGT1: the gap
						gen float fgt1_`resultvar' = .
						label var fgt1_`resultvar' "Gap in harmonized proficiency (subject-specific FGT1)"
						char fgt1_`resultvar'[clo_marker] "number"
						* FGT2: the gap squared
						gen float fgt2_`resultvar' = .
						label var fgt2_`resultvar' "Gap squared in harmonized proficiency (subject-specific FGT2)"
						char fgt2_`resultvar'[clo_marker] "number"
					}
					* Loop through all prefixes
					foreach prefix of local prefixes {
						* Retrieves list of variables used in the current prefix_threshold_var
						levelsof `prefix'_threshold_var, local(originalvars_used_in_prefix)
						* Loop through all variables used in the current prefix,
						* and performs the calculation based on it
						foreach originalvar of local originalvars_used_in_prefix {
							foreach resultvar of local resultvars {
							*------
							* FGT0
							* Calculate the harmonized proficiency dummy, for example:
							* resultvar is hpro_read and originalvar is level_llece_read
							replace `resultvar' = (`originalvar'>=`prefix'_threshold_val) if `prefix'_threshold_res == "`resultvar'" & `prefix'_threshold_var=="`originalvar'" & !missing(`originalvar')
							* Case of missing test score or test level
							replace `resultvar' = .a if `prefix'_threshold_res == "`resultvar'" & `prefix'_threshold_var == "`originalvar'" & missing(`originalvar')
							*-----
							* FGT1 = dummy * gap (=> so it is equal to 0 if above proficiency threshold)
							replace fgt1_`resultvar' = (- `originalvar' + `prefix'_threshold_val)/`prefix'_threshold_val if `prefix'_threshold_res == "`resultvar'" & `prefix'_threshold_var=="`originalvar'" & `resultvar' == 0
							* FGT2 = gap squared
							replace fgt2_`resultvar' = fgt1_`resultvar' * fgt1_`resultvar' if `prefix'_threshold_res == "`resultvar'" & `prefix'_threshold_var=="`originalvar'" & `resultvar' == 0
						}
						}
					}
					* When this ado is called, a GLAD.dta is open and it should already
					* have the metadata as standardized in the collection. This adds more:
					char _dta[onthefly_valuevars] "`all_resultvars'"
					* Unabbreviate wildcards* in the threshold triplets variables
					cap unab thresholdvars : *_threshold_var *_threshold_val *_threshold_res
					if _rc == 111 noi disp as err "No harmonized minimum proficiency thresholds defined for this learning assessment."
					else          char _dta[onthefly_traitvars] "`thresholdvars'"
					
					
				}
				else if "`=upper("$type")'"=="LABLAC-01" {
					cap drop pais
					cap drop ano
					cap drop encuesta
					cap drop trimestre
					cap gen pais = "`=lower("`country'")'"   
					cap gen ano = `year'
					if strpos("$surveyid","_")>0 {
						qui tokenize "$surveyid", p("_")
						cap gen encuesta = "`=upper("`5'")'"
						local trimestre `17'
						local trimestre : subinstr local trimestre "Q" "", all
						local trimestre = real("`trimestre'")
						cap gen trimestre = `trimestre'
					}
					else { //cant find _ in the surveyid when it is provided with surveyname
						if strpos("$f1name","_")>0 { //filename
							qui tokenize "$f1name", p("_")
							cap gen encuesta = "`=upper("`5'")'"
							local trimestre `17'
							local trimestre : subinstr local trimestre ".dta" "", all
							local trimestre : subinstr local trimestre ".DTA" "", all
							local trimestre : subinstr local trimestre "Q" "", all
							local trimestre = real("`trimestre'")
							cap gen trimestre = `trimestre'
						}
						else noi dis as error "Can't merge with CPI data - no variables created in merging - please check with the regional team."
					} //$surveyid check _ CPI	
					cap merge m:1 pais ano encuesta trimestre `cpilevel' using `cpiuse', gen(_mcpi) keepus($cpivarw) update replace
					if _rc~=0 noi dis as error "Can't merge with CPI data - please check with the regional team."
				}
				else {
					qui merge m:1 code year `cpilevel' using `cpiuse', gen(_mcpi) keepus($cpivarw) update replace
				}
				qui drop if _mcpi==2		
				qui drop _mcpi
				cap drop datalevel 
				cap drop ppp_note
				qui if strpos("$surveyid","EU-SILC")>0 replace year = year + 1				//EUSILC year
				noi dis as text in yellow `"{p 4 4 2}The data is loaded in your notebook.{p_end}"'			
			}
		} //_rc save
	} //nocpi
	else {
		noi dis as text in yellow `"{p 4 4 2}The dofile (`filename') is loaded in your notebook.{p_end}"'			
	}
	
end

cap drop program _display_logo
program define _display_logo
	disp in g _n(2)""
	disp in g _col(2)"  ___  ____  ____  ____            ____        ____  ___ (R)"
	disp in g _col(2)" /  / ____/   /   ____/   /    /  /___/ /   / /___ /___/"
	disp in g _col(2)"/__/ /___/   /   /___/   /__  /  /___/ /_/_/ /___ /___/ "
	disp ""   _col(2)
	disp in w _col(2)"Datalibweb is an API data platform specifically designed to enable users to access "
	disp in w _col(2)"the most up-to-date data and documentation available in different regional catalogs "
	disp in w _col(2)"at the World Bank. It allows users to access the latest and historical versions of"
	disp in w _col(2)"non-harmonized (original/raw) data as well as different harmonized collections."
	disp in w _col(2)"It is integrated with Stata through the Datalibweb Stata package."
	disp in g _n(2)""
end