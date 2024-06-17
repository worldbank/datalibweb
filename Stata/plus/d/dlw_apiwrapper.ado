program define dlw_apiwrapper
    version 16.0

    //display as error `"`0'"'
    capture plugin call _datalibweb_v2, `0'
    local rc = _rc
    if `rc' {
		dlw_message, error(`rc')
        exit `rc'
    }
    if `dlibrc' != 0 {
		dlw_message, error(`dlibrc')
		exit `dlibrc'
	}

    //display as error "`ldibrc'"
    //display as error "`dlibFileName'"

    c_local dlibrc "`dlibrc'"
    c_local dlibFileName "`dlibFileName'"
    c_local dlibDataSize "`dlibDataSize'"
    c_local dlibType "`dlibType'"
end

capture program define _datalibweb_v2, plugin using("Dlib2SOL_`=cond(strpos(`"`=c(machine_type)'"',"64"),64,32)'.dll")	
if _rc > 0 & _rc != 110 {
    display as error "Unable to load the plugin from its location, please check if Dlib2SOL_`=cond(strpos(`"`=c(machine_type)'"',"64"),64,32)'.dll is copied to PLUS folder or no other plugin application is running."
    exit `= _rc'
}
