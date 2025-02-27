*! version 0.1 16apr017
*! Minh Cong Nguyen

program define dlw_servercatalog, rclass	
	version 10, missing
    local verstata : di "version " string(_caller()) ", missing:" 
	syntax, server(string) [savepath(string) update]
	local server = upper("`server'")	
	local persdir : sysdir PERSONAL
    if "$S_OS"=="Windows" local persdir : subinstr local persdir "/" "\", all
	local dl 0
	if "`update'"=="update" local dl 1
	else {		
		cap confirm file "`persdir'datalibweb\data\Catalog_`server'.dta"
		if _rc==0 {
			cap use "`persdir'datalibweb\data\Catalog_`server'.dta", clear	
			if _rc==0 {
				local dtadate : char _dta[version]			
				if "$updateday"=="" global updateday 1
				if (date("$S_DATE", "DMY")-date("`dtadate'", "DMY")) > $updateday local dl 1				
				else return local catalogfile "`persdir'datalibweb\data\Catalog_`server'"
			}
			else local dl 1
		}
		else {
			cap mkdir "`persdir'datalibweb\data"
			local dl 1
		}
	}
	qui if `dl'==1 {			
		//Audit - check first			
		local dlaudit 0
		if "`update'"=="update" local dlaudit 1
		else {		
			cap confirm file "`persdir'datalibweb\data\User_audit.dta"
			if _rc==0 {
				cap use "`persdir'datalibweb\data\User_audit.dta", clear	
				if _rc==0 {
					local dtadate : char _dta[version]			
					if "$updateday"=="" global updateday 1
					if (date("$S_DATE", "DMY")-date("`dtadate'", "DMY")) > $updateday local dlaudit 1				
					else {
						return local catalogfile "`persdir'datalibweb\data\User_audit"
						global ftmpaudit 1
					}
				}
				else local dlsub 1
			}
			else {
				cap mkdir "`persdir'datalibweb\data"
				local dlaudit 1
			}
		}
		
		//audit download
		qui if `dlaudit'==1 {	
			global ftmpaudit 0
			tempfile audit
			dlw_api, option(6) outfile(`audit') reqtype("Download") 									
			if `dlibrc'==0 {    
				if ("`dlibType'"=="csv") {
					cap insheet using "`audit'", clear	names
					if _rc==0 {
						cap drop userpin requesttype accessedfolder organization department timestamp modifiedby createdby created  appid applicationid ipaddress  para1 para2 para3 para4 name  level ext command
						if _N==0 noi dis as text in red "Note: User has no subscription in the catalog for this country `code'."
						else {														
							keep if type=="Data" & token==8		
							if _N>0 {
								ren server serveralias							
								cap confirm variable modified
								if _rc~=0 gen str downloaddate = ""
								else ren modified downloaddate
								gen isdownload = cond(downloaddate != "", 1, 0)									
								bys serveralias surveyid filename ( downloaddate): gen latest = _n==_N
								keep if latest==1
								if _N>0 {
									global ftmpaudit 1
									drop latest							
									char _dta[version] $S_DATE							
									compress						
									saveold "`persdir'datalibweb\data\User_audit", replace	
								}
							}
						}
					}
					else {
						noi dis as error "Cant open the usage data. Please check the required parameters."
					}
				} //csv
			} //dlibrc
		} //dlaudit
				
		//subscription - check first		
		local dlsub 0
		if "`update'"=="update" local dlsub 1
		else {		
			cap confirm file "`persdir'datalibweb\data\User_subscription.dta"
			if _rc==0 {
				cap use "`persdir'datalibweb\data\User_subscription.dta", clear	
				if _rc==0 {
					local dtadate : char _dta[version]			
					if "$updateday"=="" global updateday 1
					if (date("$S_DATE", "DMY")-date("`dtadate'", "DMY")) > $updateday local dlsub 1				
					else {
						return local catalogfile "`persdir'datalibweb\data\User_subscription"
						global ftmpsub 1
					}
				}
				else local dlsub 1
			}
			else {
				cap mkdir "`persdir'datalibweb\data"
				local dlsub 1
			}
		}
		
		//subscription download	
		qui if `dlsub'==1 {	
			global ftmpsub 0					
			tempfile subscription
			dlw_api, option(5) outfile(`subscription')						
			if `dlibrc'==0 {
				if ("`dlibType'"=="csv") {
					cap insheet using "`subscription'", clear names					
					if _rc==0 {
						if _N==0 noi dis as text in white "User has no subscription in the catalog for this country `code'."
						else {
							global ftmpsub 1	
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
							drop if requesttype=="Documentation" | token==5
							drop if country=="SUPPORT"
							//drop duplicates due to public and user subscription
							duplicates drop serveralias country year acronym requesttype token foldername, force
							char _dta[version] $S_DATE							
							compress						
							saveold "`persdir'datalibweb\data\User_subscription", replace									
						} //_N
					} //rc
					else {
						noi dis as error "Cant open the subscription data. Please check the required parameters."
					}
				} //csv
			}
			else {
				dlw_message, error(`dlibrc')
			}
		}
		
		//server catalog
		global ftmpserver = 0
		tempfile servercatalog
		dlw_api, option(2) outfile(`servercatalog') query("`server'")		
		if `dlibrc'==0 {
			if ("`dlibType'"=="csv") {				
				cap insheet using "`servercatalog'", clear names
				if _rc==0 {
					if _N==1 {
						noi dis as text in white "No data in the catalog for this server `server'."
						error 198
					}
					else {		
						global ftmpserver = 1
						cap drop v7 v8
						cap drop if year=="NULL"
						cap destring year, replace
						cap replace filepath = subinstr(filepath, "/", "\",.) 
						gen ndir = strlen(filepath) - strlen(subinstr(filepath,"\","",.))
						gen pos0 = strpos(filepath, ".dta")
						gen pos1 = strpos(filepath, ".DTA")
						gen pos = pos0
						replace pos = pos1 if pos1>0
						drop if pos==0
						drop pos0 pos1 pos 
						split filepath, p("\")
						replace filepath1 = upper(filepath1)
						drop if filepath1=="SUPPORT"						
						ren filepath3 surveyid
						gen pos = strpos(surveyid, "_")
						drop if pos==0
						gen ntoken = strlen(surveyid) - strlen(subinstr(surveyid,"_","",.))
						gen type = "RAW" if ntoken==4
						replace type = "Harmonized" if ntoken==7
						keep if type=="Harmonized"
						*gen filepathU = upper(filepath)
						*gen pos_data = strpos(filepathU, "DATA")
						
						//Server with data folder
						if "`server'"=="ASPIRE" | "`server'"=="GPWG" | "`server'"=="GMD" {
							su ndir, de
							if r(mean)~=3 {
								dis as error "Mixed data system, please check."
								error 1
							}
							else {
								ren filepath4 filename 
								ren filepath relpath
								gen str guikey4 = "Data"							
							}		
						}
						
						//Server without data folder
						if "`server'"=="ECA" | "`server'"=="EAP" | "`server'"=="I2D2" | "`server'"=="LABLAC" | "`server'"=="MNA" | "`server'"=="SAR" | "`server'"=="SEDLAC" | "`server'"=="SSA" | "`server'"=="ECA_EUROSTAT" | "`server'"=="GLD" {	
							keep if upper(filepath4)=="DATA"							
							drop if strpos(upper(filepath5), ".DTA") > 0
							keep if upper(filepath5)=="HARMONIZED"								
							ren filepath6 filename
							gen str guikey4 = filepath4 + "\" + filepath5							
						}		
						
						split filename, p("_")
						cap drop if upper(filename6)=="WRK" | upper(filename6)=="VTEMP"						
						ren filename8 guikey1
						drop if strpos(upper(guikey1), ".DTA") > 0	
						drop if guikey1==""
						ren filename fname
						drop filename*
						ren fname filename							
						drop if strpos(upper(filename), ".DTA") == 0
						tempfile sur3 sur4
						save `sur3', replace
						keep surveyid 
						duplicates drop _all, force
						split surveyid, p("_")
						replace surveyid6 = lower(surveyid6)
						replace surveyid4 = lower(surveyid4)							
						bysort surveyid1 surveyid2 surveyid3 surveyid8 (surveyid4 surveyid6): gen latest = _n==_N
						keep surveyid latest
						save `sur4', replace
						use `sur3', clear							
						merge m:1 surveyid using `sur4'
						drop _m
						replace latest = 0 if latest==.
						duplicates drop serveralias country year survey filename, force
						
						//ren filepath1 guikey2
						ren filepath2 guikey2
						ren surveyid guikey3						
						gen str guicmd  = ""
						replace guicmd = "datalibweb, coun(" + country + ") y(" + string(year) + ") t(" + guikey1 + ")" + " sur(" + guikey3 + ") filen(" + filename + ")"						
						cap drop if length(guicmd)>244
						//la def subscribed -1 "No" 0 "Expired" 1 "Yes"						
						//la val subscribed subscribed							
						//label define isdownload 1 "YES" 0 "NO"
						//label values isdownload isdownload
						sort guikey1 guikey2 guikey3 guikey4 														
						cap drop ext relpath
						cap drop filepath* ndir pos ntoken
						gen subscribed = -1	
						gen str downloaddate = ""
						gen byte isdownload =.
						ren survey acronym
						tempfile data8 data9
						save `data8', replace
						
						//merge with correct collection subscription
						qui if $ftmpsub==1 {
							cap use "`persdir'datalibweb\data\User_subscription.dta", clear	
							if _rc==0 { 
								keep if serveralias=="`server'"
								if _N > 0 {
									save `data9', replace
									use `data8', clear
									merge m:1 country year acronym using `data9', keepus(expdate subscribed) update replace
									drop if _m==2
									drop _m
									compress
									save `data8', replace
								}								
							}
							else noi dis as error "Cant open the subscription data. Please check the required parameters." 
						}
						
						//merge with correct collection audit						
						qui if $ftmpaudit==1 {
							cap use "`persdir'datalibweb\data\User_audit.dta", clear	
							if _rc==0 { 
								keep if serveralias=="`server'"
								if _N > 0 {
									save `data9', replace
									use `data8', clear									
									merge m:1 serveralias country year acronym filename using `data9', keepus(downloaddate isdownload) update replace									
									drop if _m==2
									drop _m
									compress
									save `data8', replace
								}								
							}
							else noi dis as error "Can't open the subscription data. Please check the required parameters." 
						}
						
						//save all inventory						
						use `data8', clear
						char _dta[version] $S_DATE		
						cap gen filesize =.
						gen str filemoddate = ""
						gen str guisubexp = serveralias + "," + acronym + "," + string(year) + "," + country + "," + guikey1 if guikey1~=""
						replace guisubexp = serveralias + "," + acronym + "," + string(year) + "," + country + "," + "RAW" if guikey1==""
						order guikey1 guikey2 guikey3 guikey4 guicmd guisubexp filename subscribed latest isdownload  downloaddate filesize filemoddate
						compress						
						if "`savepath'"~="" saveold "`savepath'\\Catalog_`server'", replace
						saveold "`persdir'datalibweb\data\Catalog_`server'", replace		
						return local catalogfile "`persdir'datalibweb\data\Catalog_`server'"						
					} //_N==1
				} //_rc
				else {
					dis as error "Cant open the server catalog data."
					error 198
				}
			} //csv
		} //dlibrc
		else {
			dlw_message, error(`dlibrc')
			error 1
		}		
	} //dl=1
end
