# -*- coding: utf-8 -*-
"""
Created on Sun Apr 22 15:29:19 2018

@author: WB472400
"""
import pandas as pd
import requests
import numpy as np
import xml.etree.ElementTree as et
from settings import serversetting

common_headers = {'user-agent': 'Mozilla/5.0', 'Accept' : '*/*'}

def findnth(haystack, needle, n):
	parts= haystack.split(needle, n+1)
	if len(parts)<=n+1:
		return -1
	return len(haystack)-len(parts[-1])-len(needle)

def getFileNameWithoutVersion(orgfilename):
	startpos = findnth(orgfilename, '_', 2) + 1
	endpos = findnth(orgfilename, '_', 3) + 1
	minfile = orgfilename[:startpos] + orgfilename[endpos:]
	startpos = findnth(minfile, '_', 3) + 1
	endpos = findnth(minfile, '_', 4) + 1
	minfile = minfile[:startpos] + minfile[endpos:]
	return minfile

def getModuleNo(orgfilename):
	startpos = findnth(orgfilename, '_',7) + 1
	endpos = findnth(orgfilename, '.',1)- 3
	return orgfilename[startpos:endpos] 



def getLatestFile(files):
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
        
        
		nfiles['file'] = nfiles.FileName.apply(getFileNameWithoutVersion)
		nfiles['module'] = nfiles.FileName.apply(getModuleNo)
        
		uniquefilecat = set(nfiles.file)
		result_row = []
        
		for i,cat in enumerate(uniquefilecat):
			result_row.append(list(nfiles[(nfiles.file==cat)].sort_values(by=['majorver','minorver'], ascending=[False, False]).iloc[0]))
        
		latestfiles = pd.DataFrame(data=result_row, columns=nfiles.columns)
		return latestfiles
	else:
		return pd.DataFrame()


def getFileCollection(server, country, year, collection, authHeader, modules=None,  latest = True):
	SITE = 'http://qsapps.worldbank.org/ECAService/ECAFileDownloadService.svc/GetFileInfo2'

	fileinfo_fields = {'Server' : server,
					'Country' : country,
					'Year' :  year,
					'Collection' : collection}
    
	resp = requests.post(SITE, data=fileinfo_fields, 
								auth=authHeader, 
								headers=common_headers, stream=True )
    
	with open('C:/Users/wb472400/Documents/Projects/STATA/output/result.csv', 'wb') as fd:
		for chunk in resp.iter_content(chunk_size=128):
			fd.write(chunk)
            
	dta_file = pd.read_csv('C:/Users/wb472400/Documents/Projects/STATA/output/result.csv')
    
	if latest==True and not dta_file.empty:
		return getLatestFile(dta_file)
	else:
		return dta_file


def getRecords(server, countries, years, collection, authHeader,  modules=None,  latest = True):
	gfiles = pd.DataFrame()
	collection_data = pd.DataFrame()
	main_data = pd.DataFrame()
	setng = serversetting(collection)
    
	if modules == None:
		modules = setng.defaultmodule
        
	for yr in years:
		for cnt in countries:
			fileset = getFileCollection(server, cnt, yr, collection, authHeader, latest = True)
			collection_data = pd.DataFrame()
			for col in setng.collections:
				jkeys = setng.getmodulejoinkeys(col)
				gfiles = pd.DataFrame()
				mod2get = set(setng.getmodules(col)) & set(modules)
				for  index, modfile in fileset[fileset.module.isin(mod2get)].iterrows():
					if 'BASE_' not in modfile.FileName:
						localfileRecords = getConsolidatedRecords1(server, modfile.FileName, 
																	modfile.FileSharePath , authHeader)
                        
						#if not localfileRecords.empty:
						#	print("Converting keys to integer")
						#	for keyname in jkeys:
						#		localfileRecords[keyname] = localfileRecords[keyname].astype('int32')
                        
						print('Converting pid to category')
						localfileRecords['pid'] = localfileRecords['pid'].astype('category')


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
        
                
	return main_data

def getConsolidatedRecords1(server, filename, filepath, authHeader):
	country, year, collection = extractserverdetailsfromfile(filename)
	dt=getRecordsFromSingleFile(server, country, year, collection, 
										filepath, authHeader)
	return dt


def getConsolidatedRecords(server, latestfiles, mods, authHeader):
	result_mdl_df = pd.DataFrame()
	for index, row in latestfiles[latestfiles.module.isin(mods)].iterrows():
		if 'BASE_' not in row.FileName:
			country, year, collection = extractserverdetailsfromfile(row.FileName)
			dt=getRecordsFromSingleFile(server, country, year, collection, 
												row.FileSharePath, authHeader)
			if result_mdl_df.empty:
				result_mdl_df = dt
			else:
				if not dt.empty:
					result_mdl_df = pd.merge(result_mdl_df, dt, on=['hhid','pid'])
	return result_mdl_df


def extractserverdetailsfromfile(fname):
	splitinfo = fname.split('_')
	country = splitinfo[0]
	year = splitinfo[1]
	collection = splitinfo[7]
	return country, year, collection

def getRecordsByCollection(server, country, year, collection, authHeader, modules = None, fileNames=None):
	fnames = None
	if fileNames==None:
		fnames = getFileCollection(server, country, year, collection, authHeader, latest = True)
    
	setng = serversetting(collection)

	if modules == None:
		modules = setng.defaultmodule
    
	setng.hhmlist.isin(modules)
    
	result_df = pd.DataFrame()

	for index, row in fileNames[fnames.module.isin(modules)].iterrows():
		dt=getRecordsFromSingleFile(server, country, year, collection,
											row.FileSharePath, authHeader)
		if result_df.empty:
			result_df = dt
		else:
			if not dt.empty:
				result_df = pd.merge(result_df, dt, on='hhid')

def loadServerConfig(server, authHeader):
	fileName = server + '.xml'
	server_config=''
	SITE = 'http://spqsapps.worldbank.org/qs/ECA/DataLib/' + fileName
	resp = requests.get(SITE, auth=authHeader, 
								headers=common_headers)
    
	server_config = et.fromstring(resp.text)

	return server_config

def getRecordsFromSingleFile(server, country, year, collection, sharedpath, authHeader):
	SITE = 'http://qsapps.worldbank.org/ECAService/ECAFileDownloadService.svc/GetFileInfo2'
    
	fileinfo_fields = {'Server' : server,
					'Country' : country,
					'Year' :  year,
					'Para1' : sharedpath,
					'Collection' : collection}

	resp = requests.post(SITE, data=fileinfo_fields, 
								auth=authHeader, 
								headers=common_headers, stream=True )
    
	dta_file = pd.DataFrame()
	print(resp.status_code)
	if(resp.ok):    
		with open('C:/Users/wb472400/Documents/Projects/STATA/output/result.dta', 'wb') as fd:
			for chunk in resp.iter_content(chunk_size=128):
				fd.write(chunk)
                
		dta_file = pd.read_stata('C:/Users/wb472400/Documents/Projects/STATA/output/result.dta')

	return dta_file
