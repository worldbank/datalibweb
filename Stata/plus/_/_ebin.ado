*! version 1.0          < 06april2020>         JPAzevedo
*      add touse in several lines
*  version 0.2          < 02april2020>         JPAzevedo
*      fix weight
*  version 0.1          < 24march2012>         JPAzevedo

cap program drop _ebin

    program define _ebin, rclass sortpreserve

   		version 8.0

        syntax varlist(numeric min=1 max=1) ///
                     [if] [in]       ///
                     [pweight fweight aweight] , ///
                     NQuantiles(string)  ///
                     GENerate(string) ///
                     [order(varname)]

        quietly {

            tempvar var touse rank1 rank2 rank3 rank4 wgt

            local nq `nquantiles'
            local var `varlist'

            if ("`weight'" == "") {
                gen `wgt' = 1
                local weight1 "`wgt'"
                local weight "[fw=`wgt']"
            }
            else {
                local weight  "[`weight' `exp']"
                local weight1 = trim(subinstr("`exp'","=","",.))
            }

            if ("`order'" != "") {
                local iforder  " & (`order'!=.)"
            }

            if ("`if'" == "") {
                local if2 " if (`var'!=.) & (`weight1'!=.) `iforder'"
            }
             if ("`if'" != "") {
                local if2 " `if'  & (`var'!=.) & (`weight1'!=.) `iforder'"
            }

* 			mark `touse' `in' `if'
            gen `touse' = 1 `in' `if2'

            if ("`order'" != "") {
                _pecatsal `order'
                if (`r(numcats)' < `nq') {
                    di as err "number of bins can not greater than the number of available categories."
                    exit 198

                }
            }

            if ("`order'" == "") {
                sort `touse' `var' `weight1', stable
            }
            else {
                sort `touse' `order' `weight1' `var', stable
            }

            
			gen double 	`rank1'	= `weight1' 					in 1	if `touse'
            replace 	`rank1' = `rank1'[_n-1] + `weight1'[_n] in 2/l

            sum 		`weight1'                            	if `touse' == 1
            gen double 	`rank2' = `rank1'/`r(sum)'				if `touse' == 1
            
			gen double 	`rank3' = `rank2'*`nq'                  if `touse' == 1
            
			gen double 	`rank4' = int(`rank3')					if `touse' == 1
            replace 	`rank4' = `nq'-1 						if `rank4' >= `nq' & `touse' == 1
            replace 	`rank4' = `rank4'+1						if `touse' == 1

            gen double `generate' = `rank4'                     if `touse' == 1

    }

end
