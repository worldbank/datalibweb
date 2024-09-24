program define dlw_apiclient_cached, rclass properties(cachable disk outfile)
    version 16.0

    syntax anything(name=action), OUTfile(string) [signature replace *]

    local 0 ", `options'"

    local user = upper(c(username))
	local user = subinstr("`user'","WB","",.)
	local user = subinstr("`user'","C","",.)
	local user = subinstr("`user'","S","",.)
	local user = subinstr("`user'","D","",.)
	//local user : display %09.0f `user' // !!!!! audit endpoint doesn't work if the leading zeros are present !!!!!

	dlw_version
	local current_version "`r(version)'"

    local process_command "_process_empty"

     if "`action'" == "get_file" {

        syntax, COUNtry(string) Year(integer) [server(string)  ///
	        COLlection(string) survey(string) ///
            token(numlist max=1) filename(string) ext(string) ///
	        para1(string) para2(string) para3(string) para4(string)]
	
        local folder : copy local survey

        local query "Server=`server'&Country=`country'&Year=`year'"
        foreach cstr in collection folder token filename ext para1 para2 para3 para4 {
            if "``cstr''" != "" {
                local query "`query'&`cstr'=``cstr''"
            }
        }

        local signature_string "`current_version'|`action'|`query'"
		local api_params `""0" "`outfile'" "`query'""'
    
        local process_command "_process_filelist"

	}
	else if "`action'" == "server_catalog" {

		syntax, server(string)

        local signature_string "`current_version'|`action'|`server'"
		local api_params `""2" "`outfile'" "`server'""'
	
		local fail_message "Can't open the catalog data."

        local process_command "_process_catalog"

	}
	else if "`action'" == "country_catalog" {

		syntax, country(string)

        local signature_string "`current_version'|`action'|`country'"
    	local api_params `""3" "`outfile'" "`country'""'
	
		local fail_message "Can't open the catalog data."

        local process_command "_process_catalog"

	}
    else if "`action'" == "server_configs" {

        local signature_string "RANDOMCONSTANTHERE"
        local api_params `""4" "`outfile'""'

    }
    else if "`action'" == "subscriptions" {

        syntax, country(string)

        local signature_string "`current_version'|`action'|`country'"
        local api_params `""5" "`outfile'" "`user'" "`country'""'

        local process_command "_process_subscriptions"

    }
    else if "`action'" == "audit" {

        syntax, [country(string)]

        local signature_string "`current_version'|`action'|`country'"
        local api_params `""6" "`outfile'" "`user'" "`country'" "Download" "Y""'

		local process_command "_process_audit"
    }

    if "`signature'" != "" {
        return local signature "`signature_string'"
        exit
    }

    dlw_apiwrapper `api_params'

    if "`dlibType'" != "csv" {
        return local dlibFileName "`dlibFileName'"
        return scalar dlibDataSize = real("`dlibDataSize'")
        return local dlibType "`dlibType'"

        exit
    }


    quietly `process_command' `outfile'

    return local dlibType "dta"
end

program define _process_empty
	args returnfile

    insheet using "`returnfile'", clear names

    save "`returnfile'", replace
end

program define _process_catalog
	args returnfile

	tempfile server_configs
	dlw_apiclient server_configs //, outfile(`server_configs')
	generate Ufoldername = strupper(foldername)
	save `server_configs'

	insheet using "`returnfile'", clear names
	if _N==1 {
		display as text in white "No data in the catalog for this `filter'."
		exit 0 // is this an error?
	}

	rename survey acronym		
	split filepath, p("\" "/")
	local pathvars = r(k_new)
	generate filename = filepath`pathvars'
	replace filename = filepath4 if filename == ""

	rename filepath3 surveyid
	generate byte token = 1 + strlen(surveyid) - strlen(subinstr(surveyid,"_","",.))

	generate foldername = subinstr(subinstr(subinstr(filepath, filepath1 + "/" + filepath2 + "/" + surveyid + "/", "", .), "/" + filename, "", .), filename, "", .)
	generate Ufoldername = strupper(foldername)
	generate server = serveralias
	rename ext extn

	merge m:1 server Ufoldername token using `server_configs', keep(master match) keepusing(title requesttype ext) nogenerate

	rename title type

	replace requesttype = "" if strpos("|" + ext + "|", "|" + extn + "|") == 0 // file with unknown extention
	drop filepath? ext Ufoldername
	rename extn ext

	generate collection = substr(surveyid, 1 - strpos(reverse(surveyid), "_"), .) if token == 8
	replace collection = serveralias + type if token == 5
	generate module = strupper(subinstr(subinstr(filename, surveyid + "_", "", .), "." + ext, "", .)) if token == 8 & strpos(filename, surveyid + "_") > 0

	generate type2 = 0
	replace type2 = 1 if token == 8
	replace type2 = 2 if inlist(collection, "GMD", "GLD", "GPWG", "ASPIRE", "I2D2", "I2D2-Labor", "GLAD")  // add as many global collections as available
	replace type2 = 3 if inlist(collection, "GMI", "HLO", "CLO")  // add as many thematic indicators as available

	save "`returnfile'", replace
end

program define _process_filelist
	args returnedfile

    insheet using "`returnedfile'", clear names
    split filesharepath, p("\" "/")
	rename filesharepath3 survey
	rename filesharepath4 surveyid
    generate ext = substr(filename,length(filename)-strpos(reverse(filename),".")+2,strpos(reverse(filename),"."))
    generate ntoken = strlen(surveyid) - strlen(subinstr(surveyid,"_","",.))
	generate type = "RAW" if ntoken == 4
	replace type = "Harmonized" if ntoke == 7

    split surveyid, p(_)
	rename surveyid1 countrycode
	rename surveyid2 year
	rename surveyid3 surveyname
    rename surveyid4 verm
	rename surveyid5 verm_l
	generate str collection = ""
	replace collection = "`=upper("`server'")'RAW" if type == "RAW"

    capture confirm variable surveyid8
	if _rc == 0 {
		rename surveyid6 vera
		rename surveyid7 vera_l
		replace collection = surveyid8 if type == "Harmonized"	
		split file if type == "Harmonized", p(_)					
		generate str mod = ""
		replace mod = substr(file9, 1, length(file9) - 4)					
		drop file1-file9
	}
    save "`returnedfile'", replace
end

program define _process_subscriptions
	args returnedfile
	insheet using "`returnedfile'", clear names
	if _N==0 {
        display as text in white "User has no subscription in the catalog for this country `code'."
        exit 200
    }

	//hot fix IND due to wrong year
    destring year, replace
    capture drop userpin emailaddress subscribedto modified created createdby modifiedby
	rename region serveralias
	replace serveralias = upper(serveralias)

	tostring reqexpirydate, replace // is this a bug????
	replace reqexpirydate = substr(reqexpirydate, 1, 10)
	replace reqexpirydate = "9999-12-30" if upper(ispublic)=="TRUE"
	generate double expdate = date(reqexpirydate, "YMD")
    format %td expdate
	split surveyid, parse("_")
	rename surveyid3 acronym
	drop surveyid1 surveyid2 surveyid
			
    generate subscribed = (expdate - date("$S_DATE", "DMY")) >= 0 if expdate != .
	label define subscribed -1 "No" 0 "Expired" 1 "Yes"
	label values subscribed subscribed

	drop reqexpirydate
	replace collection = upper(collection)

	drop if collection != "ALL" & token == 5

	capture confirm string variable foldername
	if _rc!=0 {
		drop foldername
		generate str foldername = ""
    }
	bysort serveralias country year acronym requesttype token foldername (expdate): keep if _n==_N
	duplicates drop serveralias country year acronym requesttype token foldername, force

    save "`returnedfile'", replace
end

program define _process_audit
	args returnedfile

	import delimited using "`returnedfile'", clear varnames(1)
	if _N==0 {
        display as text in white "User has no subscription in the catalog for this country `code'."
        exit 2000
    }
	keep surveyid filename
	tostring surveyid filename, replace

	// downloaddate is currently not returned
	generate downloaddate = "12/31/2023"
	generate isdownload = cond(downloaddate != "", 1, 0)
	label define isdownload 1 "YES" 0 "NO"
	label values isdownload isdownload

	duplicates drop surveyid filename, force


    save "`returnedfile'", replace
end
