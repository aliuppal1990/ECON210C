* Github ============================================================================*
 
* Programme: Ali_Uppal_EC210C_PS1
* Author: Ali Uppal
* Date: 04/04/2020
* Purpose: Practice using HP Filter

* This programme has the following sections:
* (0)  Preliminaries
* (1)  Import Data & Merge
* (2)  Question 1
* (3)  Question 2
* (4)  Question 3
* (5)  Question 4
* (6)  Question 5
* (7)  Question 6
* (8)  Question 7

* ============================================================================

				* =================
				* (0) Preliminaries
				* =================

clear
cap 			log close 
set 			more off

*				set path structure
cd				"C:\Users\auppa\Desktop\UCSD\First Year\Macro\Econ 210C Macro\Psets"

				* ========================
				* (1)  Import Data & Merge
				* ========================

insheet using "Fixed Assets NIPA.csv", clear

gen dateq = yq(year, quarter)
format dateq %tq

save "NIPA.dta", replace

clear

import fred PAYEMS PCECC96 GDPC1 GPDIC1 HOANBS, aggregate(quarterly,eop) clear

gen dateq = qofd(daten)
format dateq %tq



merge 1:1 dateq using "C:\Users\auppa\Desktop\UCSD\First Year\Macro\Econ 210C Macro\Psets\NIPA.dta"

drop if _m==2

rename *, lower

rename payems total_employment
rename pcecc96 real_consumption
rename gdpc1 real_GDP
rename gpdic1 real_investment
rename hoanbs total_hours
rename private_nonres_fixed_assets capital_stock
rename private_nonres_fixed_assets_inde capital_stock_index

gen log_total_employment = log(total_employment)
gen log_real_consumption = log(real_consumption)
gen log_real_GDP = log(real_GDP)
gen log_real_investment = log(real_investment)
gen log_total_hours = log(total_hours)
gen log_capital_stock = log(capital_stock)
gen log_capital_stock_index = log(capital_stock_index)

ipolate log_capital_stock dateq, gen(ilog_capital_stock) epolate
ipolate log_capital_stock_index dateq, gen(ilog_capital_stock_index) epolate

gen k_share=0.67

gen log_SR = log_real_GDP - (1-k_share)*log_total_hours - k_share*ilog_capital_stock

gen log_SR2 = log_real_GDP - (1-k_share)*log_total_hours - k_share*ilog_capital_stock_index

tsset dateq


tsline log_real_GDP log_total_employment log_real_consumption log_real_investment log_total_hours ilog_capital_stock ilog_capital_stock_index log_SR2 if tin(1947q1, 2019q4)

cap gen linear = "linear"
foreach i in 1600 10000 999999999999{
    
	local varname = `i'
	local temp = `i'
	
	if `varname' == 999999999999 {
		local temp = "linear"
	}
	local varname = `temp'
	
	tsfilter hp gdp_hp`varname'=log_real_GDP, smooth(`i')
	tsfilter hp consumption_hp`varname'=log_real_consumption, smooth(`i')
	tsfilter hp investment_hp`varname'=log_real_investment, smooth(`i')
	tsfilter hp employment_hp`varname'=log_total_employment, smooth(`i')
	tsfilter hp hours_hp`varname'=log_total_hours, smooth(`i')
	tsfilter hp kstock_hp`varname'=ilog_capital_stock, smooth(`i')
	tsfilter hp kstockindex_hp`varname'=ilog_capital_stock_index, smooth(`i')
	tsfilter hp SR_hp`varname'=log_SR, smooth(`i')	
	tsfilter hp SR2_hp`varname'=log_SR2, smooth(`i')		
}

/*
tsfilter hp consumption_hp1600=log_real_consumption, smooth(1600)
tsfilter hp investment_hp1600=log_real_investment, smooth(1600)
tsfilter hp employment_hp1600=log_total_employment, smooth(1600)
tsfilter hp hours_hp1600=log_total_hours, smooth(1600)
tsfilter hp kstock_hp1600=ilog_capital_stock, smooth(1600)
tsfilter hp kstockindex_hp1600=ilog_capital_stock_index, smooth(1600)
*/


//local varlist gdp_hp1600 consumption_hp1600 investment_hp1600 employment_hp1600 hours_hp1600 kstockindex_hp1600 SR2_hp1600

cap program drop sum_stat
prog define sum_stat, eclass
version 11
syntax varlist
tempvar id0
g `id0' =_n
qui tsset `id0'
mat drop _all

local denominator `: word 1 of `varlist''
qui sum(`denominator')
local sd_`denominator' = `r(sd)'
local size : list sizeof varlist
mat table_out=J(`=`size'',4,.)

local rownames
local i 1
foreach name of local varlist {

// sd & rel sd
qui su `name'
    mat table_out[`i',1]=100*r(sd)
	mat table_out[`i',2]=r(sd)/`sd_`denominator''

// 1st-order autocorrelations
        qui reg `name' L1.`name'
        mat b_`name'=e(b)
            mat table_out[`i',3]=b_`name'[1,1]
// Corr with output        
		qui corr `name' `denominator'
        mat b_`name'=r(rho)
            mat table_out[`i',4]=b_`name'[1,1]
		local `++i'
local rownames `rownames' "`name'"

    }
mat colnames table_out="Standard Deviation" "Relative Standard Deviation" "First-Order Autocorrelation" "Correlation with Output"
mat rownames table_out=`rownames'

// output table

matlist table_out, format(%20.2f) border(top bottom)

end

tsset dateq

//creates table in word:    asdoc wmat, matrix(table_out) dec(2) tzok rnames(Y C I N H K SR) cnames(Standard_Deviation Relative_Standard_Deviation First-Order_Autocorrelation Comtemporaneous_Correlation_with_Output)

foreach i in 1600 10000 linear{

sum_stat gdp_hp`i' consumption_hp`i' investment_hp`i' employment_hp`i' hours_hp`i' kstockindex_hp`i' SR2_hp`i'

}


foreach k in gdp_hp* consumption_hp* investment_hp* employment_hp* hours_hp* kstockindex_hp* SR2_hp* {

tsline `k' if tin(1947q1, 2019q4)
//graph export
}
