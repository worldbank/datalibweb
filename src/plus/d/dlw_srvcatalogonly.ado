program define dlw_srvcatalogonly, rclass	
	version 10, missing
    local verstata : di "version " string(_caller()) ", missing:" 
	syntax, server(string) savepath(string) 
	local server = upper("`server'")	
	
	//server catalog	
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
					if "`server'"=="ECA" | "`server'"=="EAP" | "`server'"=="I2D2" | "`server'"=="LABLAC" | "`server'"=="MNA" | "`server'"=="SAR" | "`server'"=="SEDLAC" | "`server'"=="SSA" | "`server'"=="ECA_EUROSTAT" {	
						keep if upper(filepath4)=="DATA"							
						drop if strpos(upper(filepath5), ".DTA") > 0
						keep if upper(filepath5)=="HARMONIZED"								
						ren filepath6 filename
						gen str guikey4 = filepath4 + "\" + filepath5							
					}		
					
					split filename, p("_")
					drop if upper(filename6)=="WRK"
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
					
					sort guikey1 guikey2 guikey3 guikey4 														
					cap drop ext relpath
					cap drop filepath* ndir pos ntoken				
					ren survey acronym
					
					char _dta[version] $S_DATE		
					order guikey1 guikey2 guikey3 guikey4  filename  latest 
					compress						
					saveold "`savepath'", replace					
				} //_N==1
			} //_rc
			else {
				dis as error "Can't open the server catalog data."
				error 198
			}
		} //csv
	} //dlibrc
	else {
		dlw_message, error(`dlibrc')
		error 1
	}
end
