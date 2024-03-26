*! version 0.2  26oct2015
*! Minh Cong Nguyen
* version 0.1  2jun2015

cap program drop _datalibweb_ini
program define _datalibweb_ini, rclass
	version 13, missing
    local verstata : di "version " string(_caller()) ", missing:" 
	syntax, typef(string) keylist(string) [global]
	return clear	
	//local keylist hhid pid defmod hhmlist indmlist root rootname subfolders type cpi cpiw cpivarw distxt email
	if _rc==0 {
		_txtsearch, dofile0(`typef') namelist(`keylist')
		foreach item of local keylist {	
			//return local `item'_ini `"`=stcode'"'			
			if "`=lower("`global'")'"=="global" global `item' `=`item'_stcode'
		}	
	}
end
