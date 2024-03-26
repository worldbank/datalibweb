*! version 0.5  24feb2016
*! Minh Cong Nguyen
* version 0.1  2jun2015
* version 0.2  12sep2015
* version 0.3  30dec2015 - update with RAW/BASE search
* version 0.4  03feb2016 - update with no ctry available
* version 0.5  24feb2016 - flexible module/filename in the file (harmonization of harmonization)

** folder/file search
cap program drop filesearch
program define filesearch, rclass
	version 12, missing
	local verstata : di "version " string(_caller()) ", missing:"
	if c(more)=="on" set more off
	syntax, COUNtry(string) Year(numlist max=1) root(string) [save(string) col(string) surveyid(string) subfolders(string) COMBstring(string) ANYstring(string) ext(string) obs(numlist max=1) latest NOMETA]
	
	//Error
	global errcode 0
	if "`combstring'"~="" & "`anystring'"~="" {
		dis in yellow "Both conditions: combstring and anystring options cannot go together. You must select only one option."
		error 198
	}
	
	if "`obs'"=="" local obs 1000
	qui {
		//setup data
		clear
		*tempfile __data_1
		set obs `obs'
		gen __xxx__=.
		
		*use "`save'", clear
		gen str path = ""
		gen str file = ""
		gen str survey = ""
		gen str surveyid = ""
	}
	local i = 1
	
	if "`ext'"=="" local ext .dta
	local col2 `col'
	if (strpos("`=upper("`col'")'","RAW") > 0) | (strpos("`=upper("`col'")'","BASE") > 0) local col // condition for RAW/BASE database	
	
	//confirm the folder
	local cwd `"`c(pwd)'"'
	quietly capture cd `"`root'\\`country'"'
	if _rc~=0 {
		noi dis in yellow "There is no survey/data with defined parameters: `col2', `country', `year', `surveyid'"
		global errcode 676
		clear
		error 198
	}
	else {
		quietly cd `"`cwd'"'
	}
	
	local folders: dir "`root'\\`country'" dirs "*`year'*", nofail respectcase
	
	qui foreach f of local folders {				
		local folders1: dir "`root'\\`country'\\`f'" dirs "*`col'*", nofail respectcase
		// check verison of the current folder
		local rawlist	
		if "`col'"=="" {
			foreach f0 of local folders1 {
				if `=strpos("`f0'","_A_")'==0 local rawlist "`rawlist' `f0'"
			}
			local folders2 "`rawlist'"
		}
		else {
			local folders2 "`folders1'"
		}
		
		// Data\Harmonized\
		foreach fdta of local folders2 {			
			local dtafile: dir "`root'\\`country'\\`f'\\`fdta'\\`subfolders'" files "*`ext'", nofail respectcase
			qui foreach file0 of local dtafile {
				replace survey = "`f'" in `i'
				replace surveyid = "`fdta'" in `i'
				replace path = "`f'\\`fdta'\\`subfolders'" in `i'
				replace file = "`file0'" in `i'
				local i = `i' + 1				
			}
		}
	}
		
	//Clean and Save the filesearch data
	order survey surveyid path file
	qui gen surveyidup = upper(surveyid)
	qui gen fileup = upper(file)
	
	// Additional filters based on the surveyid
	qui if "`surveyid'"~="" {
		tempvar idcond		
		local keyevalid
		local k=1
		foreach keyid of local surveyid {
			tempvar var`k'
			gen `var`k'' = regexm(surveyidup, "`=upper("`keyid'")'")
			local keyevalid "`keyevalid'*`var`k''"
		}
		gen `idcond' = 1`keyevalid'
		keep if `idcond'==1
	}
	
	// Additional filters based on the anystring (all together)
	qui if "`anystring'"~="" {
		tempvar strcond0		
		local keyeval 0
		local k=1
		gen str surveyfile = surveyidup + "\" + fileup
		foreach key of local anystring {
			tempvar var`k'
			gen `var`k'' = regexm(surveyfile, "`=upper("`key'")'")
			local keyeval "`keyeval'+`var`k''"
		}
		gen `strcond0' = `keyeval'
		keep if `strcond0'>=1
		cap drop surveyfile
	}
	
	// Additional filters based on the combstring (all together)
	qui if "`combstring'"~="" {
		tempvar strcond		
		local keyeval
		local k=1
		gen str surveyfile = surveyidup + "\" + fileup
		foreach key of local combstring {
			tempvar var`k'
			gen `var`k'' = regexm(surveyfile, "`=upper("`key'")'")
			local keyeval "`keyeval'*`var`k''"
		}
		gen `strcond' = 1`keyeval'
		keep if `strcond'==1
		cap drop surveyfile
	}
	
	qui compress
	cap drop __* surveyidup fileup
	qui drop if path==""
	
	if "`save'"~="" saveold "`save'", replace
	
	if _N>0 {
		// get version
		qui if "`col'"=="" { //raw data
			split surveyid, p(_)
			ren surveyid1 countrycode
			ren surveyid2 year
			ren surveyid3 surveyname
			ren surveyid4 verm
			ren surveyid5 verm_l
			gen collection = "`col2'"
			sort countrycode year surveyname verm verm_l
		}
		
		qui if "`col'"~="" { //harmonized data
			*split surveyid, p(_)
			split file, p(_)
			ren file1 countrycode
			ren file2 year
			ren file3 surveyname
			ren file4 verm
			ren file5 verm_l
			ren file6 vera
			ren file7 vera_l
			ren file8 collection
			if `=strpos(collection,".dta")'>0 | `=strpos(collection,".DTA")'>0 {
				replace collection = subinstr(collection, ".dta", "",1)
				replace collection = subinstr(collection, ".DTA", "",1)
			}
			if `=strpos(file9,".dta")'>0 | `=strpos(file9,".DTA")'>0 {
				cap gen mod = substr(file9,1,length(file9)-4)
			}
			else {
				//harmonization of harmonization, add second vintage
				cap gen mod = file9
			}
			cap drop file9
			sort countrycode year surveyname verm verm_l vera vera_l
		}
		
		// check survey
		qui levelsof survey, local(surlist)
		if `=wordcount(`"`surlist'"')' >1 { // more than one type of survey
		}
		else { //one type of survey only
			// latest or not
			qui if "`latest'"~="" {
				//get the latest only
				cap drop if upper(verm)=="WRK"
				cap drop if upper(vera)=="WRK"
				
				qui levelsof verm, local(mlist)
				listsort `"`mlist'"', lexicographic
				keep if verm=="`=word(`"`s(list)'"',-1)'"
				cap confirm variable vera
				if _rc==0 {
					qui levelsof vera, local(alist)
					listsort `"`alist'"', lexicographic
					keep if vera=="`=word(`"`s(list)'"',-1)'"
				}
			}		
		}
								
		// list if there is more than one or get the file
		qui levelsof surveyid, local(surveylist)
		if `=wordcount(`"`surveylist'"')' >1 {
			noi dis in yellow _n "There are `=wordcount(`"`surveylist'"')' survey/data/vintage with defined parameters. Click on the following to redefine the search."			
			local rn = 1
			bys surveyid (file): gen seq = _n
			bys surveyid (file): gen seqN = _N			
			foreach ids of local surveylist {	
				//local text filesearch, col(`=collection[`rn']') country(`=countrycode[`rn']') year(`=year[`rn']') root("`root'") subfolders("`subfolders'") surveyid(`ids') save(data1) 
				//local text datalibweb, country(`=countrycode[`rn']') year(`=year[`rn']') type(`=collection[`rn']') surveyid(`ids') fileserver
				local text datalibweb, country(`=countrycode[`rn']') year(`=year[`rn']') type(`=collection[`rn']') surveyid(`ids') local
				noi dis `"`rn'. [{stata `"`text'"':`text'}]"'				
				local rn = `rn' + `=seqN[`rn']'
				if "`nometa'"=="" _metadisplay, surveyid(`=trim("`ids'")')
			}			
			qui clear
		} // end of many survey ID
		else { // one Survey ID
			qui levelsof file, local(filelist)
			local ids `=surveyid[1]'
			if `=wordcount(`"`filelist'"')' >1 {
				noi dis in yellow _n "There are more than one data files with defined parameters. Click on the following to redefine the search."
				local rn = 1
				noi dis in yellow "Files available for this Survey ID: `ids'"
				if "`nometa'"=="" _metadisplay, surveyid(`=trim("`ids'")')				
				foreach fs of local filelist {					
					//local text filesearch, col(`=collection[`rn']') country(`=countrycode[`rn']') year(`=year[`rn']') root("`root'") subfolders("`subfolders'") surveyid(`=surveyid[`rn']') anystring(`=file[`rn']') save(data1) 
					//local text datalibweb, country(`=countrycode[`rn']') year(`=year[`rn']') type(`=collection[`rn']') surveyid(`ids') filename(`=file[`rn']') fileserver `nometa'
					local text datalibweb, country(`=countrycode[`rn']') year(`=year[`rn']') type(`=collection[`rn']') surveyid(`ids') filename(`=file[`rn']') local `nometa'
					noi dis `"`rn'. [{stata `"`text'"':`text'}]"'
					local rn = `rn' + 1
				}
				qui clear				
			}
			else { //only 1 file, load it			
				dis as text "{hline}"
				noi dis as text "{p 4 4 2}{cmd:Country:} "             in y "`=upper("`country'")'" as text " {p_end}"
				noi dis as text "{p 4 4 2}{cmd:Year:} "                in y "`=year[1]'" as text " {p_end}"
				noi dis as text "{p 4 4 2}{cmd:Survey:} "              in y "`=surveyname[1]'" as text " {p_end}"
				cap confirm variable mod, ex
				if _rc==0 {
					noi dis as text "{p 4 4 2}{cmd:Module:} "              in y "`=mod[1]'" as text " {p_end}"
					local rmod `=mod[1]'
				}
				noi dis as text "{p 4 4 2}{cmd:Type:} "                in y "`=collection[1]'" as text " {p_end}"
				noi dis as text "{p 4 4 2}{cmd:Master Version:} "      in y "`=verm[1]'" as text " {p_end}"
				cap confirm variable vera, ex
				if _rc==0 {
					noi dis as text "{p 4 4 2}{cmd:Alternative Version:} " in y "`=vera[1]'" as text " {p_end}"
					local rvera `=vera[1]'
				}
				noi dis as text "{p 4 4 2}{cmd:Data file name(s):} "   in y "`=file[1]'" as text " {p_end}"
				dis as text "{hline}" _newline
				local rverm `=verm[1]'
				local rfile `=file[1]'				
				if "`nometa'"=="" _metadisplay, surveyid(`=trim("`ids'")')				
				cap use "`root'\\`country'\\`=path[1]'\\`=file[1]'", clear
				if _rc==0 {
					return local type `col2'
					return local module `rmod'
					return local verm `rverm'
					return local vera `rvera'
					return local surveyid `ids'
					return local filename `rfile'
					return local idno `r(id)'
				}
				else {
					//Error when loading the data
					noi dis in yellow "Data is not loaded with defined parameters: `col2', `country', `year', `ids'"
					noi dis in yellow "Data might be saved under new versions of Stata"
					global errcode 676
					clear
					error 3
				}		
			} // end of onefile
		} // end of one survey ID
	} //end of r(N)>0
	else {
		noi dis in yellow "There is no survey/data with defined parameters: `col2', `country', `year', `surveyid'"
		global errcode 676
		clear
		error 198
		//exit 1
	}
end
