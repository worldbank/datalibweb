//Datalibweb system file - do not delete or change
//SES.do
global hhid 
global pid 
global defmod "ANONYM"	
global idmod 
global hhmlist 
global indmlist 
global root 
global rootname ECA_Eurostat
global subfolders Data\Harmonized
global data `" "Data\Harmonized" "' //one folder
global doc `" "Doc\Questionnaire" "Doc\technical" "' //can be more than 1 folder
global prog `" "Programs" "'  //can be more than 1 folder
global token 8
global updateday 5
global type SES
global base 
global basedeffile
global cpi 
global cpifile 
global cpic SUPPORT
global cpiy 2005
global cpif Data\Stata
global rootcpi
*global cpiw "Server=$rootcpi&Country=$cpic&Year=$cpiy&filename=$cpifile&folder=$cpif"
global cpivarw icp* cpi*
global distxt ECA TSD
global email datalibweb@worldbank.org
