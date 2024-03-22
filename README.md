# **datalibweb** - frontend application with microdata API endpoints for World Bank users

## Description

**datalibweb** is a data system specifically designed to enable users to access the most up to date versions of non-harmonized (original/raw) and harmonized datasets of different collections across Global Practices in the World Bank Group. It can easily explore and load the microdata within statistical software such as Stata for any analysis. Users can browse the data catalog, check access immediately for public data, and request access to private data through the Datalibweb website. 

**datalibweb** provides World Bank users to access the most up-to-date data and documentation available in different regions catalogs at the World Bank. It allows users to access the latest and historical versions of non-harmonized (original/raw) data as well as different harmonized collections across Global Practices. 

**datalibweb** has two main components: (1) the website for data exploration and data requests , and (2) a set of API endpoints to securely access to granted microdata. Currently, the API endpoints are integrated with Stata through the `datalibweb` Stata package. 

## Installation of datalibweb package in Stata

**datalibweb** is currently only availible on World Bank computers, and there is no installation needed as **datalibweb** is already installed on all World Bank computers that have Stata installed. Run `datalibweb` or `dlw` in your Stata session to test if it is really installed. If it is not installed, users can download the Datalibweb Stata package in the github and copy both folders (personal and plus) to c:/ado. In case of using remote or virtual servers, please check the path of ado folder by using `sysdir` command in Stata.

## Disclaimer

**datalibweb** is developed to facilitate the access of the ex-post harmonization and not-harmonized (original or raw) data produced and gathered by the regional and sectoral teams in the different Global Practice in the World Bank.

Please use with **CAUTION** and please remember to follow the **datalibweb**'s [TERMS OF USE](#terms_use)!!

Access to the harmonized or original dataset is not given to users automatically unless the dataset is marked with Public access. 
Users need to contact regional/collection focal points and ask for the permission. Each user will have different sets of subscription to the survey. 
At the minimum, users will be able to query the meta data of the survey. 

Users are expected to conduct their own due diligence before implementing any analysis using this harmonized datasets. Please notice
that not all survey years within specific countries are necessarily comparable due to changes in survey design and questionnaire.
For further information regarding the metadata of the each original survey used in this harmonization and to access any supporting
documentation, please visit the [Microdata Library intranet site](http://microdatalib.worldbank.org/index.php/catalog/eca).
For information on how to upload or download data from the Microdata library, click [here](\\Ecafile\eca-special\ECA_Databank\datalib\_doc\ECADATAPORTAL_Guidelines_1page.pdf).

Users are expected to check summary statistics and published critical indicators computed with this microdata such as: poverty, inequality, and/or 
shared prosperity numbers in the regional data lab sites in [Poverty Global Practice intranet site](http://globalpractices.worldbank.org/poverty/Pages/en/GPGHome.aspx)
before conducting any analysis. 

Users are encouraged to take note of the vintage of the harmonization that is being used in order to assure future 
replicability of results. Please notice that this application will also retrieve by default the latest version of the harmonization, 
and this might change over time. For more information please read the help file, including on how to retrieve previous 
vintages. 

## Terms of use for collections/databases <a name="terms_use"></a>

By accessing **datalibweb** you agree to the following Conditions:

1.	Data and other material provided by the Poverty GP Team for Statistical Development provided by this tool will be
used solely by users who have valid labour contracts consistent with the mandate and official
activities of the World Bank, and shall not be redistributed to other individuals, institutions or organizations without prior
written consent from focal points of each collection/region. Access to the data may not be shared. The Global-TSD requests that all requests for access
to and use of **datalibweb** are directed to us through the email address
[datalibweb@worldbank.org](mailto:datalibweb@worldbank.org?subject=datalibweb%20helpdesk:%20please%20describe%20your%20question%20and%2For%20comment%20here) with the subject `datalibweb helpdesk: <<<please describe your question and/or comment here>>>`.
Users will need separate access request per type/collection (if any) from the collection/regional focal points.

2.	The data will be used for World Bank related business only. They will be used solely for generating and reporting 
aggregated information. 

3.	All users agree to respect the privacy of survey respondents. No attempt will be made to identify respondents, and
no use will be made of the identity of any person, facility or establishment discovered inadvertently. Any such discovery must
immediately be reported to the Global-TSD unit by emailing [datalibweb@worldbank.org](mailto:datalibweb@worldbank.org?subject=datalibweb%20helpdesk:%20reporting%20resondent%20privacy%20breach) with a description of the case. Please include `datalibweb helpdesk: reporting resondent privacy breach` in the subject line.

4.	Any output, published or otherwise, including presentations employing data obtained from **datalibweb**, will cite 
the source as "Source: [Collection] ([Region]TSD/World Bank)" or "Source: [Collection] Harmonization or Raw data ([Region]TSD)". 

And include in the reference list: 

[Region]TSD ([year of access (YYYY)]). [Collection] Ex-post Harmonization or Raw data. Countries/Survey IDs: [country names/years 
(separated by semi-colon)]. As of [date of access (dd/mm/yyyy)] via **datalibweb** Stata Package.

5.	Furthermore, copies of all publications and working papers using **datalibweb** data will be sent to Global-TSD, to 
be included in a list of publications utilizing these data. Additionally, we reserve the right to request copies of 
do-files and other programs developed by **datalibweb** users with **datalibweb** data. Note that these will not be shared without 
author's permission. 

6.	Any violations or inobservance of provisions 1 to 5 of these terms and conditions will be considered 
misconduct. 

7.	The World Bank, Poverty Global Practices, and all partners and sources of funding, bear no responsibility for 
the use or misuse of the data or for interpretations or inferences based upon such uses. 

8.	Users of these data should be aware that the World Bank does not issue the data. Statistical offices 
throughout have provided this data. Therefore, the World Bank does not guarantee the accuracy of the information provided.
Moreover, results from these data may change as a consequence of possible 
updates. Note that these updates will be processed directly through **datalibweb** without any user notifications. 
We advise making reference to the date when the database was consulted, as statistics may change.

## Acknowledgements

This **datalibweb 2.0** program was developed by the Data for Goals (D4G) team in the Global Poverty Practice and Enterprise ITS of the World Bank Group. The program was benifited significantly from the earlier developments of **datalibweb 1.0** (2014-2024), **datalib** in LAC TSD (by João Pedro Azevedo and Raul Andres Castaneda Aguilar), and **datalib2** in ECA TSD (by João Pedro Azevedo and Cesar Cancho).	

We would like to thank many colleagues in various teams involving in the discussion, suggestion and testing, implemetation: ECA TSD, LAC TSD, EAP TSD, ECA IT, QuickStrike ITS, Enterprise IT, Microdata Library, all members of GPWG and Data for Goals (D4G), regional focal points in all regions (EAP, ECA, LAC, MNA, SAR, and SSA).  

All errors and ommissions are of exclusive responsability of the authors. Comments and suggestions are most welcome. Please send an email to: <datalibweb@worldbank.org> .
	
## Authors - **datalibweb** team

**Datalibweb 2.0** is based on **Datalibweb 1.0** (2014-2024). The **Datalibweb 2.0** was developed by the Bank teams: Poverty GP - Minh Cong Nguyen, Zurab Sajaia, Laura Liliana Moreno Herrera, Haoyu Wu, Cameron Nadim Haddad, Danielle Victoria Aron, and ITS - Kunal Patel, Ramgopal Erabelly, Sebastian Ariel Dolber, and Rajesh Kumar Danda. **Datalibweb 1.0** was developed by the Bank teams: Poverty GP - Minh Cong Nguyen, João Pedro Azevedo, Raul Andres Castañeda Aguilar, José Montes, Paul Andres Corral Rodas; ITS - Paul Ricci, Louis Wahsieh Elliott, Antonio Ramos-Izquierdo, Intekhab Alam Sheikh, Monisha Menon, Nishant Nitin Trivedi.
