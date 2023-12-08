program define datalibweb
    version 16

    syntax [, version(string) token(passthru) *]

    // use version 1 by default
    if "`version'" == "" {
        local version "1"
    }

    if "`version'" == "1" | "`version'" == "" {
        local command "datalibweb_v1"
    }
    else if "`version'" == "2" {
        local command "datalibweb_v2"        
    }
    else {
        display as error "incorrect version `version'"
        exit 198
    }

    global DATALIBWEB_VERSION `version'

    if "`token'" != "" {
        if "`version'" != "2" {
            display as error "token() option is only supported with version(2) at this moment"
        }
        dlw_api, opt(8) `token' // any other parameter present would be ignored
        exit
    }
    `command', `options'

end
