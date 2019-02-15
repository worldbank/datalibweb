# datalibweb - Datalibweb is an API data platform specifically designed to enable users to access the most up-to-date data and documentation available in different regional catalogs at the World Bank.


## Description 

Datalibweb is an API data platform specifically designed to enable users to access the most up-to-date data and documentation available in different regiona catalogs at the World Bank. It allows users to access the latest and historical versions of non-harmonized (original/raw) data as well as different harmonized collections across across Global Practices. It is integrated with Stata through the Datalibweb Stata package.

## Disclaimer

 {cmd:datalibweb} is developed to facilitate the access of the ex-post
harmonization and not-harmonized (original or raw) data produced and gathered by the regional teams in the Poverty Global Practice.
Please use with {cmd: CAUTION} and please remember to follow the
{help datalibweb##termsofuse:TERMS OF USE}!! 

Access to the harmonized or original dataset is not given to users automatically unless the dataset is marked with Public access. 
Users need to contact regional/collection focal points and ask for the permission. Each user will have different sets of subscription to the survey. 
At the minimum, users will be able to query the meta data of the survey. 

 Users are expected to conduct their own due diligence before implementing any analysis using this harmonized datasets. Please notice
that not all survey years within specific countries are necessarily comparable due to changes in survey design and questionnaire.
For further information regarding the metadata of the each original survey used in this harmonization and to access any supporting
documentation, please visit the {browse "http://microdatalib.worldbank.org/index.php/catalog/eca": Microdata Library intranet site}.
For information on how to upload or download data from the Microdata library, click {browse "\\Ecafile\eca-special\ECA_Databank\datalib\_doc\ECADATAPORTAL_Guidelines_1page.pdf":here}.

 Users are expected to check summary statistics and published critical indicators computed with this microdata such as: poverty, inequality, and/or 
shared prosperity numbers in the regional data lab sites in {browse "http://globalpractices.worldbank.org/poverty/Pages/en/GPGHome.aspx": Poverty Global Practice intranet site}
before conducting any analysis. 

 Users are encouraged to take note of the vintage of the harmonization that is being used in order to assure future 
replicability of results. Please notice that this application will also retrieve by default the latest version of the harmonization, 
and this might change over time. For more information please read the help file, including on how to retrieve previous 
vintages. 

## Terms of use for collections/databases

By accessing {cmd:datalibweb} you agree to the following Conditions:

1.	Data and other material provided by the Poverty GP Team for Statistical Development provided by this tool will be 
used solely by users who have valid labour contracts consistent with the mandate and official 
activities of the World Bank, and shall not be redistributed to other individuals, institutions or organizations without prior 
written consent from focal points of each collection/region. Access to the data may not be shared. The Global-TSD requests that all requests for access 
to and use of {browse "mailto: datalibweb@worldbank.org":datalibweb} be directed to us through the email address 
{browse "mailto: datalibweb@worldbank.org, ?subject=Datalibweb helpdesk: <<<please describe your question and/or comment here>>>" :Global-TSD helpdesk}. 
Users will need separate access request per type/collection (if any) from the collection/regional focal points. 

2.	The data will be used for World Bank related business only. They will be used solely for generating and reporting 
aggregated information. 

3.	All users agree to respect the privacy of survey respondents. No attempt will be made to identify respondents, and 
no use will be made of the identity of any person, facility or establishment discovered inadvertently. Any such discovery must 
immediately be reported to the Global-TSD unit by emailing {browse "mailto: datalibweb@worldbank.org, ?subject=Datalibweb helpdesk: <<<please describe your question and/or comment here>>>&cc=jazevedo@worldbank.org" :Global-TSD helpdesk}  

4.	Any output, published or otherwise, including presentations employing data obtained from {cmd:datalibweb}, will cite 
the source as "Source: [Collection] ([Region]TSD/World Bank)" or "Source: [Collection] Harmonization or Raw data ([Region]TSD)". 

And include in the reference list: 

[Region]TSD ([year of access (YYYY)]). [Collection] Ex-post Harmonization or Raw data. Countries/Survey IDs: [country names/years 
(separated by semi-colon)]. As of [date of access (dd/mm/yyyy)] via Datalibweb Stata Package.

5.	Furthermore, copies of all publications and working papers using {cmd:datalibweb} data will be sent to Global-TSD, to 
be included in a list of publications utilizing these data. Additionally, we reserve the right to request copies of 
do-files and other programs developed by {cmd:datalibweb} users with {cmd:datalibweb} data. Note that these will not be shared without 
author's permission. 

6.	Any violations or inobservance of provisions 1 to 5 of these terms and conditions will be considered 
misconduct. 

7.	The World Bank, Poverty Global Practices, and all partners and sources of funding, bear no responsibility for 
the use or misuse of the data or for interpretations or inferences based upon such uses. 

8.	Users of these data should be aware that the World Bank does not issue the data. Statistical offices 
throughout have provided this data. Therefore, the World Bank does not guarantee the accuracy of the information provided.
Moreover, results from these data may change as a consequence of possible 
updates. Note that these updates will be processed directly through {cmd:datalibweb} without any user notifications. 
We advise making reference to the date when the database was consulted, as statistics may change.

## Acknowledgements

This program was developed by the Global-TSD unit in the Global Poverty Practice of the World Bank. The program was benifited significantly from the earlier developments of {cmd:datalib} in LAC TSD (by João Pedro Azevedo and Raul Andres Castaneda Aguilar), and {cmd:datalib2} in ECA TSD (by João Pedro Azevedo and Cesar Cancho).	

We would like to thank many colleagues in various teams involving in the discussion, suggestion and testing, implemetation: ECA TSD, LAC TSD, EAP TSD, ECA IT, QuickStrike ITS, Microdata Library, all members of GPWG, regional focal points in all regions (EAP, ECA, LAC, MNA, SAR, and SSA).  

All errors and ommissions are of exclusive responsability of the authors. Comments and suggestions are most welcome. Please send an email to: {browse "mailto: datalibweb@worldbank.org":datalibweb@worldbank.org}. 
	
## Authors - datalibweb team
Contributing authors:  
- Stata front-end application: Minh Cong Nguyen, Raul Andres Castaneda Aguilar, Jose Montes, and João Pedro Azevedo, with support from Paul Andres Corral Rodas. 
- Plugin, IT coordinator/support: Paul Ricci, Louis Wahsieh Elliott, Antonio Ramos-Izquierdo. 
- SharePoint web application: Soumalya De; Ravikumar Murugaiah Samy; Intekhab Alam Sheikh, Monisha Menon, Nishant Nitin Trivedi. 
- Overall {cmd:datalibweb} project supervision: João Pedro Azevedo and Minh Cong Nguyen. 
