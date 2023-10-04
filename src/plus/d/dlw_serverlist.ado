*! version 0.1 28apr017
*! Minh Cong Nguyen

program define dlw_serverlist, rclass	
	version 10, missing
	local persdir : sysdir PERSONAL
	syntax, [savepath(string) update]
    if "$S_OS"=="Windows" local persdir : subinstr local persdir "/" "\", all
	local dl 0
	if "`update'"=="update" local dl 1
	else {		
		cap confirm file "`persdir'datalibweb\data\Serverlist.dta"
		if _rc==0 {
			cap use "`persdir'datalibweb\data\Serverlist.dta", clear	
			if _rc==0 {
				local dtadate : char _dta[version]			
				if "$updateday"=="" global updateday 1
				if (date("$S_DATE", "DMY")-date("`dtadate'", "DMY")) > $updateday local dl 1				
				else return local serverlist "`persdir'datalibweb\data\Serverlist"
			}
			else local dl 1
		}
		else {
			cap mkdir "`persdir'datalibweb\data"
			local dl 1
		}
	}
	
	qui if `dl'==1 {	
		//server config		
		tempfile tmpconfig
		dlw_api, option(4) outfile(`tmpconfig')
		local dlibrc `r(rc)'
		if `dlibrc'==0 {
			if ("`dlibType'"=="csv") {
				cap insheet using "`tmpconfig'", clear names
				if _rc==0 {
					if _N==1 noi dis as text in white "No data in the data config. Please check with the system admin."
					else {						
						keep server
						ren server serveralias	
						duplicates drop serveralias, force
						sort serveralias	
						char _dta[version] $S_DATE							
						compress
						saveold "`persdir'datalibweb\data\Serverlist", replace	
					}
				}
				else {
					noi dis as error "Cant open the config data. Please check with the system admin."
				}	
			}
		}
		else {
			dlw_message, error(`dlibrc')
		}
	}
end
