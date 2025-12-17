/*-------------------------------------------------------------------------
Title: Master
Authors: Jesse LaBelle, Inmaculada Martínez-Zarzoso, Ana Maria Santacreu, and Yoto Yotov
Purpose: Run all scripts to reproduce INPACIT-S and INPACIT-S-Citations

Directory Structure Assumption:
   /Project Root/
       /data/
           /sql_output/  <-- Raw text files from SQL (Input)
           /imputed/     <-- Created by these scripts (Output)
       /code/
           /stata/       <-- You are here
----------------------------------------------------------------------------*/

clear all
set more off
set trace off

/* ------------------------------------------------------------------------- 
   STEP 0: SET PATHS
------------------------------------------------------------------------- */

local current_dir "`c(pwd)'"
global root     "../.."
global data     "$root/data"
global code     "$root/code/stata"
global raw_sql  "$data/sql_output" 

* Create Output Folders
capture mkdir "$data/imputed"
capture mkdir "$data/imputed/yearly"
capture mkdir "$data/Datasets"
capture mkdir "$data/datasets/robustness"

* Switch to Data Directory
cd "$data"

/* ------------------------------------------------------------------------- 
   STEP 1: CONFIGURATION
------------------------------------------------------------------------- */

* Years for processing applications
global years 1980_1984 1985_1989 1990_1994 1995_1999 2000_2004 2005_2009 2010_2014 2015_2019 2020_2024

* Default types (Used for Script 1)
global types applt invt

* Priority Year Cutoffs (Used in Script 1)
global min_priority_year 1940
global max_priority_year 2023

*--------------------------------------------------------------------------
* SECTION 2: EXECUTION
*--------------------------------------------------------------------------

* Patents - Step 1: Create Imputation Dictionaries
* We run this ONCE for ALL types (applt and invt). 
* It creates the lookup files that Script 2 will draw from.
do "$code/1 -- deRassenfosse Imputation.do"

* Patents - Step 2: Construct Flows (with Robustness Loops)
* We loop through binary flags (0=Off, 1=On) for all 3 methods.
foreach dr in 0 1 {
    foreach ra in 0 1 {
        foreach wipo in 0 1 {
            
            * Set globals that Script 2 will read
            global run_dr   `dr'
            global run_ra   `ra'
            global run_wipo `wipo'
            
            * LOGIC CHECK:
            * If this is the "Full" run (1-1-1), we run for both Applicants and Inventors.
            * For all other combinations (Robustness), we ONLY run for Applicants.
            if `dr' == 1 & `ra' == 1 & `wipo' == 1 {
                global types "applt invt"
                display "Running MAIN VERSION (Applt + Invt): DR=1 | RA=1 | WIPO=1"
            }
            else {
                global types "applt"
                display "Running ROBUSTNESS (Applt Only): DR=`dr' | RA=`ra' | WIPO=`wipo'"
            }
            
            do "$code/2 -- Bilateral Patent Flows Construction.do"
        }
    }
}

* OECD Comparison (Runs using the outputs from Script 2)
* This now generates the Robustness Figures as well.
do "$code/3 -- OECD Comparisons.do"

* Citations (Only runs on the final/main version)
do "$code/3 -- Creating and Exporting Data for MATLAB.do"

/* MATLAB CHECK */
capture confirm file "Matlab_Output.dta" 
if _rc != 0 {
    display as error "***************************************************************"
    display as error "STOPPING: MATLAB INTERVENTION REQUIRED"
    display as error "Run 'Code M4__MATLABImputation.m' in MATLAB then return here."
    display as error "***************************************************************"
    exit
}

do "$code/5 -- Bilateral 4D Citation Data"
display "Master Execution Complete."