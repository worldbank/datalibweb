*! version 0.3  19jan2017
*! Minh Cong Nguyen
* version 0.1  2jun2015
* version 0.2  26oct2015
* version 0.3  19jan2017 - plugin v2

program define filesearchw2, rclass
	version 12, missing
	local verstata : di "version " string(_caller()) ", missing:"
	if c(more)=="on" set more off
	syntax, COUNtry(string) Year(numlist max=1) [server(string) save(string) ///
	COLlection(string) surveyid(string) folder(string) level(numlist max=1) token(numlist max=1) filename(string) txtname(string) ///
	para1(string) para2(string) para3(string) para4(string) ext(string) latest NOMETA NET]
	
	// Error
	global errcode 0
	
	// pass to _datalibweb
	tempfile temp1
	local collname `server'
	
	/*
	if ("`surveyid'" ~= "" & "`filename'"~="") local filename `filename' 		
	if ("`surveyid'" ~= "" & "`filename'"=="") {
		if strpos("`=upper("`collection'")'","RAW") >0 local filename 	
		else                                           local filename `surveyid'
	}
	if ("`surveyid'" == "" & "`filename'"~="") local filename `filename'
	*/
	*foreach cstr in collection folder token filename para1 para2 para3 para4 ext {
	foreach cstr in collection folder token filename para1 para2 para3 para4 {
		if "``cstr''"=="" local s_`cstr'
		else local s_`cstr' "&`cstr'=``cstr''"
	}
	local dlibapi "Server=`server'&Country=`country'&Year=`year'`s_collection'`s_folder'`s_token'`s_filename'`s_para1'`s_para2'`s_para3'`s_para4'`s_ext'"			

	dlw_api, option(0) outfile(`temp1') query("`dlibapi'")
	if `dlibrc'==0 {
		if "`dlibFileName'"=="ECAFileinfo.csv" { // results in list of files		
			qui insheet using "`temp1'", clear				
			if _N==1 { // Check errorcode in the list			
				cap confirm numeric variable filename
				if _rc==0 {
					noi dis as text in red "{p 4 4 2}`=errordetail[1]'{p_end}"
					dlw_message, error(`=errorcode[1]')
					global errcode `=errorcode[1]'
					clear
					error 1
				}
			}
			qui { //qui
				cap drop filepath
				ren filename file								
				cap split filesharepath, p("\" "/")
				ren filesharepath3 survey
				ren filesharepath4 surveyid
				ren filesharepath path
				gen ext = substr(file,length(file)-strpos(reverse(file),".")+2,strpos(reverse(file),"."))
				if "$DATALIBWEB_VERSION"=="1" {						
					replace filesize = subinstr(filesize, " bytes","",.)
					destring filesize, replace
				}
				replace filesize = round(filesize/1e6,.001) 
				format %10.3g filesize
				//Clean and Save the filesearch data
				order survey surveyid path file		
				qui compress
				cap drop __*  
				cap drop filesharepath*
				qui drop if path==""
				
				gen ntoken = strlen(surveyid) - strlen(subinstr(surveyid,"_","",.))
				gen type = "RAW" if ntoken==4
				replace type = "Harmonized" if ntoken==7
				split surveyid, p(_)
				ren surveyid1 countrycode
				ren surveyid2 year
				ren surveyid3 surveyname
				ren surveyid4 verm
				ren surveyid5 verm_l
				gen str collection = ""
				replace collection = "`=upper("`server'")'RAW" if type == "RAW"
			} //qui
			cap confirm variable surveyid8
			qui if _rc==0 {
				ren surveyid6 vera
				ren surveyid7 vera_l
				replace collection = surveyid8 if type == "Harmonized"	
				split file if type == "Harmonized", p(_)					
				cap gen str mod = ""
				cap replace mod = substr(file9,1,length(file9)-4)					
				cap drop file1-file9
			}
			
			if _N>0 { // get version								
				qui levelsof survey, local(surlist) // check survey types
				if `=wordcount(`"`surlist'"')' >1 { // more than one type of survey
					noi dis in yellow _n "{p 4 4 2}There are `=wordcount(`"`surlist'"')' different types of surveys with defined parameters. Click on the following links to redefine the search.{p_end}"					
					local rn = 1
					local rn2 = 1
					bys survey (file): gen seq = _n
					bys survey (file): gen seqN = _N			
					foreach ids of local surlist {							
						local text datalibweb, country(`=countrycode[`rn']') year(`=year[`rn']') type(`=collection[`rn']') surveyid(`ids') `nometa'						
						noi dis as text `"`rn2'. [{stata `"`text'"':`text'}]"'								
						noi dis as text in red "{p 4 4 2}`=errordetail[`rn']'{p_end}"
						if "`net'" ~="" noi dis `"<a onclick="sendCommand('`text'')">`text'</a>"'
						local rn = `rn' + `=seqN[`rn']'	
						local rn2 = `rn2' + 1
						//if "`nometa'"=="" _metadisplay, surveyid(`=trim("`ids'")')											
					}			
					qui clear
				} //end of more than one survey types
				else { //one type of survey only					
					qui if "`latest'"~="" { // latest or not
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
					
					// list if there is more than one or get the file
					qui levelsof surveyid, local(surveylist)
					if `=wordcount(`"`surveylist'"')' >1 {
						noi dis in yellow _n "{p 4 4 2}There are `=wordcount(`"`surveylist'"')' survey/data vintages with defined parameters. Click on the following links to redefine the search.{p_end}"	
						local rn = 1
						local rn2 = 1
						bys surveyid (file): gen seq = _n
						bys surveyid (file): gen seqN = _N			
						foreach ids of local surveylist {							
							local text datalibweb, country(`=countrycode[`rn']') year(`=year[`rn']') type(`=collection[`rn']') surveyid(`ids') `nometa'						
							noi dis `"`rn2'. [{stata `"`text'"':`text'}]"'								
							noi dis as text in red "{p 4 4 2}`=errordetail[`rn']'{p_end}"
							if "`net'" ~="" noi dis `"<a onclick="sendCommand('`text'')">`text'</a>"'
							local rn = `rn' + `=seqN[`rn']'	
							local rn2 = `rn2' + 1
							if "`nometa'"=="" _metadisplay, surveyid(`=trim("`ids'")')											
						}			
						qui clear
					} // end of many survey ID
					else { // one Survey ID
						qui levelsof file, local(filelist)
						local ids `=surveyid[1]'
						if `=wordcount(`"`filelist'"')' >1 {	
							qui replace ext = lower(ext)
							qui levelsof ext, local(extlist)
							tempfile extdata
							qui save `extdata', replace
							noi dis in yellow _n "{p 4 4 2}There are more than one files with defined parameters. Click on the following to redefine the search.{p_end}"
							local rn = 1
							noi dis in yellow "{p 4 4 2}Files available for this Survey ID: `ids'{p_end}"
							noi dis as text in red "{p 4 4 2}`=errordetail[`rn']'{p_end}"
							if "`nometa'"=="" _metadisplay, surveyid(`=trim("`ids'")')
							*if "`folder'"~="" noi dis in yellow _newline "{p 4 4 2}For folder: `folder'{p_end}"
							foreach ex of local extlist {
								qui use "`extdata'", clear
								qui keep if ext=="`ex'"
								local rn = 1
								local nfiles = _N
								qui levelsof file, local(filelist)
								noi dis in yellow _newline "{p 4 4 2}File type: .`ex' (`nfiles' files){p_end}"
								foreach fs of local filelist {												
									local text datalibweb, country(`=countrycode[`rn']') year(`=year[`rn']') type(`=collection[`rn']') surveyid(`ids') filename(`=file[`rn']') `nometa'
									noi dis `"`rn'. [{stata `"`text'"':`text'}]"'
									if "`net'" ~="" noi dis `"<a onclick="sendCommand('`text'')">`text'</a>"'
									local rn = `rn' + 1
								}
							}
							qui clear
						}
						else { //only 1 file, load it
							cap gen mod = ""
							cap gen vera = ""
							
							dis as text "{hline}"
							noi dis as text _col(5) "{cmd:Country:} " in y "`=upper("`country'")'" 
							noi dis as text _col(5) "{cmd:Year:} " in y "`=year[1]'"
							noi dis as text _col(5) "{cmd:Survey:} " in y "`=surveyname[1]'" 
							noi dis as text _col(5) "{cmd:Type:} " in y "`=collection[1]'"							
							noi dis as text _col(5) "{cmd:Master Version:} " in y "`=verm[1]'" 
							cap confirm variable vera, ex
							if _rc==0 noi dis as text _col(5) "{cmd:Alternative Version:} " in y "`=vera[1]'"
							noi dis as text _col(5) "{cmd:Data type:} " in y "`surveyname'" 
							cap confirm variable mod, ex
							if _rc==0 noi dis as text _col(5) "{cmd:Module:} " in y "`=mod[1]'"
							noi dis as text _col(5) "{cmd:File name(s):} " in y "`=file[1]'" 
							noi dis as text _col(5) "{cmd:File size (MB):} " in y "`=filesize[1]'"
							noi dis as text _col(5) "{cmd:Last modified date(s):} " in y "`=filelastmodifeddate[1]'" 
							if "`=filelastdownloadeddate[1]'"~="." noi dis as text _col(5) "{cmd:Last downloaded date(s):} " in y "`=filelastdownloadeddate[1]'"
							dis as text "{hline}" _newline							
							if "`nometa'"=="" _metadisplay, surveyid(`=trim("`ids'")')
							
							return local type `=collection[1]'	
							cap confirm variable mod, ex
							/*
							if _rc==0 return local module `=mod[1]'						
							return local verm `=verm[1]'						
							cap confirm variable vera, ex
							if _rc==0 return local vera `=vera[1]'						
							return local surveyid `ids'
							return local filename `=file[1]'
							return local idno `r(id)'
							*/
							if _rc==0 local mod `=mod[1]'						
							local verm `=verm[1]'						
							cap confirm variable vera, ex
							if _rc==0 local vera `=vera[1]'						
							local surveyid `ids'
							local filename `=file[1]'
							local filedate `=filelastmodifeddate[1]'
							local idno `r(id)'
							// call the single file, often no permission
							tempfile temp2
							local filename `=file[1]'
							foreach cstr in collection folder token filename /*para1 para2 para3 para4 ext*/ {
								if "``cstr''"=="" local s_`cstr'
								else local s_`cstr' "&`cstr'=``cstr''"
							}
							local dlibapi "Server=`server'&Country=`country'&Year=`year'`s_collection'`s_folder'`s_token'`s_filename'`s_para1'`s_para2'`s_para3'`s_para4'`s_ext'"			
							dlw_api, option(0) outfile(`temp2') query("`dlibapi'")
							if `dlibrc'==0 {			
								if "`dlibFileName'"=="ECAFileinfo.csv" {
									qui insheet using "`temp2'", clear
									noi dis as text in red "{p 4 4 2}`=errordetail[1]'{p_end}"
									dlw_message, error(`=errorcode[1]')
									global errcode `=errorcode[1]'
									clear
									error 1
								}
								else { //different filename, then load it
									local tmppath = substr("`temp2'",1,length("`temp2'")-strpos(reverse("`temp2'"),"\")+1)
									if "`dlibType'"=="dta" {							
										cap use "`temp2'", clear	
										if _rc==0 {
											return local type `collection'
											return local module `mod'
											return local verm `verm'
											return local vera `vera'
											return local surveyid `surveyid'
											return local filename `dlibFileName'
											return local filedate `filedate'
											return local idno `r(id)'
										}
										else {
											noi dis as text in red "{p 4 4 2}Can't open the file (`dlibFileName'). Data file was saved with new Stata versions.{p_end}"	
											global errcode = 999
											error 1
										}
									} 	
									else if "`dlibType'"=="do" { // only one file matched/subscribed - load the file  													
										cap doedit "`tmppath'\`dlibFileName'"
										if _rc==0 {
											noi dis as text in yellow `"{p 4 4 2}The dofile (`dlibFileName') is loaded.{p_end}"'	
											return local type `collection'
											return local module `mod'
											return local verm `verm'
											return local vera `vera'
											return local surveyid `surveyid'
											return local filename `dlibFileName'
											return local filedate `filedate'
											return local idno `r(id)'
										}
										else {
											noi dis as text in red "{p 4 4 2}This dofile (`dlibFileName') is not a properly formatter dofile.{p_end}"	
											global errcode = 999
											error 1
										}
									}
									else { //different types
										cap shell `tmppath'\`dlibFileName'
										if _rc==0 {
											noi dis as text in yellow `"{p 4 4 2}The file "`dlibFileName'" is loaded.{p_end}"'	
											return local type `collection'
											return local module `mod'
											return local verm `verm'
											return local vera `vera'
											return local surveyid `surveyid'
											return local filename `dlibFileName'
											return local filedate `filedate'
											return local idno `r(id)'
										}
										else { //cant open
											noi dis as text in red "{p 4 4 2}Can't open the file (`dlibFileName'). This file extension is not supported yet by your operating systems or the file is damaged.{p_end}"	
											global errcode = 999
											error 1
										}
									} //different types
								} //end of different filename
							} //dlibrc==0						
							else {
								dlw_message, error(`dlibrc')
								global errcode `dlibrc'
								clear
								error 1
							}
							
						} // end of onefile
					} // end of one survey ID
				} //one type of survey only	
			} //end of r(N)>0
			else {
				noi dis as text in red "{p 4 4 2}There is NO survey/data with defined parameters: `collection', `country', `year', `surveyid'. Please redefine the parameters.{p_end}"
				error 1
			} //_N==0			
		} //ECAFileinfo.csv
		else { //single file with permission
			if "`surveyid'"=="" local strtoken "`dlibFileName'" //tokenize the survey id or filename dlibFileName
			else                local strtoken "`surveyid'"			
			local surveyid3 = subinstr("`strtoken'","_"," ",.)
			local surveyid3 = subinstr("`surveyid3'",".dta","",.)
			if `=wordcount("`surveyid3'")-1' >= 4 {
				tokenize "`surveyid3'"
				local surveyname `3'
				local verm       `4'
				if `=wordcount("`surveyid3'")-1' >= 5 {
					local vera `6'
					local mod `9'
				}
			}
			
			dis as text "{hline}"
			noi dis as text _col(5) "{cmd:Country:} " in y "`=upper("`country'")'" 
			noi dis as text _col(5) "{cmd:Year:} " in y "`year'"
			noi dis as text _col(5) "{cmd:Survey:} " in y "`surveyname'" 
			noi dis as text _col(5) "{cmd:Type:} " in y "$type"
			noi dis as text _col(5) "{cmd:Master Version:} " in y "`verm'" 
			if "`6'"~="" noi dis as text _col(5) "{cmd:Alternative Version:} " in y "`vera'"
			noi dis as text _col(5) "{cmd:Data type:} " in y "`surveyname'" 
			if "`9'"~="" noi dis as text _col(5) "{cmd:Module:} " in y "`mod'"
			noi dis as text _col(5) "{cmd:Data file name(s):} "   in y "`dlibFileName'" 
			local filesize : dis %10.3g `=`dlibDataSize'/1e6'
			noi dis as text _col(5) "{cmd:File size(MB):} "   in y "`=trim("`filesize'")'"
			*noi dis as text _col(5) "{cmd:File size(MB):} "   in y "`=`dlibDataSize'/1e6'" 
			//noi dis as text _col(5) "{cmd:Last modified date(s):} "   in y "`=filelastmodifeddate[1]'" as text " {p_end}"
			//noi dis as text _col(5) "{cmd:Last downloaded date(s):} "   in y "`=filelastdownloadeddate[1]'" as text " {p_end}"										
			dis as text "{hline}" _newline
			if "`surveyid'"=="" local surveyid = subinstr("`strtoken'",".dta","",.)
			if "`nometa'"==""   _metadisplay, surveyid(`=trim("`surveyid'")')			
			
			local tmppath = substr("`temp1'",1,length("`temp1'")-strpos(reverse("`temp1'"),"\")+1)				
			if "`dlibType'"=="dta" { // only one file matched/subscribed - load the file  									
				cap use `temp1', clear	 //load the data
				if _rc==0 {
					return local type `collection'
					return local module `mod'
					return local verm `verm'
					return local vera `vera'
					return local surveyid `surveyid'
					return local filename `dlibFileName'
					return local idno `r(id)'
				}
				else {
					noi dis as text in red "{p 4 4 2}Can't open the file (`dlibFileName'). Data file was saved with new Stata versions.{p_end}"	
					global errcode = 999
					error 1
				}
			} // dta type
			else if "`dlibType'"=="do" { // only one file matched/subscribed - load the file  													
				cap doedit "`tmppath'\`dlibFileName'"
				if _rc==0 {
					noi dis as text in yellow `"{p 4 4 2}The dofile (`dlibFileName') is loaded.{p_end}"'	
					return local type `collection'
					return local module `mod'
					return local verm `verm'
					return local vera `vera'
					return local surveyid `surveyid'
					return local filename `dlibFileName'
					return local idno `r(id)'
				}
				else {
					noi dis as text in red "{p 4 4 2}This dofile (`dlibFileName') is not a properly formatter dofile.{p_end}"	
					global errcode = 999
					error 1
				}
			}
			else { //different types
				cap shell `tmppath'\`dlibFileName'
				if _rc==0 {
					noi dis as text in yellow `"{p 4 4 2}The file (`dlibFileName') is loaded in the corresponding application.{p_end}"'	
					return local type `collection'
					return local module `mod'
					return local verm `verm'
					return local vera `vera'
					return local surveyid `surveyid'
					return local filename `dlibFileName'
					return local idno `r(id)'
				}
				else { //cant 
					noi dis as text in red "{p 4 4 2}Can't open the file (`dlibFileName'). This file extension is not supported yet by your operating systems or the file is damaged.{p_end}"	
					global errcode = 999
					error 1
				}
			}
		} //end single file
	} //end of _rc plugin
	else {	
		dlw_message, error(`dlibrc')
		global errcode `dlibrc'
		clear
		error 1
	} //end else of _rc plugin
	
end
