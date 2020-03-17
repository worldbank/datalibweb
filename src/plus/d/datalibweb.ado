*! version 1.04  12dec2019
*! Minh Cong Nguyen, Raul Andres Castaneda Aguilar, Jose Montes, Paul Andres Corral Rodas, Joao Pedro Azevedo, Paul Ricci
* version 0.1  02jun2015
* version 0.2  26oct2015 - collection dofiles
* version 0.3  11dec2015 - Add sysdir, conditions for collections, merging
* version 0.31 11dec2015 - General collection with no CPI loaded
* version 0.32 12apr2016 - exact search added
* version 0.4  XXdec2015 - Add date filter, merge (ongoing)
* version 0.5 Nov2016 - add getfile, mata data function
* version 0.6 Dec2016 - add new CPI/PPP function connection
* version 1   Jan2017 - add plugin v2
* version 1.01 26Jan2017 - add repo option, improve eusilc files and cpi
* version 1.02 19Feb2018 - add CPI vintages
* version 1.03 15Apr2019 - add new collections, countrycodes,
* version 1.04 12dec2019 - new CPI vintage with surveyname, enable some undocumented functions

cap program drop datalibweb
program define datalibweb, rclass	
	version 10, missing
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
		IGNOREerror  CONFidential                                     ///
		Working base latesty info                                     ///
		region(string) CPIVINtage(string)                             ///
		merge(string) update(string)                                  ///
		REPOsitory(string) reporoot(string)	repofile(string) 		  /// 
		NET	NOUPDATE FILEServer GUI									  ///
		getfile local localpath(string) cpilocal(string) sh(string) ALLmodules         ///
		]
	//SURvey(string) 
	qui set checksum off
	qui set varabbrev on
	local cmdline: copy local 0
	
	// add external program - MUST check and download locally from our incase it is failed for the SSC
	/*
	local extpro lstrfun varlocal
	foreach pg of local extpro {
		cap which `pg'
		if _rc~=0 cap ssc inst `pg', replace
		if _rc~=0 dis as error "You have to download the external program manually."
	}
	*/
	
	_dlogo		// display datlaibweb log 	
	//user check
 	//datalibweb_usercheck
	//local user = "`r(user)'"	
	global dlw_update = 0
	local user = c(username)
	//datalibweb_update 10may2017, user("`user'")	
	datalibweb_update, user("`user'")	
	if $dlw_update==1 {
		//cap local exit `r(exit)'
		//`exit'
		clear all
		discard
		cap program drop datalibweb
		*cap prog drop _datalibweb
		*cap prog drop dlwgui
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
	/*
	if ("`vintage'" == "" &  "`country'" == "" ) {
		noi di as error "option country() or vintage required"
		global errcode 198
		error 198
	}
	*/
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
		qui copy "http://ecaweb.worldbank.org/povdata/datalibweb/_ado/d/datalibweb_ini.zip" "`zpfile'", replace 
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
	//if $token==8 {
	//	if "`module'"~="" local para1 ${type}_`module'
	//}
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
			/*
			if (date("$S_DATE", "DMY")-date("${`type'_cpivindate}", "DMY"))==0 {
				if "${l`type'cpivin}"=="" {
					//get latest cpi vintage based on the mata `type'_cpidata
				}
			}
			else local dl 1 //daily reload
			*/
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
				*cap putmata `=upper("`type'")'_cpidata = (code year survey col verm surveyid), replace
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
				noi di as error `"The requeted cpivintage(`cpivintage') is not available. Please check and change it."' _new
				global errcode 170
				error 170
			}
			else global r${rootcpi}cpivin `cpivin'
		}
		else global r${rootcpi}cpivin ${l${rootcpi}cpivin} //use latest
		if `"${cpiw}"'~="" global cpiw ${cpiw}&para1=${r${rootcpi}cpivin}   
		*noi dis "$cpiw"
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
			*global cpi "`persdir'datalibweb\\data\\$rootname\\Support\Support_2005_CPI\Support_2005_CPI_v01_M\Data\Stata\\${cpifile}"
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
	//if (strpos("`=upper("$type")'","RAW") > 0) | (strpos("`=upper("$type")'","BASE") > 0) {
	if $token==5 { //RAW
		global nocpi nocpi
		if "`=lower("`fileserver'")'"~="fileserver" global type2 
	}
	
	// NEW info option - check this again, should be top
	/*
	if ("`info'" == "info") {
		datalibweb_info, country(`country') year(`year') type(`type')
		exit 
	}
	*/

	// Generic text
	dis as text "{hline}"
	noi dis as text in y "{p 4 4 2}DISCLAIMER:{p_end}"
	noi dis as text `"{p 6 4 0 80}This is the beta version of the Datalibweb command. This application was developed to facilitate the access of the original data and ex-post harmonization and is a work in progress. Please use with {cmd: CAUTION} and please remember to follow the {help datalibweb##termsofuse:TERMS OF USE}!! {p_end}"'
	noi dis as text `"{p 6 4 0 80}Users are expected to conduct their own due diligence before implementing any analysis using this harmonization. Please notice that not all survey years within specific countries are necessarily comparable due to changes in survey design and questionnaire. For further information regarding the metadata of the each original survey used in this harmonization and to access any supporting documentation, please visit the regional data portals {browse "http://poverty/" : Poverty} or {browse "http://microdatalib.worldbank.org/index.php/home":Microdata Library}. {p_end}"'
	noi dis as text `"{p 6 4 0 80}Users are expected to check summary statistics and published critical indicators computed with this microdata (poverty, inequality, and/or shared prosperity numbers) before conducting any analysis. {p_end}"'
	noi dis as text "{p 6 4 0 80}Users are encouraged to take note of the vintage of the harmonization that is being used in order to assure future replicability of results. Please notice that this application will also retrieve by default the latest version of the harmonization, and this might change over time. For more information please read the {help datalibweb: help file}, including on how to retrieve previous vintages. {p_end}"
	noi dis as text "{p 6 4 0 80}Please cite the data used as follows: {p_end}"
	noi dis as text in white "{p 8 12 2 80}$distxt ([year of access (YYYY)]). Survey IDs: [Survey IDs separated by semi-colon (countrycode, survey year, survey acronym)]. As of [date of access (dd/mm/yyyy)] via Datalibweb Stata Package {p_end}"
	noi dis as text `"{p 6 4 0 80} For any comments and/or questions on the datalibweb system, please write to {browse "mailto:datalibweb@worldbank.org; ?subject=Datalibweb ado helpdesk: <<<please describe your question and/or comment here>>>&cc=mnguyen3@worldbank.org" :datalibweb ado helpdesk}  {p_end}"'
    noi dis as text `"{p 6 4 0 80} For any comments and/or questions on the micro data (raw and/or harmonized), please write to regional admins {browse "mailto:$email, ?subject=Datalibweb microdata helpdesk: <<<please describe your question and/or comment here>>>&cc=datalibweb@worldbank.org" :datalibweb microdata helpdesk}  {p_end}"'
	dis as text "{hline}"
	
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
					foreach clx0 in region country years module vermast veralt /*surveyid*/ {
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
					foreach clx0 in region country years module vermast veralt /*surveyid*/ {
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
					foreach clx0 in region country years module vermast veralt /*surveyid*/ {
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
						*cap noi _datalibcall, country(`ctryx') year(`yr') type($type) request(`request') token($token) module(`module') vermast(`vermast') veralt(`veralt') filename(`filename') surveyid(`surveyid') para1(`para1') para2(`para2') para3(`para3') para4(`para4') $nocpi `fileserver' $nometa `base' `net'
						cap noi _datalibcall, country(`ctryx') year(`yr') type($type) token($token) vermast(`vermast') veralt(`veralt') folder(`fld') surveyid(`surveyid') para1(`para1') para2(`para2') para3(`para3') para4(`para4') $nocpi `fileserver' $nometa `base' `net' period(`period')
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
	*if "`request'"=="" local request data
	global request `request'
	
	/*
	if "`request'"=="" local request data
	global request `request'
	if ("`=upper("`request'")'"=="DOC" | "`=upper("`request'")'"=="PROG") {
		if "`ext'"=="" global ext
		local nocpi nocpi
	}
	*/
	
	//check data in memory
	//if ("`noupdate'"=="" & "`=upper("`request'")'"=="DATA" & $token==8) {
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
					*cap noi _datalibcall, country(`ctryx') year(`yr0') type($type) request(`request') token($token) module(`module') vermast(`vermast') veralt(`veralt') filename(`filename') surveyid(`surveyid') para1(`para1') para2(`para2') para3(`para3') para4(`para4') $nocpi `fileserver' $nometa `base' `net'
					cap noi _datalibcall, country(`ctryx') year(`yr0') type($type) token($token) module(`module') vermast(`vermast') veralt(`veralt') filename(`filename') surveyid(`surveyid') para1(`para1') para2(`para2') para3(`para3') para4(`para4') ext($ext) $nocpi `fileserver' $nometa `base' `net' period(`period')

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
					*cap noi _datalibcall, country(`ctryx') year(`yr') type($type) request(`request') token($token) module(`module') vermast(`vermast') veralt(`veralt') filename(`filename') surveyid(`surveyid') para1(`para1') para2(`para2') para3(`para3') para4(`para4') $nocpi `fileserver' $nometa `base' `net'
					cap noi _datalibcall, country(`ctryx') year(`yr') type($type) token($token) module(`module') vermast(`vermast') veralt(`veralt') filename(`filename') surveyid(`surveyid') para1(`para1') para2(`para2') para3(`para3') para4(`para4') ext($ext) $nocpi `fileserver' $nometa `base' `net' period(`period')
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
		//qui error $errcode
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
						//cap noi dlw_getfile, col($type2) country(`ctryx') year(`yr') server($rootname) savepath("$localpath") surveyid(`surveyid') folder(`fld')
						if $errcode~=0 dis in red "There is no files for the request of `request': `ctryx', `yr', $type, and `fld'."
					} //fld
				} //yr
			} //ctryx			
		} //non-data
		
		if ($token==8 & "`=upper("`request'")'"=="DATA" ) { //get CPI for harmonized
			if `"$cpiw"'~="" {
				tempfile tempcpi
				plugin call _datalibweb, "0" "`tempcpi'" "$cpiw"
				if `dlibrc'==0 {
					if "`dlibFileName'"~="ECAFileinfo.csv" {
						cap shell mkdir "${localpath}\\${cpic}\\${cpic}_${cpiy}_CPI\\${r${rootcpi}cpivin}\\Data\Stata"
						cap copy "`tempcpi'" "${localpath}\\${cpic}\\${cpic}_${cpiy}_CPI\\${r${rootcpi}cpivin}\\Data\Stata\\${cpifile}", replace
						*cap shell mkdir "${localpath}\\Support\Support_2005_CPI\Support_2005_CPI_v01_M\Data\Stata"
						*cap copy "`tempcpi'" "${localpath}\\Support\Support_2005_CPI\Support_2005_CPI_v01_M\Data\Stata\\${cpifile}", replace
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

*! version 0.2 26oct2015
*! Minh Cong Nguyen
* version 0.1 2jun2015
cap program drop _datalibcall
program define _datalibcall, rclass	
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
	//if "`vermast'" == "" & "`veralt'" =="" & "`surveyid'"=="" local latest latest
	*if "`vermast'" == "" & "`veralt'" =="" local latest latest
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
		/*
		else {
			di in red "This type ($type) has no base option. Please check with the collection admin." _new
			global errcode 198
			error 198
		}
		*/
	}

	if ($token==5) {
		local nocpi nocpi
		if "`=lower("`fileserver'")'"~="fileserver" global type2 
	}
	
	// search options	
	*if "`=upper("`request'")'"=="DATA" {
		* Get the requested module
		if `=wordcount("`module'")' ==0 {
			if "`=lower("`fileserver'")'"=="fileserver" cap noisily filesearch, col($type2) country(`country') year(`year') root($root) subfolders($subfolders) surveyid(`surveyid') combstring(`filename' `version') `latest' `nometa' /* save("`data2'")  */
			else                                        cap noisily filesearchw2, token(`token') col($type2) country(`country') year(`year') server($rootname) surveyid(`surveyid') filename(`filename') folder(`folder') para1(`para1') para2(`para2') para3(`para3') para4(`para4') `latest' `nometa' `net' /* save("`data2'")  */			
			*else                                        cap noisily filesearchw2, token(`token') col($type2) country(`country') year(`year') server($rootname) filename(`filename') folder($subfolders) para1(`para1') para2(`para2') para3(`para3') para4(`para4') `latest' `nometa' `net' /* save("`data2'")  */			
			//else                                      cap noisily filesearchw2, token(`token') col($type2) country(`country') year(`year') server($rootname) surveyid(`surveyid') filename(`filename') para1(`version')  `latest' `nometa' `net' /* save("`data2'")  */			
								
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
			//else	                                    cap noisily filesearchw2, token(`token') col($type2) country(`country') year(`year') server($rootname) surveyid(`surveyid') para1(${type}_`module'$ext) para2(`version') para3(`filename') `latest' `nometa' `net' /* save("`data2'")  */				
						
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
					*else                                        cap noisily filesearchw2, token(`token') col($type2) country(`country') year(`year') server($rootname) folder($subfolders) para1($para1) para2($para2) para3($para3) para4($para4) `latest' `nometa' `net' /*save("`data2'")  */
					//else                                      cap noisily filesearchw2, token(`token') col($type2) country(`country') year(`year') server($rootname) surveyid(`surveyid') para1(${type}_`m0'$ext) para2(`version') para3(`filename') `latest' `nometa' `net' /*save("`data2'")  */

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
					//cap destring $hhid $pid, force replace
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
					//OLD if "`=lower("`fileserver'")'"=="fileserver" cap noisily filesearch, col($type2) country(`country') year(`year') root($root) subfolders($subfolders) anystring(${type}_`m0'$ext `version') `latest' `nometa' /*save("`data2'")  */				
					else                                        cap noisily filesearchw2, token(`token') col($type2) country(`country') year(`year') server($rootname) surveyid(`surveyid') filename(`filename') folder(`folder') para1($para1) para2($para2) para3($para3) para4($para4) `latest' `nometa' `net' /*save("`data2'")  */
					*else                                        cap noisily filesearchw2, token(`token') col($type2) country(`country') year(`year') server($rootname) folder($subfolders) para1($para1) para2($para2) para3($para3) para4($para4) `latest' `nometa' `net' /*save("`data2'")  */
					//else                                      cap noisily filesearchw2, token(`token') col($type2) country(`country') year(`year') server($rootname) para1(${type}_`m0'$ext) para2(`version') `latest' `nometa' `net' /*save("`data2'")  */

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
					//cap destring $hhid, force replace 
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
				//report merge
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
			*global surveyid  `r(surveyid)'
			if "$surveyid"=="" global surveyid  `r(surveyid)'
			global f1name `r(filename)'
		} //merge between modules
		
		// merge CPI
		qui if "`nocpi'"=="" /*& `rc'==0*/ { // _rc check
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
								*cap use "`persdir'datalibweb\data\\${rootname}\\${cpifile}", clear	
								cap use "`persdir'datalibweb\data\\${rootname}\\${cpic}\\${cpic}_${cpiy}_CPI\\${r${rootcpi}cpivin}\\Data\Stata\\${cpifile}", clear	
								if _rc==0 local cpino = 1
								else local dl 1
								*noi dis "use localfile"
							}
							else local dl 1						
						}
						else { 
							*cap confirm file "`persdir'datalibweb\data\\${rootname}\\${cpifile}"
							cap confirm file "`persdir'datalibweb\data\\${rootname}\\${cpic}\\${cpic}_${cpiy}_CPI\\${r${rootcpi}cpivin}\\Data\Stata\\${cpifile}"
							if _rc==0 {
								*cap use "`persdir'datalibweb\data\\${rootname}\\${cpifile}", clear
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
							cap program define _datalibweb, plugin using("dlib2_`=cond(strpos(`"`=c(machine_type)'"',"64"),64,32)'.dll")					
							plugin call _datalibweb, "0" "`tempcpi'" "$cpiw"	
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
									*saveold "`persdir'datalibweb\data\\${rootname}\\${cpifile}", replace	
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
					//OLD 30Jan18: qui if strpos("$surveyid)","EU-SILC")==0 cap keep if code=="`=upper("`country'")'"
					//qui if "`=upper("$type")'"=="UDB-C" | "`=upper("$type")'"=="UDB-L" cap keep if code=="`=upper("`country'")'"
					save `cpiuse', replace
					
					use `datafinal', clear	
					cap destring year, replace
					cap gen str code = "`=upper("`country'")'"   //need to be removed later
					cap gen year = `year'                        //need to be removed later			
					qui if strpos("$surveyid)","EU-SILC")>0 replace year = year - 1				//EUSILC year
					//qui if "`=upper("$type")'"=="UDB-C" | "`=upper("$type")'"=="UDB-L" replace year = year - 1				//EUSILC year
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
							*cap merge m:1 pais ano encuesta trimestre `cpilevel' using `cpiuse', gen(_mcpi) keepus($cpivarw) update replace
							*if _rc~=0 noi dis as error "Can't merge with CPI data - please check with the regional team."
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
					//qui if "`=upper("$type")'"=="UDB-C" | "`=upper("$type")'"=="UDB-L" replace year = year + 1				//EUSILC year
					
				}
			} //_rc save
		}
		//end
	*}
	/*
	else { //Non-data type
		foreach fld of global `request' {
			noi dis in yellow _newline "{p 4 4 2}For folder: `fld'{p_end}"
			if "`=lower("`fileserver'")'"=="fileserver" cap noisily filesearch, col($type2) country(`country') year(`year') root($root) subfolders(`fld') surveyid(`surveyid') combstring(`filename' `version') `latest' `nometa' 
			else                                        cap noisily filesearchw2, token(`token') col($type2) country(`country') year(`year') server($rootname) folder(`fld') surveyid(`surveyid') filename(`filename') para1(`version')  `latest' `nometa' `net' 			
			//else                                      cap noisily filesearchw2, token(`token') col($type2) country(`country') year(`year') server($rootname) folder(`fld') surveyid(`surveyid') filename(`filename') para1(`version')  `latest' `nometa' `net' 			
		}
		exit
	}
	*/
end


cap program drop  _dlogo
program define _dlogo
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
					  
cap program drop dircheck
program define dircheck, rclass
	version 9
	local curdir `"`c(pwd)'"'
	cap cd `"`1'"'
	local confdir = _rc 
	qui cd `"`curdir'"'
	ret scalar confdir = `confdir'
end

version 10
cap mata : mata drop _fselectdata()
mata:
mata set matalnum on
mata set mataoptimize on
mata set matafavor speed
//mata drop _fselectdata()
//return the result to the local
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
