/** JPA 20140322 */
/** JPA 20130727 */


cap program drop b40
cap program define b40, rclass sortpreserve
    version 8.0

    syntax varlist(numeric min=1 max=1) [pweight fweight aweight] [if] [in], [ noisily generate(string)]
    tempvar tmp touse wgt
    local var `varlist'

    quietly {

         if ("`weight'" == "") {
             gen `wgt' = 1
             local weight1 `wgt'
             local weight "[fw=`wgt']"
         }
         else {
             local weight  "[`weight' `exp']"
             local weight1 = subinstr("`exp'","=","",.)
         }
         if ("`if'" == "") {
             local if2 " if (`var'!=.) & (`weight1'!=.) "
         }
          if ("`if'" != "") {
             local if2 " `if'  & (`var'!=.) & (`weight1'!=.) "
         }

         gen `touse' = 1 `in' `if2'

        _ebin `var' `if2'  `weight', gen(`tmp') nq(10)

        `noisily' sum  `var' `weight' if `touse' == 1
        local r1 = r(mean)
        local n1 = r(N)
        local s1 = r(sum)
        `noisily' sum  `var' `weight' if `touse' == 1 & `tmp' <= 4
        local r2 = r(mean)
        local n2 = r(N)
        local s2 = r(sum)
        `noisily' sum  `var' `weight' if `touse' == 1 & `tmp' > 4
        local r3 = r(mean)
        local n3 = r(N)
        local s3 = r(sum)

        return local mean = `r1'
        return local Nmean = `n1'
        return local Smean = `s1'

        return local b40  = `r2'
        return local Nb40  = `n2'
        return local Sb40  = `s2'

        return local t60  = `r3'
        return local Nt60  = `n3'
        return local St60  = `s3'

        `noisily' tab `tmp'
		
		if ("`generate'" != "") {
			gen `generate' = 1  if `touse' == 1 & `tmp' <= 4
			replace `generate' = 0 if `touse' == 1 & `tmp' > 4
		}

    }
end
