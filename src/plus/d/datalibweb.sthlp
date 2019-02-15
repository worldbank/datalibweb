{smcl}
{* 24oct2015 }{...}
{cmd:help datalibweb} 
{hline}
 
{title:Title}

{p2colset 9 24 22 2}{...}
{p2col :{hi:datalibweb} {hline 2}}Datalibweb is an API data platform specifically designed to enable users to access 
 the most up-to-date data and documentation available in different regional catalogs 
 at the World Bank. {p_end}
{p2colreset}{...}

{* SYNTAX *}
{title:Syntax}

{p 6 16 2}
{cmd:datalibweb}{cmd:,} {it:{help datalibweb##options:parameters}} [{it:{help datalibweb##options:options}}]
 
{pstd}
where {it:parameters} identify the characteristics of the file to be loaded.

{marker sections}{...}
{title:Sections}

{pstd}
Sections are presented under the following headings:

		{it:{help datalibweb##desc:Command description}}
		{it:{help datalibweb##param:Parameters description}}
		{it:{help datalibweb##Examples:Examples}}
		{it:{help datalibweb##PPP:PPP Conversion}}
		{it:{help datalibweb##disclaimer:Disclaimer}}
		{it:{help datalibweb##termsofuse:Terms of use}}
		{it:{help datalibweb##howtocite:How to cite}}

{marker desc}{...}
{title:Description}

{pstd}
{cmd: datalibweb} Datalibweb is an API data platform specifically designed to enable users to access 
 the most up-to-date data and documentation available in different regional catalogs 
 at the World Bank. It allows users to access the latest and historical versions of
 non-harmonized (original/raw) data as well as different harmonized collections across
 across Global Practices. It is integrated with Stata through the Datalibweb Stata package. The commands also allows to extract different modules if available.  In 
addition {cmd: datalibweb} generates time-deflated variables, poverty lines, (LCU equivalent to 2005 or  2011 PPP US$) and the conversion factors used. Prospective 
users must ask access to: {browse "mailto: datalibweb@worldbank.org":datalibweb@worldbank.org}

{pstd}
{cmd: datalibweb} is a data system developed by the Global Team for Statistical Development, Poverty and Equity GP, of the World Bank in collobration with the ECA IT and QuickStrike teams in the ITS group. {p_end}

{pstd}
Alternatively, -{cmd:datalibweb}- provides the user with another level of interactivity with Graphical User Interface and in Stata. It is possible type {cmd:datalibweb} on the Stata command window to see an interactive screen 
that allows users to find available surveys in the datalib system. Users will have to follow a dynamic tree selecting first the desired region, then the country, and finally the 
collection to see all available harmonized and raw survey dataset.

{marker Options2}{...}
{title:Parameters}
{marker basics}{...}

{marker param}{...}
{synoptset 27 tabbed}{...}
{synopthdr:Required}
{synoptline}
{synopt:{opt coun:try(string)}}three digits country code (WDI standards). More than one country is allowed, i.e "ALB VNM". {p_end}

{synopt:{opt y:ears(numlist)}}years for which the data is requested (one or many years: i.e. 2005 or 2005/2008 or 2005 2008).{p_end}

{synopt:{opt t:ype(string)}}type of ONE collection requested. Currently the only COLLECTIONS available are: {it:eappov}, {it:ecapov}, {it:ecaraw}, {it:eu-lfs}, {it:udb-c} or {it:eusilc}, {it:udb-l} (panel eusilc), {it:mnapov}, {it:mnaraw}, {it:sarmd}, {it:ssapov}, and {it:gpwg}. Incoming collections: {it:gmd}, {it:sarraw}, {it:eapraw}, {it:ssaraw}, {it:sedlac} and {it:lablac}. {p_end} 
				 Click {browse "http://eca/povdata/_57YTY987/ECATSD_EUSILC_UserGuidelines_141008.pdf":here} for more information on the {it:eusilc} collection. 

{marker options}{...}
{synoptset 27 tabbed}{...}
{synopthdr:Optional}
{synoptline}

{marker PPP}{...}
{dlgtab:PPP Conversion}

{synopt:{opt ppp:(numlist)}}allows to select between 2005 and/or 2011 as the PPP deflation factor in the corresponding CPI/PPP database. It is used in combination with {cmd:plppp()} and/or {cmd:incppp()} options.{p_end}
		
{synopt:{opt pl:ppp(numlist)}}allows to create local currency unit (LCU) poverty lines equivalent to international dollars. Conversion 
        is done by using 2011/2005 PPP with corresponding 2011/2005 CPI values. The user has to enter a list of numbers
		with the poverty lines (in 2005/2011 dollars). If the poverty line is a fractional number 
		(i.e. 1.9 or 3.1), {cmd: datalibweb} will create a variable using the value entered as part of the variable name. For 
		instance, if the user puts the 1.9 dollar a day poverty line, the variable name created will be 
		“lp_1_9usd_2005” or “lp_1_9usd_2011” depending on the PPP year specified in the {cmd:ppp()} option because Stata does not allow to use “.” as part of variable names. It is used in combination with the {cmd:ppp()} option.{p_end}

{synopt:{opt inc:ppp(varlist)}}converts variables (in nominal LCU) in the {it:varlist} to PPP-based variables, expressed in 2005 and/or 2011 PPP US$ as defined in the {cmd:ppp()} option. It is useful to convert income/consumption aggregates for across years/countries comparisons and international poverty and shared prosperity indicators.
		This option creates new variables with the same name as the original, plus the suffix either _2005 or _2011. {p_end}
		
{synopt:{opt nocpi}}opens the requested dataset without including any cpi and ppp variables. {p_end}		
		
		
{dlgtab: Specific files or Modules}

{synopt:{opt filen:ame(string)}}indicates the file to be opened. {p_end}

{synopt:{opt surveyid(string)}}uses the unique Survey ID to access that specific data. For example, the Survey ID could be ALB_2012_LSMS_v01_M_v04_A_ECAPOV for harmonized data or ALB_2012_LSMS_v01_M for raw/original data.{p_end}

{synopt:{opt mod:ule(string)}}lists of modules to be merged and loaded. It is ONLY AVAILABLE for some collections such as ({it:eappov}, ({it:ecapov} and {it:eusilc}). It identifies the modules to be merged and loaded.
Enter a number list with the modules desired. If none is entered, {cmd:datalibweb} will load the default module defined by each type/collection, for example 3 (Household Consumption) for {it:ecapov} collection, and module D (Household Register) for {it:eusilc}.
The variables m{it:xyz} are created and contain the results from merging modules {it:x}, {it:y} and {it:z}. {p_end}
					The following modules are available for the {it:eusilc} collection:
						- D Household Register
						- H Household
						- R Personal Register
						- P Personal

					For {it:ecapov}, the following modules are available:
						- 2 Individual Characteristics
						- 3 Household Consumption
						- 4 Utilities Expenses
						- 6 Social Protection
						- 7 Income
						- 9 Access to basic service and assets
						
					For {it:eappov}, the following modules are available:
						- B Basic data
						- H Household 
						- I Individual
						- POV Poverty

{dlgtab:Versions}

{synopt:{opt verm:aster(#)}}specifies the master version to be used. By default, the latest version is selected if it is omitted.{p_end}

{synopt:{opt vera:lt(#)}}specifies the harmonization version to be used. By default, the latest harmonization version is selected for the latest master version if it is omitted. {p_end}

{synopt:{opt w:orking}}calls the working version. This version contains updates and editions to the latest version available but not released. {p_end}

{dlgtab:Availability of data}

{pstd}There are several ways to get the catalog of availal surveys in the system with sub-routines such as {cmd: dlw_servercatalog} and {cmd: dlw_usercatalog}. {p_end}

{synopt:{opt dlw_usercatalog, code()}} where code() is three-letter country code. This option can get you all the surveys available for this country.{p_end}

{synopt:{opt dlw_servercatalog, server()}}where server() is server alias. This option can get you all harmonized surveys available for this server.{p_end}

{dlgtab:Datalibweb local}

{synopt:{opt getfile}}User can download the all the data files for a particular survey to the structured folders in the local drive{p_end}

{synopt:{opt local}}User can ask datalibweb to access the data from that location. 
This feature is useful for those who are on mission or not on Bank network to access to the local data with the same syntax.{p_end}

{synopt:{opt localpath()}}Users can specify the path for their local collection to be used with {cmd:datalibweb}{p_end}

{synopt:{opt cpilocal()}}Users can specify the path for the CPI data to be merged together with their local collection{p_end}

{dlgtab:Repository}
{pstd}Saves a repository data file readable by {cmd:datalibweb} to call specific versions of databases used 
in specific projects. {p_end}
{pstd}This option allows the user to create, use, query, and erase do-files with specific vintage information 
for particular projects. This option is composed of three main elements: {it: instruction, name, and option}, and its syntax might be look like the options below: 
{p_end}

{p 10 14 14}{cmd:datalibweb}, {opt region(rrr)} {opt country(ccc)} {opt year(yyyy)} {opt module(abc)} {opt vermast(yyy)} {opt veralt(yyy)} {opt repository(instruction reponame, option)}{p_end}

{p 6 8 10}Except {opt repository()}, other options can take multiple values such as region(ECA LAC) or country(ALB ARM){p_end}

{p 4 8 8} In detail, {cmd: instruction} must be {it:create}, {it:use}, {it:query}, or {it:erase}. {p_end}

{p 6 8 10}{cmd:create} creates or modifies and existing repository data file{p_end}
     
{p 6 8 10}{cmd:use} forces {cmd:datalibweb} to use the version of the databases specified in {it:reponame} {p_end}
     
{p 6 8 10}{cmd:erase} creates or modifies an existing repository data file{p_end}
     
{p 6 8 10}{cmd:query} displays in the Stata results window the names ({it:reponames}) of all repository 
files in default or specifiec store{p_end}

{p 4 8 8} In detail, {cmd: reponame} might be any name (one word) the user wants that relates a particular project
 in which she is working on and the databases versions used in that project{p_end}
 
{p 4 8 8} In detail, {cmd: option} indicates {cmd: datalibweb} how to execute the {it:repository} option. If 
the user specifies the instruction {ul:create} and the {it:reponame} file already exists, she must 
specify the option either {it:replace} or {it:append}. If the user wants to delete a repository file from 
the {cmd:datalibweb} library by using the instruction {ul:erase}, she must specify the opstion {it:force}. 
The instructions {ul:use} and {ul:query} do not need any option.{p_end}

{dlgtab:CPI vintages}
{pstd}Load latest CPI vintage data files from the specified collection. {p_end}

{synopt:{opt cpivintage()}}gets the specified vintage of CPI data. If the option is not specified, the latest CPI vintage will be used.{p_end}
				
{dlgtab:Other}

{synopt:{opt base}}gets the base module or files for that Survey ID. The base option might be different for each collection. {p_end}

{synopt:{opt request()}}gets the list of files per request type for the country. There are three types: data, doc, and prog. {p_end}

{synopt:{opt latesty}}gets the latest available data for the country.{p_end}

{synopt:{opt clear}}closes current active file without saving (clear memory).{p_end}

{synopt:{opt nometa}}specifies that no metadata will be queried. By default, {cmd:datalibweb} will query the metadata from the {browse "http://microdatalib.worldbank.org/index.php/home":Microdata Library}.{p_end}

{title:Saved Results}

{cmd:datalibweb} returns results in {hi:r()} format. 
By typing {helpb return list}, the following results are reported:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(cmdline)}}the command line you entered in Stata {p_end}
{synopt:{cmd:r(surveyid)}}the unique Survey ID {p_end}
{synopt:{cmd:r(vera)}}version of adaptation/harmonization {p_end}
{synopt:{cmd:r(verm)}}version of master/raw data {p_end}
{synopt:{cmd:r(module)}}module of the file load if any {p_end}
{synopt:{cmd:r(type)}}type/collection of the file loaded {p_end}
{synopt:{cmd:r(filename)}}the name of the file loaded {p_end}
{synopt:{cmd:r(idno)}}ID link number in the Microdata Library if available {p_end}

{marker Examples}{...}
{title:Examples}{p 50 20 2}{p_end}
{pstd}

{dlgtab: basic syntax (ecapov)}

{p 8 12}{stata "datalibweb, country(alb) years(2005) type(ecapov) clear" :.datalibweb, country(alb) years(2005) type(ecapov) clear}{p_end}

{pstd} It opens the  default module (module 3 - Household Consumption) for Albania 2005 from ECAPOV collection. The default module is different for collections.{p_end}

{dlgtab: plppp}

{p 8 12}{stata "datalibweb, country(rus) years(2009) type(ecapov) ppp(2011) plppp(1.9 3.1) clear":.datalibweb, country(rus) years(2009) type(ecapov) ppp(2011) plppp(1.9 3.1) clear}{p_end}

{pstd} It opens the module 3 (Household Consumption) for Russian Federation 2009 and estimates poverty lines in current LCU equivalent to US$1.9 and US$3.1 at 2011 PPP.{p_end}

{dlgtab: basic syntax (gpwg) and incppp}

{p 8 12}{stata "datalibweb, country(col) years(2008) type(gpwg) ppp(2005) incppp(welfare) clear" :.datalibweb, country(col) years(2008) type(gpwg) ppp(2005) incppp(welfare) clear}{p_end}

{pstd} It opens the welfare file used for the estimation of Poverty Rates and Shared Prosperity for Colombia 2008. It also converts the income/consumption aggregates ({it:welfare}) into 2005 PPP US$, creating the variable {it:welfare_ppp}. {p_end}

{dlgtab: more than one survey for the same country/year/type}

{p 8 12}{stata "datalibweb, country(rou) years(2007) type(gpwg) surveyid(eusilc) clear" :.datalibweb, country(rou) years(2007) type(gpwg) surveyid(eusilc) clear}{p_end}

{pstd} If opens the welfare file of Romania in 2007 deposited in the GPWG type, using the EU-SILC harmonization instead of the ECAPOV collection. This is useful when we have more than one harmonized data in the same type, in this case GPWG.{p_end}

{dlgtab: list files available}

{p 8 12}{stata "datalibweb, country(alb) years(2012) type(ecaraw) clear" :.datalibweb, country(alb) years(2012) type(ecaraw) clear}{p_end}

{pstd} It will list all available raw or not harmonized files for Albania for 2012 in the ECATSD archive. {p_end}

{p 8 12}{stata "datalibweb, country(BLR) year(2000) type(ecapov) request(prog)"}{p_end}
{p 8 12}{stata "datalibweb, country(BLR) year(2000) type(ecapov) request(data)"}{p_end}
{p 8 12}{stata "datalibweb, country(BLR) year(2000) type(ecaraw) request(doc)"}{p_end}

{pstd} It will list all available files (both data, dofile and documentation) BLR for 2000 in the ECA catalog. {p_end}

{dlgtab: call raw data – 1 file}

{p 8 12}{stata "datalibweb, country(ALB) y(2012) t(ECARAW) surveyid(ALB_2012_LSMS_v01_M) filen(Modul_4A_labor.dta) clear":.datalibweb, country(ALB) year(2012) type(ECARAW) surveyid(ALB_2012_LSMS_v01_M) filen(Modul_4A_labor.dta) clear}{p_end}

{pstd} It opens "Modul_4A_labor.dta" file for Albania 2012 from original files. {p_end}

{p 8 12}{stata "datalibweb, country(GEO) year(2010) type(ECARAW) surveyid(GEO_2010_HIS_v01_M) filename(shinda04_coicop_2010.dta)" :.datalibweb, country(GEO) year(2010) type(ECARAW) surveyid(GEO_2010_HIS_v01_M) filename(shinda04_coicop_2010.dta)}{p_end}

{pstd} It will open "shinda04_coicop_2010.dta" file of the Georgia HIS 2010 in the ECATSD archive

{dlgtab: combine countries and years}

{p 8 12}{stata "datalibweb, country(alb arm) years(2005/2008) type(ecapov) clear" :.datalibweb, country(alb arm) years(2005/2008) type(ecapov) clear}{p_end}

{pstd} It opens the module 3 (Household Consumption) for Albania and Armenia for all available years between 2005 and 2008. {p_end}

{p 8 12}{stata "datalibweb, country(alb arm) years(2005/2008) type(gpwg) clear" :.datalibweb, country(alb arm) years(2005/2008) type(gpwg) clear}{p_end}

{pstd} It opens the welfare module for Albania and Armenia for all available years between 2005 and 2008. {p_end}

{dlgtab: get base vs regular data}

{p 8 12}{stata "datalibweb, country(col) year(2012) type(lablacraw) base"}{p_end}

{pstd} It gets base raw file for LABLC, COL 2012.{p_end}

{p 8 12}{stata "datalibweb, country(col) year(2012) type(lablacraw)"  }{p_end}

{pstd} It gets the list of LABLAC raw files. User needs to select one file as there is no default one.{p_end}

{p 8 12}{stata "datalibweb, country(col) year(2012) type(lablac)"  }{p_end}

{pstd} It gets the harmonized LABLAC file for LABLC, COL 2012. The default file is Q4 (quarter 4).{p_end}

{p 8 12}{stata "datalibweb, country(col) year(2012) type(sedlacraw) base"}{p_end}

{pstd} It gets base data for sedlac.{p_end}

{p 8 12}{stata "datalibweb, country(col) year(2012) type(sedlacraw)"  }{p_end}

{pstd} It gets raw file for sedlac.{p_end}

{p 8 12}{stata "datalibweb, country(col) year(2012) type(sedlac)"  }{p_end}

{pstd} It gets the sedlac file with the default one.{p_end}

{p 8 12}{stata "datalibweb, country(col) year(2012) type(sedlac) base"}{p_end}

{pstd} It gets base file of sedlac, which is cedlas{p_end}

{p 8 12}{stata "datalibweb, country(alb) year(2012) type(ecapov) base"}{p_end}

{pstd} It gets base of ecapov files, which is ecabase{p_end}

{dlgtab: getfile and local}

{p 8 12}{stata "datalibweb, country(alb) year(2008) type(ecaraw) getfile"}{p_end}
{p 8 12}{stata "datalibweb, country(alb) year(2008) type(ecaraw) getfile surveyid(ALB_2008_LSMS)"}{p_end}

{pstd} It gets the raw file to the local drive. In this example, you can select the ones you need if there are more than two surveys with raw data with your inputs.{p_end}
 
{p 8 12}{stata "datalibweb, country(alb) year(2008 2012) type(ecapov) getfile"}{p_end}

{pstd} It gets the harmonized data and save to the local drive.}{p_end}

{p 8 12}{stata "datalibweb, country(alb) year(2012) type(ecapov) local "}{p_end}

{pstd} You can use this local option after you download the data. It gets the files from you local drive.{p_end}

{p 8 12}{stata "datalibweb, country(alb) year(2008) type(ecaraw) local surveyid(ALB_2008_LSMS)"}{p_end}
{p 8 12}{stata "datalibweb, country(ALB) year(2008) type(ECARAW) surveyid(ALB_2008_LSMS_v03_M) filename(mobile.dta) local"}{p_end}

{pstd} You can use this local option after you download the data. It gets the files from your local drive.{p_end}

{dlgtab: get latest data}

{p 8 12}{stata "datalibweb, country(alb) type(ecapov) clear latesty" :.datalibweb, country(alb) type(ecapov) clear latesty}{p_end}

{pstd} It opens the latest available module 3 (Household Consumption) for Albania. {p_end}

{dlgtab: merge modules from one type}

{p 8 12}{stata "datalibweb, country(est) years(2009) type(eusilc) module(h r) clear" :.datalibweb, country(est) years(2009) type(eusilc) module(h r) clear}{p_end}

{pstd} It merges modules h (Household) with r (Personal Register) form the eusilc collection from EST 2009 the cross-section version. If module not defined, hence module D (Household Register) is loaded.{p_end}

{p 8 12}{stata "datalibweb, country(vnm) years(2012) type(eappov) module(h pov) clear" :.datalibweb, country(vnm) years(2012) type(eappov) module(h pov) clear}{p_end}

{pstd} It merges modules h (Household) with Pov (Poverty) form the EAPPOV collection from VNM 2012. If module not defined, hence module POV (Poverty) is loaded.{p_end}

{dlgtab: see different vintages of one survey}

{p 8 12}{stata "datalibweb, country(alb) year(2012) type(ecapov) verm(01)" :.datalibweb, country(alb) year(2012) type(ecapov) verm(01)}{p_end}

{pstd} It list all vintages ever-archived for ALB in 2012 in the collection ECAPOV.{p_end}

{p 8 12}{stata "datalibweb, country(alb) year(2012) type(ecapov) vera(wrk)" :.datalibweb, country(alb) year(2012) type(ecapov) vera(wrk)}{p_end}

{pstd} It calls the working (wrk) version of the data for ALB in 2012 in the collection ECAPOV.{p_end}

{dlgtab: Repository usage}

{p 8 12}{stata "datalibweb, type(gmd) repo(create test) " :.datalibweb, type(gmd) repo(create test) }{p_end}
{pstd}It creates the repository named "test" as the whole GMD with latest vintage per country/year/module. The actual filename is "repo_test.dta" with the prefix "repo_" added to the repository name.{p_end}

{p 8 12}{stata "datalibweb, type(gmd) repo(create test1) region(ECA)" :.datalibweb, type(gmd) repo(create test1) region(ECA)}{p_end}
{pstd}It creates the repository named "test1" as the whole GMD with latest vintage per country/year/module.{p_end}

{p 8 12}{stata "datalibweb, type(gmd) repo(create test2) vera(02) country(VNM ARG)" :.datalibweb, type(gmd) repo(create test2) vera(02) country(VNM ARG)}{p_end}
{p 8 12}{stata "datalibweb, type(gmd) repo(create test1, append) vera(03) country(VNM)" :.datalibweb, type(gmd) repo(create test1, append) vera(03) country(VNM)}{p_end}
{p 8 12}{stata "datalibweb, type(gmd) repo(create test1, append) vera(wrk) region(LAC)" :.datalibweb, type(gmd) repo(create test1, append) vera(wrk) region(LAC)}{p_end}
{p 8 12}{stata "datalibweb, type(gmd) repo(create test1, append) years(2004 2008)" :.datalibweb, type(gmd) repo(create test1, append) years(2004 2008)}{p_end}
{p 8 12}{stata "datalibweb, type(gmd) repo(create test1, replace) region(ECA) " :.datalibweb, type(gmd) repo(create test1, replace) region(ECA) }{p_end}
{p 8 12}{stata "datalibweb, type(gmd) repo(create test) " :.datalibweb, type(gmd) repo(create test) }{p_end}
{pstd} It creates and/or appends the repository named "test1" with several filtered options listed above.{p_end}

{p 8 12}{stata "datalibweb, country(alb) year(2012) type(gmd) repo(use test1)" :.datalibweb, country(alb) year(2012) type(gmd) repo(use test1)}{p_end}
{pstd} It uses the specified repository named "test1" to load the file listed in the repo data.{p_end}

{p 8 12}{stata "datalibweb, type(gmd) repo(query) " :.datalibweb, type(gmd) repo(query) }{p_end}
{pstd} It lists the available repositories available in the system for GMD collection.{p_end}

{p 8 12}{stata "datalibweb, type(gmd) repo(erase test1, force)" :.datalibweb, type(gmd) repo(erase test1, force)}{p_end}
{pstd} It erases the repo named "test1" and the file repo_test1.dta.{p_end}

{dlgtab: CPI vintages}

{p 8 12}{stata "datalibweb, country(alb) year(2012) type(gmd)" :.datalibweb, country(alb) year(2012) type(gmd)}{p_end}
{pstd} It uses the latest CPI vintages from the system.{p_end}

{p 8 12}{stata "datalibweb, country(alb) year(2012) type(gmd) cpivin(v02)" :.datalibweb, country(alb) year(2012) type(gmd) cpivin(v02)}{p_end}
{pstd} It uses the specified CPI vintage from the system.{p_end}

{dlgtab: interactive interface}

{p 8 12}{stata "datalibweb" :.datalibweb}{p_end}

{pstd} It shows a table with all regions available in {cmd: datalibweb} system, as shown below. The users will have to select the desired region and then country and collection 
to see the available surveys.{p_end}

{pstd}
	Select the region of your country of analysis:

	-----------------------------------------------
	 Region |
	 Code	|             Region Name
	--------+--------------------------------------
	  EAP 	|              East Asia and Pacific
	  ECA	|            Europe and Central Asia
	  LAC	|    Latin America and the Caribbean
	  MNA	|       Middle East and North Africa
	  SAR	|                         South Asia
	  SSA	|                 Sub-Saharan Africa
	-----------------------------------------------

{dlgtab: Graphical User interface}

{pstd} This feature can bring the Explore-view for all the data in the system. User can access it by clicking to the Datalibweb menu on the top-left corner in the Stata application. 
There are two views: by country and by server. Country views list all the raw and harmonzied data for that country across the different servers. Server views list all harmonized data 
under that collection. View can also be filtered by "Latest version" and/or "Subscribed to".

{marker disclaimer}{...}
{title:Disclaimer}

{p 4 4 2} {cmd:datalibweb} is developed to facilitate the access of the ex-post
harmonization and not-harmonized (original or raw) data produced and gathered by the regional teams in the Poverty Global Practice.
Please use with {cmd: CAUTION} and please remember to follow the
{help datalibweb##termsofuse:TERMS OF USE}!! {p_end}

{p 4 4 2}Access to the harmonized or original dataset is not given to users automatically unless the dataset is marked with Public access. 
Users need to contact regional/collection focal points and ask for the permission. Each user will have different sets of subscription to the survey. 
At the minimum, users will be able to query the meta data of the survey. {p_end}

{p 4 4 2} Users are expected to conduct their own due diligence before implementing any analysis using this harmonized datasets. Please notice
that not all survey years within specific countries are necessarily comparable due to changes in survey design and questionnaire.
For further information regarding the metadata of the each original survey used in this harmonization and to access any supporting
documentation, please visit the {browse "http://microdatalib.worldbank.org/index.php/catalog/eca": Microdata Library intranet site}.
For information on how to upload or download data from the Microdata library, click {browse "\\Ecafile\eca-special\ECA_Databank\datalib\_doc\ECADATAPORTAL_Guidelines_1page.pdf":here}.{p_end}

{p 4 4 2} Users are expected to check summary statistics and published critical indicators computed with this microdata such as: poverty, inequality, and/or 
shared prosperity numbers in the regional data lab sites in {browse "http://globalpractices.worldbank.org/poverty/Pages/en/GPGHome.aspx": Poverty Global Practice intranet site}
before conducting any analysis. {p_end}

{p 4 4 2} Users are encouraged to take note of the vintage of the harmonization that is being used in order to assure future 
replicability of results. Please notice that this application will also retrieve by default the latest version of the harmonization, 
and this might change over time. For more information please read the help file, including on how to retrieve previous 
vintages. {p_end}

{p 4 4 2} Please cite the data used as follows: {p_end}

{p 4 4 2} [Region]TSD/Collection ([year of access (YYYY)]). Survey IDs: [Survey IDs
            separated by semi-colon (countrycode, survey year, survey
            acronym)]. As of [date of access (dd/mm/yyyy)] via Datalibweb Stata Package.{p_end}

{marker termsofuse}{...}
{title:Terms of use for collections/databases}

{p 4 4 }By accessing {cmd:datalibweb} you agree to the following Conditions:{p_end}

{p 4 4 }1.	Data and other material provided by the Poverty GP Team for Statistical Development provided by this tool will be 
used solely by users who have valid labour contracts consistent with the mandate and official 
activities of the World Bank, and shall not be redistributed to other individuals, institutions or organizations without prior 
written consent from focal points of each collection/region. Access to the data may not be shared. The Global-TSD requests that all requests for access 
to and use of {browse "mailto: datalibweb@worldbank.org":datalibweb} be directed to us through the email address 
{browse "mailto: datalibweb@worldbank.org, ?subject=Datalibweb helpdesk: <<<please describe your question and/or comment here>>>" :Global-TSD helpdesk}. 
Users will need separate access request per type/collection (if any) from the collection/regional focal points. {p_end}

{p 4 4 }2.	The data will be used for World Bank related business only. They will be used solely for generating and reporting 
aggregated information. {p_end}

{p 4 4 }3.	All users agree to respect the privacy of survey respondents. No attempt will be made to identify respondents, and 
no use will be made of the identity of any person, facility or establishment discovered inadvertently. Any such discovery must 
immediately be reported to the Global-TSD unit by emailing {browse "mailto: datalibweb@worldbank.org, ?subject=Datalibweb helpdesk: <<<please describe your question and/or comment here>>>&cc=jazevedo@worldbank.org" :Global-TSD helpdesk}  {p_end}

{p 4 4 }4.	Any output, published or otherwise, including presentations employing data obtained from {cmd:datalibweb}, will cite 
the source as "Source: [Collection] ([Region]TSD/World Bank)" or "Source: [Collection] Harmonization or Raw data ([Region]TSD)". {p_end}

{p 4 12 }And include in the reference list: {p_end}

{p 8 12 }[Region]TSD ([year of access (YYYY)]). [Collection] Ex-post Harmonization or Raw data. Countries/Survey IDs: [country names/years 
(separated by semi-colon)]. As of [date of access (dd/mm/yyyy)] via Datalibweb Stata Package.{p_end}

{p 4 4 }5.	Furthermore, copies of all publications and working papers using {cmd:datalibweb} data will be sent to Global-TSD, to 
be included in a list of publications utilizing these data. Additionally, we reserve the right to request copies of 
do-files and other programs developed by {cmd:datalibweb} users with {cmd:datalibweb} data. Note that these will not be shared without 
author's permission. {p_end}

{p 4 4 }6.	Any violations or inobservance of provisions 1 to 5 of these terms and conditions will be considered 
misconduct. {p_end}

{p 4 4 }7.	The World Bank, Poverty Global Practices, and all partners and sources of funding, bear no responsibility for 
the use or misuse of the data or for interpretations or inferences based upon such uses. {p_end}

{p 4 4 }8.	Users of these data should be aware that the World Bank does not issue the data. Statistical offices 
throughout have provided this data. Therefore, the World Bank does not guarantee the accuracy of the information provided.
Moreover, results from these data may change as a consequence of possible 
updates. Note that these updates will be processed directly through {cmd:datalibweb} without any user notifications. 
We advise making reference to the date when the database was consulted, as statistics may change.{p_end}

 {marker howtocite}{...}
{title:Thanks for citing {cmd:[Collection] databases} as follows}

{p 8 12 2}"Source: [Collection] ([Region]TSD/World Bank)" or "Source: [Collection] harmonization or raw data ([Region]TSD)"{p_end}
 
{p 8 12 2}[Region]TSD ([year of access (YYYY)]). [Collection] ex-post harmonization or raw data. Countries/Survey IDs: [country names/years (separated by semi-colon)]. As of [date of access (dd/mm/yyyy)] via Datalibweb Stata Package{p_end}
 
{title:Acknowledgements}
    {p 4 4}This program was developed by the Global-TSD unit in the Global Poverty Practice of the World Bank. The program was benifited significantly from the earlier 
	developments of {cmd:datalib} in LAC TSD (by João Pedro Azevedo and Raul Andres Castañeda Aguilar), and {cmd:datalib2} in ECA TSD (by João Pedro Azevedo and Cesar Cancho).{p_end}	
	{p 4 4}We would like to thank many colleagues in various teams involving in the discussion, suggestion and testing, implemetation: ECA TSD, LAC TSD, EAP TSD, ECA IT, QuickStrike ITS, Microdata Library, all members of GPWG, regional focal points in all regions (EAP, ECA, LAC, MNA, SAR, and SSA). {p_end} 
	{p 4 4}All errors and ommissions are of exclusive responsability of the authors. Comments and suggestions are most welcome. Please send an email to: {browse "mailto: datalibweb@worldbank.org":datalibweb@worldbank.org}.{p_end} 
	
{title:Authors - {cmd:datalibweb} team}
{p 4 4}Contributing authors: {p_end} 
{p 4 4}	- Stata front-end application: Minh Cong Nguyen, Raul Andres Castañeda Aguilar, José Montes, and João Pedro Azevedo, with support from Paul Andres Corral Rodas.{p_end} 
{p 4 4}	- Plugin, IT coordinator/support: Paul Ricci, Louis Wahsieh Elliott, Antonio Ramos-Izquierdo.{p_end} 
{p 4 4}	- SharePoint web application: Soumalya De; Ravikumar Murugaiah Samy; Intekhab Alam Sheikh, Monisha Menon, Nishant Nitin Trivedi.{p_end} 
{p 4 4}	- Overall {cmd:datalibweb} project supervision: João Pedro Azevedo and Minh Cong Nguyen.{p_end} 

{title:Also see}

{p 2 4 2}Online:  help for {help apoverty}; {help ainequal};  {help wbopendata}; {help wbmetadata}; {help mpovline}; {help drdecomp}; {help skdecomp}; {help adecomp} (if installed){p_end} 
