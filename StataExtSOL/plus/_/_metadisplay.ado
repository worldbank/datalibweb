*! version 0.1  22oct2015
*! Minh Cong Nguyen

cap program drop _metadisplay
program define _metadisplay, rclass
	version 12, missing
	local verstata : di "version " string(_caller()) ", missing:"	
	syntax, surveyid(string) 
	//check surveyid
	if (strpos("`surveyid'","_M") > 0) | (strpos("`surveyid'","_A") > 0) {
		//get the SurveyID of the raw
		local idsraw = trim(substr("`surveyid'",1,`=strpos("`surveyid'","_M")+1'))
		//Meta for raw data
		cap wbmetadata, surveyid(`idsraw') key(id surveyid titl)
		if "`r(id)'"~="" { // available meta data raw								
			noi dis as text "{p 4 4 2}{cmd:Survey ID:} "            in y "`r(surveyid)'" as text " {p_end}"
			noi dis as text "{p 4 4 2}{cmd:Title:} "                in y "`r(titl)'" as text " {p_end}"
			local ddilink http://microdatalib.worldbank.org/index.php/catalog/`r(id)'
			noi di in smcl "{p 4 4 2}{cmd:Link to DDI:}  {browse "_char(34)"`ddilink'"_char(34)" : Survey metadata (Microdata Library portal)}" _newline
			
			if "`surveyid'"~="`idsraw'" {
				//meta data for harmonized id
				cap wbmetadata, surveyid(`surveyid') key(id surveyid titl)
				if "`r(id)'"~="" { // available meta data raw								
					noi dis as text "{p 4 4 2}{cmd:Survey ID:} "            in y "`r(surveyid)'" as text " {p_end}"
					noi dis as text "{p 4 4 2}{cmd:Title:} "                in y "`r(titl)'" as text " {p_end}"
					local ddilink http://microdatalib.worldbank.org/index.php/catalog/`r(id)'
					noi di in smcl "{p 4 4 2}{cmd:Link to DDI:}  {browse "_char(34)"`ddilink'"_char(34)" : Survey metadata (Microdata Library portal)}" _newline
				}
			}
		}
		else { //meta not available	for raw data									
			noi dis as text "{p 4 4 2}{cmd:Survey ID:} "            in y "`idsraw'" as text " {p_end}"
			noi dis as text "{p 4 4 2} Meta data is not available in the Microdata Library" as text " {p_end}" _newline
			if "`surveyid'"~="`idsraw'" {
				//meta data for harmonized id
				cap wbmetadata, surveyid(`surveyid') key(id surveyid titl)
				if "`r(id)'"~="" { // available meta data raw								
					noi dis as text "{p 4 4 2}{cmd:Survey ID:} "            in y "`r(surveyid)'" as text " {p_end}"
					noi dis as text "{p 4 4 2}{cmd:Title:} "                in y "`r(titl)'" as text " {p_end}"
					local ddilink http://microdatalib.worldbank.org/index.php/catalog/`r(id)'
					noi di in smcl "{p 4 4 2}{cmd:Link to DDI:}  {browse "_char(34)"`ddilink'"_char(34)" : Survey metadata (Microdata Library portal)}" _newline
				}
				else {
					noi dis as text "{p 4 4 2}{cmd:Survey ID:} "            in y "`surveyid'" as text " {p_end}"
					noi dis as text "{p 4 4 2} Meta data is not available in the Microdata Library" as text " {p_end}" _newline
				}
			}
		}
	}
end
