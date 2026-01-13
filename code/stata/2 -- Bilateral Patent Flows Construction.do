quietly {

    *-------------------------------------------------------------------------
    * PHASE 1: MAIN LOOP BY TYPE (APPLT / INVT)
    *-------------------------------------------------------------------------
    foreach t in $types {
        
        noisily display _n as text "{hline 60}"
        noisily display as result "STARTING LOOP FOR TYPE: `t'"
        noisily display as text "{hline 60}"
        
        timer clear 99
        timer on 99

	*-------------------------------------------------
        * STEP 1.1: LOAD FROM RAM STORAGE
        *-------------------------------------------------
        if "$run_dr" == "1" {
            noisily display as text "Step 1.1: Loading Imputation Data from RAM Frame... " _c
            timer clear 1
            timer on 1
            
            frame change default
            capture frame drop Frame_Imputation
            
            * Check for the Storage Frame from Script 1
            capture frame change Store_Imputed_`t'
            if _rc == 0 {
                frame change default
                frame copy Store_Imputed_`t' Frame_Imputation
                
                frame Frame_Imputation {
                    sort appln_id person_id
                }
                
                timer off 1
                timer list 1
                noisily display as result "Done. (" %5.2f r(t1) " seconds) - Completed at $S_TIME"
            }
            else {
                frame change default
                noisily display as error _n "CRITICAL ERROR: RAM Frame 'Store_Imputed_`t'' not found."
                noisily display as error "Ensure you ran Script 1 in this session."
                exit 198
            }
        }

	*-------------------------------------------------
	* STEP 1.2: BATCH LOAD RAW APPLICATIONS
	*-------------------------------------------------
	noisily display as text "Step 1.2: Retrieving Raw Data from Script 1 Frame... " _c
	timer clear 2
	timer on 2

	frame change default
	clear 

	* Check if the frame exists
	capture frame change Store_Raw_`t'
	if _rc == 0 {
		frame change default
		* Copy the heavy raw data (with IPCs) into our working space
		frame copy Store_Raw_`t' default, replace
	}
	else {
		noisily display as error "Error: Frame Store_Raw_`t' not found. Run Script 1 first."
		exit
	}
        
        timer off 2
        timer list 2
        noisily display as result "Done. (" %5.2f r(t2) " seconds) - Completed at $S_TIME"

        *-----------------------------------------------------------------
        * STEP 2: FRACTIONAL COUNTING LOGIC (Vectorized)
        *-----------------------------------------------------------------
        noisily display as text "Step 2: Calculating Fractional Counts... " _c
        timer clear 3
        timer on 3
		
	gsort appln_id person_id publn_kind ipc_class_symbol -person_ctry_code
        
        * Clean IPC
        gen ipc = subinstr(ipc_class_symbol, " ", "", .) 
        gen ipc4 = substr(ipc,1,4) 
        
        drop publn* 
	duplicates drop appln_id person_id ipc_class_symbol, force
        
        * Calculate Counts
        egen ipc4count = count(ipc_class_symbol), by(appln_id ipc4) 
        
        collapse (mean) ipc4count, by(appln_id person_id ipc4 earliest_pat_publn_id appln_auth person_ctry_code appln_filing_year)
	

        * MERGE IMPUTATION (If applicable)
        if "$run_dr" == "1" {
             * Use frlink to look up the imputed country from the Frame
             frlink m:1 appln_id person_id, frame(Frame_Imputation)
             frget person_ctry_code2, from(Frame_Imputation)
             
             replace person_ctry_code = person_ctry_code2 if missing(person_ctry_code) & !missing(person_ctry_code2)
             replace person_ctry_code = trim(person_ctry_code)
             drop person_ctry_code2 Frame_Imputation
        }

        * Fractional Math (Performed on the whole stack at once)
        egen count = sum(ipc4count), by(appln_id) 
        egen mult = min(ipc4count), by(appln_id) 
        replace count = count/mult 
        replace ipc4count = ipc4count/mult 
        drop mult

        egen techcount = sum(ipc4count), by(appln_id person_id) 
        gen techshare = ipc4count/techcount 
        gen newcount = count*techshare 

        egen tag = tag(appln_id person_id) 
        egen applicants_count = total(tag), by(appln_id) 
        drop tag

        gen app_count = newcount/applicants
        gen patent_share = app_count/count 

        * Sum Fractions
        collapse (sum) patent_share, by(appln_auth person_ctry_code appln_filing_year ipc4)
	
	if "$run_dr" == "0" & "$run_ra" == "0" & "$run_wipo" == "0" {
		save "$output/fractional_method_check${version_suffix}", replace
	} 
        
        timer off 3
        timer list 3
        noisily display as result "Done. (" %5.2f r(t3) " seconds) - Completed at $S_TIME"

        *-----------------------------------------------------------------
        * STEP 3: IPC TO ISIC CONVERSION (Using joinby)
        *-----------------------------------------------------------------
        noisily display as text "Step 3: Mapping IPC to ISIC (Joinby Method)... " _c
        timer clear 4
        timer on 4
        
        * This replaces the slow 1-100 loop.
        * joinby creates a Cartesian product of patents * matching ISIC codes
	frame Frame_ISIC: save "temp_isic_dump.dta", replace
        joinby ipc4 using "temp_isic_dump.dta"
        capture erase "temp_isic_dump.dta"
        
        gen patents = patent_share * probability_weight
        
        * Final ISIC Sums
        collapse (sum) patents, by(appln_auth person_ctry_code appln_filing_year isic_rev3_2)
        
        timer off 4
        timer list 4
        noisily display as result "Done. (" %5.2f r(t4) " seconds) - Completed at $S_TIME"
		
	* Some spring cleaning
	keep isic_rev3_2 appln_auth person_ctry_code appln_filing_year patents
	order appln_auth person_ctry_code appln_filing_year isic_rev3_2 patents

        *-----------------------------------------------------------------
        * STEP 4: REGIONAL AUTHORITY DISPERSION (Conditional)
        *-----------------------------------------------------------------
        if "$run_ra" == "1" {
		noisily display as text "Step 4: Dispersing Regional Authority Patents... " _c
		timer clear 5
		timer on 5


		* Apply Shares to Authority Patents
		* Isolate RA patents (EP, OA, etc.) into a frame
		frame put if inlist(appln_auth, "OA", "AP", "EA", "EP", "GC"), into(Frame_Disperse)
		frame Frame_Disperse {
			rename appln_auth reg_auth
		}
            
		* Merge in the Regional Authority Codes 
		frlink m:1 appln_auth, frame(Frame_RA_Codes)
		frget *, from(Frame_RA_Codes)
		drop Frame_RA_Codes

		frame put *, into(Frame_Share_Calc)
		frame Frame_Share_Calc {
		
			gen member = 1 if appln_filing_year > year_joined & appln_filing_year < year_left
			keep if member == 1
			
			egen reg_patents = sum(patents), by(reg_auth person_ctry_code appln_filing_year isic_rev3_2)
			gen share = patents / reg_patents if member == 1
			
			keep appln_auth appln_filing_year person_ctry_code reg_auth share isic_rev3_2
			drop if missing(share)

			frlink m:1 reg_auth appln_filing_year person_ctry_code isic_rev3_2, frame(Frame_Disperse)
			frget *, from(Frame_Disperse)
			drop Frame_Disperse
			
			gen extra_patents = patents * share
			
			keep appln_auth person_ctry_code appln_filing_year isic_rev3_2 extra_patents
			drop if missing(extra_patents)
		}			
			
		frame Frame_Share_Calc: save "temp_extras.dta", replace
		merge 1:1 appln_auth person_ctry_code appln_filing_year isic_rev3_2 using "temp_extras.dta", nogenerate
		capture erase "temp_extras.dta"
			
		replace patents = patents + extra_patents if !missing(extra_patents)
		drop extra_patents year_joined year_left reg_auth
		drop if missing(patents)
            
		* Remove the RA aggregate lines
		drop if inlist(appln_auth, "OA", "AP", "EA", "EP", "GC")

		frame drop Frame_Share_Calc
		frame drop Frame_Disperse

		timer off 5
		timer list 5
		noisily display as result "Done. (" %5.2f r(t5) " seconds) - Completed at $S_TIME"
	}

        *-----------------------------------------------------------------
        * STEP 5: CLEANING UP BAD DATA
        *-----------------------------------------------------------------
        noisily display as text "Step 5: Cleaning Up Bad Data... " _c
        timer clear 6
        timer on 6
        
        * Clean Person Country
	rename person_ctry_code iso2 // Just rename for the merge
        frlink m:1 iso2, frame(Frame_WIPO)
        keep if !missing(Frame_WIPO) | missing(iso2)
        frget person_ctry_code_name = country, from(Frame_WIPO)
	rename iso2 person_ctry_code
	drop Frame_WIPO
        
        * Clean Auth
        rename appln_auth iso2
        frlink m:1 iso2, frame(Frame_WIPO)
        keep if !missing(Frame_WIPO)
        frget appln_auth_name = country, from(Frame_WIPO)
	rename iso2 appln_auth
	drop Frame_WIPO
        
        * ISO
        rename person_ctry_code iso2
        frlink m:1 iso2, frame(Frame_ISO)
        keep if !missing(Frame_ISO) | missing(iso2) | iso2 == "PR"
        frget person_ctry_code_iso3 = iso3, from(Frame_ISO)
        rename iso2 person_ctry_code
	drop Frame_ISO
        
        rename appln_auth iso2
        frlink m:1 iso2, frame(Frame_ISO)
        keep if !missing(Frame_ISO)
        frget appln_auth_iso3 = iso3, from(Frame_ISO)
        rename iso2 appln_auth
	drop Frame_ISO
        
	order appln_auth appln_auth_iso3 appln_auth_name person_ctry_code person_ctry_code_iso3 person_ctry_code_name
	sort appln_auth_iso3 person_ctry_code_iso3 appln_filing_year isic_rev3_2
        
        timer off 6
        timer list 6
        noisily display as result "Done. (" %5.2f r(t6) " seconds) - Completed at $S_TIME"

        *-----------------------------------------------------------------
        * STEP 6: WIPO BLANKS LOGIC (Conditional)
        *-----------------------------------------------------------------
        if "$run_wipo" == "1" {
		
		noisily display as text "Step 6: Distributing Remaining Blanks Using WIPO... " _c
		timer clear 7
		timer on 7
			    
		frlink m:1 appln_auth person_ctry_code_iso3 appln_filing_year, frame(Frame_WIPO_Shares)
		frget *, from(Frame_WIPO_Shares)
		drop Frame_WIPO_Shares

		egen auth_yr_ind_total = sum(patents) if !missing(person_ctry_code), by(appln_auth isic_rev3_2 appln_filing_year)

		sort appln_auth appln_filing_year isic_rev3_2 person_ctry_code

		gen blanks = patents if missing(person_ctry_code)
		egen fullblanks = max(blanks), by(appln_auth isic_rev3_2 appln_filing_year) 
		replace blanks = fullblanks 

		drop if missing(person_ctry_code)

		gen share_of_blanks = blanks * wipo_shares
		replace share_of_blanks = 0 if missing(share_of_blanks)

		replace patents = patents + share_of_blanks

		drop auth_yr_ind_total blanks share_of_blanks wipo_patents auth_total wipo_shares fullblanks

		timer off 7
		timer list 7
		noisily display as result "Done. (" %5.2f r(t7) " seconds) - Completed at $S_TIME"
		
        }
        
        rename patents patents_`t'
        
        *-----------------------------------------------------------------
        * SAVE OUTPUT
        *-----------------------------------------------------------------
        noisily display as text "Saving `t'..."
        
        if "$run_dr" == "1" & "$run_ra" == "1" & "$run_wipo" == "1" {
            if "`t'" == "applt" {
                save "$output/INPACT-S${version_suffix}", replace
            } 
            else {
	    	* This is for a possible future extension that is not public as of right now but may be in the future
                save "$output/forcitations", replace
            }
        }
        else {
            save "$robustness/`t'/INPACT-S_dR${run_dr}_RA${run_ra}_WIPO${run_wipo}${version_suffix}", replace
        }
        
        * End Total Timer (99)
        timer off 99
        timer list 99
        noisily display as text "{hline 60}"
        noisily display as result "COMPLETED `t' IN " %5.2f r(t99) " SECONDS at $S_TIME"
        noisily display as text "{hline 60}"
        }
    }
