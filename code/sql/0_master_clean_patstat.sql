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
\set patstat_schema patstat_2024spring

-- Filing-year upper bound (exclusive) for the imputation algorithm.
\set max_imputation_year_excl 2025

-- DATASET GENERATION PARAMETERS
-- Set the time window for the application/inventor CSV exports here.
\set start_year     1980
\set end_year       2024
\set interval_years 5

-- DYNAMIC PATH GENERATION (Do Not Edit)
SELECT 'data/raw/' || :'patstat_schema' AS srcdir \gset

SELECT 'data/sql_output/' || :'patstat_schema' AS outdir_sql \gset

-- V2.2 supplement for applications without an IPC classification.
SELECT :'outdir_sql' || '/lost_apps' AS outdir_lost_apps \gset

-----------------------------
-- ECHO CONFIG
-----------------------------

\echo '======================================================================================================================'
\echo 'MASTER CONFIGURATION'
\echo 'Schema:      ' :patstat_schema
\echo 'Time Window: ' :start_year ' to ' :end_year ' (Interval: ' :interval_years ')'
\echo 'Output:      ' :outdir_sql
\echo '======================================================================================================================'

-----------------------------
-- STEP 0: INITIALIZE OUTPUT ROOT
-----------------------------
-- Creates the base "patstat_2024autumn" folder so sub-scripts can make sub-folders inside it.
\pset format unaligned 
\pset tuples_only on
\o _init_root.bat
SELECT format('mkdir "%s" 2>NUL', :'outdir_sql');
SELECT format('mkdir "%s" 2>NUL', :'outdir_lost_apps');
\o
\pset format aligned 
\pset tuples_only off
\! _init_root.bat
\! del _init_root.bat 2>NUL

-----------------------------
-- STEP 1: IMPORT PATSTAT CORE TABLES
-----------------------------
\echo '======================================================================================================================'
\echo 'STEP 1: Importing PATSTAT core tables into schema ' :patstat_schema ' ...'
\echo '======================================================================================================================'
\i 'code/sql/01_import_patstat_raw_data.sql'

-----------------------------
-- STEP 2: BRIDGE FILE
-----------------------------
\echo '======================================================================================================================'
\echo 'STEP 2: Building first-and-subsequent-filings bridge...'
\echo '======================================================================================================================'
\i 'code/sql/02_bridge_first_and_subsequent_filings.sql'

-----------------------------
-- STEP 3: IMPUTE APPLICANT COUNTRY CODES
-----------------------------
\echo '======================================================================================================================'
\echo 'STEP 3: Imputing applicant country codes...'
\echo '======================================================================================================================'
\i 'code/sql/03_impute_country_codes_applt.sql'

-----------------------------
-- STEP 4: BUILD APPLICATIONS BY APPLICANT
-----------------------------
\echo '======================================================================================================================'
\echo 'STEP 4: Building applications-by-applicant...'
\echo '======================================================================================================================'

\i 'code/sql/04_build_applications_by_applt.sql'

-----------------------------
-- STEP 5: IMPUTE INVENTOR COUNTRY CODES
-----------------------------
\echo '======================================================================================================================'
\echo 'STEP 5: Imputing inventor country codes...'
\echo '======================================================================================================================'
\i 'code/sql/05_impute_country_codes_invt.sql'

-----------------------------
-- STEP 6: BUILD APPLICATIONS BY INVENTOR
-----------------------------
\echo '======================================================================================================================'
\echo 'STEP 6: Building applications-by-inventor...'
\echo '======================================================================================================================'
\i 'code/sql/06_build_applications_by_invt.sql'

-----------------------------
-- STEP 7: BUILD V2.2 NO-IPC SUPPLEMENT
-----------------------------
\echo '======================================================================================================================'
\echo 'STEP 7: Recovering applications without an IPC classification ...'
\echo '======================================================================================================================'
\i 'code/sql/09_applications_lost_due_to_ipc.sql'

-----------------------------
-- STEP 8: BUILD CITATIONS & FAMILIES DATASETS
-----------------------------
\echo '======================================================================================================================'
\echo 'STEP 8: Building citations and families datasets ...'
\echo '======================================================================================================================'
\i 'code/sql/07_build_citations_and_families.sql'

\echo 'MASTER SCRIPT COMPLETED.'
