//Datalibweb system file - do not delete or change
//SSAPOV.do

global hhid hid
global pid pid
global defmod "H"	
global idmod 
global hhmlist `""P", "H", "B""'	
global indmlist `""I" "L""' 
global root 
global rootname SSA 
global subfolders Data\Harmonized 
global data `" "Data\Harmonized" "'
global doc `" "Doc\Questionnaire" "Doc\Technical" "'
global prog `" "Programs" "'
global token 8
global updateday 1
global type SSAPOV
global base 
global basedeffile
global cpi 
global cpifile Final_CPI_PPP_to_be_used.dta
global cpic SUPPORT
global cpiy 2005
global cpif Data\Stata
global rootcpi GMD
global cpiw "Server=$rootcpi&Country=$cpic&Year=$cpiy&filename=$cpifile&folder=$cpif"
global cpivarw icp* cpi* 
global distxt SSA TSD/SSAPOV 
global email datalibweb@worldbank.org; dnewhouse@worldbank.org; jmontes@worldbank.org
