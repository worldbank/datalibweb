cap program drop dlw_adoupdate
program define dlw_adoupdate
	set checksum off
	set more off
	
	local plusdir : sysdir PLUS
    if "$S_OS"=="Windows" local plusdir : subinstr local plusdir "/" "\", all	
	if ("`plusdir'" == "") {
		local plusdir "c:\ado\plus\"
		cap mkdir "`plusdir'"
	}
	
	local other : sysdir PERSONAL
    if "$S_OS"=="Windows" local other : subinstr local other "/" "\", all	
	if ("`other'" == "") {
		local other "c:\ado\personal\"
		cap mkdir "`other'"
	}
	
	** Main FROM-directories 
	local dirfrom "http://ecaweb.worldbank.org/povdata/datalibweb/_ado/" 
	
	** Create aux TO-directory
	cap mkdir "`other'datalibweb"
		
	* Machine type
	if (regexm(`"`=c(machine_type)'"', `"64"')) local mtype 64
	else local mtype 32
	if "`mtype'"=="" {
		noi dis as error "Unrecognized system - please check with admins"
		error 1
	}
	
	net from "`dirfrom'"
	net set ado "`plusdir'"
	net set other "`other'"	
	noi net install datalibweb, all replace force from("`dirfrom'")
	
	** Copy auxiliary file
	discard
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
	noi disp in y _n "{cmd:datalibweb} has been updated. " _n 
	noi type "`plusdir'd\datalibweb_version.txt"
	discard
	exit
end
