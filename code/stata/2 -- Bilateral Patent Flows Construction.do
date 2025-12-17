/*-------------------------------------------------------------------------
Title: Bilateral Patent Flows Construction

Authors: Jesse LaBelle, Inmaculada Martínez-Zarzoso, Ana Maria Santacreu, and Yoto Yotov

Purpose: Running this script will construct the bilateral patenting flows
by inventor and applicant from 1980-YYYY at the ISIC Revision 3 2-Digit 
indsutry level

Data:

Need to be placed in ./data/raw/crosswalks. You will need to grab the latest version of
WIPO from the link below. The original crosswalks are provided.

Patent data -- PATSTAT Global YYYY - single edition (Spring/Autumn) -- https://shop.epo.org/en/Data-and-services/PATSTAT/c/patstat?q=%3Arelevance%3Aperiod%3ABI_ANNUAL&text=#
IPC - ISIC crosswalk -- Lybert and Zolas (2014) -- https://sites.google.com/site/nikolaszolas/PatentCrosswalk
Regional Authority Members -- Original Data
WIPO Codes -- WIPO ST.3 Table -- https://www.uspto.gov/patents/apply/applying-online/country-codes-wipo-st3-table#heading-2
ISO 3-Digit Codes -- https://www.iban.com/country-codes
WIPO - ISO3 crosswalk -- Original Data
WIPO Patent Data -- WIPO IP Statistics Data Center -- https://www3.wipo.int/ipstats/

Notes: These datasets are massive and the use of tempfiles increases efficiency
of the code at the sacrifice of memory. As a result this script takes a lot of
memory to run from beginning to end. Depending on the specs of your computer it
may be necessary to edit this script to save actual copies of data at different
points to successfully run this code. For example, where we save tempfiles, you
might instead save actual files with the same names depending on how much memory
your computer allows STATA to access
----------------------------------------------------------------------------*/

clear all
set more off

cap mkdir ../datasets/
cap mkdir ../datasets/robustness/

foreach t in $types {
    
    *-----------------------------------------------------------------
    * CONSTRUCTING BILATERAL PATENT DATA WITH DeRASSENFOSSE IMPUTATION 
    *
    * In this next section, we apply our fractional counting method
    * from the after we impute blank person_ctry_code in the raw data 
    * using deRassanfosse method (CONDITIONAL ON $run_dr)
    *------------------------------------------------------------------
    
    foreach y in $years {   
        
        * Note: It would be possible to restructure the SQL pulls in such a way that removes the need for some of the code below, however I choose
        * to export the data as raw as possible for maximum transparency in construction and also to try out alternative methods.
        * Raw PATSTAT data
        import delimited "$raw_sql/`t'_alt/applications`y'.csv", clear //These datasets are created by the SQL scripts applications_by_`t'_alt.SQL
        replace person_ctry_code = trim(person_ctry_code)
        
        *----------------------------
        *Fractional Counting Method
        *----------------------------
        sort appln_id person_id publn_kind ipc_class_symbol
        
        gen ipc = subinstr(ipc_class_symbol, " ", "", .) // This is the full technology class code ], remove spaces because substr can be weird with spaces
    
        gen ipc4 = substr(ipc,1,4) // We group based on the first 4 characters of the technology class
        
        drop publn* // Same application can be published multiple times, drop the publication identifiers
        duplicates drop appln_id person_id ipc_class_symbol, force // Now that publication identifiers are dropped, drop duplicates
        
        egen ipc4count = count(ipc_class_symbol), by(appln_id ipc4) // We want to know how often the first 4 characters of a tech class appear in each application
        
        collapse (mean) ipc4count, by(appln_id person_id ipc4 earliest_pat_publn_id appln_auth person_ctry_code appln_filing_year) // Just collapsing on the variables we need

        *-----------------------------------------------------------------
        * ROBUSTNESS CHECK: DeRassenfosse Imputation
        * Only execute this merge if the Global flag is set to 1
        *-----------------------------------------------------------------
        if "$run_dr" == "1" {
            merge m:1 appln_id person_id using ../Data/imputed/yearly/imputed_`t'_`y', nogen keep(1 3) // Merge in new country data from previous section
            replace person_ctry_code = person_ctry_code2 if missing(person_ctry_code) & !missing(person_ctry_code2)
            replace person_ctry_code = trim(person_ctry_code)
            drop person_ctry_code2 // Don't need the imputed column anymore
        }
        
        * The crux of this method is to divide each patent into as many "pieces" as possible which will then be distributed out.
        * Ex: If a patent has 3 different invt (applt) and 3 different IPC4 classes, then there are 9 (3x3) pieces to be distributed

        egen count = sum(ipc4count),by(appln_id) // Count is the total pieces for each application
        
        egen mult = min(ipc4count), by(appln_id) // The multiplier is the smallest value of an invidiual piece, this just allows us to scale the total down without affecting the shares
        replace count = count/mult // Unscale it. The only purpose here is to make the numbers more intuitive for analyzing line-by-line if you choose too. It does not change the eventual values to skip this step
        replace ipc4count = ipc4count/mult //Unscale this too to match
        drop mult

        egen techcount = sum(ipc4count), by(appln_id person_id) // The total tech class "pieces"
        gen techshare = ipc4count/techcount // The share each tech class contributes to the overall pieces

        gen newcount = count*techshare // This is the pieces going to each tech class

        egen tag = tag(appln_id person_id) // This identifies unique inventors (applicants) from on each patent
        egen applicants_count = total(tag), by(appln_id) // Count the number of unique inventors
        drop tag

        gen app_count = newcount/applicants // The pieces each applicant (inventor) is entitiled to
        
        * If all the math is correct, then app_count should equal ipc4count because ipc4count is already collapse on the unique
        * identifying characteristics. The above serves only to explain the logic behind the calculation and check the accuracy

        gen patent_share = app_count/count // What share of the overall patent application pieces are going to each inventor/technology class. The sum of this value by appln_id should always be 1

        collapse (sum) patent_share, by(appln_auth person_ctry_code appln_filing_year ipc4) // Now we can sum these patent fractions across the bilateral relationship by year and tech class
        
        tempfile y_`y'
        save `y_`y''

    }
    
    * Append the year groupings together from previous loop
    foreach y in $years {
        append using `y_`y''
        erase `y_`y''
    }
    duplicates drop
    
    tempfile full_raw_`t'
    save `full_raw_`t''
    
    *-----------------------------------------------------------------
    * CONVERTING IPC 4-DIGIT CLASSES 
    *
    * In this next section, we use the crosswalks created by Lybbert
    * and Zolas (2014) to convert IPC codes to ISIC revision 3 2 digit codes
    *------------------------------------------------------------------
    
    * Here a m:m merge would not be acceptable to use so instead we merge one row at a time for each IPC4 classification
    import delimited crosswalks/ipc4_to_isic_rev3_2.txt, clear // IPC - ISIC crosswalk. Link above.
    forvalues x = 1/100 {
            preserve
            bys ipc4: keep if _n==`x' // Most IPC4 classes have a few different ISIC codes they sort into. Here we merge one at a time to avoid a m:m merge 
            if _N == 0 {
                restore
                continue, break
            }
            merge 1:m ipc4 using `full_raw_`t'', keep(1 3) nogenerate
            local num `x'
            tempfile ipc_`x'
            save `ipc_`x''
            restore
    }

    * Append files from the previous loop together
    clear
    forvalues x = 1/`num' {
        display "ipc_`x'"
        append using `ipc_`x''
    }
    
    gen patents = patent_share*probability_weight // Multiply our fractional patents by the probability they fall into each ISIC industry

    collapse (sum) patents, by(appln_auth person_ctry_code appln_filing_year isic_rev3_2) // Now collapse sum these patent numbers by the bilateral, yearly, industry relationships

    * Some spring cleaning
    keep isic_rev3_2 appln_auth person_ctry_code appln_filing_year patents
    order appln_auth person_ctry_code appln_filing_year isic_rev3_2 patents
    
    *-----------------------------------------------------------------
    * DISPERSING REGIONAL AUTHORITY PATENTS
    *
    * Some groups of countries form regional patent authorities which
    * take on the responsibility of reviewing granting patents.
    * However, the end goal of the applicant is to seek enforcement in certain
    * countries that take part in the regional agreement. It is highly
    * unlikely that each county attract patents to the regional authority
    * equally so we attempt to reasonably estimate where each patent is
    * inteded to be enforced. This means assigning an application to a
    * member country based on the country most likely to have attracted
    * that patent
    *
    * ROBUSTNESS CHECK:
    * This entire section is conditional on $run_ra == 1.
    * If 0, regional codes (EP, etc.) remain in the dataset.
    *------------------------------------------------------------------
    
    if "$run_ra" == "1" {
    
        * Loop through each sheet in the excel file which gives the member country and they year of ascension to that authority
        
        preserve
        local reg EPO EAPO OAPI ARIPO GCC
        foreach r of local reg{
            import excel ./crosswalks/regional_authorities.xlsx, sheet("`r'") firstrow clear // Created by authors. Data on the members of each country as well as ascension dates can be found on the website of each regional authority
            tempfile reg_`r'
            save `reg_`r''
        }

        clear
        foreach r of local reg {
            append using `reg_`r''
        }
        drop ADMIN
        tempfile regional_auth
        save `regional_auth'
        restore

        * We need the total patents to each regional authority from each origin country
        preserve
        keep if appln_auth == "OA" | appln_auth == "AP" | appln_auth == "EA" | appln_auth == "EP" | appln_auth == "GC"
        rename appln_auth reg_auth
        tempfile reg_auth_patents
        save `reg_auth_patents'
        restore
        
        * Merge in the Regional Authority Code 
        merge m:1 appln_auth using `regional_auth', nogenerate
        
        *-----------------------------------------------------------
        * Next, we calculate our estimated dispersion. The assumption here is that the relative share of patents
        * that a country attracts directly is equal to the share
        * it attracts to the regional authority. If you kept
        * only the direct patents to each member of the EPO in a year,
        * that is applications directly to Spain, directly to Germany, 
        * etc, and summed them together, each countries contribution
        * to the total is the same as their contribution to the regional
        * authority total. Example: Imagine the EPO only has Spain and 
        * Germany. If Spain had 50 patents filed directly to its office, 
        * Germany had 100, and the EPO received 200. The we take the direct
        * shares (Spain, 33% and Germany 66%) and apply those shares to
        * the EPO, so of the EPOs 200, 200*0.33 go to Spain and 200*0.66
        * go to Germany
        *-----------------------------------------------------------
        
        preserve

        gen member = 1 if appln_filing_year > year_joined & appln_filing_year < year_left // Dummy indicator for whether a country is a member of the regional authority 
        keep if member == 1 // Only interested in active regional members
        
        egen reg_patents = sum(patents), by(reg_auth person_ctry_code appln_filing_year isic_rev3_2) // Total number of direct patents to each member country directly by industry and year
        gen share = patents/reg_patents if member == 1 // Each members contribution to the total

        keep appln_auth appln_filing_year person_ctry_code reg_auth share isic_rev3_2 // All we need
        drop if share == . // If they received no patents, then we don't need them
        
        tempfile share_of_reg_auth
        save `share_of_reg_auth'

        merge m:1 reg_auth appln_filing_year person_ctry_code isic_rev3_2 using `reg_auth_patents', nogenerate // Merge with total patents filed to each authority now

        gen extra_patents = patents*share // We assume the direct share holds for the share attracted to the authority. This numbers gives the extra patents to be added to each country
        keep appln_auth person_ctry_code appln_filing_year isic_rev3_2 extra_patents
        drop if extra_patents == . // If they aren't receiving any extra patents then we do not need them
        
        tempfile extra_patents
        save `extra_patents'
        
        restore
        
        * Now we can merge these extra patents back into our data and add them together with existing patent totals
        
        merge 1:1 appln_auth appln_filing_year person_ctry_code isic_rev3_2 using `extra_patents', nogenerate
        replace patents = patents + extra_patents if extra_patents != .
        drop extra_patents year_joined year_left reg_auth
        drop if patents == .
        erase `share_of_reg_auth' 
        erase `extra_patents'
        
        drop if appln_auth == "OA" | appln_auth == "AP" | appln_auth == "EA" | appln_auth == "EP" | appln_auth == "GC" // These patent totals have been dispersed so we can get rid of them now
    
    } // End of RA Loop
    
    *-----------------------------------------------------------------
    * GETTING RID OF BAD DATA
    *
    * PATSTAT reads in the full-text data from filings. This means typos
    * on the application can make it into the raw data. For example, if 
    * someone puts EN instead of UK. It would theoretically be possible
    * to guess the most likely intended authority but we choose to drop
    * them. Here we take WIPO's official country list and merge it in
    * we drop whatever is not found in the official list
    *------------------------------------------------------------------
    
    preserve
    import delimited ./crosswalks/wipo_st3, varnames(1) encoding(UTF-8) clear // Link to source listed above
    drop if iso2 == ""
    tempfile wipo
    save `wipo'
    restore
    
    rename person_ctry_code iso2 // Just rename for the merge
    merge m:1 iso2 using `wipo' // We are careful not to use the merge options "nogen" or keep(3) here because that would also remove blank country codes which we do not want to lose
    keep if _merge == 3 | missing(iso2)
    drop _merge
    rename (iso2 country) (person_ctry_code person_ctry_code_name)
    
    rename appln_auth iso2
    merge m:1 iso2 using `wipo', nogenerate keep(3)
    rename (iso2 country) (appln_auth appln_auth_name)
    
    *------------------------------------------------------------------
    * NOW MERGE IN ISO3 CODES JUST BECAUSE WE PREFER THOSE TO ISO2
    *------------------------------------------------------------------
    
    *three digit iso_codes
    preserve
    import delimited ./crosswalks/iso_codes, varnames(1) encoding(UTF-8) clear // Link to source listed above
    tempfile iso
    save `iso'
    restore
    
    rename person_ctry_code iso2
    merge m:1 iso2 using `iso'
    keep if _merge == 3 | missing(iso2) | iso2 == "PR" // We are careful not to use the merge options "nogen" or keep(3) here because that would also remove blank country codes which we do not want to lose
    rename (iso2 iso3) (person_ctry_code person_ctry_code_iso3)
    drop _merge

    rename appln_auth iso2
    merge m:1 iso2 using `iso', nogenerate keep(3)
    rename (iso2 iso3) (appln_auth appln_auth_iso3)
    
    * Spring Cleaning
    order appln_auth appln_auth_iso3 appln_auth_name person_ctry_code person_ctry_code_iso3 person_ctry_code_name
    sort appln_auth_iso3 person_ctry_code_iso3 appln_filing_year isic_rev3_2
    
    *-----------------------------------------------------------------
    * FINALLY, WE DEAL WITH THE REMAINING BLANKS
    *
    * One possibility would be to deal with these similar to how we did
    * regional authorities. The issue with that is which patent data is
    * reported and which is imputed is likely not a random sample. Using
    * a method like that would reinforce bias in the data. We choose to
    * estimate based on WIPO value. In other words, if 25% of patent
    * applications to Canada come from the US in 2015, then we give
    * 25% of our blank Canadian patents to the US. One necessary
    * assumption is that this share holds across industries.
    *
    * ROBUSTNESS CHECK: 
    * This entire section is conditional on $run_wipo == 1.
    * If 0, blanks remain blank and Chinese exclusion is skipped.
    *------------------------------------------------------------------
    
    if "$run_wipo" == "1" {
    
        * First we want to track how many applications we fill with this method
        preserve
        
        egen totalpatents = sum(patents) // All Patents in the sample
        keep if missing(person_ctry_code) // Keep just the blank origins
        egen blankpatents = sum(patents) // All Patents in the blank sample
        collapse (mean) blankpatents totalpatents // The same for every observation so mean is just that number
        gen share = blankpatents/totalpatents // Share to be dispersed
        
        * Only export the Excel check if we are on the main run (reduces I/O overhead)
        if "$run_dr" == "1" & "$run_ra" == "1" {
             export excel using "../datasets/WIPO Blank Method `t'.xlsx", firstrow(variables) replace
        }
        
        restore
        
        preserve
        import delimited ./crosswalks/country_codes, varnames(1) encoding(UTF-8) clear // Crosswalk made by authors to go from WIPO names to ISO 3 codes
        tempfile cou_codes
        save `cou_codes'

        * WIPO IP Statistics Data Center Data
            * Indicator: Total patent applications (direct and PCT national phase entries)
            * Count by filing office and applicant's origin
            * Year range: 1980 - 2020
            
        import delimited "./raw/patent_1 - Total patent applications (direct and PCT national phase entries)_Count by filing office and applicant's origin_1980_2023", clear
        reshape long yr, i(officecode origin) j(patents) // Reshape long to match our data

        merge m:1 origin using `cou_codes', nogenerate // WIPO only gives names, we created a crosswalk from those WIPO names to ISO 3 codes

        * Some cleaning to make the data easier to use
        rename (officecode origin patents yr) (appln_auth person_ctry_code appln_filing_year wipo_patents) // Make names match PATSTAT names
        drop person_ctry_code office
        order appln_auth person_ctry_code_iso3 appln_filing_year
        drop if missing(person_ctry_code_iso3)
        sort appln_auth appln_filing_year person_ctry_code

        drop if appln_auth == "CN" & person_ctry_code_iso3 == "CHN" // deRassenfosse method does a good job with domestic Chinese patents so we assume the rest of these blanks are foreign to avoid overestimating Domestic Patents

        *get the share of each applicant country of the authority total received
        egen auth_total = sum(wipo_patents), by(appln_auth appln_filing_year) // Total Patents received by an authority
        gen wipo_shares = wipo_patents/auth_total // The shares we will use to distribute blanks

        tempfile wipo_patents
        save `wipo_patents'
        restore

        merge m:1 appln_auth person_ctry_code_iso3 appln_filing_year using `wipo_patents', nogenerate keep(1 3) // Merge in WIPO shares

        egen auth_yr_ind_total = sum(patents) if !missing(person_ctry_code), by(appln_auth isic_rev3_2 appln_filing_year) // This adds a variable that counts the total non-blank patents by application authority industry and year

        sort appln_auth appln_filing_year isic_rev3_2 person_ctry_code

        gen blanks = patents if missing(person_ctry_code)
        egen fullblanks = max(blanks), by(appln_auth isic_rev3_2 appln_filing_year) // This and the previous line tell us how many blanks exist by application authority industry and year
        replace blanks = fullblanks 
        
        drop if missing(person_ctry_code) // Don't need the blanks anymore because we saved the data necessary

        gen share_of_blanks = blanks*wipo_shares // Of those blanks, what share goes to each origin based on WIPO shares
        replace share_of_blanks = 0 if share_of_blanks == . // If it's missing then it is zero percent this just makes sure we sum by zero

        replace patents = patents+share_of_blanks // Add in each relationships share of the blank origin patents

        drop auth_yr_ind_total blanks share_of_blanks // Unneeded variables

        drop wipo_patents auth_total wipo_shares fullblanks
    
    } // End of WIPO loop
    
    rename patents patents_`t'
    
	*-----------------------------------------------------------------
    * DYNAMIC SAVING
    *
    * If this is the "Full" version (all flags = 1), save as original.
    * Otherwise, save to the Robustness folder with a suffix.
    *-----------------------------------------------------------------
    if "$run_dr" == "1" & "$run_ra" == "1" & "$run_wipo" == "1" {
        if "`t'" == "applt" {
            save "../datasets/INPACT-S", replace
        } 
        else {
            * This executes when t=invt (only happens in the Full run)
            save "forcitations", replace
        }
    }
    else {
        * Robustness runs are ALWAYS 'applt', so we don't need _`t' in the name.
        save "../datasets/robustness/INPACT-S_DR${run_dr}_RA${run_ra}_WIPO${run_wipo}", replace
    }
    
}

display "Cleaning up intermediate files..."

*------------------------------------------------------------------
* Remove the large imputation dictionaries created in Script 1
* These are heavy files only needed during the construction process.
*------------------------------------------------------------------
local files : dir "$data/imputed/yearly/" files "*.dta"
foreach f in `files' {
    capture erase "$data/imputed/yearly/`f'"
}
capture rmdir "$data/imputed/yearly"

local files : dir "$data/imputed/" files "*.dta"
foreach f in `files' {
    capture erase "$data/imputed/`f'"
}
capture rmdir "$data/imputed"