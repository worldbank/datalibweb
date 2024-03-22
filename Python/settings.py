# -*- coding: utf-8 -*-
"""
Created on Fri Apr 27 19:36:38 2018

@author: WB472400
"""

import xml.etree.ElementTree as et
import ast
import os

class serversetting:
    def __init__(self, _collection):
        self.collection = os.path.dirname(os.path.abspath(__file__)) + '/settings/' + _collection + '.xml'
        self.xl = et.parse(self.collection)
    
    @property
    def defaultmodule(self):
        mod = self.xl.find('defmod') 
        return mod.attrib['modname']

    @property
    def tokenlength(self):
        mod = self.xl.find('token') 
        return mod.attrib['count']
    
    @property
    def hhmlist(self):
        mod = []
        for m in self.xl.findall('modules/hhmlist/module'):
            mod.append(m.attrib['name'])

        return mod
    
    @property
    def indmlist(self):
        mod = []
        for m in self.xl.findall('modules/indmlist/module'):
            mod.append(m.attrib['name'])

        return mod
    
    @property
    def hhidkey(self):
        mod = self.xl.find('keys/key/[@name="hhid"]')
        return mod.text

    @property
    def pidkey(self):
        mod = self.xl.find('keys/key/[@name="pid"]')
        return mod.text

    @property
    def collections(self):
        cols = []
        for c in self.xl.findall('collections/collection'):
            cols.append(c.attrib['name'])
        return cols
    
    def getmodules(self, colName):
        mod = []
        col = self.xl.find('collections/collection/[@name="' + colName + '"]')
        for c in col.findall('modules/id'):
            mod.append(c.text)
        return mod

    def getmodulejoinkeys(self, colName):
        jk = []
        col = self.xl.find('collections/collection/[@name="' + colName + '"]')
        for k in col.findall('joinkeys/key'):
            jk.append(k.text)
        return jk

    def getkeystojoincollection(self, colName):
        joinfields = []
        col_elem = self.xl.find('collections/joins/' + colName)
        for fk in col_elem.findall('field'):
            joinfields.append(fk.text)
        return joinfields

    @property
    def cpifieldstr(self):
        fieldstr = self.xl.find('collections/cpi/fields').text
        return ast.literal_eval(fieldstr.replace("\n", "").strip())

    @property    
    def cpijoinkeys(self):
        jk = []
        col = self.xl.find('collections/cpi/joinkeys')
        for k in col.findall('key'):
            jk.append(k.text)
        return jk
