*! version 0.1 16feb017
*! Minh Cong Nguyen
capture program define dlwgui, plugin using("dlib2g_`=cond(strpos(`"`=c(machine_type)'"',"64"),64,32)'.dll")

