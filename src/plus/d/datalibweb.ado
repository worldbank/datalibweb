program define datalibweb
    version 16

    syntax [, version(string) *]

    // use version 1 by default
    if "`version'" == "" {
        local version "1"
    }

    if "`version'" == "1" | "`version'" == "" {
        local command "datalibweb_v1"
    }
    else if "`version'" == "2" {
        display as error "not implemented"
        exit 198
    }
    else {
        display as error "incorrect version `version'"
        exit 198
    }

    global DATALIBWEB_VERSION `version'
    `command', `options'

end
