*! version 0.1 26nov2016
*! Minh Cong Nguyen
capture program define _datalibweb, plugin using("dlib2_`=cond(strpos(`"`=c(machine_type)'"',"64"),64,32)'.dll")
*capture program define _datalibweb, plugin using("DataLib`=cond(strpos(`"`=c(machine_type)'"',"64"),64,32)'.dll")

cap program drop dlw_getfile
program define dlw_getfile, rclass	
	version 12, missing
    local verstata : di "version " string(_caller()) ", missing:" 
	syntax, COUNtry(string) Year(numlist max=1) [server(string) save(string) ///
	COLlection(string) surveyid(string) folder(string) level(numlist max=1) ///
	token(numlist max=1) filename(string) txtname(string) module(string) ///
	para1(string) para2(string) para3(string) para4(string) ///
	ext(string) latest savepath(string) NOMETA NET base ///
	request(string) VERMast(string) VERAlt(string)]

	// Error
	global errcode 0
	// pass to _datalibweb
	tempfile temp1
	local collname `server'
	
	local persdir : sysdir PERSONAL
    if "$S_OS"=="Windows" local persdir : subinstr local persdir "/" "\", all
	cap mkdir "`persdir'datalibweb/data"
	/*
	if "`para1'" == "" local para1 `surveyid'
	if ("`surveyid'" ~= "" & "`flnames'"~="") local flnames `flnames' 		
	if ("`surveyid'" ~= "" & "`flnames'"=="") {
		if strpos("`=upper("`col'")'","ORIGINAL") >0 local flnames 	
		else                                         local flnames `surveyid'
	}
	if ("`surveyid'" == "" & "`flnames'"~="") local flnames `flnames'
	*/
	*local col2 `col'
	*if strpos("`=upper("`col'")'","ORIGINAL") >0 local col2 
	
	local version
	if "`vermast'" == "" & "`veralt'" =="" & "`surveyid'"=="" local latest latest
	if "`vermast'" ~= "" & "`veralt'" ~="" local version `vermast'_M_`veralt'_A
	if "`vermast'" ~= "" & "`veralt'" =="" local version `vermast'_M
	if "`vermast'" == "" & "`veralt'" ~="" local version `veralt'_A	
	
	foreach cond in version surveyid { //add version and/or surveyid to para1-4
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

	foreach cstr in collection folder token filename para1 para2 para3 para4 ext {
		if "``cstr''"=="" local s_`cstr'
		else local s_`cstr' "&`cstr'=``cstr''"
	}
	local dlibapi "Server=`server'&Country=`country'&Year=`year'`s_collection'`s_folder'`s_token'`s_filename'`s_para1'`s_para2'`s_para3'`s_para4'`s_ext'"
	dlw_api, option(0) outfile(`temp1') query("`dlibapi'")
	qui if `dlibrc'==0 { //1st _datalibweb
		if "`dlibFileName'"=="ECAFileinfo.csv" { // results in list of files
			qui insheet using "`temp1'", clear	
			if _N==1 {
				cap confirm numeric variable filename
				if _rc==0 {
					noi dis as text in white "{p 4 4 2}`=errordetail[1]'{p_end}"
					dlw_message, error(`=errorcode[1]')
					global errcode `=errorcode[1]'
					clear
					error 1
				}
			}
			qui {		
				cap drop filepath
				ren filename file
				cap split filesharepath, p("\")
				ren filesharepath3 survey
				ren filesharepath4 surveyid
				ren filesharepath path
				gen ext = substr(file,length(file)-strpos(reverse(file),".")+2,strpos(reverse(file),"."))
				replace filesize = subinstr(filesize, " bytes","",.)
				destring filesize, replace
				replace filesize = round(filesize/1e6,.001) 
				//Clean and Save the filesearch data
				order survey surveyid path file		
				qui compress
				cap drop __*  
				cap drop filesharepath*
				qui drop if path==""
				
				gen ntoken = strlen(surveyid) - strlen(subinstr(surveyid,"_","",.))
				gen type = "RAW" if ntoken==4
				replace type = "Harmonized" if ntoken==7
				split surveyid, p(_)
				ren surveyid1 countrycode
				ren surveyid2 year
				ren surveyid3 surveyname
				ren surveyid4 verm
				ren surveyid5 verm_l
				gen str collection = ""
				replace collection = "`=upper("`server'")'RAW" if type == "RAW"
			}
			cap confirm variable surveyid8
			qui if _rc==0 {
				ren surveyid6 vera
				ren surveyid7 vera_l
				replace collection = surveyid8 if type == "Harmonized"	
				split file if type == "Harmonized", p(_)					
				clonevar col2 = file8
				local col2
				count if col2~=collection
				if r(N)>0 local col2 col2
				cap gen str mod = ""
				cap replace mod = substr(file9,1,length(file9)-4)					
				cap drop file1-file9
			}	
			//tempfile datatemp
			//qui save `datatemp', replace
			
			qui levelsof survey, local(surlist) // check survey types
			if `=wordcount(`"`surlist'"')' >1 { // more than one type of survey
				noi dis in yellow _n "{p 4 4 2}There are `=wordcount(`"`surlist'"')' different types of surveys with defined parameters. Click on the following links to redefine the search.{p_end}"					
				local rn = 1
				local rn2 = 1
				bys survey (file): gen seq = _n
				bys survey (file): gen seqN = _N			
				foreach ids of local surlist {		
					local text datalibweb $dlcmd surveyid(`ids')
					//local text datalibweb, country(`=countrycode[`rn']') year(`=year[`rn']') type(`=collection[`rn']') surveyid(`ids') `nometa'						
					noi dis as text `"`rn2'. [{stata `"`text'"':`text'}]"'								
					noi dis as text in white "{p 4 4 2}`=errordetail[`rn']'{p_end}"
					if "`net'" ~="" noi dis `"<a onclick="sendCommand('`text'')">`text'</a>"'
					local rn = `rn' + `=seqN[`rn']'	
					local rn2 = `rn2' + 1
					//if "`nometa'"=="" _metadisplay, surveyid(`=trim("`ids'")')											
				}			
				global errcode `=errorcode[1]'
				clear
				error 1
			} //end of more than one survey types
			else { //one type of survey only
				if _N>0 {
					if errorcode[1] > 2 { //0: OK,1: file too big,2: public files
						dlw_message, error(`=errorcode[1]')
						global errcode `=errorcode[1]'
						clear
						error 1
					}
					
					//always get the latest for the offline
					cap drop if upper(verm)=="WRK"
					cap drop if upper(vera)=="WRK"
					gen relpath = subinstr(path, file, "",.)
					
					//need to be checked by each module
					if $token==8 { //harmonized data
						bysort `col2' mod (collection verm vera): gen _latest = _N==_n
						qui keep if _latest==1						
						qui drop _latest
					}
					if $token==5 { //raw				
						qui levelsof verm, local(mlist)
						listsort `"`mlist'"', lexicographic						
						qui keep if verm=="`=word(`"`s(list)'"',-1)'"
					}
															
					//loop through each file in the list and get it
					tempfile datalist
					local chklist isdownload filelastdownloadeddate
					foreach var of local chklist {
						cap confirm numeric variable `var'
						if _rc==0 {
							drop `var'
							gen str `var' = ""
						}
					}
					gen str downloaded = "$S_DATE"
					local nfiles = _N
					qui save `datalist', replace					
					
					//Save to record downloaded files for updating later
					cap confirm file "`persdir'datalibweb/data/dlw_getfile.dta"
					if _rc==0 {
						use "`persdir'datalibweb/data/dlw_getfile.dta", clear
						append using `datalist'
						char _dta[version] $S_DATE
						bys path (filelastmodifeddate): gen ok = _n==_N
						keep if ok==1
						drop ok usersubscribed errorcode errordetail isdownload filelastdownloadeddate ext ntoken relpath verm verm_l 
						cap drop vera 
						cap drop vera_l 
						cap drop surveyid8
						compress
						save "`persdir'datalibweb/data/dlw_getfile.dta", replace
					}
					else {
						char _dta[version] $S_DATE	
						drop usersubscribed errorcode errordetail isdownload filelastdownloadeddate ext ntoken relpath verm verm_l 
						cap drop vera 
						cap drop vera_l 
						cap drop surveyid8
						compress
						save "`persdir'datalibweb/data/dlw_getfile.dta", replace
					}
					
					use `datalist', clear
					noi dis as text in yellow "{p 4 4 2}Getting `nfiles' files for `=surveyid[1]':{p_end}"
					noi list file, sep(0)
					forv f=1(1)`nfiles' { //loop by files
						use `datalist', clear
						local code 		`=countrycode[`f']'
						local year  	`=year[`f']'
						local type 		`=collection[`f']'
						local filename 	`=file[`f']'
						local relpath 	`=relpath[`f']'
						local ids  		`=surveyid[`f']'
						local err 		`=errorcode[`f']'
						if `=errorcode[`f']' <= 2 { //subscribed files
							*if (strpos("`=upper("`relpath'")'","ORIGINAL") > 0) local relpath : subinstr local relpath "Original" "Stata"							
							foreach cstr in collection folder token filename para1 para2 para3 para4 ext {
								if "``cstr''"=="" local s_`cstr'
								else local s_`cstr' "&`cstr'=``cstr''"
							}							
							local dlibapi "Server=`server'&Country=`code'&Year=`year'`s_collection'`s_folder'`s_token'`s_filename'`s_para1'`s_para2'`s_para3'`s_para4'`s_ext'"
							if "`surveyid'"~="" local dlibapi : subinstr local dlibapi "`surveyid'" "`ids'" //replace surveyid with ids							
							tempfile temp2
							dlw_api, option(0) outfile(`temp2') query("`dlibapi'")
							if `dlibrc'==0 {
								if "`dlibFileName'"~="ECAFileinfo.csv" {
									if ("`savepath'"~="" & "`relpath'" ~="") {
										cap shell mkdir -p "`savepath'\\`relpath'"
										if "`dlibType'"=="dta" {
											cap copy "`temp2'" "`savepath'\\`relpath'\\`filename'", replace
											if _rc==0 noi dis as text in white "{p 4 4 2}File (`filename') is successfully saved here (`savepath').{p_end}"
											else      noi dis as text in red   "{p 4 4 2}File (`filename') is NOT successfully saved due to permission issues, please check.{p_end}"
										}
										else { //non-dta file
											local tmppath = substr("`temp2'",1,length("`temp2'")-strpos(reverse("`temp2'"),"\")+1)				
											cap copy "`tmppath'\`dlibFileName'" "`savepath'\\`relpath'\\`filename'", replace
											if _rc==0 noi dis as text in white "{p 4 4 2}File (`filename') is successfully saved here (`savepath').{p_end}"
											else      noi dis as text in red   "{p 4 4 2}File (`filename') is NOT successfully saved due to permission issues, please check.{p_end}"										
										}
									}
									else { //savepath
										dis as error "Paths to save are not available. Please check."
									}
								}
								else { //ECAFileinfo.csv
									dis as error "Subscription data is changed in between the sessions, please check with the admin."
								}
							} 
							else {	
								dlw_message, error(`dlibrc')
							} //end else of _rc plugin
						} //errcode
					} //loop by files
				} //_N>0
				else {
					noi dis as text in white "{p 4 4 2}There is no survey/data with defined parameters: `col2', `country', `year', `surveyid'{p_end}"
					error 1
				} //_N==0
			} //one type of survey only	
		} //ECAFileinfo.csv
		else { //single file with permission
			noi dis as text "check here"			
			*relpath \ALB\ALB_2008_LSMS\ALB_2008_LSMS_v03_M\Data\Stata\
			*local relpath "\`code'\"	
			//copy the file
			//cap shell mkdir -p "`savepath'\\`relpath'"
			//cap copy "`temp1'" "`savepath'\\`relpath'\\`file'", replace
			//if _rc==0 noi dis as text in yellow "{p 4 4 2}`file' is successfully saved here (`savepath').{p_end}"
			//else      noi dis as text in yellow "{p 4 4 2}`file' is NOT successfully saved.{p_end}"
			use "`temp1'", clear
		}
	} //1st _datalibweb
	else {
		dlw_message, error(`dlibrc')
		global errcode `dlibrc'
		clear
		error 1
	} //end else of//1st _datalibweb
end
