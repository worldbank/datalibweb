program define datalibweb
    version 16

    syntax [, version(string) token(passthru) *]
	
	if "$DATALIBWEB_VERSION"=="" {
		 // use version 2 by default
		if "`version'" == "" {
			local version "3"
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
    else if "`version'" == "3" | "`version'" == "" {
        local command "datalibweb_v3"        
    }
    else {
        display as error "incorrect version `version'"
        exit 198
    }
    
    if "`token'" != "" {
        if "`version'" != "2" {
            display as error "token() option is only supported with version(2) at this moment"
        }
        dlw_api, opt(8) `token' // any other parameter present would be ignored
        exit
    }
    `command', `options'

end
