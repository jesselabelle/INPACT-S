/*-------------------------------------------------------------------------
Title: deRassenfosse Imputation

Authors: Jesse LaBelle, Inmaculada Martínez-Zarzoso, Ana Maria Santacreu, and Yoto Yotov

Purpose: This takes the output of SQL code provided by deRassenfosse & Siegler (2019) and merges it into our data for the purposes of filling
in some of the missing country codes from the raw PATSTAT data

Data:

Patent data -- PATSTAT Global 2021 - single edition (Autumn) -- https://shop.epo.org/en/Data-and-services/PATSTAT/c/patstat?q=%3Arelevance%3Aperiod%3ABI_ANNUAL&text=#


Notes: These datasets are massive and the use of tempfiles increases efficiency
of the code at the sacrifice of memory. As a result this script takes a lot of
memory to run from beginning to end. Depending on the specs of your computer it
may be necessary to edit this script to save actual copies of data at different
points to successfully run this code. For example, where we save tempfiles, you
might instead save actual files with the same names depending on how much memory
your computer allows STATA to access
----------------------------------------------------------------------------*/

*-----------------------------------------------------------------
* IMPUTED COUNTRIES
*
* First, take the output from deRassanfosse's SQL method and split
* it into smaller, more manageable datasets to be used.
*------------------------------------------------------------------

foreach t in $types {

	* Get the country codes filled in following the SQL codes provided by deRassenfosse & Siegler (2019)
	import delimited "$raw_sql/ctry_`t'_person.txt", clear // This text file is created by the SQL scripts deRassenfosse_`t'_ctry_codes_imputation.SQL edited only slightly but otherwise exactly as provided by the authors
	drop priority_date source type lastupdate // Unnecessary variables
	drop if priority_year > $max_priority_year | priority_year < $min_priority_year // Some arbitrary cut offs which make the data just a little more manageable
	duplicates drop
	sort appln_id person_id
	drop if ctry_code == "  " // Their imputation measure does not catch all missing values. The ones not caught by their method are dropped here since they are of no use
	compress
	save "imputed/imputed_countries_`t'", replace
	
}

* As opposed to the next scripts, here we need to extend our data further back. The reason for this is that patents filed in 1980 might cite patents from much earlier
* so instead of using the global for this one we set a new local `years'
foreach t in $types {
	
	*-----------------------------------------------------------------
	* FILLING BLANK DATA WITH DeRASSENFOSSE IMPUTATION 
	*
	* In this next section, we impute blank person_ctry_code in the raw data 
	* using deRassanfosse method
	*------------------------------------------------------------------
	
	foreach y in $years {	
		
		*----------------------------
		*deRassanfosse imputation
		*----------------------------
		
		import delimited "$raw_sql/`t'/applications`y'.csv", clear
		replace person_ctry_code = trim(person_ctry_code)

		bys appln_id person_id: keep if _n==1 // We only need one observation per application/person

		* m:m merges are typically not recommended however the method is actually applicable and necessary here (and was recommended 
		* by Florian Siegler via email). 
		* This is a necessary process here because PATSTAT sometimes places "0" as the person_id when other info is not known and the imputation code sometimes changes
		* the person id making a 1:1 or 1:m merge impossible. This means that four inventors in one patent could all be assigned "0".
		* However, n the imputed code they 
		* will each have a unique person_id. This necessitates a m:m merge. In another version we try a much more complicated merge system which deals with the zeros 
		* separately but the values were identical confirming this method works fine.
		sort appln_id person_id
		merge m:m appln_id using "imputed/imputed_countries_`t'", keep(1 3) 
		
		gsort appln_id person_id -ctry_code
		duplicates drop appln_id person_id, force // Keep the applications with imputed countries only

		replace person_ctry_code = ctry_code if missing(person_ctry_code) & !missing(ctry_code) // Replace blank countries with the imputed country codes where possible

		drop patent_office priority_year ctry_code country
		
		rename person_ctry_code person_ctry_code2
		keep appln_id person_id person_ctry_code2 // Just need the imputed countries and some identifiers for merging
		bys appln_id person_id: keep if _n==1 // Make sure there aren't any duplicates that will bother the merge
		
		cap mkdir "imputed/yearly/"
		
		compress
		save "imputed/yearly/imputed_`t'_`y'", replace // Save this rather than tempfile because we can use it for Green and Granted scripts
		
	}
	
}