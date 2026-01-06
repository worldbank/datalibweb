program define dlw_api
    version 16.0

    // shouldn't happen but let's still confirm
    if inlist("$DATALIBWEB_VERSION", "1", "2", "3") == 0 {
        display as error "Unsupported API version $DATALIBWEB_VERSION"
        exit 198
    }

    _dlw_api_v$DATALIBWEB_VERSION `0'

    c_local dlibrc "`dlibrc'"
    c_local dlibFileName "`dlibFileName'"
    c_local dlibDataSize "`dlibDataSize'"
    c_local dlibType "`dlibType'"
end

program define _dlw_api_v1, rclass
    version 16.0
    syntax, OPTion(integer) OUTfile(string) [Query(string) Reqtype(string)]

    capture program define _datalibweb, plugin using("dlib2_`=cond(strpos(`"`=c(machine_type)'"',"64"),64,32)'.dll")
    if _rc > 0 & _rc != 110 {
        display as error "something went wrong"
        exit `= _rc'
    }
	if (`option'==6) {
        local paramlist option outfile query reqtype
    }
    else {
        local paramlist option outfile query
    }

    // plugin fails if given an empty string
    foreach param of local paramlist {
        if "``param''" != "" {
            local nonemptyoptions `"`nonemptyoptions' "``param''""'
        }
    }
    plugin call _datalibweb, `nonemptyoptions'

    c_local dlibrc "`dlibrc'"
    c_local dlibFileName "`dlibFileName'"
    c_local dlibDataSize "`dlibDataSize'"
    c_local dlibType "`dlibType'"
end

program define _dlw_api_v2, rclass
    version 16.0
    syntax, OPTion(integer) [OUTfile(string) Query(string) Reqtype(string) Token(string)]
	
    capture program define _datalibweb_v2, plugin using("dlib2sol_`=cond(strpos(`"`=c(machine_type)'"',"64"),64,32)'.dll")	
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
			cap plugin call _datalibweb_v2, "`option'" "`user'" "`token'"
			if _rc==0 {
				noi dis as text "Datalibweb token is registered. The token is valid for 30 days as indicated in the datalibweb website."		
				c_local dlibrc "`dlibrc'"
				c_local dlibFileName "`dlibFileName'"
				c_local dlibDataSize "`dlibDataSize'"
				c_local dlibType "`dlibType'"				
			}
			else {
				noi dis as error "Datalibweb token is invalid or expired. Please visit the datalibweb website to renew the token."
				noi dis `"{browse "https://datalibweb2.worldbank.org/home":https://datalibweb2.worldbank.org/home}"'
				view browse https://datalibweb2.worldbank.org/home				
				noi dis as text "Under your name in the website, click on the renew token. Copy it and paste on the command below."
				noi dis as text "Use this: dlw, token(your copied token)"
				global errcode `=_rc'				
				error 1				
			}
		} //token provided
		else {
			noi dis as error "Datalibweb token is needed for the API option 8. Please provide the token in the option token()."
			noi dis `"{browse "https://datalibweb2.worldbank.org/home":https://datalibweb2.worldbank.org/home}"'
			view browse https://datalibweb2.worldbank.org/home		
			noi dis as text "Use this: dlw, token(your copied token)"
			global errcode 198
			error 198
		}		
	} //opt 8
	else { //other API options, not 8			
		if (`option'==6) { //user audit
			cap plugin call _datalibweb_v2, "`option'" "`outfile'" "`user'" "`query'" "`reqtype'" "Y"
		}	
		else if (`option'==5) { //user subcription
			cap plugin call _datalibweb_v2, "`option'" "`outfile'" "`user'" "`query'"
		}
		else { //0 2 3 9
			if "`query'"~="" cap plugin call _datalibweb_v2, "`option'" "`outfile'" "`query'"
			//option 4 only
			else cap plugin call _datalibweb_v2, "4" "`outfile'" 
		}
		if _rc==0 {
			c_local dlibrc "`dlibrc'"
			c_local dlibFileName "`dlibFileName'"
			c_local dlibDataSize "`dlibDataSize'"
			c_local dlibType "`dlibType'"
		}
		else {
			dlw_message, error(`=_rc')
			global errcode `=_rc'			
			error $errcode
		}
	} //other API options
end

//DLW SOL internal
program define _dlw_api_v3, rclass
    version 16.0
    syntax, OPTion(integer) [OUTfile(string) Query(string) Reqtype(string) Token(string)]
	local user = c(username)	
    capture program define _datalibweb_v3, plugin using("/jupyterhub_plugins/datalibweb.plugin")
	*capture program define _datalibweb_v3, plugin using("/userdata/`user'/ado/plus/d/datalibweb.plugin")
    if _rc > 0 & _rc != 110 {
        display as error "Unable to load the plugin from its location, please check your folder /ado/plus/d/datalibweb.plugin or no other plugin application is running."
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
			cap plugin call _datalibweb_v3, "`option'" "`user'" "`token'"
			if _rc==0 {
				noi dis as text "Datalibweb token is registered. The token is valid for 30 days as indicated in the datalibweb website."		
				c_local dlibrc "`dlibrc'"
				c_local dlibFileName "`dlibFileName'"
				c_local dlibDataSize "`dlibDataSize'"
				c_local dlibType "`dlibType'"				
			}
			else {
				noi dis as error "Datalibweb token is invalid or expired. Please visit the datalibweb website to renew the token."
				noi dis `"{browse "https://datalibweb2.worldbank.org/home":https://datalibweb2.worldbank.org/home}"'
				*view browse https://datalibweb2.worldbank.org/home				
				noi dis as text "Under your name in the website, click on the renew token. Copy it and paste on the command below."
				noi dis as text "Use this: dlw, token(your copied token)"
				global errcode `=_rc'				
				error 1				
			}
		} //token provided
		else {
			noi dis as error "Datalibweb token is needed for the API option 8. Please provide the token in the option token()."
			noi dis `"{browse "https://datalibweb2.worldbank.org/home":https://datalibweb2.worldbank.org/home}"'
			*view browse https://datalibweb2.worldbank.org/home		
			noi dis as text "Use this: dlw, token(your copied token)"
			global errcode 198
			error 198
		}		
	} //opt 8
	else { //other API options, not 8			
		if (`option'==6) { //user audit
			cap plugin call _datalibweb_v3, "`option'" "`outfile'" "`user'" "`query'" "`reqtype'" "Y"
		}	
		else if (`option'==5) { //user subcription
			cap plugin call _datalibweb_v3, "`option'" "`outfile'" "`user'" "`query'"
		}
		else { //0 2 3 9
			if "`query'"~="" cap plugin call _datalibweb_v3, "`option'" "`outfile'" "`query'"
			//option 4 only
			else cap plugin call _datalibweb_v3, "4" "`outfile'" 
		}
		if _rc==0 {
			//temp for now
			if (`option'~=0) local dlibType csv			
			local dlibType `=subinstr("`dlibType'","application/","",.)'
			c_local dlibrc "`dlibrc'"
			c_local dlibFileName "`dlibFileName'"
			c_local dlibDataSize "`dlibDataSize'"
			c_local dlibType "`dlibType'"
		}
		else {
			dlw_message, error(`=_rc')
			global errcode `=_rc'			
			error $errcode
		}
	} //other API options
end