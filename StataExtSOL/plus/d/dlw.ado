*! version 1.0.0   21nov2018
program dlw, rclass
	set linesize 168
	local user = c(username)
	global usertmp "/userdata/`user'/tmp/"
	datalibweb `0'
	return add
end

