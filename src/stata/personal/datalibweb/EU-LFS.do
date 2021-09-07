//Datalibweb system file - do not delete or change
//EU-LFS.do

global hhid
global pid
global defmod "Y" 
global hhmlist
global indmlist
global root 
global rootname ECA_Eurostat
global subfolders Data\Harmonized
global data `" "Data\Harmonized" "'
global doc `" "Doc\Questionnaire" "Doc\Technical" "'
global prog `" "Programs" "'
global token 8
global updateday 2
global type EU-LFS
global base
global basedeffile
global cpi 
global cpifile ANNUAL_ICP_CPI.dta
global cpic SUPPORT
global cpiy 2005
global cpif Data\Stata
global rootcpi ECA
*global cpiw "Server=$rootcpi&Country=$cpic&Year=$cpiy&filename=$cpifile&folder=$cpif"
global cpivarw icp* cpi*
global distxt ECA TSD/EU-LFS
global email jmontes@worldbank.org; pcorralrodas@worldbank.org; mnguyen3@worldbank.org
