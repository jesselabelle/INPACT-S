/*-------------------------------------------------------------------------
Title: Master
Authors: Jesse LaBelle, Inmaculada Marti­nez-Zarzoso, Ana Maria Santacreu, and Yoto Yotov
Purpose: Run all scripts to reproduce INPACIT-S and INPACIT-S-Citations

Directory Structure Assumption:
   /Project Root/
       /data/
           /sql_output/  <-- Raw text files from SQL (Input)
           /imputed/     <-- Created by these scripts (Output)
       /code/
           /stata/       <-- You are here
----------------------------------------------------------------------------*/

quietly {

	clear all
	set more off
	set processors 4
	timer clear 
	
	* Set Sort Seed for MP stability
	set sortseed 123456
	
	* -------------------------------------------------------------------------
	* MANDATORY USER CONFIGURATION (EDIT THIS SECTION AS NEEDED)
	* -------------------------------------------------------------------------
	
	* SET PATHS
	global root     	"/projects/p32438/The Determinants of Cross-Border Patenting"
	global data     	"$root/data"
	global code     	"$root/code/stata"
	global output 		"$root/datasets"
	global robustness 	"$output/robustness"
	
	cd "$root"

	* SQL SOURCE DATA FOLDER (Determines Major Version V#) 
	* V1 uses PATSTAT 2021 Autumn Ed.
	* V2 uses PATSTAT 2024 Spring Ed.
	global sql_subfolder "patstat_2024spring" 

	* BRIDGE FILE TOGGLE (Determines Minor Version _#)
	* Set to 1 to use 'first_and_subsequent_filings.csv' (New Method)
	* Set to 0 to use Standard Method (Original)
	global method_version 1
	
	/* IMPORTANT NOTE: One of the imputation processes relies on WIPO data that is 
	   being updated frequently by them. Using a different version may result in 
	   slight discrepencies. The data should follow: 
	   	    WIPO IP Statistics Data Center Data
		        Indicator: Total patent applications (direct and PCT national phase entries)
		        Count by filing office and applicant's origin
		        Year range: YYYY - YYYY
		Original Data was downloaded in early 2022. Data for V2 was downloaded 11/2025 */
		
	global wipo_share_data "$data/raw/crosswalks/patent_1 - Total patent applications (direct and PCT national phase entries)_Count by filing office and applicant origin_1980_2023"

	* -------------------------------------------------------------------------
	* END USER CONFIGURATION
	* -------------------------------------------------------------------------

	global raw_sql  "$data/sql_output/$sql_subfolder" 

	* Create Output Folders
	capture mkdir "$output"
	capture mkdir "$robustness"
	capture mkdir "$robustness/applt"
	capture mkdir "$robustness/invt"

	/* ------------------------------------------------------------------------- 
	   OPTIONAL USER CONFIGURATION (DEFAULT IS SET TO THE SETTINGS USED TO MAKE
	   INPACIT-S V2.1)
	------------------------------------------------------------------------- */

	* Years for processing applications (these are determined by the SQL codes)
	* Split to avoid overwhelming computer's memory
	global years 1980_1984 1985_1989 1990_1994 1995_1999 2000_2004 2005_2009 2010_2014 2015_2019 2020_2024

	* Person types
	global types applt //invt

	* Priority Year Cutoffs
	global min_priority_year 1940
	global max_priority_year 2025

	* NAMING LOGIC

	* Calculate Major Version (V#) from SQL Folder Name
	if strpos("$sql_subfolder", "2021") {
	    global v_major "V1"
	}
	else if strpos("$sql_subfolder", "2024") | strpos("$sql_subfolder", "2025") {
	    global v_major "V2"
	}
	else { // Users can add future versions here
	    global v_major "VX"
	}

	* Calculate Minor Version (_#) from Bridge Toggle
	global v_minor = $method_version

	* Construct Final Suffix
	global version_suffix "_${v_major}_${v_minor}"

	* VISUAL HEADER FOR MASTER START
	noisily display _n as text "{hline 60}"
	noisily display as result "INPACT-S MASTER EXECUTION STARTED"
	noisily display as result "TARGET VERSION: INPACT-S${version_suffix}"
	noisily display as text "{hline 60}"


	/* ------------------------------------------------------------------------- 
	STEP 2: EXECUTION
	------------------------------------------------------------------------- */

	* Step 1: Create Imputation Dictionaries
	* We run this ONCE for ALL types (applt and invt).

	noisily run "$code/1 -- deRassenfosse Imputation.do"

	* Step 2: Construct Flows (with Robustness Loops)
	* This loops through variations of the bilateral flow construction for
	* robustness

	foreach dr in 0 1 {
		foreach ra in 0 1 {
			foreach wipo in 0 1 {
		    
				global run_dr   `dr'
				global run_ra   `ra'
				global run_wipo `wipo'
		    
				noisily display _n as text "{hline 60}"
		    
				if `dr' == 1 & `ra' == 1 & `wipo' == 1 {
					noisily display as result "SCENARIO: MAIN VERSION (Applt + Invt)"
					noisily display as text "Params: DR=1 | RA=1 | WIPO=1"
				}
				else {
					noisily display as result "SCENARIO: ROBUSTNESS CHECK (Applt Only)"
					noisily display as text "Params: DR=`dr' | RA=`ra' | WIPO=`wipo'"
				}
				noisily display as text "{hline 60}"

				noisily run "$code/2 -- Bilateral Patent Flows Construction.do"
			}
		}
	}
    
	noisily display _n as text "{hline 60}"
	noisily display as result "MASTER EXECUTION COMPLETE"
	noisily display as text "{hline 60}"
}
