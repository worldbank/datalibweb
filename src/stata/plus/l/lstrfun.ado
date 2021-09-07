*! lstrfun Version 1.2 dan_blanchette@unc.edu 09Aug2011
*! the carolina population center, unc-ch
* -Nick Cox let me know that the regular expersion functions were available in Stata 9.2
*   but were just not documented
*  lstrfun Version 1.1 dan_blanchette@unc.edu 22Jul2011
** -it now can run regexr(), regexm() and regexs()
** lstrfun Version 1.0 dan_blanchette@unc.edu 09Aug2010
** Center for Entrepreneurship and Innovation Duke University's Fuqua School of Business
* modify long local macros with mata string functions 

program define lstrfun
version 9.2

syntax [namelist(local)] [, lower(string asis) upper(string asis) proper(string asis) /// 
                            ltrim(string asis) itrim(string asis) rtrim(string asis) trim(string asis)  ///
                            substr(string asis) subinstr(string asis) subinword(string asis)  ///
                            reverse(string asis) strdup(string asis) soundex(string asis) soundex_nara(string asis)   ///
                            strlen(string asis) strpos(string asis) _substr(string asis) indexnot(string asis)  ///
                            strmatch(string asis) regexr(string asis) regexm(string asis) regexms(string asis) ///
                         ]

if missing(`"`namelist'"') {
  display as error "need to specify a local macro variable name to modify or create"
  exit 198
}
local n_locals : word count `namelist'
if `n_locals' > 1 {
  display as error "only one local macro variable name can be submitted"
  exit 198
}

// local m1= !missing(`"`macval(lower)'"'   
//   says "too few quotes" when a fairly long macro submitted but only inside a program
//   using short macro names and no spaces to make it even shoerter
local m1=`"`macval(lower)'"'!=""
local m2=`"`macval(proper)'"'!=""
local m3=`"`macval(upper)'"'!=""
local m4=`"`macval(ltrim)'"'!=""
local m5=`"`macval(itrim)'"'!=""
local m6=`"`macval(rtrim)'"'!=""
local m7=`"`macval(trim)'"'!=""
local m8=`"`macval(substr)'"'!=""
local m9=`"`macval(subinstr)'"'!=""
local m10=`"`macval(subinword)'"'!=""
local m11=`"`macval(strdup)'"'!=""
local m12=`"`macval(reverse)'"'!=""
local m13=`"`macval(soundex)'"'!=""
local m14=`"`macval(soundex_nara)'"'!=""
local m15=`"`macval(strlen)'"'!=""
local m16=`"`macval(strpos)'"'!=""
local m17=`"`macval(_substr)'"'!=""
local m18=`"`macval(indexnot)'"'!=""
local m19=`"`macval(strmatch)'"'!=""
local m20=`"`macval(regexr)'"'!=""
local m21=`"`macval(regexm)'"'!=""
local m22=`"`macval(regexms)'"'!=""


if `m1'  ///  
 + `m2'  ///
 + `m3'  ///
 + `m4'  /// 
 + `m5'  /// 
 + `m6'  /// 
 + `m7'  /// 
 + `m8'  /// 
 + `m9'  /// 
 + `m10' /// 
 + `m11' /// 
 + `m12' /// 
 + `m13' /// 
 + `m14' /// 
 + `m15' /// 
 + `m16' /// 
 + `m17' /// 
 + `m18' /// 
 + `m19' /// 
 + `m20' /// 
 + `m21' > 1   { 
   display as error "you can only specify 1 option in {helpb lstrfun:lstrfun}" 
   exit 198
 } 

if `m1' == 1 {
  mata: long_lower(`macval(lower)')
  c_local `namelist' `"`macval(lower)'"'
}
else if `m2' == 1 {
  mata: long_proper(`macval(proper)')
  c_local `namelist' `"`macval(proper)'"'
}
else if `m3' == 1 {
  mata: long_upper(`macval(upper)')
  c_local `namelist' `"`macval(upper)'"'
}
else if `m4' == 1 {
  mata: long_ltrim(`macval(ltrim)')
  c_local `namelist' `"`macval(ltrim)'"'
}
else if `m5' == 1 {
  mata: long_itrim(`macval(itrim)')
  c_local `namelist' `"`macval(itrim)'"'
}
else if `m6' == 1 {
  mata: long_rtrim(`macval(rtrim)')
  c_local `namelist' `"`macval(rtrim)'"'
}
else if `m7' == 1 {
  mata: long_trim(`macval(trim)')
  c_local `namelist' `"`macval(trim)'"'
}
else if `m8' == 1 {
  mata: long_substr(`macval(substr)')
  c_local `namelist' `"`macval(substr)'"'
}
else if `m9' == 1 {
  mata: long_subinstr(`macval(subinstr)')
  c_local `namelist' `"`macval(subinstr)'"'
}
else if `m10' == 1 {
  mata: long_subinword(`macval(subinword)')
  c_local `namelist' `"`macval(subinword)'"'
}
else if `m11' == 1 {
  mata: long_strdup(`macval(strdup)')
  local len_strdup : length local strdup
  if `len_strdup' < `len_m_var' {
    local clen_m_var= string(`len_m_var',"%11.0gc")
    if c(SE) & c(maxvar) < 32767 & `len_m_var' <= 1081511 {
      display as error "{cmd:strdup()} generated a string that has `clen_m_var' characters which is more than Stata can handle" ///
                       " when {helpb maxvar:maxvar} is set to `c(maxvar)'."
      display as error "Increase your {helpb maxvar:maxvar} setting higher and try again."
      exit 149
    } 
    else {
      display as error "{cmd:strdup()} generated a string that has `clen_m_var' characters (which is more than Stata can handle)"
      exit 149
    }
  }
  c_local `namelist' `"`macval(strdup)'"'
}
else if `m12' == 1 {
  mata: long_reverse(`macval(reverse)')
  c_local `namelist' `"`macval(reverse)'"'
}
else if `m13' == 1 {
  mata: long_soundex(`macval(soundex)')
  c_local `namelist' `"`macval(soundex)'"'
}
else if `m14' == 1 {
  mata: long_soundex_nara(`macval(soundex_nara)')
  c_local `namelist' `"`macval(soundex_nara)'"'
}
else if `m15' == 1 {
  mata: long_strlen(`macval(strlen)')
  c_local `namelist' `"`macval(strlen)'"'
}
else if `m16' == 1 {
  mata: long_strpos(`macval(strpos)')
  c_local `namelist' `"`macval(strpos)'"'
}
else if `m17' == 1 {
  mata: long__substr(`macval(_substr)')
  c_local `namelist' `"`macval(_substr)'"'
}
else if `m18' == 1 {
  mata: long_indexnot(`macval(indexnot)')
  c_local `namelist' `"`macval(indexnot)'"'
}
else if `m19' == 1 {
  mata: long_strmatch(`macval(strmatch)')
  c_local `namelist' `"`macval(strmatch)'"'
}
else if `m20' == 1 {
  mata: long_regexr(`macval(regexr)')
  c_local `namelist' `"`macval(regexr)'"'
}
else if `m21' == 1 {
  mata: long_regexm(`macval(regexm)')
  c_local `namelist' `"`macval(regexm)'"'
}
else if `m22' == 1 {
  mata: long_regexms(`macval(regexms)')
  c_local `namelist' `"`macval(regexms)'"'
}
else {
  display as error "need to specify an option in {helpb lstrfun:lstrfun}"
  exit 198
}


end


mata:
void long_lower(string scalar lstring)
{
	string scalar m_var 
	m_var= strlower(lstring) 
	st_local("lower",m_var) 
}

void long_proper(string scalar lstring)
{
	string scalar m_var 
	m_var= strproper(lstring) 
	st_local("proper",m_var) 
}

void long_upper(string scalar lstring)
{
	string scalar m_var 
	m_var= strupper(lstring) 
	st_local("upper",m_var) 
}

void long_ltrim(string scalar lstring)
{
	string scalar m_var 
	m_var= strltrim(lstring) 
	st_local("ltrim",m_var) 
}

void long_itrim(string scalar lstring)
{
	string scalar m_var 
	m_var= stritrim(lstring) 
	st_local("itrim",m_var) 
}

void long_rtrim(string scalar lstring)
{
	string scalar m_var 
	m_var= strrtrim(lstring) 
	st_local("rtrim",m_var) 
}

void long_trim(string scalar lstring)
{
	string scalar m_var 
	m_var= strtrim(lstring) 
	st_local("trim",m_var) 
}
 
void long_substr(string scalar lstring, real scalar start, real scalar length)
{
	string scalar m_var 
	m_var= substr(lstring,start,length) 
	st_local("substr",m_var) 
}

void long_subinstr(string scalar lstring, string scalar old, string scalar snew, real scalar cnt)
{
	string scalar m_var 
	m_var= subinstr(lstring,old,snew,cnt) 
	st_local("subinstr",m_var) 
}

void long_subinword(string scalar lstring, string scalar old, string scalar snew, real scalar cnt)
{
	string scalar m_var 
	m_var= subinword(lstring,old,snew,cnt) 
	st_local("subinword",m_var) 
}

void long_strdup(string scalar lstring, real scalar n)
{
	string scalar m_var 
	m_var= n*lstring
        real scalar len_lstring
        len_lstring= n * strlen(lstring)
        real scalar len_m_var
        len_m_var= strlen(m_var)
	string scalar slen_m_var 
        slen_m_var= strofreal(len_m_var) 
	st_local("len_m_var",slen_m_var) 
	st_local("strdup",m_var) 
}

void long_reverse(string scalar lstring)
{
	string scalar m_var 
	m_var= strreverse(lstring) 
	st_local("reverse",m_var) 
}

void long_soundex(string scalar lstring)
{
	string scalar m_var 
	m_var= soundex(lstring) 
	st_local("soundex",m_var) 
}

void long_soundex_nara(string scalar lstring)
{
	string scalar m_var 
	m_var= soundex_nara(lstring) 
	st_local("soundex_nara",m_var) 
}

void long_strlen(string scalar lstring)
{
	string scalar m_var 
	real scalar nm_var 
	nm_var= strlen(lstring) 
	m_var= strofreal(nm_var) 
	st_local("strlen",m_var) 
}

void long_strpos(string scalar lstring, string scalar needle)
{
	string scalar m_var 
	real scalar nm_var 
	nm_var= strpos(lstring,needle) 
	m_var= strofreal(nm_var) 
	st_local("strpos",m_var) 
}

void long__substr(string scalar lstring, string scalar tosub, real scalar pos)
{
        _substr(lstring, tosub, pos)
        st_local("_substr",lstring)
}

void long_indexnot(string scalar lstring, string scalar needle)
{
	string scalar m_var 
	real scalar nm_var 
	nm_var= indexnot(lstring,needle) 
	m_var= strofreal(nm_var) 
	st_local("indexnot",m_var) 
}

void long_strmatch(string scalar lstring, string scalar pattern)
{
	string scalar m_var 
	real scalar nm_var
	nm_var= strmatch(lstring,pattern)
	m_var= strofreal(nm_var)
	st_local("strmatch",m_var) 
}

void long_regexr(string scalar lstring, string scalar pattern, string scalar rep)
{
	string scalar m_var 
	m_var= regexr(lstring,pattern,rep) 
	st_local("regexr",m_var) 
}

void long_regexm(string scalar lstring, string scalar pattern)
{
	string scalar m_var 
	real scalar nm_var
	nm_var= regexm(lstring,pattern)
	m_var= strofreal(nm_var)
	st_local("regexm",m_var) 
}

void long_regexms(string scalar lstring, string scalar pattern, real scalar ss)
{
	string scalar m_var 
	if (regexm(lstring,pattern)) {
          m_var= regexs(ss)
        }
	st_local("regexms",m_var) 
}

end
