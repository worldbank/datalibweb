*! version 0.2  12sep2015
*! Minh Cong Nguyen
* version 0.1  2jun2015
cap program drop _txtsearch
program define _txtsearch
	syntax, dofile0(string) namelist(string)
	tempfile longfile
	tempname note code stdyDscr mystr
	qui des
	qui if r(N)==0 {
		set obs 1
	}
	qui gen strL `note' = fileread("`dofile0'")
	qui gen strL `code' = ""
	local pos01 = strpos(`note', "fileread() error")
	if `pos01'>0 {
		noi dis in red "`dofile0'"
		noi err 601
	}
	else {
		foreach varname of local namelist {
			//search for syntax - *<_var_> and *</_var_> 
			local pos1 = strpos(`note', "<`varname'>")
			local pos2 = strpos(`note', "</`varname'>")
			local varlen = length("`varname'")
			if `pos1'>0 & `pos2'>0 & `pos2'>`pos1' {
				qui replace `code' = substr(`note', `pos1'+`varlen'+2, `pos2'-`pos1'-`varlen'-2)
				scalar `mystr' = `code'[1]
				scalar `varname'_stcode = `"`=`mystr''"'
			}
			else {
				scalar `varname'_stcode = ""
			}
		}
	}
end
