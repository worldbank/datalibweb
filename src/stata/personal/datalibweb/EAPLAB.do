//Datalibweb system file - do not delete or change
//EAPLAB.do

global hhid
global pid
global defmod "Y" 
global hhmlist
global indmlist
global root 
global rootname EAP
global subfolders Data\Harmonized
global data `" "Data\Harmonized" "'
global doc `" "Doc\Questionnaire" "Doc\Technical" "'
global prog `" "Programs" "'
global token 8
global updateday 1
global type EAPLAB
global base
global basedeffile
global cpi 
global cpifile PPP_CPI_EAP_all_datalibweb.dta
global cpic SUPPORT
global cpiy 2005
global cpif Data\Stata
global rootcpi EAP
*global cpiw "Server=$rootcpi&Country=$cpic&Year=$cpiy&filename=$cpifile&folder=$cpif"
global cpivarw icp* cpi*
global distxt EAP TSD/EAPLAB
global email datalibweb@worldbank.org; eaptsd@worldbank.org;
