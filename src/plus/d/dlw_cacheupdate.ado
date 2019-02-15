cap program drop dlw_cacheupdate
program define dlw_cacheupdate
	set checksum off
	set more off
	clear all
	local other : sysdir PERSONAL
    if "$S_OS"=="Windows" local other : subinstr local other "/" "\", all	
	if ("`other'" == "") {
		local other "c:\ado\personal\"
		cap mkdir "`other'"
	}
	
	//country catalog
	local codelist : dir `"`other'datalibweb\data\"' files "Catalog_*.dta", nofail respectcase
	if (`=wordcount(`"`codelist'"')' > 0) {
		foreach dtafile of local codelist {
			local code `dtafile'
			local code : subinstr local code "Catalog_" "", all
			local code : subinstr local code ".dta" "", all
			dis "`code'"
			dis "dlw_usercatalog, code(`code') update"
			
			cap describe token using `"`other'datalibweb\data\`dtafile'"', simple
			if _rc==0 { //country
				cap dlw_usercatalog, code(`code') update
				if _rc==0 noi dis as text "Update country catalog (`code') - Done"
				else      noi dis as error "Update country catalog (`code') - Failed"
			}
			else { //server
				cap dlw_servercatalog, server(`code') update
				if _rc==0 noi dis as text "Update collection catalog (`code') - Done"
				else      noi dis as error "Update collection catalog (`code') - Failed"
			}
		}
	}
	
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
