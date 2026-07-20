program define datalibweb
    version 16

    syntax [, version(string) token(passthru) email(passthru) *]
	
	if "$DATALIBWEB_VERSION"=="" {
		if "`version'" == "" {
			local version "4"
		}
		global DATALIBWEB_VERSION `version'
	}
	else { //DATALIBWEB_VERSION exists so use that
		if "`version'" ~= "" global DATALIBWEB_VERSION `version'			
		else local version $DATALIBWEB_VERSION
	}
	   	
    if "`version'" == "1" {
        local command "datalibweb_v1"
    }
	if "`version'" == "2" {
        local command "datalibweb_v2"
    }
    else if "`version'" == "4" | "`version'" == "" {
        local command "datalibweb_v4"        
    }
    else {
        display as error "incorrect version `version'"
        exit 198
    }
    
    if "`token'" != "" {
        if "`version'" != "4" {
            display as error "token() and email() options are only supported with this external version."
        }
        dlw_api, opt(8) `token' `email' // any other parameter present would be ignored
        exit
    }
    `command', `options'

end
