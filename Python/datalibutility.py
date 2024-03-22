# -*- coding: utf-8 -*-
"""
Created on Fri May 18 17:03:22 2018

@author: WB472400
"""
import json

class utility:
    def findnth(self, haystack, needle, n):
        parts= haystack.split(needle, n+1)
        if len(parts)<=n+1:
            return -1
        return len(haystack)-len(parts[-1])-len(needle)
    
    def getFileNameWithoutVersion(self, orgfilename):
        startpos = self.findnth(orgfilename, '_', 2) + 1
        endpos = self.findnth(orgfilename, '_', 3) + 1
        minfile = orgfilename[:startpos] + orgfilename[endpos:]
        startpos = self.findnth(minfile, '_', 3) + 1
        endpos = self.findnth(minfile, '_', 4) + 1
        minfile = minfile[:startpos] + minfile[endpos:]
        return minfile
    
    def getModuleNo(self, orgfilename):
        startpos = self.findnth(orgfilename, '_',7) + 1
        endpos = self.findnth(orgfilename, '.',1)- 3
        return orgfilename[startpos:endpos] 
    
        
    def extractserverdetailsfromfile(self, fname):
        splitinfo = fname.split('_')
        country = splitinfo[0]
        year = splitinfo[1]
        collection = splitinfo[7]
        return country, year, collection    
    
    def getresultstatus(self,resultstr):
        jitm = json.loads(resultstr)
        if jitm.get("result") == "success":
            return True
        else:
            return False
        
    def getkeyvalue(self,resultstr, k):
        try:
            jitm = json.loads(resultstr)
            return jitm.get(k)
        except:
            return None