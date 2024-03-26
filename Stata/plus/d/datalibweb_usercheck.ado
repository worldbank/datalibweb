*===================================================================*
* WORLD BANK - Datalibweb
* PROYECT: Check User name 
*-------------------------------------------------------------------*  
* Author: Andres Castaneda 
* DATe:  Oct/2015 Based on  datalib_usercheck Nov/2013						    
*===================================================================*
*! version 0.1  26oct2015
*! Andres Castaneda

cap program drop datalibweb_usercheck
program define datalibweb_usercheck, rclass

	local accept = 0
	local user = lower("`c(username)'")
	disp "Welcome to Datalibweb system: `user'" _con
	local upi = c(username)
	local path "C:\Users/`upi'/NotesData"

	tempfile file 
	tempname n
	cap confirm file "`path'/setup.txt"
	* find users name
	if (_rc == 0) {
		copy "`path'/setup.txt" `file' 
		file open `n' using `file', read
		file read `n' line
		local found = 0
		while (`found' == 0 & r(eof)==0) {
			if regexm(`"`line'"', "^[Uu]sername") {
				lstrfun name, regexms(`"`line'"', `"([Uu]sername=CN=)(.*)/[oO][uU]"', 2)
				local found = 1
			}
			file read `n' line
		}
	} // end of _rc == 0

	if ("`name'" == "") {
		local user = lower("`c(username)'")
	}
	else {
		local user = "`name'"
		noi disp in w " - " in y "`name'"
	}
	return local user `user'
end
