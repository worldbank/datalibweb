*! version 0.2 15apr2019
*! Minh Cong Nguyen
* version 0.1 19jan2017 - new
* version 0.2 15apr2019 - enable Support for testing

program define dlw_catalog, rclass	
	version 10, missing
    local verstata : di "version " string(_caller()) ", missing:" 
	syntax, savepath(string) [code(string) server(string) FULLonly ALLVINtages WRKvintage]
	local code = upper("`code'")	
	if ("`code'" ~= "" & "`server'"~="") {
		noi dis as error "Country `code' and server `server' cannot be together. Choose one."
		error 198
	}
	if ("`code'" == "" & "`server'"=="") {
		noi dis as error "Country `code' and server `server' cannot be both empty. Choose one."
		error 198
	}
	if "`code'"~=""   local opt 3
	if "`server'"~="" local opt 2 
	//server catalog
	tempfile servercatalog
	if `opt'==2 {
		dlw_api, option(`opt') outfile(`servercatalog') query("`server'")		
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
						cap replace filepath = subinstr(filepath, "/", "\",.) 
						gen ndir = strlen(filepath) - strlen(subinstr(filepath,"\","",.))
						gen pos0 = strpos(filepath, ".dta")
						gen pos1 = strpos(filepath, ".DTA")
						gen pos = pos0
						replace pos = pos1 if pos1>0
						drop if pos==0
						drop pos0 pos1 pos 
						split filepath, p("\")
						if "`fullonly'"=="" drop if filepath1=="Support"
						ren filepath3 surveyid
						gen pos = strpos(surveyid, "_")
						drop if pos==0
						gen ntoken = strlen(surveyid) - strlen(subinstr(surveyid,"_","",.))
						gen type = "RAW" if ntoken==4
						replace type = "Harmonized" if ntoken==7
						*gen filepathU = upper(filepath)
						*gen pos_data = strpos(filepathU, "DATA")
						
						//Server with data folder
						*if "`server'"=="ASPIRE" | "`server'"=="GPWG" | "`server'"=="GMD" {
						if "`server'"=="ASPIRE" {	
							su ndir, de
							if r(mean)~=3 {
								dis as error "Mixed data system, please check with the admin collection/email datalibbweb@worldbank.org."
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
						if "`server'"=="GMD" | "`server'"=="ECA" | "`server'"=="EAP" | "`server'"=="I2D2" | "`server'"=="LABLAC" | "`server'"=="MNA" | "`server'"=="SAR" | "`server'"=="SEDLAC" | "`server'"=="SSA" | "`server'"=="ECA_Eurostat" | "`server'"=="EDU" {	
							if "`server'"=="GMD" { //temp fix Jan292018
								//GMD for now is 3 dir layer - in the future should be 5 dir layer system
								//temporary fix to move 3-dirs to 5-dirs system so both raw and harmonized can be together
								replace filepath6= filepath4 if filepath6=="" & ndir==3
								replace filepath4="Data" if ndir==3
								replace filepath5="Harmonized" if filepath5==""
							} //temp fix GMD
							
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
							//save all inventory
							saveold "`savepath'", replace
						}
						
						if "`fullonly'"=="" { //keep only harmonized, process to get the latest
							use "`savepath'", clear	
							keep if type=="Harmonized"
							split filename, p("_")
							drop if upper(filename6)=="VTEMP"
							if "`wrkvintage'"=="" drop if upper(filename6)=="WRK" 													
							replace filename6 = lower(filename6)
							replace filename4 = lower(filename4)							
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
							replace mod = upper(mod)
							if "`allvintages'"=="" keep if latest==1
							order code year surveyid survname col mod filename latest
							keep code year surveyid survname col mod filename latest
							sort code year surveyid survname col mod
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
	}
	
	//country catalog
	if `opt'==3 {
		tempfile tmpcatalog
		dlw_api, option(`opt') outfile(`tmpcatalog'), query("`code'")		
		if `dlibrc'==0 {
			if ("`dlibType'"=="csv" | "`dlibType'"=="bin") {
				cap insheet using "`tmpcatalog'", clear	names
				if _rc==0 {
					if _N==1 noi dis as text in white "No data in the catalog for this country `code'."
					else {
						ren survey acronym						
						split filepath, p("\" "/")
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
	}
end
