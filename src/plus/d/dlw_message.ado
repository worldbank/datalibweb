//error function
cap program drop dlw_message
program define dlw_message
	syntax, error(numlist max=1)
	//subscription error
	if `error'==404 noi dis "{err}Data is not yet available in DLW catalog"
	if `error'==408 noi dis "{err}People Search Feed API call respond with timeout"
	if `error'==672 noi dis "{err}Please contact IT and activate UPI"
	if `error'==673 noi dis "{err}Please register with the datalibweb system"
	if `error'==674 noi dis "{err}Please subscribe the selected country/year/collection/module"
	if `error'==675 noi dis "{err}Please check the syntax - countrycode/year/collection/etc."
	if `error'==676 noi dis "{err}Please change countrycode/year/collection/etc."
	//Plugin error
	if `error'==601 noi dis "{err}Error code 601 - Internet bad url format"
	if `error'==602 noi dis "{err}Error code 602 - Internet authentication canceled"
	if `error'==603 noi dis "{err}Error code 603 - Internet connectivity failure"
	if `error'==604 noi dis "{err}Error code 604 - Internet datalib server unreachable"
	if `error'==605 noi dis "{err}Error code 605 - Internet unknown local error"
	if `error'==610 noi dis "{err}Error code 610 - Response error invalid content type header"
	if `error'==611 noi dis "{err}Error code 611 - Response error invalid file name header"
	if `error'==612 noi dis "{err}Error code 612 - Response error invalid content length header"
	if `error'==613 noi dis "{err}Error code 613 - Response error invalid file extension"
	if `error'==614 noi dis "{err}Error code 614 - Response error invalid status header"					
	if `error'==701 noi dis "{err}Error code 701 - Plugin usage error, parameter list"
	if `error'==702 noi dis "{err}Error code 702 - File I/O error, local file system access"
end
