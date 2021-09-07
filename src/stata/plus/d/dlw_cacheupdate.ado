*! version 0.2 12dec2019
*! Minh Cong Nguyen
* version 0.1 15jul2017 - original
cap program drop dlw_cacheupdate
program define dlw_cacheupdate
	version 10, missing
    local verstata : di "version " string(_caller()) ", missing:" 
	syntax, [code(string) server(string)]	
	local code = upper("`code'")
	
	set checksum off
	set more off
	clear all
	local other : sysdir PERSONAL
    if "$S_OS"=="Windows" local other : subinstr local other "/" "\", all	
	if ("`other'" == "") {
		local other "c:\ado\personal\"
		cap mkdir "`other'"
	}
	
	//one country code
	if ("`code'"~="") {
		cap dlw_usercatalog, code(`code') update
		if _rc==0 noi dis as text "Update country catalog (`code') - Done"
		else      noi dis as error "Update country catalog (`code') - Failed"
	}
	else { //all country catalog		
		local codelist : dir `"`other'datalibweb\data\"' files "Catalog_*.dta", nofail respectcase
		if (`=wordcount(`"`codelist'"')' > 0) {
			foreach dtafile of local codelist {
				local code1 `dtafile'
				local code1 : subinstr local code1 "Catalog_" "", all
				local code1 : subinstr local code1 ".dta" "", all
				
				cap dlw_usercatalog, code(`code1') update
				if _rc==0 noi dis as text "Update country catalog (`code1') - Done"
				else      noi dis as error "Update country catalog (`code1') - Failed"
					
				*dis "`code'"
				*dis "dlw_usercatalog, code(`code1') update"
				/*
				cap describe token using `"`other'datalibweb\data\`dtafile'"', simple
				if _rc==0 { //country
					cap dlw_usercatalog, code(`code1') update
					if _rc==0 noi dis as text "Update country catalog (`code1') - Done"
					else      noi dis as error "Update country catalog (`code1') - Failed"
				}
				else { //server
					cap dlw_servercatalog, server(`code1') update
					if _rc==0 noi dis as text "Update collection catalog (`code1') - Done"
					else      noi dis as error "Update collection catalog (`code1') - Failed"
				}
				*/
			}
		} //code list
	} //all country catalog
	
	//server latest
	local latestlist : dir `"`other'datalibweb\data\"' files "*_latest.dta", nofail respectcase
	if (`=wordcount(`"`latestlist'"')' > 0) {
		foreach ser of local latestlist {
			local server `ser'
			local server : subinstr local server "_latest.dta" "", all
			cap dlw_catalog, savepath(`"`other'datalibweb/data/`ser'"') server(`server')
			if _rc==0 noi dis as text "Update collection latest (`server') - Done"
			else      noi dis as error "Update collection latest (`server') - Failed"
		}
	}
	
end
