/*===========================================================================
project:       update datalibweb
Author:        Andres Castaneda 
Dependencies:  The World Bank
---------------------------------------------------------------------------
Creation Date:     March 24, 2015 
Modification Date: 
Do-file version:    02
References:          
Output:             
===========================================================================*/

/*=======================================================================
                                  0: Program set up               
=======================================================================*/
*! version 0.2  11dec2015
*! Andres Castaneda
version 12
program define datalibweb_update, rclass 
	syntax [anything], user(string)
	qui set checksum off
	* Initial conditions
	local exit ""
	
	local plusdir : sysdir PLUS
    if "$S_OS"=="Windows" local plusdir : subinstr local plusdir "/" "\", all
	//local plusdir "`c(sysdir_plus)'"	
	if ("`plusdir'" == "") {
		local plusdir "c:\ado\plus\"
		cap mkdir "`plusdir'"
	}
	
	local other : sysdir PERSONAL
    if "$S_OS"=="Windows" local other : subinstr local other "/" "\", all
	//local other   "`c(sysdir_personal)'"
	if ("`other'" == "") {
		local other "c:\ado\personal\"
		cap mkdir "`other'"
	}
	
	** Main FROM-directories 
	local dirfrom "http://ecaweb.worldbank.org/povdata/statapackages/" 
	
	** Create aux TO-directory
	cap mkdir "`other'datalibweb"
		
	* Machine type
	if (regexm(`"`=c(machine_type)'"', `"64"')) local mtype 64
	else local mtype 32
	if "`mtype'"=="" {
		noi dis as error "Unrecognized system - please check with admins"
		error 1
	}	
/*=======================================================================
                        1: check for update
=======================================================================*/	
	tempfile tfile0
	tempname tf0
	cap copy "`plusdir'd\datalibweb_currentversion.txt" `tfile0'
	if _rc==0 {
		file open `tf0' using `tfile0', read
		file read `tf0' line					// first line
		local olddate `"`macval(line)'"'	
		file close `tf0'
		
		tempfile tfile
		tempname tf
		copy "`dirfrom'd\datalibweb_currentversion.txt" `tfile'

		file open `tf' using `tfile', read
		file read `tf' line					// first line
		local newdate `"`macval(line)'"'	
		file close `tf'
		
		if date("`olddate'", "DMY") < date("`newdate'", "DMY") {

			/*=======================================================================
								2: Updating procedure. 
			=======================================================================*/
			window stopbox note "Dear `user'," ///
				"A New version of -datalibweb- has been released." ///
				"Please close other Stata sessions and Click OK to proceed."

			net from "`dirfrom'"
			net set ado "`plusdir'"
			net set other "`other'"		
			noi net install datalibweb, replace force from("`dirfrom'")

			** Copy auxiliary file		dlib2_
			clear all
			cap prog drop _datalibweb
			cap prog drop dlwgui
			copy "`dirfrom'd/dlib2_`mtype'.dll" "`plusdir'd\dlib2_`mtype'.dll", replace         //  DDL					
			copy "`dirfrom'd/dlib2g_`mtype'.dll" "`plusdir'd\dlib2g_`mtype'.dll", replace         //  DDL					
			copy "`dirfrom'd/Dlib2SOL_`mtype'.dll" "`plusdir'd\Dlib2SOL_`mtype'.dll", replace         //  DDL					
			copy "`dirfrom'd/datalibweb_version.txt" "`plusdir'd\datalibweb_version.txt", replace   //  SMCL
			copy "`dirfrom'd/datalibweb_currentversion.txt" "`plusdir'd\datalibweb_currentversion.txt", replace   //  SMCL			
			** Zipped files
			tempfile zpfile
			local cdir `c(pwd)'			
			qui copy "`dirfrom'd/datalibweb_ini.zip" "`zpfile'", replace 
			qui cd "`other'datalibweb"
			cap unzipfile "`zpfile'", replace // name of zip file.
			if _rc==0 noi dis in y _n "Successfully updated Setting dofiles"
			else noi dis in y _n "Failed to update Setting dofiles"	
			qui cd "`cdir'"
					
			//net get datalibweb, `replace'
			//net set other
			
			noi disp in y _n "{cmd:datalibweb} has been updated. " _n 
			*noi disp in y _n "Click {stata discard:here} to finish {cmd: datalibweb}" _request(_discard)		      
			*if ("`discard'" == "discard") {
				discard
				noi type "`plusdir'd\datalibweb_version.txt"
			*}
			discard
			local exit exit
			global dlw_update = 1
		}
		return local exit "`exit'"
	}
	else {
		copy "`dirfrom'd/datalibweb_currentversion.txt" "`plusdir'd\datalibweb_currentversion.txt", replace  
	}
end
exit

/* End of do-file */
