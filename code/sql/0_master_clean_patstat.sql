/*****************************************************************************************
 MASTER SCRIPT: build cleaned PATSTAT-based datasets

 REPLICATION INSTRUCTIONS (READ FIRST):
 --------------------------------------
 1. INSTALL POSTGRESQL:
    - Download and install from: https://www.postgresql.org/download/
    - Remember your password for the 'postgres' user.

 2. SETUP FOLDERS:
    - Ensure your project folder looks exactly like this:
      Project_Root/
      ├── code/sql/             <-- Place all .sql scripts here
      ├── data/sql_output/      <-- Create this empty folder
      └── data/raw/             
          └── patstat_2024spring/   <-- Unzip your PATSTAT CSVs here
                                        (Rename this folder if using a different vintage)

 3. CONFIGURE THIS SCRIPT:
    - Edit the "USER CONFIG" section below to match your vintage (e.g., patstat_2024spring).

 4. RUN:
    - Open your psql terminal and sign in
    - Navigate to project root: cd "path/to/project_root"
    - Run: \i code/sql/0_master_clean_patstat.sql
******************************************************************************************/

-----------------------------
-- USER CONFIG
-----------------------------

-- PATSTAT schema to use (must match your data/raw/ folder name).
-- Examples: patstat_2021autumn, patstat_2024spring
\set patstat_schema patstat_2024spring

-- Filing-year upper bound (exclusive) for the imputation algorithm.
-- For PATSTAT 2024 spring (data to 2024): 2025
\set max_imputation_year_excl 2025

-- Single output directory for ALL SQL outputs (Relative to project root)
\set outdir_sql 'data/sql_output'

-- DYNAMIC PATH GENERATION (Do Not Edit)
-- Derives srcdir from patstat_schema automatically
SELECT 'data/raw/' || :'patstat_schema' AS srcdir \gset

-----------------------------
-- ECHO CONFIG
-----------------------------

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'MASTER CONFIGURATION'
\echo 'Schema:   ' :patstat_schema
\echo 'Source:   ' :srcdir
\echo 'Output:   ' :outdir_sql
\echo '----------------------------------------------------------------------------------------------------------------------'

-----------------------------
-- STEP 1: IMPORT PATSTAT CORE TABLES
-----------------------------

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'STEP 1: Importing PATSTAT core tables into schema ' :patstat_schema ' ...'
\echo '----------------------------------------------------------------------------------------------------------------------'

-- \i 'code/sql/01_import_patstat_raw_data.sql'


-----------------------------
-- STEP 2: IMPUTE APPLICANT COUNTRY CODES
-----------------------------

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'STEP 2: Imputing applicant country codes...'
\echo '----------------------------------------------------------------------------------------------------------------------'

\i 'code/sql/02_impute_country_codes_applt.sql'


-----------------------------
-- STEP 3: IMPUTE INVENTOR COUNTRY CODES
-----------------------------

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'STEP 3: Imputing inventor country codes...'
\echo '----------------------------------------------------------------------------------------------------------------------'

\i 'code/sql/03_impute_country_codes_invt.sql'


-----------------------------
-- STEP 4: BUILD APPLICATIONS BY APPLICANT
-----------------------------

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'STEP 4: Building applications-by-applicant (5-year groups)...'
\echo '----------------------------------------------------------------------------------------------------------------------'

-- \i 'code/sql/04_build_applications_by_applt.sql'


-----------------------------
-- STEP 5: BUILD APPLICATIONS BY INVENTOR
-----------------------------

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'STEP 5: Building applications-by-inventor (5-year groups)...'
\echo '----------------------------------------------------------------------------------------------------------------------'

-- \i 'code/sql/05_build_applications_by_invt.sql'


-----------------------------
-- STEP 6: BUILD CITATIONS DATASETS
-----------------------------

-- \echo '----------------------------------------------------------------------------------------------------------------------'
-- \echo 'STEP 6: Building citations and families datasets ...'
-- \echo '----------------------------------------------------------------------------------------------------------------------'

-- \i 'code/sql/06_build_citations_and_families.sql'

\echo 'MASTER SCRIPT COMPLETED.'