//Datalibweb system file - do not delete or change
//SARMD.do

global hhid idh
global pid idp	
global defmod "IND"	
global idmod 
global hhmlist	
global indmlist
global root 
global rootname SAR
global subfolders Data\Harmonized
global data `" "Data\Harmonized" "'
global doc `" "Doc\Questionnaire" "Doc\Technical" "'
global prog `" "Programs" "'
global token 8
global updateday 1
global type SARMD
global base 
global basedeffile 
global cpi 
global cpifile Final CPI PPP to be used SARMD.dta
global cpic SUPPORT
global cpiy 2011
global cpif Data\Stata
global rootcpi SAR
global cpiw "Server=$rootcpi&Country=$cpic&Year=$cpiy&filename=$cpifile&folder=$cpif"
global cpivarw ppp* cpi* 
global distxt SAR TSD/SARMD 
global email datalibweb@worldbank.org; dnewhouse@worldbank.org; ffatima@worldbank.org
