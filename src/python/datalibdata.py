# -*- coding: utf-8 -*-
"""
Created on Sun May 20 18:54:59 2018

@author: WB472400
"""
import requests
import pandas as pd
import xml.etree.ElementTree as et
from datalibutility import utility
from requests_ntlm import HttpNtlmAuth
import time
from winservice import winservice
import os

class datalibdata:
    USERNAME = ""
    password = ""
    authHeader = HttpNtlmAuth(USERNAME, password)
    common_headers = {'user-agent': 'Mozilla/5.0', 'Accept' : '*/*'} 
    SITE = 'http://qsapps.worldbank.org/ECAService/ECAFileDownloadService.svc/GetFileInfo2'
    
    util = None
    def __init__(self):        
        self.util = utility()

    def servicepost(self, filename, fields, SITE, download_path=None, Verbose=False):
        if Verbose==True:
            start_time = time.time()
            
        resp = requests.post(SITE, data=fields, 
                                 auth=self.authHeader, 
                                 headers=self.common_headers, stream=True )

        if Verbose==True:
            print(fields)
            print(resp.status_code)
        
        if download_path==None:
            download_path = os.path.dirname(os.path.abspath(__file__)) + '/output/'
        
        if not os.path.exists(download_path):
            os.makedirs(download_path)
        
        if(resp.ok):    
            with open(download_path + filename, 'wb') as fd:
                for chunk in resp.iter_content(chunk_size=128):
                    fd.write(chunk)
        if Verbose==True:        
            print("Time to download %s seconds ---" % (time.time() - start_time))
        
        return True
    
    def winservicepost(self, filename, fields, SITE, download_path=None, Verbose=False):
        if Verbose==True:
            start_time = time.time()
        
        if download_path==None:
            download_path = os.path.dirname(os.path.abspath(__file__)) + '/output/'

        if not os.path.exists(download_path):
            os.makedirs(download_path)

        qstring = ''
        for key, value in fields.items():
            print(key + '=' + value)
            qstring = qstring + '&' + key + '=' + value
        
        if qstring:
            qstring = qstring[1:]
        
        result = winservice.queryservice(filename, qstring, SITE, download_path)
        print(result)
        
        if Verbose==True:        
            print("Time to download %s seconds ---" % (time.time() - start_time))
        
        return result
    
    
    def dataFileCollection(self, server, country, year, collection, 
                          authHeader, modules=None,  latest = True,
                          majver=None, minver=None):    
        fileinfo_fields = {'Server' : server,
                        'Country' : country,
                        'Year' :  year,
                        'Collection' : collection}
        
        if self.util.getresultstatus(self.winservicepost('result.csv', fileinfo_fields, self.SITE)):
            return pd.read_csv(os.path.dirname(os.path.abspath(__file__)) + '/output/result.csv')
        else:
            return pd.DataFrame()

    def dataRecordsFromSingleFile(self, server, country, year, collection, sharedpath):        
        fileinfo_fields = {'Server' : server,
                        'Country' : country,
                        'Year' :  year,
                        'Para1' : sharedpath,
                        'Collection' : collection}
    
        if self.util.getresultstatus(self.winservicepost('result.dta', fileinfo_fields, self.SITE)):        
            dta_file = pd.read_stata(os.path.dirname(os.path.abspath(__file__)) +'/output/result.dta')    
            return dta_file
        else:
            return pd.DataFrame()


    def dataRAWFileList(self, server, country, year, tokenlength,  fileExtFilter = None):
        #Server=ECA&Country=ALB&Year=2012&token=5
        fileinfo_fields = {'Server' : server,
                        'Country' : country,
                        'Year' :  year,
                        'token' : tokenlength}
        if self.util.getresultstatus(self.winservicepost('result.csv', fileinfo_fields, self.SITE)):                    
            dta_file = pd.read_csv(os.path.dirname(os.path.abspath(__file__)) + '/output/result.csv')    
            return dta_file
        else:
            return pd.DataFrame()
        

    def dataFile(self, server, sharedpath, download_path=None):
        filename = sharedpath[sharedpath.rfind('\\') + 1:]

        thirdstring = sharedpath.split('\\')[3]
        country = thirdstring.split('_')[0]
        year = thirdstring.split('_')[1]
        fileinfo_fields = {'Server' : server,
                        'Country' : country,
                        'Year' :  year,
                        'token' : '5' ,
                        'filename':filename,
                        'para1' : thirdstring}
    
        if self.util.getresultstatus(self.winservicepost(filename, fileinfo_fields, self.SITE, download_path)):
            return filename
        else:
            return None
    
    
    def dataServerConfig(self, server):
        fileName = server + '.xml'
        server_config=''
        SITE = 'http://spqsapps.worldbank.org/qs/ECA/DataLib/' + fileName
        resp = requests.get(SITE, auth=self.authHeader, 
                                 headers=self.common_headers)

        server_config = et.fromstring(resp.text)
    
        return server_config
    

    def datacpifile(self, fileinfo_fields):
        resultstr = self.winservicepost('cpi.dta', fileinfo_fields, self.SITE)
        if self.util.getresultstatus(resultstr):
            filename = self.util.getkeyvalue(resultstr, 'filename');
            print(filename)
            return filename