# -*- coding: utf-8 -*-
"""
Created on Tue Jul 10 17:01:49 2018

@author: WB472400
"""

import clr
import os
from DatalibWeb.ServiceInterface import SharePoint

class winservice:
    def queryservice(filename, fields, SITE, download_path=None):
        #'Server=ECA&Country=ALB&Year=2008&Collection=ECAPOV'
        print('Field Query String : ' + fields)
        clr.AddReference(os.path.dirname(os.path.abspath(__file__)) + "/DatalibWeb.ServiceInterface.dll")
        result = SharePoint.QueryService(fields, filename, SITE, download_path)
        return result


