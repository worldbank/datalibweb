program define _datalibcall_v2, rclass	
	version 10, missing
    local verstata : di "version " string(_caller()) ", missing:" 
	syntax [anything] [if] [in] [,                                    ///
		COUNtry(string) Year(string) CIRca(string)                   ///
		SURvey(string) PERiod(string)                                 ///
		NATure(string) path(string)                                   ///
		Type(string) MODule(string)                                  ///
		APPEND SAVE folder(string) level(numlist max=1)               ///
		filename(string) token(numlist max=1)                         ///
		para1(string) para2(string) para3(string) para4(string)       ///
		DISPLAY /*request(string)  */                                   ///
		CLEAR REPLACE                                                 ///
		ppp(numlist) INCppp(string) PLppp(numlist) PLlcu(numlist) 	  ///
		VERMast(string) VERAlt(string)                                ///
		VINTage(string) PROject(string)                               ///
		IGNOREerror CONFidential Working                              ///
		surveyid(string) ext(string)                                  ///
		NOCPI NOMETA NET  fileserver base                             ///
		]
	
	// Datalibweb error code
	global errcode 0
	* Get the version
	local latest
	local version
	if "`vermast'" == "" & "`veralt'" =="" & strpos("`filename'","_WRK_")==0 local latest latest
	if "`vermast'" ~= "" & "`veralt'" ~="" local version `vermast'_M_`veralt'_A
	if "`vermast'" ~= "" & "`veralt'" =="" local version `vermast'_M
	if "`vermast'" == "" & "`veralt'" ~="" local version `veralt'_A	
	
	//Country fix to make sure past codes run
	if "`=upper("`country'")'"=="KSV" local country XKX
	if "`period'"~="" local surveyid "`surveyid'-`period'" //added May 15th 2019
	foreach cond in version surveyid ext { //add version and/or surveyid to para1-4
		if "``cond''"~="" {
			if ("`para1'"=="") local para1 ``cond''
			else {
				if ("`para2'"=="") local para2 ``cond''
				else {
					if ("`para3'"=="") local para3 ``cond''
					else {
						if ("`para4'"=="") local para4 ``cond''
						else {
							dis as error "Too many conditions (para1-4 and `cond'), please redefine the parameters."
							error 1
						}
					}
				}
			}
		}
	} //cond
	
	// CPI PPP 
	//chekc base here, if 8 and base (whole),
	//if not,
	global type2 $type
	if "`base'"=="base" {
		if "$base"~="" {
			if (`=strpos("$base", "\")'>0 | `=strpos("$base", "/")'>0) {
				local subfolders $base
				global defmod 
				local para1 $basedeffile
			}
			else {
				local para1 $base
				global type2
			}
		}
	}

	if ($token==5) {
		local nocpi nocpi
		if "`=lower("`fileserver'")'"~="fileserver" global type2 
	}
	
	// search options	
	* Get the requested module
	if `=wordcount("`module'")' ==0 {
		if "`=lower("`fileserver'")'"=="fileserver" cap noisily filesearch, col($type2) country(`country') year(`year') root($root) subfolders($subfolders) surveyid(`surveyid') combstring(`filename' `version') `latest' `nometa' /* save("`data2'")  */
		else                                        cap noisily filesearchw2, token(`token') col($type2) country(`country') year(`year') server($rootname) surveyid(`surveyid') filename(`filename') folder(`folder') para1(`para1') para2(`para2') para3(`para3') para4(`para4') `latest' `nometa' `net' /* save("`data2'")  */			
						
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
		
		//Add code to the database
		qui if strpos("`r(surveyid)'","EU-SILC")>0 & (upper("`r(module)'")=="D" | upper("`r(module)'")=="H" | upper("`r(module)'")=="P" | upper("`r(module)'")=="R") { 	
			cap clonevar `=lower("`r(module)'")'b020 = country0
			cap drop code
			gen str6 code=""
			replace code="AUT" if `=lower("`r(module)'")'b020=="AT"
			replace code="BEL" if `=lower("`r(module)'")'b020=="BE"
			replace code="BGR" if `=lower("`r(module)'")'b020=="BG"
			replace code="CYP" if `=lower("`r(module)'")'b020=="CY"
			replace code="CZE" if `=lower("`r(module)'")'b020=="CZ"
			replace code="DEU" if `=lower("`r(module)'")'b020=="DE"
			replace code="DNK" if `=lower("`r(module)'")'b020=="DK"
			replace code="EST" if `=lower("`r(module)'")'b020=="EE"
			replace code="GRC" if `=lower("`r(module)'")'b020=="EL" | `=lower("`r(module)'")'b020=="GR"
			replace code="ESP" if `=lower("`r(module)'")'b020=="ES"
			replace code="FIN" if `=lower("`r(module)'")'b020=="FI"
			replace code="FRA" if `=lower("`r(module)'")'b020=="FR"
			replace code="HUN" if `=lower("`r(module)'")'b020=="HU"
			replace code="IRL" if `=lower("`r(module)'")'b020=="IE"
			replace code="ISL" if `=lower("`r(module)'")'b020=="IS"
			replace code="ITA" if `=lower("`r(module)'")'b020=="IT"
			replace code="LTU" if `=lower("`r(module)'")'b020=="LT"
			replace code="LUX" if `=lower("`r(module)'")'b020=="LU"
			replace code="LVA" if `=lower("`r(module)'")'b020=="LV"
			replace code="MLT" if `=lower("`r(module)'")'b020=="MT"
			replace code="NLD" if `=lower("`r(module)'")'b020=="NL"
			replace code="NOR" if `=lower("`r(module)'")'b020=="NO"
			replace code="POL" if `=lower("`r(module)'")'b020=="PL"
			replace code="PRT" if `=lower("`r(module)'")'b020=="PT"
			replace code="ROU" if `=lower("`r(module)'")'b020=="RO"
			replace code="SRB" if `=lower("`r(module)'")'b020=="RS"
			replace code="SWE" if `=lower("`r(module)'")'b020=="SE"
			replace code="SVN" if `=lower("`r(module)'")'b020=="SI"
			replace code="SVK" if `=lower("`r(module)'")'b020=="SK"
			replace code="GBR" if `=lower("`r(module)'")'b020=="UK"
			replace code="HRV" if `=lower("`r(module)'")'b020=="HR"
			replace code="CHE" if `=lower("`r(module)'")'b020=="CH"			
		}
	}
	if `=wordcount("`module'")' ==1 {
		global para1 `para1'
		global para2 `para2'
		global para3 `para3'
		global para4 `para4'	
		if ("`para1'"=="") global para1 ${type2}_`module'
		else {
			if ("`para2'"=="") global para2 ${type2}_`module'
			else {
				if ("`para3'"=="") global para3 ${type2}_`module'
				else {
					if ("`para4'"=="") global para4 ${type2}_`module'
					else {
						dis as error "Too many conditions (para1-4 and `cond'), please redefine the parameters."
						error 1
					}
				}
			}
		}
			
		if "`=lower("`fileserver'")'"=="fileserver" cap noisily filesearch, col($type2) country(`country') year(`year') root($root) subfolders($subfolders) surveyid(`surveyid') combstring(${type}_`module'$ext `version' `filename') `latest' `nometa' /* save("`data2'")  */				
		else	                                    cap noisily filesearchw2, token(`token') col($type2) country(`country') year(`year') server($rootname) surveyid(`surveyid') filename(`filename') folder($subfolders) para1($para1) para2($para2) para3($para3) para4($para4) `latest' `nometa' `net' /* save("`data2'")  */				
					
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
		
		//Add code to the database
		qui if strpos("`r(surveyid)'","EU-SILC")>0 & (upper("`r(module)'")=="D" | upper("`r(module)'")=="H" | upper("`r(module)'")=="P" | upper("`r(module)'")=="R") { 	
			cap clonevar `=lower("`r(module)'")'b020 = country0
			cap drop code
			gen str6 code=""
			replace code="AUT" if `=lower("`r(module)'")'b020=="AT"
			replace code="BEL" if `=lower("`r(module)'")'b020=="BE"
			replace code="BGR" if `=lower("`r(module)'")'b020=="BG"
			replace code="CYP" if `=lower("`r(module)'")'b020=="CY"
			replace code="CZE" if `=lower("`r(module)'")'b020=="CZ"
			replace code="DEU" if `=lower("`r(module)'")'b020=="DE"
			replace code="DNK" if `=lower("`r(module)'")'b020=="DK"
			replace code="EST" if `=lower("`r(module)'")'b020=="EE"
			replace code="GRC" if `=lower("`r(module)'")'b020=="EL" | `=lower("`r(module)'")'b020=="GR"
			replace code="ESP" if `=lower("`r(module)'")'b020=="ES"
			replace code="FIN" if `=lower("`r(module)'")'b020=="FI"
			replace code="FRA" if `=lower("`r(module)'")'b020=="FR"
			replace code="HUN" if `=lower("`r(module)'")'b020=="HU"
			replace code="IRL" if `=lower("`r(module)'")'b020=="IE"
			replace code="ISL" if `=lower("`r(module)'")'b020=="IS"
			replace code="ITA" if `=lower("`r(module)'")'b020=="IT"
			replace code="LTU" if `=lower("`r(module)'")'b020=="LT"
			replace code="LUX" if `=lower("`r(module)'")'b020=="LU"
			replace code="LVA" if `=lower("`r(module)'")'b020=="LV"
			replace code="MLT" if `=lower("`r(module)'")'b020=="MT"
			replace code="NLD" if `=lower("`r(module)'")'b020=="NL"
			replace code="NOR" if `=lower("`r(module)'")'b020=="NO"
			replace code="POL" if `=lower("`r(module)'")'b020=="PL"
			replace code="PRT" if `=lower("`r(module)'")'b020=="PT"
			replace code="ROU" if `=lower("`r(module)'")'b020=="RO"
			replace code="SRB" if `=lower("`r(module)'")'b020=="RS"
			replace code="SWE" if `=lower("`r(module)'")'b020=="SE"
			replace code="SVN" if `=lower("`r(module)'")'b020=="SI"
			replace code="SVK" if `=lower("`r(module)'")'b020=="SK"
			replace code="GBR" if `=lower("`r(module)'")'b020=="UK"
			replace code="HRV" if `=lower("`r(module)'")'b020=="HR"
			replace code="CHE" if `=lower("`r(module)'")'b020=="CH"			
		}
	}

	* Merge between modules	
	if `=wordcount("`module'")'  >1 {
		local filenames
		local filedates
		local modules
		local indm
		local hhm
		foreach m of local module {
			if inlist(upper("`m'"), $indmlist) local indm `"`indm' `m'"'
			if inlist(upper("`m'"), $hhmlist) local hhm `"`hhm' `m'"'
		}
		** Get individual modules
		if wordcount("`indm'") >0 {
			foreach m0 of local indm {
				global para1 `para1'
				global para2 `para2'
				global para3 `para3'
				global para4 `para4'		
				if ("`para1'"=="") global para1 ${type2}_`m0'
				else {
					if ("`para2'"=="") global para2 ${type2}_`m0'
					else {
						if ("`para3'"=="") global para3 ${type2}_`m0'
						else {
							if ("`para4'"=="") global para4 ${type2}_`m0'
							else {
								dis as error "Too many conditions (para1-4 and `cond'), please redefine the parameters."
								error 1
							}
						}
					}
				}
				tempfile d`m0'				
				if "`=lower("`fileserver'")'"=="fileserver" cap noisily filesearch,  col($type2) country(`country') year(`year') root($root) subfolders($subfolders) surveyid(`surveyid') combstring(${type}_`m0'$ext `version' `filename') `latest' `nometa' /*save("`data2'")  */
				else                                        cap noisily filesearchw2, token(`token') col($type2) country(`country') year(`year') server($rootname) surveyid(`surveyid') filename(`filename') folder(`folder') para1($para1) para2($para2) para3($para3) para4($para4) `latest' `nometa' `net' /*save("`data2'")  */
				local filenames "`filenames' `r(filename)';"
				local filedates "`filedates' `r(filedate)';"
				local modules "`modules' `r(module)'"
				global surveyid  `r(surveyid)' //new sep 22 2016
				if strpos("`r(surveyid)'","EU-SILC")>0 & (upper("`r(module)'")=="P" | upper("`r(module)'")=="R") { //EU-SILC UDB-C hhid
					cap confirm variable hhid
					if _rc==0 {
						clonevar hhid_n = hhid
						clonevar pid_n = pid
					}
					else {
						*gen double hhid_n = int(`=lower("`r(module)'")'b030/100)
						gen double hhid_n = `=lower("`r(module)'")'x030 // changed Feb 2 2018 based on Eurostat email
						gen double pid_n  = `=lower("`r(module)'")'b030
					}
					clonevar year_n = `=lower("`r(module)'")'b010
					cap clonevar `=lower("`r(module)'")'b020 = country0
					clonevar ctry_n = `=lower("`r(module)'")'b020					
					order year_n ctry_n hhid_n pid_n
					global hhid year_n ctry_n hhid_n
					global pid pid_n
					
					//Add code to the database
					qui {
						cap drop code
						gen str6 code=""
						replace code="AUT" if `=lower("`r(module)'")'b020=="AT"
						replace code="BEL" if `=lower("`r(module)'")'b020=="BE"
						replace code="BGR" if `=lower("`r(module)'")'b020=="BG"
						replace code="CYP" if `=lower("`r(module)'")'b020=="CY"
						replace code="CZE" if `=lower("`r(module)'")'b020=="CZ"
						replace code="DEU" if `=lower("`r(module)'")'b020=="DE"
						replace code="DNK" if `=lower("`r(module)'")'b020=="DK"
						replace code="EST" if `=lower("`r(module)'")'b020=="EE"
						replace code="GRC" if `=lower("`r(module)'")'b020=="EL" | `=lower("`r(module)'")'b020=="GR"
						replace code="ESP" if `=lower("`r(module)'")'b020=="ES"
						replace code="FIN" if `=lower("`r(module)'")'b020=="FI"
						replace code="FRA" if `=lower("`r(module)'")'b020=="FR"
						replace code="HUN" if `=lower("`r(module)'")'b020=="HU"
						replace code="IRL" if `=lower("`r(module)'")'b020=="IE"
						replace code="ISL" if `=lower("`r(module)'")'b020=="IS"
						replace code="ITA" if `=lower("`r(module)'")'b020=="IT"
						replace code="LTU" if `=lower("`r(module)'")'b020=="LT"
						replace code="LUX" if `=lower("`r(module)'")'b020=="LU"
						replace code="LVA" if `=lower("`r(module)'")'b020=="LV"
						replace code="MLT" if `=lower("`r(module)'")'b020=="MT"
						replace code="NLD" if `=lower("`r(module)'")'b020=="NL"
						replace code="NOR" if `=lower("`r(module)'")'b020=="NO"
						replace code="POL" if `=lower("`r(module)'")'b020=="PL"
						replace code="PRT" if `=lower("`r(module)'")'b020=="PT"
						replace code="ROU" if `=lower("`r(module)'")'b020=="RO"
						replace code="SRB" if `=lower("`r(module)'")'b020=="RS"
						replace code="SWE" if `=lower("`r(module)'")'b020=="SE"
						replace code="SVN" if `=lower("`r(module)'")'b020=="SI"
						replace code="SVK" if `=lower("`r(module)'")'b020=="SK"
						replace code="GBR" if `=lower("`r(module)'")'b020=="UK"
						replace code="HRV" if `=lower("`r(module)'")'b020=="HR"
						replace code="CHE" if `=lower("`r(module)'")'b020=="CH"
					} 						
				}
				cap destring year_n hhid_n $pid, force replace
				cap destring year, force replace
				qui save `d`m0'', replace
				clear					
			}
			
			** Merge individual modules
			tempfile inddata			
			tokenize `indm'
			qui if wordcount("`indm'") >1 {					
				use `d`1'', clear
				forv j=2(1)`=wordcount("`indm'")' {
					merge 1:1 $hhid $pid using `d``j''', gen(_m`1'``j'')
					// Check condition of merge
					save `inddata', replace					
				}
			}
			qui else {					
				use `d`1'', clear
				save `inddata', replace				
			}			
		}
		
		** Get household modules
		if wordcount("`hhm'") >0 {
			foreach m0 of local hhm {
				global para1 `para1'
				global para2 `para2'
				global para3 `para3'
				global para4 `para4'	 	
				if ("`para1'"=="") global para1 ${type2}_`m0'
				else {
					if ("`para2'"=="") global para2 ${type2}_`m0'
					else {
						if ("`para3'"=="") global para3 ${type2}_`m0'
						else {
							if ("`para4'"=="") global para4 ${type2}_`m0'
							else {
								dis as error "Too many conditions (para1-4 and `cond'), please redefine the parameters."
								error 1
							}
						}
					}
				}
				tempfile d`m0'
				** get info
				if "`=lower("`fileserver'")'"=="fileserver" cap noisily filesearch, col($type2) country(`country') year(`year') root($root) subfolders($subfolders) surveyid(`surveyid') combstring(${type}_`m0'$ext `version' `filename') `latest' `nometa' /*save("`data2'")  */
				else                                        cap noisily filesearchw2, token(`token') col($type2) country(`country') year(`year') server($rootname) surveyid(`surveyid') filename(`filename') folder(`folder') para1($para1) para2($para2) para3($para3) para4($para4) `latest' `nometa' `net' /*save("`data2'")  */
				local filenames "`filenames' `r(filename)';"
				local filedates "`filedates' `r(filedate)';"
				local modules "`modules' `r(module)'"
				global surveyid  `r(surveyid)' //new sep 22 2016
				if strpos("`r(surveyid)'","EU-SILC")>0 & (upper("`r(module)'")=="D" | upper("`r(module)'")=="H") { //EU-SILC UDB-C hhid
					cap confirm variable hhid 
					if _rc==0 clonevar hhid_n = hhid
					else      clonevar hhid_n = `=lower("`r(module)'")'b030
					cap clonevar year_n = `=lower("`r(module)'")'b010
					cap clonevar `=lower("`r(module)'")'b020 = country0
					cap clonevar ctry_n = `=lower("`r(module)'")'b020
					order year_n ctry_n hhid_n 
					global hhid year_n ctry_n hhid_n 
					
					//Add code to the database
					qui {					
						cap drop code
						gen str6 code=""
						replace code="AUT" if `=lower("`r(module)'")'b020=="AT"
						replace code="BEL" if `=lower("`r(module)'")'b020=="BE"
						replace code="BGR" if `=lower("`r(module)'")'b020=="BG"
						replace code="CYP" if `=lower("`r(module)'")'b020=="CY"
						replace code="CZE" if `=lower("`r(module)'")'b020=="CZ"
						replace code="DEU" if `=lower("`r(module)'")'b020=="DE"
						replace code="DNK" if `=lower("`r(module)'")'b020=="DK"
						replace code="EST" if `=lower("`r(module)'")'b020=="EE"
						replace code="GRC" if `=lower("`r(module)'")'b020=="EL" | `=lower("`r(module)'")'b020=="GR"
						replace code="ESP" if `=lower("`r(module)'")'b020=="ES"
						replace code="FIN" if `=lower("`r(module)'")'b020=="FI"
						replace code="FRA" if `=lower("`r(module)'")'b020=="FR"
						replace code="HUN" if `=lower("`r(module)'")'b020=="HU"
						replace code="IRL" if `=lower("`r(module)'")'b020=="IE"
						replace code="ISL" if `=lower("`r(module)'")'b020=="IS"
						replace code="ITA" if `=lower("`r(module)'")'b020=="IT"
						replace code="LTU" if `=lower("`r(module)'")'b020=="LT"
						replace code="LUX" if `=lower("`r(module)'")'b020=="LU"
						replace code="LVA" if `=lower("`r(module)'")'b020=="LV"
						replace code="MLT" if `=lower("`r(module)'")'b020=="MT"
						replace code="NLD" if `=lower("`r(module)'")'b020=="NL"
						replace code="NOR" if `=lower("`r(module)'")'b020=="NO"
						replace code="POL" if `=lower("`r(module)'")'b020=="PL"
						replace code="PRT" if `=lower("`r(module)'")'b020=="PT"
						replace code="ROU" if `=lower("`r(module)'")'b020=="RO"
						replace code="SRB" if `=lower("`r(module)'")'b020=="RS"
						replace code="SWE" if `=lower("`r(module)'")'b020=="SE"
						replace code="SVN" if `=lower("`r(module)'")'b020=="SI"
						replace code="SVK" if `=lower("`r(module)'")'b020=="SK"
						replace code="GBR" if `=lower("`r(module)'")'b020=="UK"
						replace code="HRV" if `=lower("`r(module)'")'b020=="HR"
						replace code="CHE" if `=lower("`r(module)'")'b020=="CH"
					} 
				}				
				cap destring year_n hhid_n , force replace 
				cap destring year, force replace
				qui save `d`m0'', replace
				clear
			}
			
			** Merge HH modules
			tempfile hhsdata			
			tokenize `hhm'
			qui if wordcount("`hhm'") >1 {					
				use `d`1'', clear
				forv j=2(1)`=wordcount("`hhm'")' {
					merge 1:1 $hhid using `d``j''', gen(_m`1'``j'')
					// Check condition of merge
					save `hhsdata', replace
				}
			}
			qui else {					
				use `d`1'', clear
				save `hhsdata', replace
			}
		}
		
		// Merge HH and individual
		qui if `=wordcount("`indm'")' >0 & `=wordcount("`hhm'")'==0 use `inddata', clear
		qui if `=wordcount("`indm'")'==0 & `=wordcount("`hhm'")' >0 use `hhsdata', clear
		qui if `=wordcount("`indm'")' >0 & `=wordcount("`hhm'")' >0 {
			use `hhsdata', clear
			merge 1:m $hhid using `inddata', gen(_mhhind)
		}
		local rc = _rc
		
		return local type `r(type)'
		return local module `modules'
		return local verm `r(verm)'
		return local vera `r(vera)'
		return local surveyid  `r(surveyid)'
		return local filename `filenames'
		return local filedate `filedates'
		return local idno `r(idno)'
		if "$surveyid"=="" global surveyid  `r(surveyid)'
		global f1name `r(filename)'
	} //merge between modules

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
					
					if "${${rootname}CPI_date}"~="" {
						if (date("$S_DATE", "DMY")-date("${${rootname}CPI_date}", "DMY")) <= $updateday {
							cap use "`persdir'datalibweb\data\\${rootname}\\${cpic}\\${cpic}_${cpiy}_CPI\\${r${rootcpi}cpivin}\\Data\Stata\\${cpifile}", clear	
							if _rc==0 local cpino = 1
							else local dl 1
						}
						else local dl 1						
					}
					else { 
						cap confirm file "`persdir'datalibweb\data\\${rootname}\\${cpic}\\${cpic}_${cpiy}_CPI\\${r${rootcpi}cpivin}\\Data\Stata\\${cpifile}"
						if _rc==0 {
							cap use "`persdir'datalibweb\data\\${rootname}\\${cpic}\\${cpic}_${cpiy}_CPI\\${r${rootcpi}cpivin}\\Data\Stata\\${cpifile}", clear
							if _rc==0 {
								local dtadate : char _dta[version]			
								if (date("$S_DATE", "DMY")-date("`dtadate'", "DMY")) > $updateday local dl 1
								else {
									local cpino = 1
									global ${rootname}CPI_date `dtadate'
								}
							}
							else local dl 1
						}
						else {
							cap mkdir "`persdir'datalibweb\data\\${rootname}"
							cap mkdir "`persdir'datalibweb\data\\${rootname}\\${cpic}"
							cap mkdir "`persdir'datalibweb\data\\${rootname}\\${cpic}\\${cpic}_${cpiy}_CPI"
							cap mkdir "`persdir'datalibweb\data\\${rootname}\\${cpic}\\${cpic}_${cpiy}_CPI\\${r${rootcpi}cpivin}"
							cap mkdir "`persdir'datalibweb\data\\${rootname}\\${cpic}\\${cpic}_${cpiy}_CPI\\${r${rootcpi}cpivin}\\Data"
							cap mkdir "`persdir'datalibweb\data\\${rootname}\\${cpic}\\${cpic}_${cpiy}_CPI\\${r${rootcpi}cpivin}\\Data\Stata"				
							local dl 1
						}
					}
					
					if `dl'==1 {
						if "$DATALIBWEB_VERSION"=="1" dlw_api, option(0) outfile(`tempcpi') query("$cpiw")
						else dlw_api_v2, option(0) outfile(`tempcpi') query("$cpiw")
						if `dlibrc'==0 {
							if "`dlibFileName'"~="ECAFileinfo.csv" {			
								use `tempcpi', clear
								char _dta[version] $S_DATE							
								compress
								cap mkdir "`persdir'datalibweb\data\\${rootname}"
								cap mkdir "`persdir'datalibweb\data\\${rootname}\\${cpic}"
								cap mkdir "`persdir'datalibweb\data\\${rootname}\\${cpic}\\${cpic}_${cpiy}_CPI"
								cap mkdir "`persdir'datalibweb\data\\${rootname}\\${cpic}\\${cpic}_${cpiy}_CPI\\${r${rootcpi}cpivin}"
								cap mkdir "`persdir'datalibweb\data\\${rootname}\\${cpic}\\${cpic}_${cpiy}_CPI\\${r${rootcpi}cpivin}\\Data"
								cap mkdir "`persdir'datalibweb\data\\${rootname}\\${cpic}\\${cpic}_${cpiy}_CPI\\${r${rootcpi}cpivin}\\Data\Stata"	
								saveold "`persdir'datalibweb\data\\${rootname}\\${cpic}\\${cpic}_${cpiy}_CPI\\${r${rootcpi}cpivin}\\Data\Stata\\${cpifile}", replace	
								local cpino = 1
								global ${rootname}CPI_date $S_DATE
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
				cap destring year, replace
				cap gen str code = "`=upper("`country'")'"   //need to be removed later
				cap gen year = `year'                        //need to be removed later			
				qui if strpos("$surveyid)","EU-SILC")>0 replace year = year - 1				//EUSILC year
				//datalevel  
				local cpilevel				
				if "`=upper("$type")'"=="GPWG" | "`=upper("$type")'"=="GMD" | "`=upper("$type")'"=="SSAPOV" | "`=upper("$type")'"=="PCN" {	
					cap drop datalevel
					local cpilevel datalevel survname
					qui if "`=upper("`country'")'"=="IDN" | "`=upper("`country'")'"=="CHN" | "`=upper("`country'")'"=="IND" gen datalevel = urban						
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
					if "`=upper("`country'")'"=="IDN" gen datalevel = urban
					else gen datalevel = 2						
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
				if "`=upper("$type")'"=="GLAD" { //GLAD March 17 2020
					
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
			}
		} //_rc save
	}
end
