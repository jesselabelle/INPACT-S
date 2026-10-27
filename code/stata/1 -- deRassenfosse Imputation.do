quietly {

	*-----------------------------------------------------------------
	* PRELIMINARY STEP: LOAD BRIDGE
	*-----------------------------------------------------------------
	if "$method_version" == "1" {
		timer clear 1
		timer on 1
		noisily display as text "Preliminary Step: Loading bridge data into memory... " _c

		capture frame drop Frame_Bridge_Raw
		frame create Frame_Bridge_Raw
		frame Frame_Bridge_Raw {
			import delimited "$raw_sql/imputed/first_and_subsequent_filings.csv", clear
			compress
			keep if appln_id != prior_appln_id
			keep appln_id prior_appln_id
		}
		timer off 1
		timer list 1
		noisily display as result "Done. (" %5.2f r(t1) " seconds) - Completed at $S_TIME"
	}
	* --------------------------------------------------------

	foreach t in $types {

		noisily display _n as text "{hline 60}"
		noisily display as result "STARTING PROCESS FOR TYPE: `t' (Version: $version_suffix)"
		noisily display as text "{hline 60}"

		timer clear 99
		timer on 99

		*-----------------------------------------------------------------
		* STEP 1: PREPARE IMPUTATION DATA (IN MEMORY)
		*-----------------------------------------------------------------
		noisily display as text "Step 1: Preparing Imputation Reference Data... " _c
		timer clear 1
		timer on 1

		* Check if CSV exists
		capture confirm file "$raw_sql/imputed/ctry_`t'_person.csv"

		if _rc == 0 {
			* If CSV exists, load it
			import delimited "$raw_sql/imputed/ctry_`t'_person.csv", clear
		}
		else {
			* If CSV is missing, assume it is TXT and load that
			import delimited "$raw_sql/imputed/ctry_`t'_person.txt", clear
		}

		duplicates drop 
		drop if priority_year > $max_priority_year | priority_year < $min_priority_year
		drop priority_date source type lastupdate
		sort appln_id person_id
		drop if ctry_code == "  " 

		tempfile imputation_ref
		save "`imputation_ref'"

		timer off 1
		timer list 1
		noisily display as result "Done. (" %5.2f r(t1) " seconds) - Completed at $S_TIME"

		*-----------------------------------------------------------------
		* STEP 2: LOAD AND APPEND APPLICATIONS
		*-----------------------------------------------------------------
		noisily display as text "Step 2: Loading and Stacking Application Data... "

		clear
		tempfile master_stack
		save "`master_stack'", emptyok

		foreach y in $years {
			timer clear 2
			timer on 2
			noisily display as text "    > Running Years - `y'... " _c

			import delimited "$raw_sql/`t'_alt/applications`y'.csv", clear
			replace person_ctry_code = trim(person_ctry_code)

			* Create a unique ID to preserve original file order (Necessary for
			* replicability in STATA 17 MP and beyond)
			gen long file_rec_id = _n

			append using "`master_stack'", force
			save "`master_stack'", replace
			timer off 2
			timer list 2
			noisily display as result "Done. (" %5.2f r(t2) " seconds) - Completed at $S_TIME"
		}

		if "$overall_subversion" == "2" {
			timer clear 2
			timer on 2
			noisily display as text "        > Adding unknown IPC4 codes (optional) ... " _c

			import delimited "$raw_sql/lost_apps/applications_undefined_tech_class_`t'.csv", clear
			replace person_ctry_code = trim(person_ctry_code)

			gen long file_rec_id = _n

			append using "`master_stack'", force
			save "`master_stack'", replace
			timer off 2
			timer list 2
			noisily display as result "Done. (" %5.2f r(t2) " seconds) - Completed at $S_TIME"
		}


		* To be used in the next script
		capture frame drop Store_Raw_`t'
		frame copy default Store_Raw_`t' 

		timer clear 2
		timer on 2
		noisily display as text "Step 2.1 Deduplicating for Imputation logic..." _c
		sort appln_id person_id file_rec_id 
		bys appln_id person_id: keep if _n==1
		drop file_rec_id
		timer off 2
		timer list 2
		noisily display as result "Done. (" %5.2f r(t2) " seconds) - Completed at $S_TIME"

		*-----------------------------------------------------------------
		* STEP 3: MERGE (Direct Imputation)
		*-----------------------------------------------------------------
		noisily display as text "Step 3: Performing Many-to-Many Merge... " _c
		timer clear 3
		timer on 3

		sort appln_id person_id

		merge m:m appln_id using "`imputation_ref'", keep(1 3) nogenerate

		gsort appln_id person_id -ctry_code
		duplicates drop appln_id person_id, force 
		replace person_ctry_code = ctry_code if missing(person_ctry_code) & !missing(ctry_code)

		timer off 3
		timer list 3
		noisily display as result "Done. (" %5.2f r(t3) " seconds) - Completed at $S_TIME"

		*-----------------------------------------------------------------
		* STEP 3.5: BRIDGE LOGIC (VX.1 ONLY - The new methodology)
		*-----------------------------------------------------------------
		if "$method_version" == "1" {

			noisily display as text "Step 3.5: Executing Bridge Imputation (V1)... " _c
			timer clear 35
			timer on 35

			* CREATE KNOWLEDGE BASE
			* Capture all applications that currently HAVE a country code
			capture frame drop Frame_Known

			frame put if !missing(person_ctry_code), into(Frame_Known)

			frame Frame_Known {
				keep appln_id person_ctry_code

				* SAFETY: must be unique to serve as a lookup key
				duplicates drop appln_id, force

				rename appln_id prior_appln_id
				rename person_ctry_code inherited_ctry

				* Optimize for frlink
				sort prior_appln_id
			}

			* Load relationship file, link to knowledge base to find "Parent Country"
			capture frame drop Frame_Bridge

			frame copy Frame_Bridge_Raw Frame_Bridge
			frame Frame_Bridge {

				* Link to the Known frame to get parent's country
				* Note: 'prior_appln_id' matches 'prior_appln_id' in Frame_Known
				frlink m:1 prior_appln_id, frame(Frame_Known)
				frget inherited_ctry, from(Frame_Known)

				* Optimization: Drop rows that didn't find a parent country
				drop if missing(inherited_ctry)

				* SAFETY: appln_id must be unique to link back to the Main dataset.
				* If a child has multiple parents, we sort by prior_appln_id 
				* to deterministically pick the EARLIEST parent.
				sort appln_id prior_appln_id
				by appln_id: keep if _n == 1

				keep appln_id inherited_ctry
			}

			* APPLY THE BRIDGE
			frlink m:1 appln_id, frame(Frame_Bridge)
			frget inherited_ctry, from(Frame_Bridge)

			* The Bridge Imputation: Fill remaining blanks
			replace person_ctry_code = inherited_ctry if missing(person_ctry_code)

			drop inherited_ctry Frame_Bridge
			frame drop Frame_Known
			frame drop Frame_Bridge

			timer off 35
			timer list 35
			noisily display as result "Done. (" %5.2f r(t35) " seconds) - Completed at $S_TIME"
		}

		*-----------------------------------------------------------------
		* STEP 4: CLEAN UP
		*-----------------------------------------------------------------
		noisily display as text "Step 4: Cleaning for use... " _c
		timer clear 4
		timer on 4

		* Final Cleanup
		drop patent_office priority_year ctry_code country

		rename person_ctry_code person_ctry_code2
		keep appln_id person_id person_ctry_code2
		bys appln_id person_id: keep if _n==1

		* To be used in Script 2
		* We name it dynamically based on type (e.g., Store_Imputed_applt)
		capture frame drop Store_Imputed_`t'
		frame copy default Store_Imputed_`t'

		timer off 4
		timer list 4
		noisily display as result "Done. (" %5.2f r(t4) " seconds) - Completed at $S_TIME"

		*-----------------------------------------------------------------
		* TOTAL TIME
		*-----------------------------------------------------------------
		timer off 99
		timer list 99
		noisily display as text "{hline 60}"
		noisily display as result "COMPLETED `t' IN " %5.2f r(t99) " SECONDS"
		noisily display as text "{hline 60}"

	}
	capture frame drop Frame_Bridge_Raw

	*-------------------------------------------------------------------------
	* PRELIMINARY: LOAD STATIC LOOKUPS INTO FRAMES TO USE IN LOOPS
	*-------------------------------------------------------------------------
	noisily display _n as text "{hline 60}"
	noisily display as result "PRELIMINARY: Loading Static Lookups into RAM Frames Useful for the Loops ..."
	noisily display as text "{hline 60}"

	* Start Timer for Phase 0
	timer clear 1
	timer on 1

	noisily display as text "Step 0: Loading Crosswalks (ISIC, WIPO, ISO, RA) and WIPO Shares... " _c

	*-------------------------
	* 1. ISIC CROSSWALK FRAME
	*-------------------------
	* Maps 1 IPC4 code to Many ISIC codes (with weights)
	frame create Frame_ISIC
	frame Frame_ISIC {
		import delimited "$data/raw/crosswalks/ipc4_to_isic_rev3_2.txt", clear 
	}

	* 2. WIPO CODES FRAME
	*-------------------------
	frame create Frame_WIPO
	frame Frame_WIPO {
		import delimited "$data/raw/crosswalks/wipo_st3", varnames(1) encoding(UTF-8) clear
		keep if iso2 != ""
	}

	* 3. ISO CODES FRAME
	*-------------------------
	frame create Frame_ISO
	frame Frame_ISO {
		import delimited "$data/raw/crosswalks/iso_codes", varnames(1) encoding(UTF-8) clear
	}

	* 4. REGIONAL AUTHORITIES FRAME (Conditional)
	*-------------------------
	frame create Frame_RA_Codes
	frame Frame_RA_Codes {
		local reg EPO EAPO OAPI ARIPO GCC
		foreach r of local reg {
			import excel "$data/raw/crosswalks/regional_authorities.xlsx", sheet("`r'") firstrow clear
			tempfile reg_`r'
			save `reg_`r''
		}

		clear
		foreach r of local reg {
			append using `reg_`r''
		}
		drop ADMIN
	}

	* 5. Calculate WIPO Shares (Condtional)
	*-------------------------
	frame create Frame_WIPO_Shares
	frame Frame_WIPO_Shares {
		import delimited "$data/raw/crosswalks/country_codes", varnames(1) encoding(UTF-8) clear 
		tempfile cou_codes
		save `cou_codes'

		import delimited "$wipo_share_data", clear
		reshape long yr, i(officecode origin) j(patents)

		merge m:1 origin using `cou_codes', nogenerate

		rename (officecode origin patents yr) (appln_auth person_ctry_code ///
			appln_filing_year wipo_patents)
		drop person_ctry_code office
		order appln_auth person_ctry_code_iso3 appln_filing_year
		drop if missing(person_ctry_code_iso3)
		sort appln_auth appln_filing_year person_ctry_code		

		drop if appln_auth == "CN" & person_ctry_code_iso3 == "CHN"

		egen auth_total = sum(wipo_patents), by(appln_auth appln_filing_year)
		gen wipo_shares = wipo_patents/auth_total
	}

	timer off 1
	timer list 1
	noisily display as result "Done. (" %5.2f r(t0) " seconds) - Completed at $S_TIME"
}
