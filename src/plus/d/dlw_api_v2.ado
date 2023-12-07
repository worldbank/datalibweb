*! version 0.02 28nov2023
*! Minh Cong Nguyen, Zurab Sajaia 

program define dlw_api_v2, rclass
    version 16
    syntax, OPTion(integer) [OUTfile(string) Query(string) Reqtype(string) Token(string)]
	
    capture program define _datalibweb, plugin using("Dlib2SOL_`=cond(strpos(`"`=c(machine_type)'"',"64"),64,32)'.dll")	
    if _rc > 0 & _rc != 110 {
        display as error "Unable to load the plugin from its location, please check if Dlib2SOL_`=cond(strpos(`"`=c(machine_type)'"',"64"),64,32)'.dll is copied to PLUS folder or no other plugin application is running."
        exit `= _rc'
    }
	
	local user = upper(c(username))
	local user = subinstr("`user'","WB","",.)
	local user = subinstr("`user'","C","",.)
	local user = subinstr("`user'","S","",.)
	local user = subinstr("`user'","D","",.)
			
	//load register first it is asked via dlw_api
	if (`option'==8) { //register token
		if "`token'"~="" {			
			local user = `=9-length("`user'")'*"0" + "`user'"
			cap plugin call _datalibweb, "`option'" "`user'" "`token'"
			if _rc==0 {
				noi dis as text "Datalibweb token is registered. The token is valid for 30 days as indicated in the datalibweb website."		
				c_local dlibrc "`dlibrc'"
				c_local dlibFileName "`dlibFileName'"
				c_local dlibDataSize "`dlibDataSize'"
				c_local dlibType "`dlibType'"				
			}
			else {
				noi dis as error "Datalibweb token is invalid or expired. Please visit the datalibweb website to renew the token."
				noi dis as text "Use this: dlw_api, option(8) token(your token here)"
				exit `= _rc'
			}
		} //token provided
		else {
			noi dis as error "Datalibweb token is needed for the API option 8. Please provide the token in the option token()."
			noi dis as text "Use this: dlw_api, option(8) token(your token here)"
			global errcode 198
			error 198
		}		
	} //opt 8
	else { //other API options, not 8			
		if (`option'==6) { //user audit
			plugin call _datalibweb, "`option'" "`outfile'" "`user'" "`query'" "`reqtype'"
		}	
		else if (`option'==5) { //user subcription
			plugin call _datalibweb, "`option'" "`outfile'" "`user'" "`query'"
		}
		else { //0 2 3 9
			if "`query'"~="" plugin call _datalibweb, "`option'" "`outfile'" "`query'"
			//option 4 only
			else plugin call _datalibweb, "4" "`outfile'" 			
		}
		
		c_local dlibrc "`dlibrc'"
		c_local dlibFileName "`dlibFileName'"
		c_local dlibDataSize "`dlibDataSize'"
		c_local dlibType "`dlibType'"
		
	} //other API options
end
