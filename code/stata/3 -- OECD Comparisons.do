*-------------------------------------------------------------------------
Title: OECD Comparison (Robustness Edition)

Authors: Jesse LaBelle, Inmaculada Martínez-Zarzoso, and Ana Maria Santacreu

Purpose: This script compiles ALL robustness versions of the Applicant data
(plus the Baseline and Full Inventor data) and merges them with official 
OECD statistics.

OECD Data -- OECD Patent Dta En -- https://www.oecd-ilibrary.org/science-and-technology/data/oecd-patent-statistics_patent-data-en

Inputs:
    1. Robustness/INPACT-S_applt_DR*_RA*_WIPO*.dta (All 8 Robustness Versions)
    2. Robustness/INPACT-S_invt_DR0_RA0_WIPO0.dta (Baseline Invt)
    3. INPACT-S.dta (Full Applt)
    4. forcitations.dta (Full Invt)
    5. oecd/PATS_IPC-en.csv (External OECD Data)
----------------------------------------------------------------------------*/

clear all
set more off

* Check if OECD data exists before running
capture confirm file "./oecd/PATS_IPC-en.csv"
if _rc != 0 {
    display as error "WARNING: OECD Data file (./oecd/PATS_IPC-en.csv) not found."
    display as error "Skipping OECD Comparison."
    exit
}

display "Constructing Comprehensive OECD Comparison Dataset..."

*--------------------------------------------------------------
* STEP 1: LOOP AND MERGE ALL APPLICANT VERSIONS
*--------------------------------------------------------------

* We initialize a tempfile to hold our master list
tempfile master_list
local first_run = 1

* Loop through every combination of flags
foreach dr in 0 1 {
    foreach ra in 0 1 {
        foreach wipo in 0 1 {
            
            *-----------------------------------
            * A. LOCATE THE FILE
            *-----------------------------------
            * Logic to find where the file is located based on Script 2's saving rules
            
            local fpath ""
            
            * CASE 1: The Full Main Version (1-1-1)
            if `dr' == 1 & `ra' == 1 & `wipo' == 1 {
                local fpath "../Datasets/INPACT-S.dta"
                local varname "applt_FULL_111"
            }
            * CASE 2: The Robustness Versions (Includes Baseline 0-0-0)
            else {
                local fpath "../Datasets/Robustness/INPACT-S_applt_DR`dr'_RA`ra'_WIPO`wipo'.dta"
                local varname "applt_d`dr'_r`ra'_w`wipo'"
            }
            
            *-----------------------------------
            * B. LOAD AND PREP
            *-----------------------------------
            display "Loading: `fpath'"
            
            capture confirm file "`fpath'"
            if _rc == 0 {
                use "`fpath'", clear
                
                * Rename the patent column to the specific version name (e.g., applt_d0_r1_w0)
                * Note: The variable inside is named 'patents_applt' (or just 'patents' depending on save)
                * We capture rename to be safe
                capture rename patents_applt patents
                rename patents `varname'
                
                * Keep only identifiers and the value
                keep appln_auth person_ctry_code ipc4 appln_filing_year `varname'
                
                * Collapse to ensure uniqueness (just in case)
                collapse (sum) `varname', by(appln_auth person_ctry_code ipc4 appln_filing_year)
                
                *-----------------------------------
                * C. MERGE INTO MASTER
                *-----------------------------------
                if `first_run' == 1 {
                    save `master_list', replace
                    local first_run = 0
                }
                else {
                    merge 1:1 appln_auth person_ctry_code ipc4 appln_filing_year using `master_list', nogenerate
                    save `master_list', replace
                }
            }
            else {
                 display as error "Warning: File `fpath' not found. Skipping."
            }
            
        }
    }
}

*--------------------------------------------------------------
* STEP 2: ADD INVENTOR DATA (Baseline and Full Only)
*--------------------------------------------------------------
* Note: We only generated INVT data for 0-0-0 and 1-1-1 to save time.

* Load Baseline Inventor (0-0-0)
capture confirm file "../Datasets/Robustness/INPACT-S_invt_DR0_RA0_WIPO0.dta"
if _rc == 0 {
    use "../Datasets/Robustness/INPACT-S_invt_DR0_RA0_WIPO0.dta", clear
    rename patents_invt invt_BASE_000
    merge 1:1 appln_auth person_ctry_code ipc4 appln_filing_year using `master_list', nogenerate
    save `master_list', replace
}

* Load Full Inventor (1-1-1)
capture confirm file "forcitations.dta"
if _rc == 0 {
    use "forcitations.dta", clear
    rename patents_invt invt_FULL_111
    merge 1:1 appln_auth person_ctry_code ipc4 appln_filing_year using `master_list', nogenerate
    save `master_list', replace
}

*--------------------------------------------------------------
* STEP 3: PREPARE AND MERGE OECD DATA
*--------------------------------------------------------------

* Add ISO3 codes to our master list for merging with OECD
use `master_list', clear
rename person_ctry_code iso2

preserve
    import delimited ./crosswalks/iso_codes, varnames(1) encoding(UTF-8) clear
    tempfile iso
    save `iso'
restore

merge m:1 iso2 using `iso', keep(1 3) nogenerate
rename (iso3 iso2) (person_ctry_code_iso3 person_ctry_code)
tempfile final_data
save `final_data'

* --- Process OECD Data ---
import delimited ./oecd/PATS_IPC-en.csv, encoding(UTF-8) clear 

local OECDtypes INVENTORS APPLICANTS

foreach o in `OECDtypes' {
    preserve
    
    keep if inrange(length(ipc),4,4) 
    keep if kinddate == "APPLICATION" 
    keep if kindcountry == "`o'" 
    keep if kindpatent == "EPO_A" | kindpatent == "USPTO_A" 
    
    drop unitcode powercodecode referenceperiodcode flagcodes kinddate kindcountry 
    rename (ipc time kindpatent location) (ipc4 appln_filing_year appln_auth person_ctry_code_iso3) 
    
    sort person_ctry_code_iso3 ipc4 appln_filing_year
    replace appln_auth = substr(appln_auth,1,2) 

    keep if appln_filing_year >= 1980 
    
    rename value OECD_`o'_patents
    
    tempfile OECD_`o'
    save `OECD_`o''
    
    restore
}

* Merge OECD Inventors and Applicants
use `OECD_APPLICANTS', clear
merge 1:1 appln_auth person_ctry_code_iso3 ipc4 appln_filing_year using `OECD_INVENTORS', nogen
tempfile OECD_FINAL
save `OECD_FINAL'

* --- Final Merge ---
use `final_data', clear
merge 1:1 appln_auth person_ctry_code_iso3 ipc4 appln_filing_year using `OECD_FINAL', nogen

rename (OECD_INVENTORS_patents OECD_APPLICANTS_patents) (OECD_invt OECD_applt)

* Organize columns for easier reading
order appln_auth person_ctry_code ipc4 appln_filing_year OECD_applt applt_FULL_111 applt_d0_r0_w0

save "../datasets/comparisons/OECD_COMPARISON_ALL_VERSIONS.dta", replace

*--------------------------------------------------------------
* STEP 4: VISUALIZATION (Time Series Comparison)
*--------------------------------------------------------------
display "Generating Comparison Figures..."

* Set a clean graph scheme
set scheme s2color

*----------------------------
* FIGURE 1: APPLICANTS
*----------------------------
preserve

    * Collapse data to yearly totals for the graph
    collapse (sum) OECD_applt applt_*, by(appln_filing_year)
    
    * Label variables for the legend
    label var OECD_applt "OECD (Benchmark)"
    label var applt_FULL_111 "INPACT-S (Full)"
    label var applt_d0_r0_w0 "Baseline (Raw)"
    
    * Build the graph command dynamically for the intermediate robustness versions
    * We want the "Main" lines to be thick/colored and the "Robustness" lines to be thin/gray
    local robust_lines ""
    foreach var of varlist applt_d* {
        if "`var'" != "applt_d0_r0_w0" {
             local robust_lines `robust_lines' (line `var' appln_filing_year, lcolor(gs12) lwidth(thin))
        }
    }

    * Generate the Applicant Graph
    twoway `robust_lines' ///
           (line applt_d0_r0_w0 appln_filing_year, lcolor(blue) lpattern(dash)) ///
           (line applt_FULL_111 appln_filing_year, lcolor(red) lwidth(medium)) ///
           (line OECD_applt appln_filing_year, lcolor(black) lwidth(thick)), ///
           title("OECD Comparison: Applicants") ///
           subtitle("Total Patent Counts (1980-2020)") ///
           legend(order(9 "OECD" 8 "INPACT-S (Full)" 7 "Baseline (Raw)" 1 "Robustness Variations") rows(1) size(small)) ///
           ytitle("Total Patents") xtitle("Year") ///
           note("Gray lines represent the 6 intermediate robustness combinations.")
           
    graph export "../datasets/comparisons/Figure_OECD_Applicants.png", replace width(2000)

restore

*----------------------------
* FIGURE 2: INVENTORS
*----------------------------
preserve

    * Collapse data to yearly totals
    collapse (sum) OECD_invt invt_*, by(appln_filing_year)
    
    label var OECD_invt "OECD (Benchmark)"
    label var invt_FULL_111 "INPACT-S (Full)"
    label var invt_BASE_000 "Baseline (Raw)"

    * Generate the Inventor Graph
    twoway (line invt_BASE_000 appln_filing_year, lcolor(blue) lpattern(dash)) ///
           (line invt_FULL_111 appln_filing_year, lcolor(red) lwidth(medium)) ///
           (line OECD_invt appln_filing_year, lcolor(black) lwidth(thick)), ///
           title("OECD Comparison: Inventors") ///
           subtitle("Total Patent Counts (1980-2020)") ///
           legend(rows(1)) ///
           ytitle("Total Patents") xtitle("Year")
           
    graph export "../datasets/comparisons/Figure_OECD_Inventors.png", replace width(2000)

restore

display "Figures saved to ../datasets/comparisons/"

display "---------------------------------------------------------"
display "OECD Comparison Complete!"
display "File Saved: datasets/comparisons/OECD_COMPARISON_ALL_VERSIONS.dta"
display "Contains columns for OECD, Full 111, Baseline 000, and all 6 intermediate robustness versions."
display "---------------------------------------------------------"