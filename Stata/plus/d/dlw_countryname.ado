
program define dlw_countryname
	syntax, [savepath(string) clear replace]

	quietly {
		if "`savepath'" != "" {
			preserve
			local clear "clear"
		}
		findfile dlw_countryname.ado
		local csvdata = subinstr("`r(fn)'", "dlw_countryname.ado", "dlw_countryname.csv", .)
		import delimited using "`csvdata'", `clear' varnames(1) 

		label var region "Region"
		label var countrycode "Country Code"
		label var countryname "Country Name"
		compress
	}

	if "`savepath'" != "" {
		save "`savepath'", `replace'
	}
end
