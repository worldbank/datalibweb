//Datalibweb system file - do not delete or change
//GMD.do

global hhid hhid
global pid pid	
global defmod GPWG
global hhmlist	
global indmlist `""GPWG", "ALL""'
global root 
global rootname GMD
global subfolders
global data `" "Data\Harmonized" "'
global doc `" "Doc\Questionnaire" "Doc\Technical" "'
global prog `" "Programs" "'
global token 8
global updateday 5
global type GMD
global base 
global basedeffile
global cpi \\wbntst01.worldbank.org\TeamDisk\GMD\datalib\all_region\Support\Support_2005_CPI\Support_2005_CPI_v03_M\Data\Original\Final CPI PPP to be used.dta
global cpifile Final CPI PPP to be used.dta
global cpiw "Server=$rootcpi&Country=$cpic&Year=$cpiy&filename=$cpifile&folder=$cpif""
*global cpiw "Server=GPWG&Country=SUPPORT&Year=2005&filename=$cpifile&folder=Data\Stata"
global cpivarw icp* cpi*
global distxt GLOBAL TSD/GMD
global email gmd@worldbank.org; datalibweb@worldbank.org
