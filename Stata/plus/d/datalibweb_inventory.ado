*! version 1.03 12dec2019
*! Minh Cong Nguyen, Raul Andres Castaneda Aguilar
* version 1.01  26jan2018 - original
* version 1.02  15apr2019 - add new category/conditions for type2
* version 1.03  12dec2019 - add manual refresh link

program define datalibweb_inventory, rclass

	syntax [anything(name=lookup)] , [ ///
		Code(string) ///
		Name(string)				  ///
		Region(string)			             ///
		type(string)				             ///
		year(numlist max=1)	             ///
		module	doc					 ///
		vintage                          ///
		raw regional global             ///
		vermast(string) veralt(string)	 ///
		survey(string)]

	version 16.0

	if "`code'" != "" & "`name'" != "" {
		display as error "Only one of code or name is allowed."
		exit 198
	}
	if "`code'`name'" != "" & "`region'" != "" {
		display "NOTE: When country code/name is specified region will be ignored"
		local region
	}


	local code = upper("`code'")
	local name = upper("`name'")
	local region = upper("`region'")
	local type = upper("`type'")

	// in case country code or country name are selected
	if "`name'" != "" {
		keep if countryname == "`name'"
		if _N != 1 {
			noisily display as error "Name doesn't correspond to any single country."
			exit 198
		}

		local code = countrycode[1]
	}


	// nothing was provided, show list of regions
	if "`code'`region'`type'" == "" {
		noisily _list_regions
		clear
		exit
	}


	// we have region, show countries
	if "`region'" != "" {

		// simple list of countries
		if "`type'" == "" { 
			_list_countries `region'
		}
		else {
			// filtered by type, requires catalog
			_list_filtered_countries `region' `type'
		}
		clear
		exit 
	}

	// we have country, show types
	if "`type'" == "" {
		_list_types `code'
		clear
		exit
	}
			
	****** 2.2.4 To find year based on type and country
	if "`raw'" == "raw" {
		_list_raw `code' `type'
		clear
	}
		
	if "`regional'" == "regional" | "`global'" == "global" {
		if "`vermast'" == "" & "`veralt'" == "" {
			if "`vintage'" == "vintage" {

				_list_vintages `code' `type'
			}
			if "`module'" == "module" {
				_list_modules `code' `type'
			}
			if "`doc'" == "doc" {
				_list_docs `code' `type'
			}
		}
		else {
			_list_year_vintages `code' `year'
		}

		clear			
	}
			
		* 2.3 Return locals
		return local countrycode = ""
		return local countryname = ""
		return local region = ""
		return local N = r(N)
		return local type = "`type'"		

end

*************************************************************************************
*-----------------------------------
* 3. Create dataset
*-----------------------------------

program define _catalog

	args countrycode

	quietly {
		tempfile subscriptions audit
		dlw_apiclient subscriptions, country(`countrycode') outfile(`subscriptions')
		capture dlw_apiclient audit, country(`countrycode') outfile(`audit')
		if _rc == 2000 {
			// we don't have any audit history so far
			local noaudit 1
		}

		dlw_apiclient country_catalog, country(`countrycode')
		quietly merge m:1 serveralias country year acronym requesttype token foldername using `subscriptions', keep(master match) keepusing(expdate subscribed)
		replace subscribed = -1 if subscribed == .

		bysort country year acronym collection (type): generate count = _N
		quietly levelsof requesttype, local(ftype)
		foreach ty of local ftype {
			bysort country year acronym collection (type): egen is_`ty' = sum(requesttype=="`ty'")
		}
		
		keep if upper(ext)=="DTA"
		generate datanature = serveralias + "RAW" if requesttype == "Data" & token == 5

		split surveyid, p("_")
		generate vermast = subinstr(lower(surveyid4), "v", "", .)
		generate veralt = ""
		replace veralt = subinstr(lower(surveyid6), "v", "", .) if token == 8
		drop if vermast == "wrk" | veralt == "wrk"

		if "`noaudit'" == "" {
			merge 1:1 surveyid filename using `audit', nogenerate
			replace isdownload = 0 if isdownload == .
		}
		else {
			generate byte isdownload = 0
		}
	}
end

program define _list_regions
	display in y _n "{ul: Select the region/group of your country/countries of analysis:}" _n
	display as text "{hline 13}{c TT}{hline 36}"
	display in g _col(2) "Region/group" _col(14) "{c |}"
	display in g _col(2) "Code" _col(14) "{c |}" _col(25) "Region/group name"
	display as text "{hline 13}{c +}{hline 36}"		
	foreach reg in EAP ECA LAC MNA SAR SSA NAC Others {
		local inst "stata datalibweb_inventory, region(`reg'): `reg'"
			* Regions names
		if ("`reg'" == "EAP") local regname "East Asia and Pacific"
		if ("`reg'" == "ECA") local regname "Europe and Central Asia"
		if ("`reg'" == "LAC") local regname "Latin America and the Caribbean"
		if ("`reg'" == "MNA") local regname "Middle East and North Africa"
		if ("`reg'" == "SAR") local regname "South Asia"
		if ("`reg'" == "SSA") local regname "Sub-Saharan Africa"
		if ("`reg'" == "NAC") local regname "North America"
		if ("`reg'" == "Others") local regname "Other groups"
		* Display
		display _col(4) `"{`inst'}"' in g _col(14) "{c |}" in y _col(`=47-length("`regname'")') "`regname'" 
	}
	display as text "{hline 13}{c BT}{hline 36}"
end

program define _list_countries
	args region

	_load_countrynames
	
	tempvar touse
	generate `touse' = 1 if region == "`region'"
	sort `touse' countryname

	noi disp in y _n(2) "{ul: Select country/group of analysis}" _n
	noi disp in g "{hline 10}{c TT}{hline 55}"
	noi disp in g _col(2) "Country" _col(11) "{c |}"
	noi disp in g _col(2) "Code" _col(11) "{c |}" _col(25) "Country/group name"
	noi di as text "{hline 10}{c +}{hline 55}"

	local i = 1
	while `touse'[`i'] == 1  {
		display _col(2) `"{stata datalibweb_inventory, code(`=countrycode[`i']') : `=countrycode[`i']'}"'  ///
			in g _col(11) "{c |}" in y "{ralign 55: `=countryname[`i']'}"
		local ++i		
	}
	display as text "{hline 10}{c BT}{hline 55}"
end

program define _list_filtered_countries
	args region type

	tempfile cnames
	_load_countrynames `cnames'

	dlw_apiclient server_catalog, server(`region')

	quietly keep if collection == "`type'"
	collapse (firstnm) type, by(country)
	rename country countrycode
	
	merge 1:1 countrycode using `cnames', keep(match) nogenerate

	display in y _n(2) "{ul: Select Country of analysis}" _n
	display in g "{hline 37}"
	display in g _col(2) "Country" _col(11) "{c |}"
	display in g _col(2) "Code" _col(11) "{c |}" _col(25) "Country Name"
	display as text "{hline 10}{c +}{hline 27}"

	forvalues i=1/`=_N' {
		local code = countrycode[`i']
		display _col(6) `"{stata datalibweb_inventory, code(`code') type(`type') : `code'}"' ///
			in g _col(11) "{c |}" in y "{ralign 27: `=countryname[`i']'}" 
	}
	display as text "{hline 10}{c BT}{hline 27}"
end

program define _list_types
	args code

	_catalog `code'

	local rline 37
	local lline 15 

	display in y _n(2) "{ul: Select collection of analysis}" _n
			
	//RAW collection			
	display _col(4) in g "{it:Raw collection:}"
	display _col(4) in g "{hline `lline'}{c TT}{hline `rline'}" 
			
	quietly levelsof datanature if (requesttype == "Data" & type2 == 0), local(colraws)
	foreach colraw of local colraws {
		if ("`colraw'" == "ORIGINAL") {
			continue 
		}
		local codeline "datalibweb_inventory, code(`code') type(`colraw') raw "
		display _col(6) in y "`colraw'" in g _col(19) "{c |}" _col(21) `"{stata `codeline': Data & documentation availability}"'
	}
	display _col(4) in g "{hline `lline'}{c BT}{hline `rline'}" 
			
	// Regional harmonization
	quietly count if type2 == 1
	if r(N) > 0 {
		noi disp _n _col(4) in g "{it:Regional harmonized collection:}" 
		noi disp _col(4) in g "{hline `lline'}{c TT}{hline `rline'}" 
		quietly levelsof collection if type2 == 1, local(collections)
		foreach collection of local collections {
			local codeline "datalibweb_inventory, code(`code') type(`collection') vintage regional"
			local codemodule "datalibweb_inventory, code(`code') type(`collection') module regional"
			local codedoc "datalibweb_inventory, code(`code') type(`collection') doc regional"
			noi disp _col(6) in y "`collection'"  in g _col(19) "{c |}" ///
				_col(21) `"{stata `codeline': Vintages }"'    ///
				_col(31) `"{stata `codemodule': Modules }"' ///
				_col(41) `"{stata `codedoc': Documentation }"'
		}
		disp _col(4) in g "{hline `lline'}{c BT}{hline `rline'}" 
	}

	//Global harmonization
	quietly count if type2 == 2
	if r(N) > 0 {
		noi disp _n _col(4) in g "{it:Global harmonized collection:}" 
		noi disp _col(4) in g "{hline `lline'}{c TT}{hline `rline'}" 
		quietly levelsof collection if type2 == 2, local(collections)
		foreach collection of local collections {
			local codeline "datalibweb_inventory, code(`code') type(`collection') vintage global"
			local codemodule "datalibweb_inventory, code(`code') type(`collection') module global"
			local codedoc "datalibweb_inventory, code(`code') type(`collection') doc global"
			noi disp _col(6) in y "`collection'"  in g _col(19) "{c |}"    ///
				_col(21) `"{stata `codeline': Vintages }"'  ///
				_col(31) `"{stata `codemodule': Modules }"' ///
				_col(41) `"{stata `codedoc': Documentation }"' 
		}
		display _col(4) in g "{hline `lline'}{c BT}{hline `rline'}" 
	}

	//Global indicators
	quietly count if type2 == 3
	if r(N)>0 {
		noi disp _n _col(4) in g "{it:Thematic indicators:}" 
		noi disp _col(4) in g "{hline `lline'}{c TT}{hline `rline'}" 
		quietly levelsof collection if type2 == 3, local(collections)
		foreach collection of local collections {
			local codeline "datalibweb_inventory, code(`code') type(`collection') vintage global"
			local codemodule "datalibweb_inventory, code(`code') type(`collection') module global"
			local codedoc "datalibweb_inventory, code(`code') type(`collection') doc global"
			noi disp _col(6) in y "`collection'"  in g _col(19) "{c |}"    ///
				_col(21) `"{stata `codeline': Vintages }"'  ///
				_col(31) `"{stata `codemodule': Modules }"' ///
				_col(41) `"{stata `codedoc': Documentation }"' 
		}
		display _col(4) in g "{hline `lline'}{c BT}{hline `rline'}" 
	}
end

program define _list_raw
	args code type

	_catalog `code'

	keep if datanature == "`type'"

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
	
		quietly levelsof acronym, local(surveys)
			local nsurvey: word count `surveys' 	
			local s = 0
			foreach survey of local surveys {
				local ++s
				quietly levelsof year if acronym == "`survey'", local(years) 
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
end

program define _list_vintages

	args code type
				_catalog `code'
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
					
					quietly levelsof year if acronym == "`survey'", local(years) 
					foreach year of local years {
						noi disp in y _col(`=`col1'-3') "{ul:`year'}"  _n 
						quietly levelsof n if (year == `year' & acronym == "`survey'"), local(lines)
						foreach line of local lines {
							local vm: disp vermast[`line']
							local va: disp veralt[`line'] 
							local dl: label isdownload `:disp isdownload[`line']'
							local sb: label subscribed `:disp subscribed[`line']'
							
							local coded  "datalibweb, country(`code') year(`year') type(`type') vermast(`vm') veralt(`va') survey(`survey') clear"
							local codem  "datalibweb_inventory, code(`code') year(`year') type(`type') vermast(`vm') veralt(`va') survey(`survey') regional"
							
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
end

program define _list_modules
	args code type
				_catalog `code'
				
				keep if collection == "`type'"
				drop if lower(veralt)=="wrk"
				bys serveralias acronym year module (verm vera): gen a = _n==_N 
				keep if a == 1
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
end

program define _list_docs
	args code type
				_catalog `code'
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
end

program define _list_year_vintages
	args code year
				_catalog `code'
				
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
end

program define _load_countrynames
	args savepath

	dlw_version

	//local nocache "nocache"

	if "`savepath'" != "" {
		datacache, `nocache' disk signature("`r(version)'") option_name("savepath") : dlw_countryname, savepath(`savepath')
	}
	else {
		datacache, `nocache' memory signature("`r(version)'") : dlw_countryname, clear
	}
end