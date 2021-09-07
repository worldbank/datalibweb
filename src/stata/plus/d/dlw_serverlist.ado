*! version 0.1 28apr017
*! Minh Cong Nguyen

capture program define _datalibweb, plugin using("dlib2_`=cond(strpos(`"`=c(machine_type)'"',"64"),64,32)'.dll")
*capture program define _datalibweb, plugin using("DataLib`=cond(strpos(`"`=c(machine_type)'"',"64"),64,32)'.dll")

cap program drop dlw_serverlist
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
		qui plugin call _datalibweb , "4" "`tmpconfig'"
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
