*! version 1.0  Aug2012
*! Viviane Sanfelice 

cap program drop varlocal
program define  varlocal, rclass sortpreserve
	version 8.1
	syntax varlist [if] [in] [, SEparate(string) REPLACESpace NOMISSing]

preserve

local keepmissing "novarlist"
if "`nomissing'"!="" local keepmissing ""
marksample touse , `keepmissing' strok 

qui keep if `touse'

keep `varlist' 

qui desc `varlist'
local obs `r(N)'

local s " "
if "`separate'"!="" local s "`separate'"
local i 0
while `i'!=`obs' {
	local ++i
	foreach var in `varlist' {
		local x : di `var'
		if "`x'"=="" local x "."
		if "`replacespace'"!="" local x = subinstr(trim("`x'")," ","_",.)
		local `var' "``var''`s'`x'"
		if `i'==1 local `var' =  subinstr("``var''","`s'"," ",1)
	}	
	qui drop in 1
}

foreach var in `varlist' {
	di _n in y "``var''"
	return local `var' "``var''"	
}

restore
end

