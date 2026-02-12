//Datalibweb system file - do not delete or change
//I2D2-Labor.do
global hhid idh
global pid idp	
global defmod "all"	
global idmod 
global hhmlist 
global indmlist `""all""'
global root 
global rootname I2D2
global subfolders Data\Harmonized
global data `" "Data\Harmonized" "' //one folder
global doc `" "Doc\Questionnaire" "Doc\Technical" "' //can be more than 1 folder
global prog `" "Programs" "'  //can be more than 1 folder
global token 8
global updateday 5
global type I2D2-Labor
global base 
global basedeffile
global cpi 
global cpifile 
global cpic SUPPORT
global cpiy 2005
global cpif Data\Stata
global rootcpi GMD
*global cpiw "Server=$rootcpi&Country=$cpic&Year=$cpiy&filename=$cpifile&folder=$cpif"
global cpivarw icp* cpi*
global distxt Global TSD/I2D2
global email datalibweb@worldbank.org
