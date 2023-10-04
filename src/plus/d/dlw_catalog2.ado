*! version 0.1 19jan2017
*! Minh Cong Nguyen

program define dlw_catalog, rclass	
	version 10, missing
    local verstata : di "version " string(_caller()) ", missing:" 
	syntax, savepath(string) [code(string) server(string) FULLonly update]	
	local persdir : sysdir PERSONAL
	if "$S_OS"=="Windows" local persdir : subinstr local persdir "/" "\", all
	if ("`code'" ~= "" & "`server'"~="") {
		noi dis as error "Country `code' and server `server' cannot be together. Choose one."
		error 198
	}
	if ("`code'" == "" & "`server'"=="") {
		noi dis as error "Country `code' and server `server' cannot be both empty. Choose one."
		error 198
	}
	if "`code'"~="" {
		local opt 3
		local code = upper("`code'")
		local filecheck "`persdir'datalibweb/data/Catalog_`code'"
	}
	if "`server'"~="" {
		local opt 2 
		local server = upper("`server'")
		local filecheck "`persdir'datalibweb/data/`server'_latest"
	}
	local dl 0
	if "`update'"=="update" local dl 1
	else {		
		if "`savepath'"=="" {
			cap confirm file "`filecheck'.dta"
			if _rc==0 {
				cap use "`filecheck'.dta", clear	
				if _rc==0 {
					local dtadate : char _dta[version]			
					if "$updateday"=="" global updateday 1
					if (date("$S_DATE", "DMY")-date("`dtadate'", "DMY")) > $updateday local dl 1				
					else return local catalogfile "`filecheck'"
				}
				else local dl 1
			}
			else {
				cap mkdir "`persdir'datalibweb\data"
				local dl 1
			}	
		}
	}
	
	qui if `dl'==1 {
		//server catalog
		tempfile servercatalog
		if `opt'==2 {
			dlw_api, option(`opt') outfile(`servercatalog') query("`server'")
			local dlibrc `r(rc)'
			if `dlibrc'==0 {
				if ("`dlibType'"=="csv") {
					//local ser = subinstr("`server'",".xml","",.)
					cap insheet using "`servercatalog'", clear names
					if _rc==0 {
						if _N==1 {
							noi dis as text in white "No data in the catalog for this server `server'."
							error 198
						}
						else {
							cap drop v7 v8
							cap drop if year=="NULL"
							cap destring year, replace
							gen ndir = strlen(filepath) - strlen(subinstr(filepath,"\","",.))
							gen pos0 = strpos(filepath, ".dta")
							gen pos1 = strpos(filepath, ".DTA")
							gen pos = pos0
							replace pos = pos1 if pos1>0
							drop if pos==0
							drop pos0 pos1 pos 
							split filepath, p("\")
							drop if filepath1=="Support"
							ren filepath3 surveyid
							gen pos = strpos(surveyid, "_")
							drop if pos==0
							gen ntoken = strlen(surveyid) - strlen(subinstr(surveyid,"_","",.))
							gen type = "RAW" if ntoken==4
							replace type = "Harmonized" if ntoken==7
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
									drop pos ntoken ndir filepath*
									compress
									saveold "`savepath'", replace //save all inventory
								}		
							}
							
							//Server without data folder
							if "`server'"=="ECA" | "`server'"=="EAP" | "`server'"=="I2D2" | "`server'"=="LABLAC" | "`server'"=="MNA" | "`server'"=="SAR" | "`server'"=="SEDLAC" | "`server'"=="SSA" {	
								keep if upper(filepath4)=="DATA"
								//filepath7 should be empty or not available		
								cap des filepath7
								if _rc==0 drop if filepath7~=""		
								ren filepath1 code
								ren filepath2 surv
								ren filepath4 folder1
								ren filepath5 folder2
								ren filepath6 filename
								ren filepath relpath
								cap drop pos ntoken ndir filepath*
								compress								
								saveold "`savepath'", replace //save all inventory
							}
							
							if "`fullonly'"=="" { //keep only harmonized, process to get the latest
								use "`savepath'", clear	
								keep if type=="Harmonized"
								split filename, p("_")
								drop if upper(filename6)=="WRK"
								cap drop code
								ren filename1 code
								//ren filename2 year
								ren filename3 survname
								ren filename4 verm
								ren filename6 vera
								ren filename8 col
								ren filename9 mod
								replace mod = subinstr(mod,".dta","",.)
								replace mod = subinstr(mod,".dta","",.)
								drop if mod==""
								bys code year survname col mod (verm vera): gen latest = _n==_N
								keep if latest==1
								replace mod = upper(mod)
								order code year survname col mod filename
								keep code year survname col mod filename
								sort code year survname col mod
								char _dta[version] $S_DATE	
								compress
								saveold "`savepath'", replace	
							}
						} //_N==1
					} //_rc
					else {
						dis as error "Cant open the server catalog data."
						error 198
					}
				} //xml
			} //dlibrc
			else {
				dlw_message, error(`dlibrc')
				error 1
			}
		} //opt 2
		
		//country catalog
		if `opt'==3 {
			tempfile tmpcatalog
			dlw_api, option(`opt') outfile(`tmpcatalog') query("`code'")
			local dlibrc `r(rc)'
			if `dlibrc'==0 {
				if ("`dlibType'"=="csv" | "`dlibType'"=="bin") {
					cap insheet using "`tmpcatalog'", clear	
					if _rc==0 {
						if _N==1 noi dis as text in white "No data in the catalog for this country `code'."
						else {
							ren survey acronym
							split filepath, p("\")
							ren filepath3 surveyid
							gen token = 1 + strlen(surveyid) - strlen(subinstr(surveyid,"_","",.))
							gen type = "RAW" if token==5
							replace type = "Harmonized" if token==8
							gen filename = substr(filepath, length(filepath)-strpos(reverse(filepath), "\")+2, .)
							cap drop filepath?
							save `savepath', replace
						} //_N
					} //_rc
					else {
						dis as error "Cant open the country catalog data."
						error 198
					}
				} //dlibtype
			} //dlibrc
			else {
				dlw_message, error(`dlibrc')
				error 1
			}
		} //opt 3	
	} //end dl==1
	end
