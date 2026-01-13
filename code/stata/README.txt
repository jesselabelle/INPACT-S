################################################################################
# README: INPACT-S Patent Flow Construction Project
# Authors: Jesse LaBelle, Inmaculada Martínez-Zarzoso, Ana Maria Santacreu, and Yoto Yotov
################################################################################

TABLE OF CONTENTS
-----------------
1. PROJECT OVERVIEW & UPDATE NOTES
2. DIRECTORY STRUCTURE & REQUIREMENTS
3. CONFIGURATION GUIDELINES (MASTER SCRIPT)
4. DATA SOURCES
5. DETAILED METHODOLOGY & TECHNICAL NOTES
   5.1. Imputation Logic (deRassenfosse & Bridge)
   5.2. Fractional Counting Construction
   5.3. IPC to ISIC Conversion
   5.4. Regional Authority Dispersion
   5.5. Handling "Bad" Data & WIPO Blank Filling

================================================================================
1. PROJECT OVERVIEW & UPDATE NOTES
================================================================================

This package constructs bilateral patenting flows by inventor and applicant from 
1980-2024 (depending on input data) at the ISIC Revision 3 2-Digit industry level.

UPDATE: HIGH-PERFORMANCE COMPUTING (HPC) OPTIMIZATION
The scripts in this folder have been rewritten from the "Original" baseline to 
optimize for Stata 17 MP+ environments. Key changes include:

1. Data Frames: The code now utilizes Stata Frames to keep lookups (ISIC, WIPO, ISO) 
   and heavy datasets in RAM, reducing I/O operations and read/write times.
2. Vectorization: Loops over observations have been replaced with vectorized 
   operations (e.g., `joinby` instead of looping 1-100 for IPC conversion).
3. Modularity: The Master script now controls major/minor versioning and allows 
   users to toggle specific robustness checks (Imputation, Regional Authority, 
   WIPO filling) via global macros.

================================================================================
2. DIRECTORY STRUCTURE & REQUIREMENTS
================================================================================

Assumed Directory Structure:
/Project Root/
    /data/
        /sql_output/    <-- Input: Raw text files from SQL (PATSTAT)
        /imputed/       <-- Output: Created by these scripts
        /raw/crosswalks/ <-- Input: Helper files (WIPO, ISO, Regional Auth)
    /code/
        /stata/         <-- Place these .do files here
    /datasets/          <-- Final Output

Memory Warning:
These datasets are massive. The original scripts relied heavily on tempfiles to 
save memory. The new scripts rely on RAM (Stata Frames). Ensure your machine 
(or HPC allocation) has sufficient RAM to hold the full application stack and 
lookup tables simultaneously.

================================================================================
3. CONFIGURATION GUIDELINES (MASTER SCRIPT)
================================================================================

The `0 -- Master For Public Folder.do` script serves as the central control panel. 
You must configure the following globals before running:

1. `global sql_subfolder`: Defines the input folder name. The script automatically 
   detects the Major Version (V1, V2) based on the year in this folder name 
   (e.g., "patstat_2021" -> V1).

2. `global method_version`: Controls the Minor Version.
   - Set to `0`: Uses the Standard Method (Original).
   - Set to `1`: Activates the "Bridge" imputation method (utilizing 
     'first_and_subsequent_filings.csv' to inherit country codes from parent applications).

3. Robustness Toggles (`dr`, `ra`, `wipo`):
   The Master script runs nested loops to generate various versions of the data 
   for robustness checks:
   - `dr` (deRassenfosse): Toggle imputation on/off.
   - `ra` (Regional Authority): Toggle regional patent dispersion on/off.
   - `wipo` (WIPO Blanks): Toggle filling remaining blanks with WIPO shares on/off.

================================================================================
4. DATA SOURCES
================================================================================

1. Patent Data: PATSTAT Global (Autumn 2021 or Spring 2024/2025)
   Source: https://shop.epo.org/en/Data-and-services/PATSTAT

2. IPC - ISIC Crosswalk: Lybert and Zolas (2014)
   Source: https://sites.google.com/site/nikolaszolas/PatentCrosswalk

3. WIPO Codes: WIPO ST.3 Table
   Source: https://www.uspto.gov/patents/apply/applying-online/country-codes-wipo-st3-table

4. ISO 3-Digit Codes
   Source: https://www.iban.com/country-codes

5. WIPO Patent Data: WIPO IP Statistics Data Center
   Source: https://www3.wipo.int/ipstats/
   Note: Used for the "Blank Filling" method.

================================================================================
5. DETAILED METHODOLOGY & TECHNICAL NOTES
================================================================================

The following sections detail the logic used in the scripts. While the code comments
in the optimized scripts are brief, the methodological justifications from the 
original construction are preserved below.

--------------------------------------------------------------------------------
5.1. IMPUTATION LOGIC (Script: 1 -- deRassenfosse Imputation.do)
--------------------------------------------------------------------------------

Source Logic:
We take the output from deRassenfosse & Siegler (2019) SQL algorithms and merge 
it into our data to fill missing country codes.
- Cutoffs: We apply arbitrary cutoffs (Priority Year 1940-2025) to make the data 
  manageable, as very old patents are less relevant for current analysis.
- Cleaning: We drop country codes equal to "  " (empty strings) as the imputation 
  measure does not catch all missing values; these are useless for our purposes.

The Many-to-Many (m:m) Merge Justification:
In Step 3 of the Imputation script, you will see a `merge m:m`. 
*Why?* PATSTAT sometimes assigns "0" as the `person_id` when information is unknown. 
However, the imputation SQL code sometimes updates these IDs, meaning four inventors 
on one patent who were all "0" in the raw data might have unique IDs in the 
imputation file. 
- A 1:1 merge fails here.
- This `m:m` approach was recommended by Florian Siegler via email. 
- We tested a complex alternative dealing with "0"s separately, but results were 
  identical, confirming this method works validly for this specific dataset.

--------------------------------------------------------------------------------
5.2. FRACTIONAL COUNTING (Script: 2 -- Bilateral Patent Flows Construction.do)
--------------------------------------------------------------------------------

The Crux of the Method:
We divide each patent into as many "pieces" as possible to be distributed out.
Example: If a patent has 3 different inventors and 3 different IPC4 classes, 
there are 9 (3x3) "pieces" to be distributed.

Code Logic:
1. `ipc4count`: We calculate how often a tech class appears in an application.
2. Scaling (`mult`): We find the smallest value of an individual piece to scale 
   the total down. This is purely to make the numbers intuitive for line-by-line 
   analysis; it does not change the eventual shares.
3. `patent_share`: The share of the overall patent application pieces going to 
   each inventor/technology class. The sum of this value by `appln_id` is always 1.

--------------------------------------------------------------------------------
5.3. IPC TO ISIC CONVERSION (Script: 2 -- Step 3)
--------------------------------------------------------------------------------

We use the crosswalks created by Lybbert and Zolas (2014) to convert IPC codes 
to ISIC Rev 3 2-digit codes.

- Most IPC4 classes sort into several different ISIC codes based on probability weights.
- OPTIMIZATION NOTE: The original script used a loop (`forvalues x = 1/100`) to 
  merge these one at a time to avoid a memory-crashing m:m merge. The new script 
  uses `joinby`, which is faster but memory-intensive.

--------------------------------------------------------------------------------
5.4. REGIONAL AUTHORITY DISPERSION (Script: 2 -- Step 4)
--------------------------------------------------------------------------------

The Problem:
Groups of countries (EPO, ARIPO, etc.) form Regional Authorities (RA) to review 
patents. However, applicants usually intend to enforce patents in specific member 
countries. It is unlikely every country attracts patents from the RA equally.

The Assumption:
The relative share of patents that a country attracts *directly* is equal to the 
share it attracts from the *Regional Authority*.

Example:
Imagine the EPO only consists of Spain and Germany.
- Direct filings to Spain: 50
- Direct filings to Germany: 100
- Filings to EPO: 200

We calculate the direct shares: Spain (33%) and Germany (66%). We apply these 
shares to the EPO total.
- Spain receives extra: 200 * 0.33 = 66
- Germany receives extra: 200 * 0.66 = 132

The code calculates these `extra_patents` and adds them to the country's total. 
RA totals (e.g., "EP", "OA") are then dropped to avoid double counting.

--------------------------------------------------------------------------------
5.5. BAD DATA & WIPO BLANK FILLING (Script: 2 -- Step 5 & 6)
--------------------------------------------------------------------------------

Cleaning Typos:
PATSTAT reads full-text data, so typos exist (e.g., "EN" instead of "UK"). 
While we could guess, we choose to drop codes that do not appear in the official 
WIPO country list to ensure accuracy.

WIPO Blank Filling (Step 6):
After imputation, some country codes remain blank.
- Why not use the Regional Authority method? The data reported vs. imputed is likely 
  not a random sample. Using the RA method here would "reinforce bias" in the data.
- The Solution: We estimate based on WIPO aggregate values.
- Example: If WIPO data shows that 25% of patent applications to Canada came 
  from the US in 2015, we assign 25% of our *blank* Canadian patents to the US.
- Assumption: This share holds constant across industries.