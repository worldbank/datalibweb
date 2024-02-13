//error function
cap program drop dlw_message
program define dlw_message
	syntax, error(numlist max=1)
	//subscription error
	if `error'==3 noi dis "{err}Access denied - Please agree to General MOU/Disclaimer to download at http://datalibweb"
	else if `error'==4 noi dis "{err}Access denied - survey disclaimer has not been accepted"		
	else if `error'==5 noi dis "{err}Access denied - expired subscription for the selected Country/Year/Collection"
	else if `error'==6 noi dis "{err}Access denied - registered users - no permission to the selected Country/Year/Survey/Collection"	
	else if `error'==404 noi dis "{err}Error code 404 - Data is not yet available in DLW catalog"
	else if `error'==672 noi dis "{err}Please contact IT and activate UPI"
	else if `error'==673 noi dis "{err}Please register with the datalibweb system"
	else if `error'==674 noi dis "{err}Please subscribe the selected country/year/collection/module"
	else if `error'==675 noi dis "{err}Please check the syntax - countrycode/year/collection/etc."
	else if `error'==676 noi dis "{err}Please change countrycode/year/collection/etc."
	else if `error'==677 noi dis "{err}Access denied - pending request"
	//Plugin error
	else if `error'==401 noi dis "{err}Error code 401 - Expired or invalid token"
	else if `error'==408 noi dis "{err}Error code 408 - People Search Feed API call respond with timeout"
	else if `error'==500 noi dis "{err}Error code 500 - Website or API timeout"
	else if `error'==502 noi dis "{err}Error code 502 - API issues"
	else if `error'==503 noi dis "{err}Error code 502 - No catalog or files for this country"
	else if `error'==601 noi dis "{err}Error code 601 - Internet bad url format"
	else if `error'==602 noi dis "{err}Error code 602 - Internet authentication canceled"
	else if `error'==603 noi dis "{err}Error code 603 - Internet connectivity failure"
	else if `error'==604 noi dis "{err}Error code 604 - Internet datalib server unreachable"
	else if `error'==605 noi dis "{err}Error code 605 - Internet unknown local error"
	else if `error'==610 noi dis "{err}Error code 610 - Response error invalid content type header"
	else if `error'==611 noi dis "{err}Error code 611 - Response error invalid file name header"
	else if `error'==612 noi dis "{err}Error code 612 - Response error invalid content length header"
	else if `error'==613 noi dis "{err}Error code 613 - Response error invalid file extension"
	else if `error'==614 noi dis "{err}Error code 614 - Response error invalid status header"					
	else if `error'==701 noi dis "{err}Error code 701 - Plugin usage error, parameter list"
	else if `error'==702 noi dis "{err}Error code 702 - File I/O error, local file system access"
	else noi dis "{err}Error code `error' - Unknown error code"
end
