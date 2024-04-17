program define dlw_apiclient
    version 16.0

    gettoken action 0 : 0, parse(" ,")

	if inlist("`action'", "audit", "get_file", "country_catalog", "server_catalog", "server_configs", "subscriptions", "register") == 0 {
		display as error "Action `action' is not supported."
		exit 198
	}

    if "`action'" == "register" {

		syntax , Token(string)

		local user = upper(c(username))
		local user = subinstr("`user'","WB","",.)
		local user = subinstr("`user'","C","",.)
		local user = subinstr("`user'","S","",.)
		local user = subinstr("`user'","D","",.)
		local user : display %09.0f `user'

		local api_params `""8" "`user'" "`token'""'

        dlw_apiwrapper `api_params'
	}
    else {
        syntax , [OUTfile(string) nocache replace *]

        tempfile returnedfile
        datacache, `cache' : dlw_apiclient_cached `action', `options' outfile(`returnedfile') replace
    }


    if "`outfile'" == "" {
        _open_file "`returnedfile'" "`r(dlibType)'" "`r(dlibFileName)'"
    }
    else {
        copy "`returnedfile'" "`outfile'", `replace'
    }
end

program define _open_file

	args returnedfile dlibType dlibFileName

	mata : pathsplit(st_local("returnedfile"), path1=., .)
	mata : st_local("tmppath", path1)
	if "`dlibType'"=="dta" { // only one file matched/subscribed - load the file  									
		capture use `returnedfile', clear	 //load the data
		if _rc > 0 {
			display as error "{p 4 4 2}Can't open the file (`dlibFileName'). Data file was saved with new Stata versions.{p_end}"	
			error 1
		}
	} // dta type
	else if "`dlibType'"=="do" { // only one file matched/subscribed - load the file  													
		capture doedit "`tmppath'/`dlibFileName'"
		if _rc > 0 {
			display as error "{p 4 4 2}This dofile (`dlibFileName') is not a properly formatter dofile.{p_end}"	
			error 1
		}
	}
	else { //different types
		capture shell `tmppath'/`dlibFileName'
		if _rc > 0 {
			display as error "{p 4 4 2}Can't open the file (`dlibFileName'). This file extension is not supported yet by your operating systems or the file is damaged.{p_end}"	
			error 1
		}
	}
end