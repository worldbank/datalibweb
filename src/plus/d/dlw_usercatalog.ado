*! version 0.2 14apr2019
*! Minh Cong Nguyen
* version 0.1 16feb2017 - original
* version 0.2 15apr2019 - add new collection category in type2

program define dlw_usercatalog, rclass	
	version 10, missing
    local verstata : di "version " string(_caller()) ", missing:" 
	syntax, code(string) [savepath(string) update]	
	local code = upper("`code'")
	local persdir : sysdir PERSONAL
    if "$S_OS"=="Windows" local persdir : subinstr local persdir "/" "\", all
	local dl 0
	if "`update'"=="update" local dl 1
	else {		
		cap confirm file "`persdir'datalibweb\data\Catalog_`code'.dta"
		if _rc==0 {
			cap use "`persdir'datalibweb\data\Catalog_`code'.dta", clear	
			if _rc==0 {
				local dtadate : char _dta[version]			
				if "$updateday"=="" global updateday 1
				if (date("$S_DATE", "DMY")-date("`dtadate'", "DMY")) > $updateday local dl 1				
				else return local catalogfile "`persdir'datalibweb\data\Catalog_`code'"
			}
			else local dl 1
		}
		else {
			cap mkdir "`persdir'datalibweb\data"
			local dl 1
		}
	}
	
	qui if `dl'==1 {
		//server config
		global ftmpconfig = 0
		tempfile tmpconfig
		if "$DATALIBWEB_VERSION"=="1" dlw_api, option(4) outfile(`tmpconfig')
		else dlw_api_v2, option(4) outfile(`tmpconfig')
		if `dlibrc'==0 {
			if ("`dlibType'"=="csv") {
				cap insheet using "`tmpconfig'", clear names
				if _rc==0 {
					if _N==1 noi dis as text in white "No data in the data config. Please check with the system admin."
					else {
						global ftmpconfig = 1
						ren ext extn
						ren server serveralias
						replace serveralias = upper(serveralias)
						replace foldername = "" if foldername=="NULL"
						qui saveold "`tmpconfig'", replace	
						
						tempfile sub2		
						duplicates drop _all, force
						bys serveralias requesttype token: gen seq = _n
						bys serveralias requesttype token: gen all = _N
						reshape wide foldername folderlevel extn, i( serveralias requesttype token all) j(seq)
						save `sub2', replace
					}
				}
				else {
					noi dis as error "Cant open the config data. Please check with the system admin."
				}	
			}
		}
		else {
			dlw_message, error(`dlibrc')
		}

		//catalog country
		global ftmpcatalog = 0
		tempfile tmpcatalog
		if "$DATALIBWEB_VERSION"=="1" dlw_api, option(3) outfile(`tmpcatalog') query("`code'")
		else dlw_api_v2, option(3) outfile(`tmpcatalog') query("`code'")
		if `dlibrc'==0 {
			if ("`dlibType'"=="csv") {
				cap insheet using "`tmpcatalog'", clear	names
				if _rc==0 {
					if _N==1 noi dis as text in white "No data in the catalog for this country `code'."
					else {
						global ftmpcatalog = 1
						*ren survey acronym //added May 14 2019 
						split filepath, p("\")
						ren filepath3 surveyid
						split surveyid, p("_") //added May 14 2019 
						ren surveyid3 acronym //added May 14 2019 
						drop surveyid? //added May 14 2019 
						gen token = 1 + strlen(surveyid) - strlen(subinstr(surveyid,"_","",.))
						gen type = "RAW" if token==5
						replace type = "Harmonized" if token==8
						gen str finaltype = ""
						gen str foldername = ""
						gen folderlevel =.
						gen str fext = ""
						gen path1 = filepath1 + "\" + filepath2 + "\" + surveyid + "\"
						gen filename = substr(filepath, length(filepath)-strpos(reverse(filepath), "\")+2, .)
						replace serveralias = upper(serveralias)
						save `tmpcatalog', replace	
					}
				}
				else {
					noi dis as error "Cant open the catalog data. Please check the server name."
				}
			}
		}
		else {
			dlw_message, error(`dlibrc')
		}

		if ($ftmpconfig==1 & $ftmpcatalog==1) {
			tempfile subtemp
			use `sub2', clear
			levelsof requesttype, local(lvltype)
			foreach rtype of local lvltype {
				use `sub2', clear
				keep if requesttype=="`rtype'"
				save `subtemp', replace
				
				use `tmpcatalog', clear
				merge m:1 serveralias token using `subtemp', update replace
				drop if _m==2
				drop _m
				su all, mean
				forv i=1(1)`r(max)' { //loop through folder
					//foldername is different than blank
					gen tmp1 = strpos(extn`i', ext)
					gen tmp2 = strpos(filepath, foldername`i')
					gen tmp3 = length(path1)+1
					gen tmp4 = length(path1)+ length(foldername`i') + length(filename) + 1 if foldername`i'~=""
					replace tmp4 = length(path1)+ length(foldername`i') + length(filename)  if foldername`i'==""
					gen tmp5 = length(filepath)
					replace finaltype   = requesttype    if folderlevel`i'~=. & tmp1>0 & tmp2==tmp3 & tmp4==tmp5
					replace foldername  = foldername`i'  if folderlevel`i'~=. & tmp1>0 & tmp2==tmp3 & tmp4==tmp5
					replace folderlevel = folderlevel`i' if folderlevel`i'~=. & tmp1>0 & tmp2==tmp3 & tmp4==tmp5
			
					//foldername is blank, the data is right at the path1 folder, level should be 0
					replace finaltype  = requesttype     if folderlevel`i'~=. & tmp1>0 & foldername`i'=="" & tmp4==tmp5
					replace foldername = foldername`i'   if folderlevel`i'~=. & tmp1>0 & foldername`i'=="" & tmp4==tmp5
					replace folderlevel = folderlevel`i' if folderlevel`i'~=. & tmp1>0 & foldername`i'=="" & tmp4==tmp5
					cap drop tmp1 tmp2 tmp3 tmp4 tmp5
				}
				replace requesttype = finaltype
				save `tmpcatalog', replace
			}
		}

		//audit
		global faudit 0
		tempfile audit
		if "$DATALIBWEB_VERSION"=="1" dlw_api, option(6) outfile(`audit') query("`code'") reqtype("Download") 
		else dlw_api_v2, option(6) outfile(`audit') query("`code'") reqtype("Download") 
		//qui plugin call _datalibweb , "6" "`audit'" "`code'" "Download" 
		qui if `dlibrc'==0 {    
			if ("`dlibType'"=="csv") {
				cap insheet using "`audit'", clear	names					
				if _rc==0 {
					cap drop userpin requesttype accessedfolder organization department timestamp modifiedby createdby created acronym appid applicationid ipaddress collection country year para1 para2 para3 para4 name type token foldername level ext command
					if _N==0 noi dis as text in red "Note: User has no subscription in the catalog for this country `code'."
					else {												
						cap confirm string variable server
						if _rc~=0 {
							drop server
							gen str server = ""
						}
						cap confirm string variable surveyid
						if _rc~=0 {
							drop surveyid
							gen str surveyid = ""
						}
						//cap drop userpin requesttype accessedfolder organization department timestamp modifiedby createdby created acronym appid applicationid ipaddress collection country year para1 para2 para3 para4 name type token foldername level ext command
						ren server serveralias
						ren modified downloaddate
						bys serveralias surveyid filename ( downloaddate): gen latest = _n==_N
						keep if latest==1
						if _N>0 {
							global faudit 1
							drop latest
							save `audit', replace
						}						
					}
				}
				else {
					noi dis as error "Cant open the usage data. Please check the required parameters."
				}
			}
		}

		//subscription	
		global fsubscription 0					
		tempfile subscription
		if "$DATALIBWEB_VERSION"=="1" dlw_api, option(5) outfile(`subscription') query("`code'")
		else dlw_api_v2, option(5) outfile(`subscription') query("`code'")
		if `dlibrc'==0 {
			if ("`dlibType'"=="csv") {
				cap insheet using "`subscription'", clear names
				if _rc==0 {
					if _N==0 noi dis as text in white "User has no subscription in the catalog for this country `code'."
					else {
						//hot fix IND due to wrong year
						if "`code'"=="IND" {
							cap drop if year=="2017-2021"
							cap destring year, replace
						}
						global fsubscription 1		
						cap drop userpin emailaddress subscribedto modified created createdby modifiedby
						ren surveyid acronym
						ren region serveralias
						replace serveralias = upper(serveralias)
						gen double expdate = date(reqexpirydate, "MDYhms")
						format %td expdate
						gen subscribed = expdate-date("$S_DATE", "DMY")>=0
						drop reqexpirydate
						replace collection = upper(collection)
						//For collection specific (~=ALL), keep only token~=5
						drop if collection~="ALL" & token==5
						*drop if foldername==""
						cap confirm string variable foldername
						if _rc~=0 {
							drop foldername
							gen str foldername = ""
						}
						//drop duplicates due to public and user subscription
						duplicates drop serveralias country year acronym requesttype token foldername, force
						save `subscription', replace
						tempfile sub2
						drop country year acronym expdate subscribed  ispublic collection
						duplicates drop _all, force
						bys serveralias requesttype token: gen seq = _n
						bys serveralias requesttype token: gen all = _N
						*reshape wide foldername level extn, i( serveralias requesttype token all) j(seq)
						reshape wide foldername folderlevel extn, i( serveralias requesttype token all) j(seq)
						save `sub2', replace	
					} //_N
				} //rc
				else {
					noi dis as error "Cant open the subscription data. Please check the required parameters."
				}
			}
		}
		else {
			dlw_message, error(`dlibrc')
		}

		//combine catalog + subscription + audit
		use `tmpcatalog', clear
		if $fsubscription==1 {
			merge m:1 serveralias country year acronym requesttype token foldername using `subscription', keepus(expdate subscribed)
			drop if _m==2
			drop _m
		}

		if $faudit==1 {
			merge m:1 serveralias surveyid filename using `audit', keepus(downloaddate)
			ta _m
			drop if _m==2
			drop _m
		}
		cap drop all path1 requesttype title
		cap drop extn? folderlevel? foldername? filepath?
		cap confirm variable subscribed
		if _rc==0 replace subscribed = -1 if expdate==.
		else      gen subscribed = -1
		
		cap confirm variable expdate 
		if _rc~=0 gen expdate = .
		cap confirm variable downloaddate
		if _rc~=0 gen str downloaddate = ""
		gen isdownload = cond(downloaddate != "", 1, 0)
		
		drop if finaltype==""
		//currently define 5 token as raw, 8 token as harmonized
		split surveyid, p("_")
		tempfile sur3 sur4
		save `sur3', replace
		keep surveyid* type
		duplicates drop _all, force
		cap drop if upper(surveyid6)=="WRK" | upper(surveyid6)=="VTEMP"		
		replace surveyid6 = lower(surveyid6)
		replace surveyid4 = lower(surveyid4)							
		bysort type surveyid2 surveyid3 surveyid8 (surveyid4 surveyid6): gen latest = _n==_N
		keep surveyid latest
		save `sur4', replace
		use `sur3', clear
		merge m:1 surveyid using `sur4'
		drop _m
		replace latest = 0 if latest==.
		gen collection = surveyid8 if token==8
		gen type2 = 0
		replace type2 = 1 if token==8
		replace type2 = 2 if inlist(collection, "GMD", "GLD", "GPWG", "ASPIRE", "I2D2", "I2D2-Labor", "GLAD")  // add as many global collections as available
		replace type2 = 3 if inlist(collection, "GMI", "HLO", "CLO")  // add as many thematic indicators as available
		//drop OLD stuff
		drop if collection=="GPWG"
		
		clonevar vermast = surveyid4  //always there
		gen str veralt = ""
		replace veralt = surveyid6 if token==8
		drop surveyid?
		replace vermast = subinstr(vermast, "v","",.)
		replace vermast = subinstr(vermast, "V","",.)
		replace veralt = subinstr(veralt, "v","",.)
		replace veralt = subinstr(veralt, "V","",.)
		gen module = regexs(3) if regexm(filename, "^(.*)_[Aa]_([a-zA-Z0-9\-]+)_([a-zA-Z0-9\-]+)\.[a-z]+$")
		replace module = upper(module)
		replace module = "NULL" if token==8 & module=="" & upper(ext)=="DTA"
		la var module "Available modules"
		gen str type3 = serveralias + "RAW" if type=="RAW"
		replace type3 = collection if type=="Harmonized"
		gen guikey1 = type
		replace guikey1 = type + " (" + collection + ")" if type=="Harmonized"
		gen str guikey2 = country + "_" + string(year) + "_" + acronym
		gen str guikey3 = surveyid + " (" + serveralias + ")"
		clonevar guikey4 = foldername
		gen str guicmd  = ""
		replace guicmd = "datalibweb, coun(" + country + ") y(" + string(year) + ") t(" + type3 + ")" + " sur(" + surveyid + ") filen(" + filename + ")"
		drop filepath type3 surveyid		
		//drop WRK
		drop if upper(veralt)=="WRK"		
		compress
		char _dta[version] $S_DATE				
		//outsheet _all using "`persdir'datalibweb\data\Catalog_`code'.csv", replace c		
		cap drop if length(guicmd)>244
		la def subscribed -1 "No" 0 "Expired" 1 "Yes"
		//la def subscribed 0 "No" 1 "Yes" 2 "Expired" 
		la val subscribed subscribed
		label define type2 0 "Raw data" 1 "Regional harmonized data" 2 "Global harmonized data" 3 "Thematic indicators"
		la val type2 type2
		label define isdownload 1 "YES" 0 "NO"
		label values isdownload isdownload
		gen byte filesize =.
		gen str filemoddate = ""
		gen str guisubexp = serveralias + "," + acronym + "," + string(year) + "," + country + "," + collection if collection~=""
		replace guisubexp = serveralias + "," + acronym + "," + string(year) + "," + country + "," + "RAW" if collection==""
		//server, accronym, year, country, collection
		order guikey1 guikey2 guikey3 guikey4 guicmd guisubexp filename subscribed latest isdownload  downloaddate filesize filemoddate
		compress
		if "`savepath'"~="" saveold "`savepath'\\Catalog_`code'", replace
		saveold "`persdir'datalibweb\data\Catalog_`code'", replace		
		return local catalogfile "`persdir'datalibweb\data\Catalog_`code'"
	} //end dl=1
end
