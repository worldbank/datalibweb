# -*- coding: utf-8 -*-
"""
Created on Sun Apr 22 15:29:19 2018

@author: WB472400
"""
import pandas as pd
import numpy as np
from settings import serversetting
from datalibutility import utility
from datalibdata import datalibdata
import os

class datalibweb:
    util = None
    data = None    
    def __init__(self):        
        self.util = utility()
        self.data = datalibdata()
    
    
    def getLatestFile(self, files, majver=None, minver=None, latest = True):
        if (len(files) > 1) or (len(files)==1 and np.isnan(files.iloc[0].FileName)==False):
            nfiles = pd.DataFrame(files, columns=files.columns)
            
            nfiles = nfiles[(nfiles['FileName'].str.count('_') > 5) &
                           (pd.to_numeric(nfiles['FileName'].str.split('_').str[5].str[1:], 
                                         errors='coerce').isnull()==False) &
                                          (nfiles.FileName.str.endswith('.dta'))]
            
            nfiles['minorver'] = pd.to_numeric(nfiles['FileName'].str.split('_').str[5].str[1:], 
                                         errors='coerce')
            
            nfiles['majorver'] = pd.to_numeric(nfiles['FileName'].str.split('_').str[3].str[1:], 
                                         errors='coerce')
            
            
            nfiles['file'] = nfiles.FileName.apply(self.util.getFileNameWithoutVersion)
            nfiles['module'] = nfiles.FileName.apply(self.util.getModuleNo)
            
            if minver==None and majver==None and latest==False:
                return nfiles
            else:
                uniquefilecat = set(nfiles.file)
                result_row = []
                for i,cat in enumerate(uniquefilecat):
                    if majver==None:
                        result_row.append(list(nfiles[(nfiles.file==cat)].sort_values(
                                by=['majorver','minorver'], ascending=[False, False]).iloc[0]))
                    else:
                        if ((nfiles.file==cat) & 
                                   (nfiles.majorver==majver) & 
                                   (nfiles.minorver==minver)).any():
                            result_row.append(nfiles[(nfiles.file==cat) & 
                                       (nfiles.majorver==majver) & 
                                       (nfiles.minorver==minver)].iloc[0])
    
                
                latestfiles = pd.DataFrame(data=result_row, columns=nfiles.columns)
                return latestfiles
        else:
            return pd.DataFrame()
        
    
    
    
    def getRecords(self, server, countries, years, collection, include_cpi = False, 
                   modules=None, majorversion=None, minorversion=None,  latest = True):
        gfiles = pd.DataFrame()
        collection_data = pd.DataFrame()
        main_data = pd.DataFrame()
        setng = serversetting(collection)
        
        if modules == None:
            modules = setng.defaultmodule
            
        for yr in years:
            for cnt in countries:
                fileset = self.getFileCollection(server, cnt, yr, collection, 
                                                 latest = True, majver=majorversion, 
                                                 minver=minorversion)
                collection_data = pd.DataFrame()
                for col in setng.collections:
                    jkeys = setng.getmodulejoinkeys(col)
                    gfiles = pd.DataFrame()
                    mod2get = set(setng.getmodules(col)) & set(modules)
                    for  index, modfile in fileset[fileset.module.isin(mod2get)].iterrows():
                        if 'BASE_' not in modfile.FileName:
                            localfileRecords = self.getConsolidatedRecords(server, modfile.FileName, 
                                                                       modfile.FileSharePath)
                            
                            if not localfileRecords.empty:
                                for keyname in jkeys:
                                    localfileRecords[keyname] = localfileRecords[keyname].astype('int32')
                            
                            
                            if gfiles.empty and not localfileRecords.empty:
                                gfiles = localfileRecords
                            else:
                                if not gfiles.empty and not localfileRecords.empty:
                                    gfiles = pd.merge(gfiles, localfileRecords, on = jkeys, how='left')
                                    #gfiles = pd.concat([gfiles, localfileRecords], ignore_index=True)
    
                    coljkeys = setng.getkeystojoincollection(col)
                    
                    if collection_data.empty and not gfiles.empty:
                        collection_data = gfiles
                    else:
                        if not gfiles.empty and not collection_data.empty:
                            collection_data = pd.merge(collection_data, gfiles, on = coljkeys)
            
            if main_data.empty and not collection_data.empty:
                main_data = collection_data
            else:
                if not gfiles.empty and not collection_data.empty:
                    main_data = pd.concat([main_data, collection_data], ignore_index=True)
            
            if include_cpi==True:
                #cpi_dta = self.data.datacpifile(setng.cpifieldstr)
                cpi_dta = self.getCPIData(server)
                if not main_data.empty:
                    if not cpi_dta.empty:
                        jkeys = setng.cpijoinkeys
                        if len(jkeys) >=1 :
                            main_data = pd.merge(main_data, cpi_dta, on = jkeys, how='left')                 
                else:
                    main_data = cpi_dta
                    
        return main_data
    
    def getConsolidatedRecords(self, server, filename, filepath):
        country, year, collection = self.util.extractserverdetailsfromfile(filename)
        dt=self.getRecordsFromSingleFile(server, country, year, collection, 
                                            filepath)
        return dt
    
    
    def getFileCollection(self, server, country, year, collection, 
                          modules=None,  latest = True,
                          majver=None, minver=None):
        dta_file= self.data.dataFileCollection(server, country, year, collection, 
                          modules, latest, majver, minver)
        return self.getLatestFile(dta_file, majver, minver, latest=latest)
    
    
    def getRecordsFromSingleFile(self, server, country, year, collection, sharedpath):
        return self.data.dataRecordsFromSingleFile(server, country, year, collection, sharedpath)

        
    def getRAWFileList(self, server, country, year, fileExtFilter = None):
        setng = serversetting(server)
        return self.data.dataRAWFileList(server, country, year, setng.tokenlength, fileExtFilter)
    
    
    def loadFile(self, server, sharedpath, is_dta = False, download_path=None):
        filename = self.data.dataFile(server, sharedpath, download_path)
        if is_dta==False:
            if filename != None:
                if download_path == None:
                    os.startfile(os.path.dirname(os.path.abspath(__file__)) + '/output/' + filename)
                else:
                    os.startfile(download_path + filename)
    
            else:
                print('Could not find file')

        return filename
    

    
    def getCPIData(self, collection):
        setng = serversetting(collection)
        filename= self.data.datacpifile(setng.cpifieldstr)
        if(filename.endswith('.csv')):
            file_list = pd.read_csv(os.path.dirname(os.path.abspath(__file__)) + '/output/cpi.dta')
            latest_cpi =  file_list.sort_values('FileLastModifedDate', ascending=False)
            dta_filename = self.loadFile(collection, latest_cpi.iloc[1].FileSharePath, is_dta=True)
            return pd.read_stata(os.path.dirname(os.path.abspath(__file__)) + '/output/' + dta_filename)
        elif(filename.endswith('.dta')):
            return pd.read_stata(os.path.dirname(os.path.abspath(__file__)) + '/output/cpi.dta')
        else:
            return pd.DataFrame()

        
