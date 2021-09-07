//Datalibweb system file - do not delete or change
//SEDLAC-03.do

global hhid id
global pid com	
global defmod pov
global hhmlist `""HHD", "REG""'
global indmlist `""ALL", "EDU", "DMR", "GMD", "IND", "LAB", "POV""'
global period 
global root 
global rootname SEDLAC 
global subfolders Data\Harmonized 
global data `" "Data\Harmonized" "'
global doc `" "Doc\Questionnaires" "Doc\Technical" "'
global prog `" "Programs" "'
global token 8
global updateday 1
global type SEDLAC-03
global base CEDLAS-03
global basedeffile
global cpi 
global cpifile ipc_sedlac_wb.dta
global cpic SUPPORT
global cpiy 2005
global cpif Data\Stata
global rootcpi SEDLAC
global cpiw "Server=$rootcpi&Country=$cpic&Year=$cpiy&filename=$cpifile&folder=$cpif"
global cpivarw *_sedlac ppp* conversion 
global distxt LAC TSD/SEDLAC
global email datalibweb@worldbank.org; lmorenoherrera@worldbank.org; cdiazbonilla@worldbank.org
