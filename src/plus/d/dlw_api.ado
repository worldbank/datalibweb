program define dlw_api, rclass
    syntax, OPTion(integer) OUTfile(string) [Query(string)]

    capture program define _datalibweb, plugin using("dlib2_`=cond(strpos(`"`=c(machine_type)'"',"64"),64,32)'.dll")
    if _rc > 0 & _rc != 110 {
        display as error "something went wrong"
        exit `= _rc'
    }
    plugin call _datalibweb, "`option'" "`outfile'" "`query'"

    c_local dlibrc "`dlibrc'"
    c_local dlibFileName "`dlibFileName'"
    c_local dlibDataSize "`dlibDataSize'"
    c_local dlibType "`dlibType'"
end
