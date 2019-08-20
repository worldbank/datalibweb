//Datalibweb system file - do not delete or change
//SEDLAC-02.do

global hhid id
global pid com	
global defmod pov
global hhmlist `""HHD""'
global indmlist `""POV", "ALL", "DMR", "IND", "SEDLAC""'
global period 
global root 
global rootname SEDLAC 
global subfolders Data\Harmonized 
global data `" "Data\Harmonized" "'
global doc `" "Doc\Questionnaires" "Doc\Technical" "'
global prog `" "Programs" "'
global token 8
global updateday 5
global type SEDLAC-02
global base CEDLAS-02
global basedeffile
global cpi 
global cpifile ipc_sedlac_wb.dta
global cpiw "Server=$rootcpi&Country=$cpic&Year=$cpiy&filename=$cpifile&folder=$cpif"
global cpivarw *_sedlac ppp* conversion 
global distxt LAC TSD/SEDLAC
global email datalibweb@worldbank.org; lmorenoherrera@worldbank.org; cdiazbonilla@worldbank.org; segoviajuarez@worldbank.org;
