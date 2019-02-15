*! version 0.1  23Jan2017
*! Minh Cong Nguyen - mnguyen3@worldbank.org
cap program drop dlw_display
program define dlw_display

qui {
	version 12, missing
    local verstata : di "version " string(_caller()) ", missing:" 
	syntax, row(varlist max=1) col(varlist max=1) con(varlist max=1) ///
		country(string) type(string) sub(string)
	
	foreach var of varlist `row' `col' `con' `sub' {
		cap confirm string variable `var'
		if _rc==0 clonevar `var'_str = `var'
		else cap tostring `var', gen(`var'_str)
		gen byw_`var' = length(`var'_str)
		local  lbl_`var' : variable label `var'
		if "`lbl_`var''"=="" local lbl_`var' `var'
		qui su byw_`var'
		local byw_`var' = r(max)
	}
	
	local byw_cell = 2 + max(`byw_`col'', `byw_`con'')
	local firstcol = 1+max(`=length("`lbl_`row''")', `byw_`row'', 13)
	//get the max line
	
	sort `sub' `row' `col'
	qui levelsof `sub', local(sublabel)
	qui listsort `"`sublabel'"', lexicographic
	local sublabel `s(list)'
	qui levelsof `col', local(collabel)
	qui listsort `"`collabel'"', lexicographic
	*qui listsort `"`collabel'"'
	local collabel `s(list)'
	local nmod = wordcount(`"`collabel'"')
	qui levelsof `row', local(rowlabel)
	qui listsort `"`rowlabel'"', lexicographic
	local rowlabel `s(list)'
	//local nmod = wordcount(`"`rowlabel'"')
	
	local i = 1
	qui gen varpos = .
	qui foreach md of local collabel {
		replace varpos = `i' if `col'_str=="`md'"
		local i = `i' + 1
	}
	local ltab = max(`byw_cell'*`nmod' + 4*(`nmod'-1)-`nmod'*3, length("`lbl_`col''"))
	*local lsize = `firstcol' + `byw_cell'*`nmod' + 4*(`nmod'-1)-`nmod'*3
	local lsize = `firstcol' + `ltab'
	local postxt = `firstcol' + int((`lsize' - `firstcol')/2) - int(length("`lbl_`col''")/2)
	
	//first line 
	//di in g "{hline `=`lsize'+1'}"
	noi di as text "{hline `firstcol'}{c TT}{hline `=`lsize'-`firstcol''}"
	*noi di as text _col(`=`firstcol'+1') "{c |}" _col(`postxt') "`lbl_`col''"
	noi di as text _col(`=`firstcol'-length("`lbl_`row''")') "`lbl_`row'' {c |}" _col(`postxt') "`lbl_`col''"
	
	//first label row
	*local txt _col(`=`firstcol'-length("`lbl_`row''")') "`lbl_`row'' {c |}"
	local txt _col(`=`firstcol'-length("(Subscribed)")') "(Subscribed) {c |}"
	local i = 0
	foreach mod in `collabel' {
		local txt `"`txt' _col(`=`firstcol' + `i'*`byw_cell' + `byw_cell'-length("`mod'")') "`mod'""'
		local i = `i'+ 1
	}
	noi dis as text `txt'
	noi dis as text "{hline `firstcol'}{c +}{hline `=`lsize'-`firstcol''}"
	tempfile data1
	qui save `data1'
	//cell row
	sort `sub' `row' `col'
	foreach subsur of local sublabel {
		qui use `data1', clear
		qui keep if `sub'_str=="`subsur'"
		noi di as text _col(`=`firstcol'-length("`subsur'")') "{ul:`subsur'} {c |}" 
		tempfile data2
		save `data2', replace
		foreach rn of local rowlabel {
			qui use `data2', clear
			qui keep if `row'_str=="`rn'"
			if _N>0 {
				local sb: label subscribed `: disp subscribed[1]'
				if regexm(`"`sb'"', "[Yy][Ee][Ss]") {
					local subscr (Yes)
					local color yellow
				}
				else if regexm(`"`sb'"', "[Nn][Oo]") {
					local subscr (No)
					local color red
				}
				else {                               
					local subscr (Expired)
					local color white
				}
				local txt _col(`=`firstcol'-length("`rn'`subscr'")') "`rn' " in `color' "`subscr'" in yellow "{c |}" 
				local all = _N		
				//local todisp `"`year' - `: word `s' of `surveys''"'
				//noi disp _col(4) `"{stata datalibweb, country(`code') year(`year') type(`type')  `clear': `todisp'}"' 

				forv i=1(1)`all' {
					local todisp `"`=`con'_str[`i']'"'
					//Modify the cmd line here
					local cmd `"stata datalibweb, country(`country') year(`=`row'_str[`i']') type(`type') mod(`=`col'_str[`i']') vermast(`=vermast[`i']') veralt(`=veralt[`i']') surveyid(`subsur')"'
					local txt `"`txt' _col(`=`firstcol' + `=varpos[`i']-1'*`byw_cell' + `byw_cell'-length("`=`con'_str[`i']'")') `"{`cmd': `todisp'}"'"'
				}
				noi dis as text `txt'
			}
		}
	}
	noi di as text "{hline `firstcol'}{c BT}{hline `=`lsize'-`firstcol''}"
	clear
}
end
