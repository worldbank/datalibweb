#setwd("C:/Users/wb449356/Desktop/Poverty/RCode/")

library(httr)
library(foreign)
library(readstata13)
library(config)
#library(XML)
library(reldist)
library(ineq)


config1 <- config::get(file = "conf/config.yml")

#Identify the settings file name
#xmlfile <- paste0(config1$Collection, ".xml")

#Loading the settings xml file to a dataframe
#xmlsettings_df <- getXmlSettingsDF <- function(xmlfile){
#                      xmldoc <- xmlParse(xmlfile)
#                      xmlsettings_df <- xmlToDataFrame(xmldoc)
#                      return (xmlsettings_df)
#                    }

#getting working directory
wd <- config1$WD

#getting auth dll information
dll <- paste0(config1$WD, "dlib2r.dll")

dyn.load(dll)

callDatalib <- function(x, y, z) {
  .C("dlib_call", as.character(x), as.character(y), as.character(z))
}

#callDatalib("0", "C:\\temp\\albR1.dta", "Server=ECA&Country=ALB&Year=2008&Collection=ECAPOV&FileName=ALB_2008_LSMS_v01_M_v01_A_ECAPOV_3.dta")

dpath <- paste0(config1$Download_path,"results.csv")
str_filecollection <- paste0("Server=",config1$Server,"&Country=",config1$Country,"&Year=", config1$Year,"&Collection=",config1$Collection,"&FileName=","")


#getting the file collection
callDatalib("0", dpath, str_filecollection )

#Reading the file collection into a dataframe
fc_results_file <- read.csv(dpath, header = TRUE)

#reading the .dta files into a temp data frame
temp_fcfile <- fc_results_file[grep(".dta", fc_results_file$FileName), ]

#decending order of the file names and storing the first row records
temp_fcfile1 <- head(temp_fcfile[order(temp_fcfile$FileName, decreasing=TRUE), ], 1)

#getting the file name
fc_filename <- temp_fcfile1$FileName

#Display the file name
fc_filename

#Passing the file name directly
#fc_filename <- "GEO_2016_HIS_V01_M_V02_A_GMD_ALL.dta"

#Passing the file name through config file.
#config1 <- config::get(file = "conf/config.yml")
#fc_filename <- config1$FileName

#define the file name and path for file
data_dpath <- paste0(config1$Download_path,"datafiles.dta")

#define the param string
str_datafile <- paste0("Server=",config1$Server,"&Country=",config1$Country,"&Year=", config1$Year,"&Collection=",config1$Collection,"&FileName=",fc_filename)

# getting the file from the datalibweb
callDatalib("0", data_dpath, str_datafile )

#storing the data into a data frame.
datafiles <- read.dta13(data_dpath)

#getting the CPI dataFile

#define the cpi file name and path.
cpi_dpath <- paste0(config1$Download_path,"cpi.dta")

#get the CPI file param values from config file
str_cpifile <- config1$cpidata

#get the cpi data from the datalibdata
callDatalib("0", cpi_dpath, str_cpifile )
#callDatalib("0", cpi_dpath, "Server=GMD&Country=SUPPORT&Year=2005&filename=Final CPI PPP to be used.dta&folder=Data\\Stata&para1=Support_2005_CPI_v02_M")

cpidatafile <- read.dta13(cpi_dpath)

#merging the data file with cpi data

mergedata <- base::merge(x = datafiles, y = cpidatafile, by.x = c("countrycode","year"), by.y = c("code","year"), all.x = TRUE)

#calc the welfare 2001 ppp value and adding the column to data frame
mergedata$welfare_2011ppp <-  mergedata$welfare/(mergedata$icp2011*mergedata$cpi2011)

#Gini Coeff using reldist package
ginicoeff_reldist <- Gini(mergedata$welfare_2011ppp, mergedata$weight)

ginicoeff_reldist

#Gini Coeff using ineq packages

ginicoeff_ineq <- ineq(mergedata$welfare_2011ppp)

ginicoeff_ineq

dyn.unload(dll)
