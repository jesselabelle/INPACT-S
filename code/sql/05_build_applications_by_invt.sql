/*****************************************************************************************
  05_build_applications_by_invt.sql

  Purpose:
    Construct inventor-level application datasets in 5-year filing windows.

  DBMS: PostgreSQL (via psql)
******************************************************************************************/

-- 1. Create the output folder (Windows command)
--    The '2>NUL' part hides the error if the folder already exists.
\! mkdir "data\sql_output\invt" 2>NUL
\! mkdir "data\sql_output\invt_alt" 2>NUL

SET search_path TO :patstat_schema, public;

-- 2. Performance Optimization (Tuned for 16GB RAM)
--    'work_mem': Controls speed of sorting/distinct. 1GB is safe for single-user on 16GB RAM.
--    'maintenance_work_mem': Controls speed of creating indexes.
SET work_mem = '1GB';
SET maintenance_work_mem = '2GB';

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'GENERATING YEARS 1980–1984 ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 

DROP TABLE IF EXISTS applications_full;
CREATE TEMP TABLE applications_full AS
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
WHERE a.appln_filing_year BETWEEN 1980 AND 1984
  AND a.appln_kind = 'A '  -- EXACT match to old script (Space is mandatory)
  AND pa.invt_seq_nr > 0;

-- 1) Disaggregated "alt" dataset
SELECT format('\copy (SELECT DISTINCT appln_id, person_id, earliest_pat_publn_id, appln_auth, person_ctry_code, appln_filing_year, publn_nr, publn_nr_original, publn_auth, publn_kind, ipc_class_symbol FROM applications_full ORDER BY appln_id) TO ''%s/invt_alt/applications1980_1984.csv'' CSV HEADER NULL ''  '' DELIMITER '','' ENCODING ''UTF8'';', :'outdir_sql');

-- 2) Aggregated IPC4 dataset
SELECT format('\copy ((SELECT appln_id, person_id, earliest_pat_publn_id, appln_auth, person_ctry_code, appln_filing_year, publn_nr, publn_nr_original, publn_auth, publn_kind, granted, SUBSTRING(ipc_class_symbol, 1, 4) AS ipc4, COUNT(*) AS ipc4count FROM applications_full ORDER BY appln_id) TO ''%s/invt/applications1980_1984.csv'' CSV HEADER NULL ''  '' DELIMITER '','' ENCODING ''UTF8'';', :'outdir_sql');

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'GENERATING YEARS 1985–1989 ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 

DROP TABLE IF EXISTS applications_full;
CREATE TEMP TABLE applications_full AS
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
WHERE a.appln_filing_year BETWEEN 1985 AND 1989
  AND a.appln_kind = 'A '
  AND pa.invt_seq_nr > 0;

SELECT format('\copy (SELECT DISTINCT appln_id, person_id, earliest_pat_publn_id, appln_auth, person_ctry_code, appln_filing_year, publn_nr, publn_nr_original, publn_auth, publn_kind, ipc_class_symbol FROM applications_full ORDER BY appln_id) TO ''%s/invt_alt/applications1985_1989.csv'' CSV HEADER NULL ''  '' DELIMITER '','' ENCODING ''UTF8'';', :'outdir_sql');

SELECT format('\copy ((SELECT appln_id, person_id, earliest_pat_publn_id, appln_auth, person_ctry_code, appln_filing_year, publn_nr, publn_nr_original, publn_auth, publn_kind, granted, SUBSTRING(ipc_class_symbol, 1, 4) AS ipc4, COUNT(*) AS ipc4count FROM applications_full ORDER BY appln_id) TO ''%s/invt/applications1985_1989.csv'' CSV HEADER NULL ''  '' DELIMITER '','' ENCODING ''UTF8'';', :'outdir_sql');

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'GENERATING YEARS 1990–1994 ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 

DROP TABLE IF EXISTS applications_full;
CREATE TEMP TABLE applications_full AS
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
WHERE a.appln_filing_year BETWEEN 1990 AND 1994
  AND a.appln_kind = 'A '
  AND pa.invt_seq_nr > 0;

SELECT format('\copy (SELECT DISTINCT appln_id, person_id, earliest_pat_publn_id, appln_auth, person_ctry_code, appln_filing_year, publn_nr, publn_nr_original, publn_auth, publn_kind, ipc_class_symbol FROM applications_full ORDER BY appln_id) TO ''%s/invt_alt/applications1990_1994.csv'' CSV HEADER NULL ''  '' DELIMITER '','' ENCODING ''UTF8'';', :'outdir_sql');

SELECT format('\copy ((SELECT appln_id, person_id, earliest_pat_publn_id, appln_auth, person_ctry_code, appln_filing_year, publn_nr, publn_nr_original, publn_auth, publn_kind, granted, SUBSTRING(ipc_class_symbol, 1, 4) AS ipc4, COUNT(*) AS ipc4count FROM applications_full ORDER BY appln_id) TO ''%s/invt/applications1990_1994.csv'' CSV HEADER NULL ''  '' DELIMITER '','' ENCODING ''UTF8'';', :'outdir_sql');

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'GENERATING YEARS 1995–1999 ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 

DROP TABLE IF EXISTS applications_full;
CREATE TEMP TABLE applications_full AS
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
WHERE a.appln_filing_year BETWEEN 1995 AND 1999
  AND a.appln_kind = 'A '
  AND pa.invt_seq_nr > 0;

SELECT format('\copy (SELECT DISTINCT appln_id, person_id, earliest_pat_publn_id, appln_auth, person_ctry_code, appln_filing_year, publn_nr, publn_nr_original, publn_auth, publn_kind, ipc_class_symbol FROM applications_full ORDER BY appln_id) TO ''%s/invt_alt/applications1995_1999.csv'' CSV HEADER NULL ''  '' DELIMITER '','' ENCODING ''UTF8'';', :'outdir_sql');

SELECT format('\copy ((SELECT appln_id, person_id, earliest_pat_publn_id, appln_auth, person_ctry_code, appln_filing_year, publn_nr, publn_nr_original, publn_auth, publn_kind, granted, SUBSTRING(ipc_class_symbol, 1, 4) AS ipc4, COUNT(*) AS ipc4count FROM applications_full ORDER BY appln_id) TO ''%s/invt/applications1995_1999.csv'' CSV HEADER NULL ''  '' DELIMITER '','' ENCODING ''UTF8'';', :'outdir_sql');

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'GENERATING YEARS 2000–2004 ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 

DROP TABLE IF EXISTS applications_full;
CREATE TEMP TABLE applications_full AS
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
WHERE a.appln_filing_year BETWEEN 2000 AND 2004
  AND a.appln_kind = 'A '
  AND pa.invt_seq_nr > 0;

SELECT format('\copy (SELECT DISTINCT appln_id, person_id, earliest_pat_publn_id, appln_auth, person_ctry_code, appln_filing_year, publn_nr, publn_nr_original, publn_auth, publn_kind, ipc_class_symbol FROM applications_full ORDER BY appln_id) TO ''%s/invt_alt/applications2000_2004.csv'' CSV HEADER NULL ''  '' DELIMITER '','' ENCODING ''UTF8'';', :'outdir_sql');

SELECT format('\copy ((SELECT appln_id, person_id, earliest_pat_publn_id, appln_auth, person_ctry_code, appln_filing_year, publn_nr, publn_nr_original, publn_auth, publn_kind, granted, SUBSTRING(ipc_class_symbol, 1, 4) AS ipc4, COUNT(*) AS ipc4count FROM applications_full ORDER BY appln_id) TO ''%s/invt/applications2000_2004.csv'' CSV HEADER NULL ''  '' DELIMITER '','' ENCODING ''UTF8'';', :'outdir_sql');

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'GENERATING YEARS 2005–2009 ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 

DROP TABLE IF EXISTS applications_full;
CREATE TEMP TABLE applications_full AS
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
WHERE a.appln_filing_year BETWEEN 2005 AND 2009
  AND a.appln_kind = 'A '
  AND pa.invt_seq_nr > 0;

SELECT format('\copy (SELECT DISTINCT appln_id, person_id, earliest_pat_publn_id, appln_auth, person_ctry_code, appln_filing_year, publn_nr, publn_nr_original, publn_auth, publn_kind, ipc_class_symbol FROM applications_full ORDER BY appln_id) TO ''%s/invt_alt/applications2005_2009.csv'' CSV HEADER NULL ''  '' DELIMITER '','' ENCODING ''UTF8'';', :'outdir_sql');

SELECT format('\copy ((SELECT appln_id, person_id, earliest_pat_publn_id, appln_auth, person_ctry_code, appln_filing_year, publn_nr, publn_nr_original, publn_auth, publn_kind, granted, SUBSTRING(ipc_class_symbol, 1, 4) AS ipc4, COUNT(*) AS ipc4count FROM applications_full ORDER BY appln_id) TO ''%s/invt/applications2005_2009.csv'' CSV HEADER NULL ''  '' DELIMITER '','' ENCODING ''UTF8'';', :'outdir_sql');

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'GENERATING YEARS 2010–2014 ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 

DROP TABLE IF EXISTS applications_full;
CREATE TEMP TABLE applications_full AS
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
WHERE a.appln_filing_year BETWEEN 2010 AND 2014
  AND a.appln_kind = 'A '
  AND pa.invt_seq_nr > 0;

SELECT format('\copy (SELECT DISTINCT appln_id, person_id, earliest_pat_publn_id, appln_auth, person_ctry_code, appln_filing_year, publn_nr, publn_nr_original, publn_auth, publn_kind, ipc_class_symbol FROM applications_full ORDER BY appln_id) TO ''%s/invt_alt/applications2010_2014.csv'' CSV HEADER NULL ''  '' DELIMITER '','' ENCODING ''UTF8'';', :'outdir_sql');

SELECT format('\copy ((SELECT appln_id, person_id, earliest_pat_publn_id, appln_auth, person_ctry_code, appln_filing_year, publn_nr, publn_nr_original, publn_auth, publn_kind, granted, SUBSTRING(ipc_class_symbol, 1, 4) AS ipc4, COUNT(*) AS ipc4count FROM applications_full ORDER BY appln_id) TO ''%s/invt/applications2010_2014.csv'' CSV HEADER NULL ''  '' DELIMITER '','' ENCODING ''UTF8'';', :'outdir_sql');

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'GENERATING YEARS 2015–2019 ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 

DROP TABLE IF EXISTS applications_full;
CREATE TEMP TABLE applications_full AS
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
WHERE a.appln_filing_year BETWEEN 2015 AND 2019
  AND a.appln_kind = 'A '
  AND pa.invt_seq_nr > 0;

SELECT format('\copy (SELECT DISTINCT appln_id, person_id, earliest_pat_publn_id, appln_auth, person_ctry_code, appln_filing_year, publn_nr, publn_nr_original, publn_auth, publn_kind, ipc_class_symbol FROM applications_full ORDER BY appln_id) TO ''%s/invt_alt/applications2015_2019.csv'' CSV HEADER NULL ''  '' DELIMITER '','' ENCODING ''UTF8'';', :'outdir_sql');

SELECT format('\copy ((SELECT appln_id, person_id, earliest_pat_publn_id, appln_auth, person_ctry_code, appln_filing_year, publn_nr, publn_nr_original, publn_auth, publn_kind, granted, SUBSTRING(ipc_class_symbol, 1, 4) AS ipc4, COUNT(*) AS ipc4count FROM applications_full ORDER BY appln_id) TO ''%s/invt/applications2015_2019.csv'' CSV HEADER NULL ''  '' DELIMITER '','' ENCODING ''UTF8'';', :'outdir_sql');

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'GENERATING YEARS 2020–2024 ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 

DROP TABLE IF EXISTS applications_full;
CREATE TEMP TABLE applications_full AS
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
WHERE a.appln_filing_year BETWEEN 2020 AND 2024
  AND a.appln_kind = 'A '
  AND pa.invt_seq_nr > 0;

SELECT format('\copy (SELECT DISTINCT appln_id, person_id, earliest_pat_publn_id, appln_auth, person_ctry_code, appln_filing_year, publn_nr, publn_nr_original, publn_auth, publn_kind, ipc_class_symbol FROM applications_full ORDER BY appln_id) TO ''%s/invt_alt/applications2020_2024.csv'' CSV HEADER NULL ''  '' DELIMITER '','' ENCODING ''UTF8'';', :'outdir_sql');

SELECT format('\copy ((SELECT appln_id, person_id, earliest_pat_publn_id, appln_auth, person_ctry_code, appln_filing_year, publn_nr, publn_nr_original, publn_auth, publn_kind, granted, SUBSTRING(ipc_class_symbol, 1, 4) AS ipc4, COUNT(*) AS ipc4count FROM applications_full ORDER BY appln_id) TO ''%s/invt/applications2020_2024.csv'' CSV HEADER NULL ''  '' DELIMITER '','' ENCODING ''UTF8'';', :'outdir_sql');

-- End of script