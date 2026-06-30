*! version 1.0.0 PR 16Feb2001.  (TSJ-1: dm0001)
program define listsort, sclass
version 6
gettoken p 0 : 0, parse(" ,")
if `"`p'"'=="" {
	exit
}
sret clear
syntax , [ Reverse Lexicographic ]
local lex="`lexicog'"!=""
if "`reverse'"!="" { local comp < }
else local comp >
local np: word count `p'
local i 1
while `i'<=`np' {
	local p`i': word `i' of `p'
	if !`lex' { confirm number `p`i'' }
	local i=`i'+1
}
* Apply shell sort (Kernighan & Ritchie p 58)
local gap=int(`np'/2)
while `gap'>0 {
	local i `gap'
	while `i'<`np' {
		local j=`i'-`gap'
		while `j'>=0 {
			local j1=`j'+1
			local j2=`j'+`gap'+1
			if `lex' { local swap=(`"`p`j1''"' `comp' `"`p`j2''"') }
			else local swap=(`p`j1'' `comp' `p`j2'')
			if `swap' {
				local temp `p`j1''
				local p`j1' `p`j2''
				local p`j2' `temp'
			}
			local j=`j'-`gap'
		}
		local i=`i'+1
	}
	local gap=int(`gap'/2)
}
local p
local i 1
while `i'<=`np' {
	sret local i`i' `p`i''
	local p `p' `p`i''
	local i=`i'+1
}
sret local list `p'
end
