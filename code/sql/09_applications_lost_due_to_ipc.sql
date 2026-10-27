/*****************************************************************************************
  09_pull_undefined_ipc_applications.sql
  Purpose:
    SUPPLEMENT for INPACT-S V2.2. Pulls ONLY the applications dropped by the inner
    JOIN to tls209_appln_ipc in scripts 04/06 i.e. applications that have NO IPC
    code at all and tags them with ipc_class_symbol = 'ZZZZ'.

    Output columns and copy options match the alt (DISTINCT) exports of 04/06
    exactly, so these rows can be APPENDED to the raw stack in the Stata pipeline
    (gated behind the V2.2 toggle) WITHOUT re-running 04/06 and WITHOUT overwriting
    the V2.1 outputs.

    Filters mirror 04/06 exactly (appln_kind = 'A ', 1980 to 2024, seq_nr > 0) plus a
    NOT EXISTS anti-join on tls209, so the result is the EXACT complement of the main
    extract: no overlap with what 04/06 kept, and nothing missed. The anti-join also
    prunes tls201 to the no-IPC subset BEFORE the person/publication joins run, so this
    is far cheaper than a full re-run.

  DBMS: PostgreSQL (via psql)
******************************************************************************************/

SET search_path TO :patstat_schema, public;

/* Performance (these are real joins over the large person / publication tables) */
SET work_mem = '1GB';
SET maintenance_work_mem = '2047MB';

\echo '================================================================================'
\echo 'APPLICANT SUPPLEMENT (mirrors 04_build_applications_by_applt.sql)'
\echo '================================================================================'

DROP TABLE IF EXISTS _undefined_applt;
CREATE TEMP TABLE _undefined_applt AS
SELECT DISTINCT
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
    'ZZZZ' AS ipc_class_symbol
FROM tls201_appln      AS a
JOIN tls207_pers_appln AS pa ON a.appln_id = pa.appln_id
JOIN tls206_person     AS pe ON pa.person_id = pe.person_id
JOIN tls211_pat_publn  AS pu ON a.appln_id = pu.appln_id
WHERE a.appln_filing_year BETWEEN :start_year AND :end_year
  AND a.appln_kind = 'A '
  AND pa.applt_seq_nr > 0
  AND NOT EXISTS (
        SELECT 1 FROM tls209_appln_ipc AS ip
        WHERE ip.appln_id = a.appln_id
      );

/* EXECUTE EXPORT (applications_undefined_applt.csv) */
\pset format unaligned \pset tuples_only on
\o _tmp_export_09_applt.sql
SELECT format('\copy (SELECT appln_id, person_id, earliest_pat_publn_id, appln_auth, person_ctry_code, appln_filing_year, publn_nr, publn_nr_original, publn_auth, publn_kind, ipc_class_symbol FROM _undefined_applt ORDER BY appln_id) TO ''%s/applications_undefined_tech_class_applt.csv'' CSV HEADER NULL ''  '' DELIMITER '','' ENCODING ''UTF8'';', :'outdir_lost_apps');
\o
\pset format aligned \pset tuples_only off
\i _tmp_export_09_applt.sql

\echo '================================================================================'
\echo 'INVENTOR SUPPLEMENT (mirrors 06_build_applications_by_invt.sql)'
\echo '================================================================================'

DROP TABLE IF EXISTS _undefined_invt;
CREATE TEMP TABLE _undefined_invt AS
SELECT DISTINCT
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
    'ZZZZ' AS ipc_class_symbol
FROM tls201_appln      AS a
JOIN tls207_pers_appln AS pa ON a.appln_id = pa.appln_id
JOIN tls206_person     AS pe ON pa.person_id = pe.person_id
JOIN tls211_pat_publn  AS pu ON a.appln_id = pu.appln_id
WHERE a.appln_filing_year BETWEEN :start_year AND :end_year
  AND a.appln_kind = 'A '
  AND pa.invt_seq_nr > 0
  AND NOT EXISTS (
        SELECT 1 FROM tls209_appln_ipc AS ip
        WHERE ip.appln_id = a.appln_id
      );

/* EXECUTE EXPORT (applications_undefined_invt.csv) */
\pset format unaligned \pset tuples_only on
\o _tmp_export_09_invt.sql
SELECT format('\copy (SELECT appln_id, person_id, earliest_pat_publn_id, appln_auth, person_ctry_code, appln_filing_year, publn_nr, publn_nr_original, publn_auth, publn_kind, ipc_class_symbol FROM _undefined_invt ORDER BY appln_id) TO ''%s/applications_undefined_tech_class_invt.csv'' CSV HEADER NULL ''  '' DELIMITER '','' ENCODING ''UTF8'';', :'outdir_lost_apps');
\o
\pset format aligned \pset tuples_only off
\i _tmp_export_09_invt.sql

/* Cleanup */
\! del _tmp_export_09_applt.sql 2>NUL
\! del _tmp_export_09_invt.sql 2>NUL

\echo '================================================================================'
\echo 'FINISHED'
\echo '================================================================================'
