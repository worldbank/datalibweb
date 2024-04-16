program define datalibweb_v2, rclass	
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
	
	_display_logo		// display datlaibweb logo	

	global dlw_update = 0
	local user = c(username)

	datalibweb_update, user("`user'")	
	if $dlw_update==1 {
		clear all
		discard
		cap program drop datalibweb
		exit
	}
	if "`=upper("`update'")'"=="ADO" dlw_adoupdate
	if "`=upper("`update'")'"=="DATA" dlw_dataupdate
	if "`=upper("`update'")'"=="CACHE" dlw_cacheupdate
	
	// gui	
	capture program define dlwgui, plugin using("dlib2g_`=cond(strpos(`"`=c(machine_type)'"',"64"),64,32)'.dll")		

	// Global datalibweb error code
	global errcode 0
	
	** Housekeeping check
	if ("`cpivintage'"~="" &  strpos("`=lower("`cpivintage'")'","v")==0) local cpivintage v`cpivintage'
	if ("`vermast'" != "" & "`=upper("`vermast'")'" != "WRK") if strpos("`=lower("`vermast'")'","v")==0 local vermast v`vermast'
	if ("`veralt'" != "" & "`=upper("`veralt'")'" != "WRK")  if strpos("`=lower("`veralt'")'","v")==0  local veralt v`veralt'
	if ("`vintage'" != "" & ( "`country'" != "" | "`years'" != "" | "`survey'" != "" | "`append'" == "append") ) {
		di in red "You cannot specify country, years, survey acronyms or the append option with the vintage option" _new
		global errcode 198
		error 198
	}
	if ("`local'"~="" & "`getfile'"~="") {
		di in red `"You cannot specify option "local" and "getfile" together."' _new
		global errcode 198
		error 198
	}
	if ("`local'"~="" & "`fileserver'"~="") {
		di in red `"You cannot specify option "local" and "fileserver" together."' _new
		global errcode 198
		error 198
	}
	* Circa and years error
	if ( "`years'" != "" & "`circa'" != "") {
		di as error "You must specify either circa or years option but not both"
		global errcode 198
		error 198
	}
	* ppp and incppp
	local allppp 2005 2011 2017
	local ppp : list uniq ppp
	if `:list ppp in allppp'==0 {
		di as error "You must specify either ppp() as 2005 and/or 2011"
		global errcode 198
		error 198
	}
	
	if  ("`ppp'" == "" & "`incppp'" != "") | ("`ppp'" == "" & "`plppp'" != "") {
		di as error "You must specify both ppp() with incppp() and/or plppp()"
		global errcode 198
		error 198
	}
	**  info and fileserver	
	if ("`info'" == "info" & "`fileserver'" == "") {
		disp in red "Info option not available"
		error 198
	}
	//Do API later on the subscriptions
	************************NEW***************************************
	* Selection of country, region and type when nor provided by user
	*******************************************************************		
	if ( "`vintage'" == "" &  "`country'" == "" & "`region'" == ""  & "`type'" == "" & "`repository'" == "") {  /* NEW */				
		disp in y _n "{ul: Select the region/group of your country/countries of analysis:}" _n
		noi di as text "{hline 13}{c TT}{hline 36}"
		noi disp in g _col(2) "Region/group" _col(14) "{c |}"
		noi disp in g _col(2) "Code" _col(14) "{c |}" _col(25) "Region/group name"
		noi di as text "{hline 13}{c +}{hline 36}"		
		foreach reg in EAP ECA LAC MNA SAR SSA NAC Others {
			local inst "stata datalibweb_inventory, region(`reg') `info': `reg'" // instruction 				
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
			noi disp _col(4) `"{`inst'}"' in g _col(14) "{c |}" in y _col(`=47-length("`regname'")') "`regname'" 
		}	// end of display regions loop
		noi di as text "{hline 13}{c BT}{hline 36}"
		exit 
	}
	
	** If user specified region
	if ( "`vintage'" == "" &  "`country'" == "" & "`region'" != "" & "`repository'" == "") {  /* NEW */
		datalibweb_inventory, region(`region') `info'
		exit 
	}
	** If user specified type
	if ( "`vintage'" == "" &  "`country'" == "" & "`type'" != "" & "`repository'" == "") {  /* NEW */
		datalibweb_inventory, type(`type') `info'
		exit 
	}

	***********************************************************************	
	global ext
	if "`filename'"=="" {
		if "`ext'"=="" global ext .dta
		else           global ext `ext'
	}
	* Type Conditions
	// reset global
	local resetlist hhid pid idmod defmod hhmlist indmlist period root rootname subfolders data doc prog token updateday type base basedeffile cpifile cpic cpiy cpif cpi cpiw rootcpi cpivarw distxt email surveyid
	foreach gl of local resetlist {
		global `gl'
	}
		
	tempfile tempcpi
	global nocpi
	global nometa
	if "`nocpi'"=="nocpi"  global nocpi nocpi
	if "`nometa'"=="nometa"  global nometa nometa
	///RAW and harmonized data collections
	if ("`=upper("`type'")'" == "EUSILC") | ("`=upper("`type'")'" == "EU-SILC") local type UDB-C
	if ("`=upper("`type'")'" == "EUHBS") | ("`=upper("`type'")'" == "EU-HBS") local type SUF-C
	if ("`=upper("`type'")'" == "EU-SILC-L") | ("`=upper("`type'")'" == "UDB-L") local type UDB-L
	if ("`=upper("`type'")'" == "LABLAC")  local type LABLAC-01
	if ("`=upper("`type'")'" == "SEDLAC")  local type SEDLAC-03
	if ("`=upper("`type'")'" == "GPWG")  local type GMD
	// EAP second portal
	if ("`=upper("`type'")'" == "EAPPOV-W")  local type EAPPOV
	
	//Country fix to make sure past codes run
	if "`=upper("`country'")'"=="KSV" local country XKX
	
	//check if .do is available	
	local persdir : sysdir PERSONAL
    if "$S_OS"=="Windows" local persdir : subinstr local persdir "/" "\", all
		
	cap confirm file "`persdir'datalibweb/`=upper("`type'")'.do"
	if _rc==0 { //available and load
		qui do "`persdir'datalibweb/`=upper("`type'")'.do"
	}
	else { //not available
		//check installation again
		tempfile zpfile
		local cdir `c(pwd)'		
		qui set checksum off		          
		qui copy "http://ecaweb.worldbank.org/povdata/statapackages/d/datalibweb/d/datalibweb_ini.zip" "`zpfile'", replace 
		//qui cd "`other'"
		qui cap mkdir "`persdir'datalibweb"
		qui cd "`persdir'datalibweb"		
		qui cap unzipfile "`zpfile'", replace // name of zip file. 
		if _rc==0 { //_rc unzip
			cap confirm file "`persdir'datalibweb/`=upper("`type'")'.do"
			if _rc==0 { //available and load
				qui do "`persdir'datalibweb/`=upper("`type'")'.do"
			}
			else { //still not available
				//display error
				di in red "The type -`type'- you entered is not available. Please check the help file for the list of avaiable types." _new
				global errcode 198
				error 198
			}
		} //_rc unzip
		else { //_rc unzip
			di in red "Unable to update the setup files. Please check with the system administrator." _new
			global errcode 198
			error 198
		} //_rc unzip	
		qui cd "`cdir'"
	}
	
	//reset the global for the base option
	if "`base'"=="base" {
		if "$base"~="" {
			if (`=strpos("$base", "\")'>0 | `=strpos("$base", "/")'>0) {
				global subfolders $base
				global defmod 
				local para1 $basedeffile
			}
			else {
				local para1 $base
				global type $base
			}
		}
		else {
			di in red "This type ($type) has no base option. Please check with the collection admin." _new
			global errcode 198
			error 198
		}
	}
		
	//add period option May 15th 2019
	if ("`period'"~="") {
		local period = "`=upper("`period'")'"
	}
	else {
		local period ${period}
		if ("`country'"=="ARG" & inlist("`type'","SEDLAC-02","SEDLAC-03")) local period = "S2"
	}	
	
	// load default or allmodules
	if "`module'"~="" local module `=upper("`module'")'
	if ("`repository'"=="") {
		if "`module'"=="" & "`filename'"=="" local module $defmod
		if "`allmodules'"=="allmodules" local module $hhmlist $indmlist
	}

	//localpath for local or getfile options
	if "`localpath'"~="" { 
		dircheck "`localpath'"
		if r(confdir)~=0 {
			di in red `"The path you provided (`localpath') is not correct. Please check it."' _new
			global errcode 170
			error 170
		}
	}
	else {
		cap mkdir "`persdir'datalibweb\\data\\$rootname"
		local localpath "`persdir'datalibweb\\data\\$rootname"
	}
	
	//old fileserver option still run
	if "`fileserver'"~="" {
		if "$root"=="" local fileserver
		else           local fileserver fileserver
	}
	
	//CPIVintage() - new Feb 17 2018
	if ($token~=5 & "$nocpi"=="") { //RAW
		local dl 0
		local code `"cap mata: mata describe ${rootcpi}_cpidata"' //check data in memory			
		`code'
		global nomatacpi = _rc
		if $nomatacpi==0 {	
			if (date("$S_DATE", "DMY")-date("${${rootcpi}_cpivindate}", "DMY")) >0 local dl 1
		}
		else local dl 1
			
		qui if `dl'==1 {
			tempfile cattmp
			cap dlw_catalog, savepath("`cattmp'") server(${rootcpi}) fullonly
			if _rc==0 {
				use `cattmp', clear
				replace code = upper(code)
				keep if code=="`=upper("${cpic}")'" & year==${cpiy} //as per setting
				keep if upper(filename)=="`=upper("$cpifile")'"
				split surveyid, p("_")
				ren surveyid4 verm
				replace verm = lower(verm)
				drop surveyid1 surveyid2 surveyid3 surveyid5
				bys country year survey (verm): gen l = _n==_N
				gen col = "${rootcpi}"
				cap tostring year, replace
				cap putmata ${rootcpi}_cpidata = (code year survey col verm surveyid), replace
				if _rc==0 {
					global ${rootcpi}_cpivindate $S_DATE
					global nomatacpi 0
				}
				keep if l==1
				global l${rootcpi}cpivin = surveyid[1]	
				clear
			}
			else {
				noi di as yellow `"Failed to updated the cpivintage data. Using the first vintage: ${cpic}_${cpiy}_CPI_v01_M"' _new
				global l${rootcpi}cpivin ${cpic}_${cpiy}_CPI_v01_M
			}
		} //end of dl cpivintage
		
		if "`cpivintage'"~="" {
			local code `"mata: _fselectdata(${rootcpi}_cpidata, "`=upper("${cpic}")'", "${cpiy}", "${rootcpi}", "`cpivintage'")"'
			`code'
			local cpivin `loc_name_'
			if "`cpivin'"=="" {
				noi di as error `"The requested cpivintage(`cpivintage') is not available. Please check and change it."' _new
				global errcode 170
				error 170
			}
			else global r${rootcpi}cpivin `cpivin'
		}
		else global r${rootcpi}cpivin ${l${rootcpi}cpivin} //use latest
		if `"${cpiw}"'~="" global cpiw ${cpiw}&para1=${r${rootcpi}cpivin}   
	} //only for harmonized data
	
	global localpath `localpath'
	if "`local'"~="" {
		global root "$localpath"
		if "`cpilocal'"~="" {
			cap confirm file "`cpilocal'"
			if _rc==0 global cpi `cpilocal'
			else {
				noi di in red `"The path and filename you provided for CPI (`cpipath') is not correct. Please check it."' _new
				global errcode 170
				error 170
			}
		}
		else {
			noi di in yellow "The cpilocal() option is not specified. You are using the default/sysyem CPI database."
			global cpi "`persdir'datalibweb\\data\\$rootname\\${cpic}\\${cpic}_${cpiy}_CPI\\${r${rootcpi}cpivin}\\Data\Stata\\${cpifile}"
		}
		local fileserver fileserver
	}
	
	// return
	return local type `type'
	return local module `module'
	return local cmdline datalibweb `cmdline'
	return local cpivin ${rootcpi} ${r${rootcpi}cpivin}
	return local cpifile $cpifile
	global dlcmd `cmdline'
	global type2 $type
	if $token==5 { //RAW
		global nocpi nocpi
		if "`=lower("`fileserver'")'"~="fileserver" global type2 
	}
	
	_display_disclaimer
	
	// Repo options
	if ("`repository'" != "") { //adopted from datalib
		//check and confirm the reporoot
		if ("`reporoot'" ~= "") {
			dircheck "`reporoot'"
			if r(confdir)~=0 {
				noi di in red `"The path you provided (`reporoot') is not correct. Please check it."' _new
				global errcode 170
				error 170
			}
		}
		else {
			cap mkdir "`persdir'datalibweb\\data"
			local reporoot "`persdir'datalibweb\\data"
		}
		
		//repo options
		local nword: word count `repository' 								            // number of words on repository local
		lstrfun repoins, regexms(`"`repository'"', `"^([a-z]+)"', 1) 			        // instruction in repository (first word)
		lstrfun reponame, regexms(`"`repository'"', `"^([a-z]+) ([a-zA-Z0-9_\-]+)"', 2) // name of repository file
		if (`nword' == 3) lstrfun repopt, regexms(`"`repository'"', `"([a-z]+)$"', 1) 	// name of repository file
		else local repopt ""
		
		//Check additional options to go with repository: country, year, region, vera(0X) or vera(wrk)
		if "`veralt'"~="" | "`vermast'"~="" {
			if "`=upper("`veralt'")'"=="WRK" local reopt1 wrkvintage
			else local reopt1 allvintages			
		}
		
		if (!inlist("`repoins'","create", "query", "use" ,"erase", "usefile")) {
			noi disp in red "The first instruction in repository option must be: create, query, use, usefile, or erase."
			global errcode 198
			error 198
		}
		// Create repository - latest
		if ("`repoins'" == "create") {
			tempfile cattmp ctryregname
			dlw_countryname, savepath(`ctryregname')
			cap dlw_catalog, savepath("`cattmp'") server($rootname) `reopt1'
			qui if _rc==0 {
				cap use "`cattmp'", clear
				if _rc==0 {
					merge m:1 code using `ctryregname', keep(master match) nogen
					cap tostring year, replace
					cap tostring mod, replace
					ren code country
					ren mod module
					ren year years
					split surveyid, p("_")
					ren surveyid4 vermast
					ren surveyid6 veralt
					replace vermast = upper(vermast)
					replace veralt = upper(veralt)
					drop surveyid1 surveyid2 surveyid3 surveyid5 surveyid7 surveyid8
					save "`cattmp'", replace
				}
			}
			else {
				noi dis as error "Cannot create the repository (latest) file for $rootname."
				global errcode 198
				error 198
			}
					
			qui if "`repopt'"=="" { //newfile
				cap confirm new file "`reporoot'/repo_`reponame'.dta"
				if _rc==0 {
					foreach clx0 in region country years module vermast veralt {
						if "``clx0''"~="" {
							local clx2
							local ofx of
							if "`clx0'"=="years" local clx2 numlist
							else                 local ofx in
							local inlist
							foreach clx1 `ofx' `clx2' ``clx0'' {
								local inlist `"`inlist' ,"`=upper("`clx1'")'""'
							}
							keep if inlist(`clx0'`inlist')
						}	
					}					
					if _N>0 {
						save "`cattmp'", replace			
						cap copy "`cattmp'" "`reporoot'/repo_`reponame'.dta"
						if _rc==0 noi dis as text in yellow "Repository is created - `reporoot'/repo_`reponame'.dta"
						else noi dis as error "Cannot create the repository (latest) file for $rootname."
					}
					else {
						noi dis as error "Nothing found based on specified parameters - Cannot create the repository (latest) file for $rootname."
					} //_N
				} //_rc
				else {
					noi dis "{err}Filename already exists or could not be opened"
					global errcode 198
					error 198
				}
			} //newfile
			
			qui if "`repopt'"=="replace" { //replace 
				cap confirm file "`reporoot'/repo_`reponame'.dta"
				if _rc==0 {								
					foreach clx0 in region country years module vermast veralt {
						if "``clx0''"~="" {
							local clx2
							local ofx of
							if "`clx0'"=="years" local clx2 numlist
							else                 local ofx in
							local inlist
							foreach clx1 `ofx' `clx2' ``clx0'' {
								local inlist `"`inlist' ,"`=upper("`clx1'")'""'
							}
							keep if inlist(`clx0'`inlist')
						}	
					}
					if _N>0 {
						save "`cattmp'", replace	
						cap copy "`cattmp'" "`reporoot'/repo_`reponame'.dta", replace
						if _rc==0 noi dis as text in yellow "Repository is created - `reporoot'/repo_`reponame'.dta"
						else noi dis as error "Cannot create the repository (latest) file for $rootname."
					}
					else {
						noi dis as error "Nothing found based on specified parameters - Cannot create the repository (latest) file for $rootname."
					} //_N
				}
				else {
					noi dis "{err}No filename exists or could not be opened"
					global errcode 198
					error 198
				}		
			} //replace
			
			qui if "`repopt'"=="append" {  //Other options: append, update repo
				cap confirm file "`reporoot'/repo_`reponame'.dta"
				if _rc==0 {	
					foreach clx0 in region country years module vermast veralt {
						if "``clx0''"~="" {
							local clx2
							local ofx of
							if "`clx0'"=="years" local clx2 numlist
							else                 local ofx in
							local inlist
							foreach clx1 `ofx' `clx2' ``clx0'' {
								local inlist `"`inlist' ,"`=upper("`clx1'")'""'
							}
							keep if inlist(`clx0'`inlist')
						}	
					}
					if _N>0 {
						save "`cattmp'", replace
						use "`reporoot'/repo_`reponame'.dta", clear						
						merge 1:1 country years survname col module using "`cattmp'", update replace nogen
						cap saveold "`reporoot'/repo_`reponame'.dta", replace
						if _rc==0 noi dis as text in yellow "Repository is updated - `reporoot'/repo_`reponame'.dta"
						else noi dis as error "Cannot update the repository (latest) file for $rootname."
					}
					else {
						noi dis as error "Nothing found based on specified parameters - Cannot append the repository (latest) file for $rootname."
					}
				}
				else {
					noi dis "{err}No filename exists or could not be opened"
					global errcode 198
					error 198
				}
			}
			exit
		} //create
		
		// Use repository
		if ("`repoins'" == "use") {		
			local dl 0
			local code `"cap mata: mata describe `reponame'_data"' //check data in memory			
			`code'
			global nomata = _rc	
			if $nomata==0 {			
				if (date("$S_DATE", "DMY")-date("${`reponame'_date}", "DMY")) > 0 local dl 1 //daily reload
			}
			else local dl 1
			
			if `dl'==1 {
				cap use "`reporoot'/repo_`reponame'.dta", clear
				if _rc==0 {
					cap tostring year, replace
					cap tostring mod, replace
					cap putmata `reponame'_data = (country years survname col module filename), replace
					if _rc==0 {
						global `reponame'_date $S_DATE
						global nomata 0
					}
				}	
				else {
					global nomata 1
					noi dis "{err}No filename exists or could not be opened"
					global errcode 198
					error 198
				}
			} //load repo into mata			
		} //repo use
		
		// Usefile repository
		if ("`repoins'" == "usefile") {
			if ("`repofile'" ~= "") {		
				cap use "`repofile'", clear
				if _rc==0 {
					cap tostring year, replace
					cap tostring mod, replace
					cap putmata repofile_data = (country years survname col module filename), replace
					if _rc==0 {
						global repofile_date $S_DATE
						global nomata 0
					}
				} //load the file
				else { //cant load the repofile
					global nomata 1
					noi dis "{err}unable to load the repofile: "`repofile'". Please check the contents and path, it should be a Stata file."
					global errcode 198
					error 198
				}
			} //repofile() is available		
			else { //repofile() is empty
				global nomata 1
				noi dis "{err}repofile() option is not specified. It should be use together with repo(usefile)"
				global errcode 198
				error 198
			}			
		} //repo usefile
		
		// Query
		if ( "`repoins'" == "query") {
			local repos: dir "`reporoot'" files "repo_*.dta"
			noi disp in y "{title:Query of repository files}" _n
			local nrepo = 0
			foreach repo of local repos {
				local ++nrepo
				local repo: subinstr local repo "repo_" "", all
				local repo: subinstr local repo ".dta" "", all
				noi disp in y "`nrepo'." _col(4) "`repo'"
			} // end of loop by repo files
			exit 	// exit datalibweb ado
		}
		
		// Delete repository
		if ( "`repoins'" == "erase") {
			if ("`repopt'" != "force") {
				disp as err "you must specify force to delete a repository file"
				error 197
			}
			cap confirm new file "`reporoot'/repo_`reponame'.dta"
			if (_rc) {
				erase "`reporoot'/repo_`reponame'.dta"
				cap confirm file "`reporoot'/repo_`reponame'.dta"
				if (_rc) noi disp in g "Repository file `reponame' has been erased"
			} // end of confirmation of existence of file
			else {
				noi disp in red "Repository file `reponame' does not exist" _cont
				noi disp "{stata datalibweb, repository(query): Check here}"
				exit 		// exit datalibweb ado. 
			} // end of alternative when file does not exist
			exit // exit datalibweb ado.
		} //erase
		
	} // end of repository option. 
	
	//Request type: data, doc, prog	
	if "`request'"~="" {
		if ("`=upper("`request'")'"~="DATA") global nocpi nocpi
		local request `=lower("`request'")'
		if "${`request'}"~="" {
			if "`ext'"=="" global ext
			global nocpi nocpi
			foreach ctryx of local country {
				foreach yr of numlist `years' {
					foreach fld of global `request' {
						noi dis in yellow _newline "{p 4 4 2}For folder: `fld'{p_end}"
						cap noi _datalibcall_v2, country(`ctryx') year(`yr') type($type) token($token) vermast(`vermast') veralt(`veralt') folder(`fld') surveyid(`surveyid') para1(`para1') para2(`para2') para3(`para3') para4(`para4') $nocpi `fileserver' $nometa `base' `net' period(`period')
					}
				}
			}				
		}
		else {
			dis as error "The request(`request') is not available for this collection. Please check the system or the help file."
			global errcode 198
			error 198
		}
		exit
	}
	else local request data
	global request `request'
	
	//check data in memory
	if "`repository'"=="" {
		if ("`noupdate'"=="" & $token==8) {
			local dl 0
			local code `"cap mata: mata describe ${rootname}_data"'
			`code'
			global nomata = _rc	
			if $nomata==0 {
				if (date("$S_DATE", "DMY")-date("${${rootname}_date}", "DMY")) > $updateday local dl 1
			}
			else { //not available in memory $nomata~=0
				cap confirm file "`persdir'datalibweb/data/${rootname}_latest.dta"
				if _rc==0 { //file available
					cap use "`persdir'datalibweb/data/${rootname}_latest.dta", clear	
					if _rc==0 {
						local dtadate : char _dta[version]			
						if (date("$S_DATE", "DMY")-date("`dtadate'", "DMY")) > $updateday local dl 1
						else { //less than 5 days old, put to mata
							cap tostring year, replace
							cap putmata ${rootname}_data = (code year survname col mod filename), replace
							if _rc==0 global ${rootname}_date `dtadate'
							else {
								local dl 1
								dis as text in yellow "Catalog file is available locally but unable to load into memory. Reloading it now."
							}
						}
					} //file OK
					else local dl 1 //file not OK
				} //file available
				else { //not available, then download it
					qui cap mkdir "`persdir'datalibweb/data"
					local dl 1
				}
				
				if `dl'==1 { //download the catalog
					tempfile cattmp
					cap dlw_catalog, savepath("`cattmp'") server($rootname)
					if _rc==0 {
						cap use "`cattmp'", clear
						if _rc==0 {
							cap tostring year, replace
							cap putmata ${rootname}_data = (code year survname col mod filename), replace
							if _rc==0 {
								global ${rootname}_date $S_DATE
								global nomata 0
							}
							else global nomata _rc
							qui copy "`cattmp'" "`persdir'datalibweb/data/${rootname}_latest.dta", replace
						}	
					}
					else {  
						global nomata _rc
						dis as error "Cannot update the inventory (latest) file for $rootname."
					}
				}
			}
		}
		else global nomata 1 //noupdate
	}
	
	if "`getfile'"=="" { //Get the data for ctry and year
		tempfile alldata
		clear
		qui save `alldata', replace emptyok
		
		// Latesty option	
		if "`latesty'"~="" {
			foreach ctryx of local country {
				local wrong = 1
				local yr0 : di year(date("$S_DATE", "DMY"))
				while `wrong'==1 {
					if "`repository'" != "" {
						if ($nomata==0 & "`=lower("`repoins'")'" == "use") { //mata memory repo
							if "`module'"~="" local code `"mata: _fselectdata(`reponame'_data, "`=upper("`ctryx'")'", "`yr0'", "$type", "`module'")"'
							else              local code `"mata: _fselectdata(`reponame'_data, "`=upper("`ctryx'")'", "`yr0'", "$type")"'
							`code'
							local filename `loc_name_'
							if "`filename'"~="" noi dis "Use memory ($type): `filename' - in repository"
						} //repo use
						if ($nomata==0 & "`=lower("`repoins'")'" == "usefile") { //mata direct file repo
							if "`module'"~="" local code `"mata: _fselectdata(repofile_data, "`=upper("`ctryx'")'", "`yr0'", "$type", "`module'")"'
							else              local code `"mata: _fselectdata(repofile_data, "`=upper("`ctryx'")'", "`yr0'", "$type")"'
							`code'
							local filename `loc_name_'
							if "`filename'"~="" noi dis "Use direct file repo ($type): `filename' - in repository"
						} //repo usefile
					}
					else { //no repo
						if ($nomata==0 & "$type2"~="" & "`vermast'"=="" & "`veralt'"=="" & "`filename'"=="") {	//mata memory catalog					
							if "`module'"~="" local code `"mata: _fselectdata(${rootname}_data, "`=upper("`ctryx'")'", "`yr0'", "$type", "`module'")"'
							else              local code `"mata: _fselectdata(${rootname}_data, "`=upper("`ctryx'")'", "`yr0'", "$type")"'
							`code'
							local filename `loc_name_'
							if "`filename'"~="" noi dis "Use memory ($type): `filename' - in data catalog"
						}
					}
					cap noi _datalibcall_v2, country(`ctryx') year(`yr0') type($type) token($token) module(`module') vermast(`vermast') veralt(`veralt') filename(`filename') surveyid(`surveyid') para1(`para1') para2(`para2') para3(`para3') para4(`para4') ext($ext) $nocpi `fileserver' $nometa `base' `net' period(`period')

					if $errcode~=0 {
						local yr0 = `yr0' -1
						if `yr0'<1990 local wrong = 0
					}
					else if $errcode==0 {
						local filename
						local wrong = 0
						cap append using `alldata'
						qui save `alldata', replace emptyok
					}
				}  
			}
		}		
		else { //no latesty option
			foreach ctryx of local country {
				foreach yr of numlist `years' {
					if "`repository'" != "" {
						if ($nomata==0 & "`=lower("`repoins'")'" == "use") { //mata memory repo
							if "`module'"~="" local code `"mata: _fselectdata(`reponame'_data, "`=upper("`ctryx'")'", "`yr'", "$type", "`module'")"'
							else              local code `"mata: _fselectdata(`reponame'_data, "`=upper("`ctryx'")'", "`yr'", "$type")"'
							`code'
							local filename `loc_name_'
							if "`filename'"~="" noi dis "Use memory ($type): `filename' - in repository"
						} //repo use
						if ($nomata==0 & "`=lower("`repoins'")'" == "usefile") { //mata direct file repo
							if "`module'"~="" local code `"mata: _fselectdata(repofile_data, "`=upper("`ctryx'")'", "`yr'", "$type", "`module'")"'
							else              local code `"mata: _fselectdata(repofile_data, "`=upper("`ctryx'")'", "`yr'", "$type")"'
							`code'
							local filename `loc_name_'
							if "`filename'"~="" noi dis "Use direct file ($type): `filename' - in repository"
						} //repo usefile
					}
					else { //no repo
						if ($nomata==0 & "$type2"~="" & "`vermast'"=="" & "`veralt'"=="" & "`filename'"=="") {
							if "`module'"~="" local code `"mata: _fselectdata(${rootname}_data, "`=upper("`ctryx'")'", "`yr'", "$type", "`module'")"'
							else              local code `"mata: _fselectdata(${rootname}_data, "`=upper("`ctryx'")'", "`yr'", "$type")"'
							`code'
							local filename `loc_name_'
							if "`filename'"~="" noi dis "Use memory ($type): `filename' - in data catalog"
						}
					}
					cap noi _datalibcall_v2, country(`ctryx') year(`yr') type($type) token($token) module(`module') vermast(`vermast') veralt(`veralt') filename(`filename') surveyid(`surveyid') para1(`para1') para2(`para2') para3(`para3') para4(`para4') ext($ext) $nocpi `fileserver' $nometa `base' `net' period(`period')
					if $errcode==0 {
						local filename
						cap destring year, replace
						cap append using `alldata'
						qui save `alldata', replace empty
					}
				}  
			}
		}
		qui use `alldata', clear
		if "`=upper("$type")'"~="GLAD" cap ren countrycode code
		qui save `alldata', replace empty
		return local type `r(type)'
		return local module `r(module)'
		return local verm `r(verm)'
		return local vera `r(vera)'
		return local surveyid  `r(surveyid)'
		return local filename `r(filename)'
		return local filedate `r(filedate)'
		return local idno `r(idno)'
		
		//convert to PPP - only for harmonized database
		//ppp(integer) INCppp(varname) PLppp(numlist)
		if (strpos("`=upper("$type")'","RAW") == 0) & "`ppp'"~="" & ("`incppp'"~=""|"`plppp'"~="") {
			foreach ps of local ppp {
				if "`incppp'"~="" { //incppp
					foreach inc of local incppp {
						cap confirm variable `inc'_ppp
						if _rc~=0 {
							cap gen double `inc'_`ps'ppp = `inc'/(icp`ps'*cpi`ps')
							label var `inc'_`ps'ppp "`inc' (`ps' PPP US$)"
						}
						else {
							dis in red "`inc'_`ps'ppp already defined"
							global errcode 110
							error 110
						}
					}
				}
				if "`plppp'"~="" { //PLppp(numlist)
					foreach pl of local plppp {
						if (strpos("`pl'",".") != 0) local p : subinstr local pl "." "_", all
						else local p = `pl'
						cap confirm variable lp_`p'usd_`ps'
						if _rc~=0 {
							cap gen double lp_`p'usd_`ps' = `pl'*icp`ps'*cpi`ps'
							label var lp_`p'usd_`ps' "Poverty line: Current LCU equivalent to USD`pl' per day (`ps' PPP)"
						}
						else {
							dis in red "lp_`p'usd_`ps' already defined"
							global errcode 110
							error 110
						}
					}
				}
			}		
		}		
		qui exit $errcode
	}
	else { //getfile
		if "`=upper("`request'")'"=="DATA" { //get data
			foreach ctryx of local country {
				foreach yr of numlist `years' {
					cap noi dlw_getfile, country(`ctryx') year(`yr') col($type2) server($rootname) savepath("$localpath") folder($subfolders) token($token) module(`module') vermast(`vermast') veralt(`veralt') filename(`filename') surveyid(`surveyid') para1(`para1') para2(`para2') para3(`para3') para4(`para4') `base' `net'
					if $errcode~=0 dis in red "There is no data for the request of `request': `ctryx', `yr', $type, and $subfolders."
				}
			}
		}
		else { //non-data
			foreach ctryx of local country {
				foreach yr of numlist `years' {
					foreach fld of global `request' {
						noi dis in yellow _newline "{p 4 4 2}For folder: `fld'{p_end}"
						cap noi dlw_getfile, country(`ctryx') year(`yr') col($type2) server($rootname) savepath("$localpath") folder(`fld') token($token) module(`module') vermast(`vermast') veralt(`veralt') filename(`filename') surveyid(`surveyid') para1(`para1') para2(`para2') para3(`para3') para4(`para4') `base' `net'
						if $errcode~=0 dis in red "There is no files for the request of `request': `ctryx', `yr', $type, and `fld'."
					} //fld
				} //yr
			} //ctryx			
		} //non-data
		
		if ($token==8 & "`=upper("`request'")'"=="DATA" ) { //get CPI for harmonized
			if `"$cpiw"'~="" {
				tempfile tempcpi
				dlw_api, option(0) outfile(`tempcpi') query("$cpiw")
				if `dlibrc'==0 {
					if "`dlibFileName'"~="ECAFileinfo.csv" {
						cap shell mkdir "${localpath}\\${cpic}\\${cpic}_${cpiy}_CPI\\${r${rootcpi}cpivin}\\Data\Stata"
						cap copy "`tempcpi'" "${localpath}\\${cpic}\\${cpic}_${cpiy}_CPI\\${r${rootcpi}cpivin}\\Data\Stata\\${cpifile}", replace
						if _rc~=0 dis in red `"Failed to copy the CPI/PPP data with the defined structure: $cpiw"'
					}
					else {
						noi dis as error "Failed to load the CPI data with the defined structure $cpiw"
						noi dis as error "The CPI data should be publicly available, please inform the collection admins."
					}
				}
				else {
					noi dis in yellow `"Failed to load the CPI data with the defined structure: $cpiw"'
					dlw_message, error(`dlibrc')
				}
			}
		}
	} //end getfile
	clear
end


program define _display_logo
	disp in g _n(2)""
	disp in g _col(2)"  ___  ____  ____  ____            ____        ____  ___ (R)"
	disp in g _col(2)" /  / ____/   /   ____/   /    /  /___/ /   / /___ /___/"
	disp in g _col(2)"/__/ /___/   /   /___/   /__  /  /___/ /_/_/ /___ /___/ "
	disp ""   _col(2)
	disp in w _col(2)"Datalibweb is an API data platform specifically designed to enable users to access "
	disp in w _col(2)"the most up-to-date data and documentation available in different regional catalogs "
	disp in w _col(2)"at the World Bank. It allows users to access the latest and historical versions of"
	disp in w _col(2)"non-harmonized (original/raw) data as well as different harmonized collections across"
	disp in w _col(2)"across Global Practices. It is integrated with Stata through the Datalibweb Stata package."
	disp in g _n(2)""
end

program define _display_disclaimer
	// Generic text
	display as text "{hline}"
	display as text in y "{p 4 4 2}DISCLAIMER:{p_end}"
	display as text `"{p 6 4 0 80}This is the beta version of the Datalibweb command. This application was developed to facilitate the access of the original data and ex-post harmonization and is a work in progress. Please use with {cmd: CAUTION} and please remember to follow the {help datalibweb##termsofuse:TERMS OF USE}!! {p_end}"'
	display as text `"{p 6 4 0 80}Users are expected to conduct their own due diligence before implementing any analysis using this harmonization. Please notice that not all survey years within specific countries are necessarily comparable due to changes in survey design and questionnaire. For further information regarding the metadata of the each original survey used in this harmonization and to access any supporting documentation, please visit the regional data portals {browse "http://poverty/" : Poverty} or {browse "http://microdatalib.worldbank.org/index.php/home":Microdata Library}. {p_end}"'
	display as text `"{p 6 4 0 80}Users are expected to check summary statistics and published critical indicators computed with this microdata (poverty, inequality, and/or shared prosperity numbers) before conducting any analysis. {p_end}"'
	display as text "{p 6 4 0 80}Users are encouraged to take note of the vintage of the harmonization that is being used in order to assure future replicability of results. Please notice that this application will also retrieve by default the latest version of the harmonization, and this might change over time. For more information please read the {help datalibweb: help file}, including on how to retrieve previous vintages. {p_end}"
	display as text "{p 6 4 0 80}Please cite the data used as follows: {p_end}"
	display as text in white "{p 8 12 2 80}$distxt ([year of access (YYYY)]). Survey IDs: [Survey IDs separated by semi-colon (countrycode, survey year, survey acronym)]. As of [date of access (dd/mm/yyyy)] via Datalibweb Stata Package {p_end}"
	display as text `"{p 6 4 0 80} For any comments and/or questions on the datalibweb system, please write to {browse "mailto:datalibweb@worldbank.org; ?subject=Datalibweb ado helpdesk: <<<please describe your question and/or comment here>>>&cc=mnguyen3@worldbank.org" :datalibweb ado helpdesk}  {p_end}"'
    display as text `"{p 6 4 0 80} For any comments and/or questions on the micro data (raw and/or harmonized), please write to regional admins {browse "mailto:$email, ?subject=Datalibweb microdata helpdesk: <<<please describe your question and/or comment here>>>&cc=datalibweb@worldbank.org" :datalibweb microdata helpdesk}  {p_end}"'
	display as text "{hline}"
end
				  
program define dircheck, rclass
	version 9
	local curdir `"`c(pwd)'"'
	cap cd `"`1'"'
	local confdir = _rc 
	qui cd `"`curdir'"'
	ret scalar confdir = `confdir'
end

version 10

mata:

void _fselectdata(string matrix data, string scalar code, string scalar year, string scalar col,| string scalar mod, string scalar survname) {
	st_local("loc_name_","")
	a = select(data, data[.,1]:==code)
	a = select(a, a[.,2]:==year)
	a = select(a, a[.,4]:==col)	
	if (args()==5) a = select(a, a[.,5]:==mod)
	if (args()==6) a = select(a, a[.,3]:==survname)
	if (rows(a)==1) st_local("loc_name_", a[cols(a)])
}

end
