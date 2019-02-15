*! version 1.01  26jan2018
*! Minh Cong Nguyen, Raul Andres Casta񥤡 Aguilar

cap program drop datalibweb_inventory
program define datalibweb_inventory, rclass

syntax [anything(name=lookup)] , [ ///
	Code(string)				             ///
	Name(string)				             ///
	Region(string)			             ///
	type(string)				             ///
	year(numlist max=1)	             ///
	module	doc					 ///
	vintage                          ///
	clear							               ///
	raw regional  global             ///
	vermast(string) veralt(string)	 ///
	survey(string)                   /// 
	]
	version 11

qui {
	global yesno 0
	if "$updateday"=="" global updateday 5
	*-----------------------------------
	* 0. Program set up
	*-----------------------------------
	cap which varlocal
	if (_rc) ssc install varlocal
	local code = upper("`code'")
	local name = upper("`name'")
	local region = upper("`region'")
	local type = upper("`type'")

	*-----------------------------------
	* 1. create data base
	*-----------------------------------
	dlw_countryname		// see program below
	tempfile cnames
	save `cnames', replace

	*---------------------------------------
	* 2. Procedure for region or countries
	*--------------------------------------
	* 2.1 In case country code or country name are selected
	if ("`code'" != "" & "`region'" == "") keep if countrycode == "`code'"
	if ("`name'" != "" & "`region'" == "") keep if countryname == "`name'"
	count 
	if r(N) == 1 {
		return local countrycode = countrycode[1]
		return local countryname = countryname[1]
		return local region = region[1]
		return local N = r(N)
	}

	* 2.2 In case region is selected
	else {
		* 2.2.1 To find country based on Region
		if ("`region'" != "" & "`code'" == "") {
			keep if region == "`region'"
			varlocal countrycode countryname, replacespace
			local codes = r(countrycode)
			local names = r(countryname)
			return local countrylist = "`codes'"
			noi disp in y _n(2) "{ul: Select Country of analysis}" _n
			noi disp in g "{hline 10}{c TT}{hline 27}"
			noi disp in g _col(2) "Country" _col(11) "{c |}"
			noi disp in g _col(2) "Code" _col(11) "{c |}" _col(25) "Country Name"
			noi di as text "{hline 10}{c +}{hline 27}"

			local i = 0
			foreach c of local codes {
				local ++i
				local n: word `i' of `names'
				local n: subinstr local n "_" " ", all
				noi disp _col(6) `"{stata datalibweb_inventory, code(`c') region(`region') : `c'}"'  ///
					in g _col(11) "{c |}" in y _col(`=37-length("`n'")') "`n'" 				
			}	// end of codes loop	
			noi di as text "{hline 10}{c BT}{hline 27}"
			clear
		}	// end of region conditional
		
		*********************************************
		/* STEP 3:  To find type based on Country*/
		*********************************************
		
		if ("`region'" != "" & "`code'" != "" &  "`type'" == "") {	
			 _catalog `code' `region' $yesno		 
			local rline 37
			local lline 15
			 
			noi disp in y _n(2) "{ul: Select collection of analysis}" _n
			noi disp _col(4) in g "{it:Raw collection:}"
			noi disp _col(4) in g "{hline `lline'}{c TT}{hline `rline'}" 
			levelsof datanature if (finaltype == "Data" & type2 == 0), local(colraws)
			foreach colraw of local colraws {
				if ("`colraw'" == "ORIGINAL") continue 
				local codeline "datalibweb_inventory, region(`region') code(`code') type(`colraw') raw "
				noi disp _col(6) in y "`colraw'" in g _col(19) "{c |}" _col(21) `"{stata `codeline': Data & documentation availability}"'
			}
			noi disp _col(4) in g "{hline `lline'}{c BT}{hline `rline'}" 
			
			noi disp _n _col(4) in g "{it:Regional harmonized collection:}" 
			noi disp _col(4) in g "{hline `lline'}{c TT}{hline `rline'}" 
			levelsof collection if type2 == 1, local(collections)
			foreach collection of local collections {
				local codeline "datalibweb_inventory, region(`region') code(`code') type(`collection') vintage regional"
				local codemodule "datalibweb_inventory, region(`region') code(`code') type(`collection') module regional"
				local codedoc "datalibweb_inventory, region(`region') code(`code') type(`collection') doc regional"
				noi disp _col(6) in y "`collection'"  in g _col(19) "{c |}" ///
					_col(21) `"{stata `codeline': Vintages }"'    ///
					_col(31) `"{stata `codemodule': Modules }"' ///
					_col(41) `"{stata `codedoc': Documentation }"'
			}
			noi disp _col(4) in g "{hline `lline'}{c BT}{hline `rline'}" 
			
			noi disp _n _col(4) in g "{it:Global harmonized collection:}" 
			noi disp _col(4) in g "{hline `lline'}{c TT}{hline `rline'}" 
			levelsof collection if type2 == 2, local(collections)
			foreach collection of local collections {
				local codeline "datalibweb_inventory, region(`region') code(`code') type(`collection') vintage global"
				local codemodule "datalibweb_inventory, region(`region') code(`code') type(`collection') module global"
				local codedoc "datalibweb_inventory, region(`region') code(`code') type(`collection') doc global"
				noi disp _col(6) in y "`collection'"  in g _col(19) "{c |}"    ///
					_col(21) `"{stata `codeline': Vintages }"'  ///
					_col(31) `"{stata `codemodule': Modules }"' ///
					_col(41) `"{stata `codedoc': Documentation }"' 
			}
			noi disp _col(4) in g "{hline `lline'}{c BT}{hline `rline'}" 
			drop type2
			clear
		} // end of condition if ("`region'" != "" & "`type'" == "")
		
		/* ************************************
		STEP 4: Find country base and type
		************************************ */
		
		****** 2.2.4 To find Country based on type. 
		if ("`region'" == "" & "`code'" == "" &  "`type'" != "") {
			_catalog `code' `region' $yesno
			keep if (collection == "`type'")
			collapse (firstnm) type, by(country)
			rename country countrycode
			merge 1:1 countrycode using `cnames', keep(match) nogen   // merge with country names file	
			varlocal countrycode countryname region, replacespace
			local codes   = r(countrycode)
			local names   = r(countryname)
			local regions = r(region)
			noi disp in y _n(2) "{ul: Select Country of analysis}" _n
			noi disp in g "{hline 37}"
			noi disp in g _col(2) "Country" _col(11) "{c |}"
			noi disp in g _col(2) "Code" _col(11) "{c |}" _col(25) "Country Name"
			noi di as text "{hline 10}{c +}{hline 27}"

			local i = 0
			foreach c of local codes {
				local ++i 
				local n: word `i' of `names'
				local n: subinstr local n "_" " ", all
				local r: word `i' of `regions'
				noi disp _col(6) `"{stata datalibweb_inventory, code(`c') region(`r') type(`type') : `c'}"' ///
					in g _col(11) "{c |}" in y _col(`=37-length("`n'")') "`n'" 
			}	// end of codes loop
			noi di as text "{hline 10}{c BT}{hline 27}"
			clear
		}
			
		****** 2.2.4 To find year based on type and country
		if ("`raw'" == "raw") {
			* use "C:\ado\plus\_\_inventory.dta", clear
			_catalog `code' `region' $yesno
			keep if datanature == "`type'"
			* local type "ECARAW"
			collapse (max) subscribed is_*, by(year acronym)
			sort year acronym
			gen n = _n 
			** display data availability by survey
			
			* Column size in table
			local col1 6
			local col2 12
			local col3 20
			local col4 32
			local col5 43
			local col6 54
			* Begin heading
			noi disp "" _n 
			noi disp _col(`=`col1'-1') in g "{hline `=`col5'+4'}"
			noi disp _col(`col1') in g "Year" _col(`col2') "Survey" _col(`col3') "Subscribed" ///
				_col(`col4') "Document-" _col(`col5') "Programs" 
			noi disp _col(`col4') "ation" _col(`col5') "/Dofile"
			noi disp _col(`=`col1'-1') in g "{hline `=`col5'+4'}"
			* End Heading
	
			levelsof acronym, local(surveys)
			local nsurvey: word count `surveys' 	
			local s = 0
			foreach survey of local surveys {
				local ++s
				levelsof year if acronym == "`survey'", local(years) 
				foreach year of local years {
					sum n if year == `year' & acronym == "`survey'", meanonly
					local line = r(mean)
					local sb: label subscribed `: disp subscribed[`line']'
					local is_data = is_Data[`line']>0
					local is_doc  = is_Documentation[`line']>0
					if `is_doc'>0 local codeq "{stata datalibweb, country(`code') year(`year') type(`type') surveyid(`survey') request(doc): Link}"
					else  local codeq " NA"
					if `is_doc'>0 local codet "{stata datalibweb, country(`code') year(`year') type(`type') surveyid(`survey') request(prog): Link}"
					else local codet " NA"
					*local codep "datalibweb, country(`code') year(`year') type(`type') surveyid(`survey') request(prog)"
					local codeb "datalibweb, country(`code') year(`year') type(`type') surveyid(`survey') clear"
					
					if      regexm(`"`sb'"', "[Yy][Ee][Ss]") local link2data `" "{stata `codeb': YES}" "'
					else if regexm(`"`sb'"', "[Nn][Oo]")     local link2data `" in red " NO" "'
					else                                     local link2data `" in green "Expired" "'
					
					noi disp _col(`col1') in y "`year'" _col(`=`col2'+1') "`survey'" ///
						_col(`=`col3'+1') `link2data'	  ///
						_col(`=`col4'+1') `"`codeq'"'	_col(`=`col5'+1') `"`codet'"'
					
				} // end of years loop
				if (`s' != `nsurvey') noi disp _col(`=`col1'-1') in y _dup(15) " - "
			}  // end of surveys loop
			noi disp _col(`=`col1'-1') in g "{hline `=`col5'+4'}"
			clear
		} // end of display raw data availability
		
		if ("`regional'" == "regional" | "`global'" == "global") {
			if ("`vermast'" == "" & "`veralt'" == "" & "`vintage'" == "vintage") {
				_catalog `code' `region' $yesno
				keep if collection == "`type'"
				collapse (max) isdownload , by(year acronym vermast veralt subscribed )
				label values isdownload isdownload
				sort year acronym vermast veralt isdownload 
				gen n = _n 
				** display data availability by survey
				
				* Column size in table
				local col1 = 7
				local col2 = `col1'+11
				local col3 = `col2'+16
				local col4 = `col3'+12
				local col5 = `col4'+10
				
				levelsof acronym, local(surveys)
				local nsurvey: word count `surveys' 
				
				local s = 0
				foreach survey of local surveys {
					local ++s
					* Begin heading
					noi disp _col(`=`col1'-1') in g "{hline `=`col5'+4'}"
					noi disp _col(`=`col2'+2') in y "{it: Vintage availability of `survey' as {ul:`type'}}" 
					noi disp _col(`col1') in g "V. Master" _col(`col2') "V. Alternative" ///
						_col(`col3') "Downloaded" _col(`=`col4'+5') "Access to" 
						
					noi disp _col(`=`col1'-1') in g "{hline `=`col5'+4'}"
					* End Heading
					
					levelsof year if acronym == "`survey'", local(years) 
					foreach year of local years {
						noi disp in y _col(`=`col1'-3') "{ul:`year'}"  _n 
						levelsof n if (year == `year' & acronym == "`survey'"), local(lines)
						foreach line of local lines {
							local vm: disp vermast[`line']
							local va: disp veralt[`line'] 
							local dl: label isdownload `:disp isdownload[`line']'
							local sb: label subscribed `:disp subscribed[`line']'
							
							local coded  "datalibweb, country(`code') year(`year') type(`type') vermast(`vm') veralt(`va') survey(`survey') clear"
							local codem  "datalibweb_inventory, code(`code') region(`region') year(`year') type(`type') vermast(`vm') veralt(`va') survey(`survey') regional"
							
							if regexm(`"`sb'"', "[Yy][Ee][Ss]") {
								local linkdefault `" _col(`=`col4'+1') "{stata `codem': Modules}" _col(`=`col5'')  "{stata `coded': Default}" "'
							}
							else if regexm(`"`sb'"', "[Nn][Oo]") {
								local linkdefault `" _col(`=`col4'+3')  in red "Not Subscribed" "'
							}
							else local linkdefault `" _col(`=`col4'+6')  in green "Expired" "'
							noi disp _col(`=`col1'+3') in y "`vm'" _col(`=`col2'+5') "`va'" ///
							_col(`=`col3'+4') "`dl'"  `linkdefault'		
						} // end of loop lines
						
					} // end of years loop
						if (`s' != `nsurvey') noi disp _col(`=`col1'-1') in y _dup(15) " - "
				}  // end of surveys loop
				noi disp _col(`=`col1'-1') in g "{hline `=`col5'+4'}"
				clear
			} // end of display vintages availability
			
			if ("`vermast'" == "" & "`veralt'" == "" & "`module'" == "module") {
				_catalog `code' `region' $yesno
				
				keep if collection == "`type'"	
				drop if lower(veralt)=="wrk"
				bys serveralias acronym year module (verm vera): gen a = _n==_N 
				keep if a == 1
				//tostring year, replace
				//decode subscribed, gen(sub)
				//replace year = year + "(" +sub + ")"
				keep serveralias year module vermast veralt acronym subscribed
				gen vintage = vermast + "-" + veralt
				levelsof acronym, local(surveys)
				compress
				tempfile serfile
				save `serfile', replace
				levelsof serveralias, local(serverlist)
				foreach ser of local serverlist {
					use `serfile', clear
					keep if serveralias=="`ser'"
					noi disp _n _col(`=`col2'+2') in y "{it: Module availability for most recent vintage in collection {ul:`type'} (Server: `ser')}" 
					noi dlw_display, row(year) col(module) con(vintage) country(`code') type(`type') sub(acronym)
				}
				/*
				tempfile sur
				save `sur', replace
				foreach survey of local surveys {
					use `sur', clear
					keep if acronym=="`survey'"
					noi disp _n _col(`=`col2'+2') in y "{it: Module availability for most recent vintage of {ul:`survey'} in {ul:`type'}}" 
					noi dlw_display, row(year) col(module) con(vintage) country(`code') type(`type') sub(acronym)
				}
				*/
			} 
			if ("`vermast'" == "" & "`veralt'" == "" & "`doc'" == "doc") {
				_catalog `code' `region' $yesno
				keep if collection == "`type'"		
				collapse (max) subscribed is_*, by(year acronym)
				sort year acronym
				gen n = _n 
				** display data availability by survey
				
				* Column size in table
				local col1 6
				local col2 12
				local col3 20
				local col4 32
				local col5 43
				local col6 54
				* Begin heading
				noi disp "" _n 
				noi disp _col(`=`col1'-1') in g "{hline `=`col5'+4'}"
				noi disp _col(`col1') in g "Year" _col(`col2') "Survey" _col(`col3') "Subscribed" ///
					_col(`col4') "Document-" _col(`col5') "Programs" 
				noi disp _col(`col4') "ation" _col(`col5') "/Dofile"
				noi disp _col(`=`col1'-1') in g "{hline `=`col5'+4'}"
				* End Heading
		
				levelsof acronym, local(surveys)
				local nsurvey: word count `surveys' 	
				local s = 0
				foreach survey of local surveys {
					local ++s
					levelsof year if acronym == "`survey'", local(years) 
					foreach year of local years {
						sum n if year == `year' & acronym == "`survey'", meanonly
						local line = r(mean)
						local sb: label subscribed `: disp subscribed[`line']'
						local is_data = is_Data[`line']>0
						local is_doc  = is_Documentation[`line']>0
						if `is_doc'>0 local codeq "{stata datalibweb, country(`code') year(`year') type(`type') surveyid(`survey') request(doc): Link}"
						else  local codeq " NA"
						if `is_doc'>0 local codet "{stata datalibweb, country(`code') year(`year') type(`type') surveyid(`survey') request(prog): Link}"
						else local codet " NA"
						*local codep "datalibweb, country(`code') year(`year') type(`type') surveyid(`survey') request(prog)"
						local codeb "datalibweb, country(`code') year(`year') type(`type') surveyid(`survey') clear"
						
						if      regexm(`"`sb'"', "[Yy][Ee][Ss]") local link2data `" "{stata `codeb': YES}" "'
						else if regexm(`"`sb'"', "[Nn][Oo]")     local link2data `" in red " NO" "'
						else                                     local link2data `" in green "Expired" "'
						
						noi disp _col(`col1') in y "`year'" _col(`=`col2'+1') "`survey'" ///
							_col(`=`col3'+1') `link2data'	  ///
							_col(`=`col4'+1') `"`codeq'"'	_col(`=`col5'+1') `"`codet'"'
						
					} // end of years loop
					if (`s' != `nsurvey') noi disp _col(`=`col1'-1') in y _dup(15) " - "
				}  // end of surveys loop
				noi disp _col(`=`col1'-1') in g "{hline `=`col5'+4'}"
				clear	
			}
			if ("`vermast'" != "" | "`veralt'" != "") {
				_catalog `code' `region' $yesno	
				
				if ("`year'" != "") local ifyear " & year == `year' "
				else local ifyear ""
				keep if (collection == "`type'" & vermast == "`vermast'" ///
					& veralt == "`veralt'" & acronym == "`survey'" `ifyear')
				sort module
				gen n = _n 
				*----
				** display data availability by survey
				noi disp _n _col(4) in y "{it:{ul:Module availability for `type'-`survey'-`year':}}"  _n
				
				noi disp in g _col(4) "{hline 37}"
				noi disp in g _col(5) "Module"  _col(18) "Subscribed"  _col(31) "Downloaded"
				noi disp in g _col(4) "{hline 37}"
				levelsof module, local(modules)
				foreach module of local modules {
					sum n if module == "`module'"
					local line = r(mean)
					local dl: label isdownload `:disp isdownload[`line']'
					local sb: label subscribed `:disp subscribed[`line']'
					local coded  "datalibweb, country(`code') year(`year') type(`type') vermast(`vermast') veralt(`veralt') survey(`survey') module(`module') clear"
					noi disp _col(6) in y "{stata `coded': `module'} " _col(20) "`sb'" _col(33) "`dl'"
				}
				noi disp in g _col(4) "{hline 37}"
				clear
			} // end of presenting modules for particular vintage
			
		} // end of regional 
			
		* 2.3 Return locals
		return local countrycode = ""
		return local countryname = ""
		return local region = ""
		return local N = r(N)
		return local type = "`type'"		
	}	// end of else 
}		// end of qui
 
end

*************************************************************************************
*-----------------------------------
* 3. Create dataset
*-----------------------------------

cap program drop _catalog
program define _catalog

qui {  
	args countrycode region yesno
	if `yesno'==0 {
		local dl 0
		//path
		local persdir : sysdir PERSONAL
		if "$S_OS"=="Windows" local persdir : subinstr local persdir "/" "\", all
		
		cap confirm file "`persdir'datalibweb\data\Catalog_`countrycode'.dta"
		if _rc==0 {
			cap use "`persdir'datalibweb\data\Catalog_`countrycode'.dta", clear	
			if _rc==0 {
				local dtadate : char _dta[version]			
				if (date("$S_DATE", "DMY")-date("`dtadate'", "DMY")) > $updateday local dl 1
			}
			else local dl 1
		}
		else {
			cap mkdir "`persdir'datalibweb\data"
			local dl 1
		}
		if `dl'==1 {
			qui dlw_usercatalog, code(`countrycode')
			cap use "`persdir'datalibweb\data\Catalog_`countrycode'.dta", clear	
			global yesno 1
		}
	}
	else {
		cap use "`persdir'datalibweb\data\Catalog_`countrycode'.dta", clear	
		global yesno 1
	}
	bys country year acronym collection (type): gen count=_N
	levelsof finaltype, local(ftype)
	foreach ty of local ftype {
		tempvar `ty'
		gen ``ty'' = count>0 if finaltype=="`ty'"
		bys country year acronym collection (type): egen is_`ty' = sum(``ty'')
	}
	
	keep if upper(ext)=="DTA"
	gen datanature = serveralias + "RAW" if finaltype == "Data" & token==5
	//gen datanature = "`region'RAW" if finaltype == "Data" & token==5
	//replace datanature = serveralias + "RAW" if finaltype == "Data" & token==5 & (serveralias=="SEDLAC"|serveralias=="LABLAC")
	/*		
	split filepath, p("\")
	* rename  filepath3 surveyid
	rename  filepath4 filetype
	replace filetype = upper(filetype)
	rename  filepath5 datanature
	replace datanature = upper(datanature)
	replace datanature = "`region'RAW" if datanature == "STATA"
	drop filepath?

	gen vermast  = regexs(2) if regexm(surveyid, "^(.*)_[Vv]([0-9]+)_[Mm]")
	gen veralt   = regexs(2) if regexm(surveyid, "^(.*)_[Vv]*([0-9]+|[a-zA-Z]+)_[Aa]_")
	gen survey   = regexs(3) if regexm(surveyid, "^([a-zA-Z]+)_([0-9]+)_([a-zA-Z]+)")
	replace survey = upper(survey)
	* gen filename  = ustrregexs(2) if ustrregexm(filepath, "^(.*)\\(.*)\.[a-z]+$")		
	gen collection = regexs(2) if regexm(filename, "^(.*)_[Aa]_([a-zA-Z0-9\-]+)(_[a-zA-Z0-9\-]+)*")
	gen module     = regexs(3) if regexm(filename, "^(.*)_[Aa]_([a-zA-Z0-9\-]+)_([a-zA-Z0-9\-]+)\.[a-z]+$")
	replace module = upper(module)
	replace module = "NULL" if token==8 & module==""
	tempvar t
	gen `t' = regexm(filepath, `"^.*_[Vv][0-9][1-9]_[Mm]_[a-zA-Z0-9]+_[Aa]_"')

	replace collection = upper(collection)
	replace collection = datanature if `t' == 0 
	replace `t' = 2 if inlist(collection, "GMD", "GPWG", "ASPIRE", "I2D2", "I2D2-Labor")  // add as many global collections as available
	clonevar _t = `t'	
	gen isdownload = cond(downloaddate != "", 1, 0)
	label define isdownload 1 "YES" 0 "NO"
	label values isdownload isdownload
	*/
}
end
exit 
