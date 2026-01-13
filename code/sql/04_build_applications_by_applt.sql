/*****************************************************************************************
  04_build_applications_by_applt.sql
  Purpose:
    Construct applicant-level application datasets in dynamic filing windows.
    DEPENDENCY: Depends on :start_year, :end_year, and :interval_years set in Master.
    
  DBMS: PostgreSQL (via psql)
******************************************************************************************/

-- Dynamic Directory Creation (Inside Script)
\pset format unaligned 
\pset tuples_only on
\o _mkdir_app.bat
SELECT format('mkdir "%s\applt" 2>NUL', :'outdir_sql');
SELECT format('mkdir "%s\applt_alt" 2>NUL', :'outdir_sql');
\o
\pset format aligned 
\pset tuples_only off
\! _mkdir_app.bat
\! del _mkdir_app.bat 2>NUL

SET search_path TO :patstat_schema, public;

-- Performance Optimization
SET work_mem = '1GB';
SET maintenance_work_mem = '2047MB';

\echo '--------------------------------------------------------------------------------'
\echo 'INITIALIZING DYNAMIC GENERATION (BY APPLICANT)'
\echo 'Range: ' :start_year ' to ' :end_year ' (Step: ' :interval_years ')'
\echo '--------------------------------------------------------------------------------'

-- 3. Generate the execution script
--    Turn off formatting to write clean SQL code to file
\pset format unaligned 
\pset tuples_only on

\o _dynamic_job.sql

SELECT format($$
\echo '--------------------------------------------------------------------------------'
\echo 'PROCESSING YEARS %1$s to %2$s ...'
\echo '--------------------------------------------------------------------------------'

DROP TABLE IF EXISTS applications_current_window;
CREATE TEMP TABLE applications_current_window AS
SELECT
    a.appln_id,
    pa.person_id,
    a.earliest_pat_publn_id,
    a.appln_auth,
    pe.person_ctry_code,
    a.appln_filing_year,
    pu.publn_nr,
    pu.publn_nr_original,
    pu.publn_auth,
    pu.publn_kind,
    a.granted,
    ip.ipc_class_symbol
FROM tls201_appln      AS a
JOIN tls207_pers_appln AS pa ON a.appln_id = pa.appln_id
JOIN tls206_person     AS pe ON pa.person_id = pe.person_id
JOIN tls209_appln_ipc  AS ip ON a.appln_id = ip.appln_id
JOIN tls211_pat_publn  AS pu ON a.appln_id = pu.appln_id
WHERE a.appln_filing_year BETWEEN %1$s AND %2$s
  AND a.appln_kind = 'A '
  AND pa.applt_seq_nr > 0;

-- EXPORT 1: Distinct (applt_alt)
\copy (SELECT DISTINCT appln_id, person_id, earliest_pat_publn_id, appln_auth, person_ctry_code, appln_filing_year, publn_nr, publn_nr_original, publn_auth, publn_kind, ipc_class_symbol FROM applications_current_window ORDER BY appln_id) TO '%3$s/applt_alt/applications%1$s_%2$s.csv' CSV HEADER NULL '  ' DELIMITER ',' ENCODING 'UTF8';

-- EXPORT 2: Aggregated (applt)
\copy ((SELECT appln_id, person_id, earliest_pat_publn_id, appln_auth, person_ctry_code, appln_filing_year, publn_nr, publn_nr_original, publn_auth, publn_kind, granted, SUBSTRING(ipc_class_symbol, 1, 4) AS ipc4, COUNT(*) AS ipc4count FROM applications_current_window GROUP BY appln_id, person_id, earliest_pat_publn_id, appln_auth, person_ctry_code, appln_filing_year, publn_nr, publn_nr_original, publn_auth, publn_kind, granted, SUBSTRING(ipc_class_symbol, 1, 4) ORDER BY appln_id)) TO '%3$s/applt/applications%1$s_%2$s.csv' CSV HEADER NULL '  ' DELIMITER ',' ENCODING 'UTF8';

$$,
    g.y, 
    LEAST(g.y + :interval_years - 1, :end_year), 
    :'outdir_sql'
)
FROM generate_series(:start_year, :end_year, :interval_years) AS g(y);

-- Restore formatting for console output
\o
\pset format aligned 
\pset tuples_only off

-- 4. Execute the generated script
\i _dynamic_job.sql

-- 5. Cleanup
\! del _dynamic_job.sql 2>NUL
\echo '--------------------------------------------------------------------------------'
\echo 'FINISHED.'
\echo '--------------------------------------------------------------------------------'