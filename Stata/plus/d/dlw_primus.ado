*! version 0.1 22oct2024
*! Minh Cong Nguyen
cap program drop dlw_primus
program define dlw_primus, rclass	
	version 10, missing
    local verstata : di "version " string(_caller()) ", missing:" 
	syntax, COUNtry(string) Year(string) type(string)  TRANxid(string) [filename(string)]
	
	local country = upper("`country'")	
	
	//check if .do is available	
	local persdir : sysdir PERSONAL
    if "$S_OS"=="Windows" local persdir : subinstr local persdir "/" "\", all
		
	cap confirm file "`persdir'datalibweb/`=upper("`type'")'.do"
	if _rc==0 { //available and load
		qui do "`persdir'datalibweb/`=upper("`type'")'.do"
	}
	
	local user = upper(c(username))
	local user = subinstr("`user'","WB","",.)
	local user = subinstr("`user'","C","",.)
	local user = subinstr("`user'","S","",.)
	local user = subinstr("`user'","D","",.)
	
	local opt 9
	
	//get the list or specific files from pending transactions in PRIMUS
	tempfile primusout
	local tmppath = substr("`primusout'",1,length("`primusout'")-strpos(reverse("`primusout'"),"\")+1)	
	
	*foreach cstr in collection folder token filename para1 para2 para3 para4 {
	foreach cstr in folder token filename para1 para2 para3 para4 {
		if "``cstr''"=="" local s_`cstr'
		else local s_`cstr' "&`cstr'=``cstr''"
	}
	local dlibapi "Upi=`user'&Server=$rootname&Country=`country'&Year=`year'&Collection=$type&TransactionId=`tranxid'&`s_collection'`s_folder'`s_token'`s_filename'`s_para1'`s_para2'`s_para3'`s_para4'`s_ext'"			
	*noi dis `"dlw_api, option(9) outfile(`primusout') query("`dlibapi'")"'
	dlw_api, option(9) outfile(`primusout') query("`dlibapi'")
	if `dlibrc'==0 {
		if "`dlibFileName'"=="ECAFileinfo.csv" {
			qui insheet using "`primusout'", clear
			noi dis "File list is loaded"
		}
		else { //different filenames
			if "`=lower("`dlibType'")'"=="dta" { // only one file matched/subscribed - load the file  									
				cap use `primusout', clear	 //load the data
				if _rc==0 {
					noi dis "Data file is loaded"
				}
				else {
					noi dis as text in red "{p 4 4 2}Can't open the file (`dlibFileName'). Data file was saved with new Stata versions.{p_end}"	
					global errcode = 999
					error 1
				}
			} // dta type
			else if "`=lower("`dlibType'")'"=="do" { // only one file matched/subscribed - load the file  													
				cap doedit "`tmppath'\`dlibFileName'"
				if _rc==0 {
					noi dis as text in yellow `"{p 4 4 2}The dofile (`dlibFileName') is loaded.{p_end}"'	
					return local type `collection'
					return local module `mod'
					return local verm `verm'
					return local vera `vera'
					return local surveyid `surveyid'
					return local filename `dlibFileName'
					return local idno `r(id)'
				}
				else {
					noi dis as text in red "{p 4 4 2}This dofile (`dlibFileName') is not a properly formatted dofile.{p_end}"	
					global errcode = 999
					error 1
				}
			} //do
			else { //different types
				cap shell `tmppath'\`dlibFileName'
				if _rc==0 {
					noi dis as text in yellow `"{p 4 4 2}The file (`dlibFileName') is loaded in the corresponding application.{p_end}"'	
					return local type `collection'
					return local module `mod'
					return local verm `verm'
					return local vera `vera'
					return local surveyid `surveyid'
					return local filename `dlibFileName'
					return local idno `r(id)'
				}
				else { //cant 
					noi dis as text in red "{p 4 4 2}Can't open the file (`dlibFileName'). This file extension is not supported yet by your operating systems or the file is damaged.{p_end}"	
					global errcode = 999
					error 1
				}
			} //others
		} //diff filename
	} //dlibrc
		
end