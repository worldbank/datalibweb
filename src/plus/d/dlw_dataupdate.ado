*! version 0.2 12dec2019
*! Minh Cong Nguyen
* version 0.1 15jul2017 - original
cap program drop dlw_dataupdate
program define dlw_dataupdate
	set checksum off
	set more off
	
	local other : sysdir PERSONAL
    if "$S_OS"=="Windows" local other : subinstr local other "/" "\", all	
	if ("`other'" == "") {
		local other "c:\ado\personal\"
		cap mkdir "`other'"
	}
	cap confirm file `"`other'datalibweb\data\dlw_getfile.dta"'
	if _rc==0 {
		cap use `"`other'datalibweb\data\dlw_getfile.dta"', clear
		if _rc==0 {
			local all =_N
			tempfile dldata
			save `dldata', replace
			forv i=1(1)`all' {
				use `dldata', clear				
				local code 		`=countrycode[`f']'
				local year  	`=year[`f']'
				local type 		`=collection[`f']'
				local filename 	`=file[`f']'
				local relpath 	`=relpath[`f']'
				local ids  		`=surveyid[`f']'
				
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
				}
			}
		}
		else {
			noi dis as error "Cant open the data (dlw_getfile). Data was saved under new version of Stata or file is corrupted."
			error 198
		}
	}
	else {
		noi dis as error "Cant find the data (dlw_getfile) or users did not use the getfile option in the past. No file is updated."
		exit
	}
end
