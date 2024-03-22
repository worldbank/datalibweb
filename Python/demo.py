# -*- coding: utf-8 -*-
"""
Created on Fri May 18 16:50:48 2018

@author: WB472400
"""
#
from gini import gini
from datalibweb import datalibweb
dw = datalibweb()


files = dw.getFileCollection('ECA', 'ALB', '2008','ECAPOV', latest=False)

indfilerecords1 =  dw.getRecords(server='ECA', countries= ['ALB'], 
                                 years= ['2008'], 
                                 collection= 'ECAPOV', 
                                 modules=['2','6'],
                                 minorversion=6, majorversion=1, latest=False)


allfiles = dw.getRAWFileList(server='ECA', country= 'ARM', year= '2012')

dw.loadFile(server='ECA',
            sharedpath='\\ARM\\ARM_2012_ILCS\\ARM_2012_ILCS_v01_M\\Doc\\Technical\\World Bank.doc')




indfilerecords1 =  dw.getRecords(server='GMD', countries= ['GEO'], 
                                 years= ['2016'], 
                                 collection= 'GMD', modules =['ALL'], include_cpi=True)

indfilerecords1['welfare_ppp'] = indfilerecords1['welfare']/(indfilerecords1['cpi2011'] * 
                                   indfilerecords1['icp2011']) 

gindex = gini(indfilerecords1['welfare_ppp'].values)

print('GINI Index ', gindex)

allfiles = dw.getRAWFileList(server='GMD', country= 'GEO', year= '2016')
files = dw.getFileCollection('GMD', 'GEO', '2016','GMD')



