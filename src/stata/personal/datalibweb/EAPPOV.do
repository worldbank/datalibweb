//Datalibweb system file - do not delete or change
//EAPPOV.do

global hhid hid
global pid indid	
global defmod "POV"
global idmod 
global hhmlist `""POV", "H", "B""'
global indmlist `""I""' 
global root 
global rootname EAP
global subfolders Data\Harmonized
global data `" "Data\Harmonized" "'
global doc `" "Doc\Questionnaire" "Doc\Technical" "'
global prog `" "Programs" "'
global token 8
global updateday 1
global type EAPPOV
global base 
global basedeffile
global cpi 
global cpifile PPP_CPI_EAP_all_datalibweb.dta
global cpic SUPPORT
global cpiy 2005
global cpif Data\Stata
global rootcpi EAP
global cpiw "Server=$rootcpi&Country=$cpic&Year=$cpiy&filename=$cpifile&folder=$cpif"
global cpivarw icp* cpi*
global distxt EAP TSD/EAPPOV
global email datalibweb@worldbank.org; jyang4@worldbank.org; rdewina@worldbank.org
