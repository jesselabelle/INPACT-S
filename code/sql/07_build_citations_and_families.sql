/*****************************************************************************************
  06_build_citations_and_families.sql
  
  Purpose: Combined script for Families and Citations.
  Note: Output files are saved directly to the sql_output folder (no subfolders).
******************************************************************************************/

SET search_path TO :patstat_schema, public;

-- 2. Performance Optimization (Tuned for 16GB RAM)
SET work_mem = '1GB';
SET maintenance_work_mem = '2047MB';

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'PART 1: FAMILIES ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 

DROP TABLE IF EXISTS families_temp;
CREATE TEMP TABLE families_temp AS
SELECT
    a.appln_id,
    a.earliest_pat_publn_id,
	a.docdb_family_id,
    p.publn_nr,
    p.publn_auth,
    p.publn_kind
FROM tls201_appln      AS a
JOIN tls211_pat_publn  AS p ON a.appln_id = p.appln_id
GROUP BY
    a.appln_id,
    a.earliest_pat_publn_id,
	a.docdb_family_id,
    p.publn_nr,
    p.publn_auth,
    p.publn_kind;

-- EXECUTE EXPORT (families.csv)
\pset format unaligned \pset tuples_only on
\o _tmp_export.sql
SELECT format('\copy families_temp TO ''%s/families.csv'' CSV HEADER NULL ''  '' DELIMITER '','' ENCODING ''UTF8'';', :'outdir_sql');
\o
\pset format aligned \pset tuples_only off
\i _tmp_export.sql

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'PART 2: CITATIONS (Full) ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 

DROP TABLE IF EXISTS citations_full_temp;
CREATE TEMP TABLE citations_full_temp AS
SELECT
    pat_publn_id,
    citn_id,
    citn_origin,
    cited_pat_publn_id,
    cited_appln_id,
    pat_citn_seq_nr,
    citn_gener_auth
FROM tls212_citation
WHERE pat_citn_seq_nr > 0
  AND citn_origin = 'APP'
ORDER BY pat_publn_id, citn_id;

-- EXECUTE EXPORT (citations_full.csv)
\pset format unaligned \pset tuples_only on
\o _tmp_export.sql
SELECT format('\copy citations_full_temp TO ''%s/citations_full.csv'' CSV HEADER NULL ''  '' DELIMITER '','' ENCODING ''UTF8'';', :'outdir_sql');
\o
\pset format aligned \pset tuples_only off
\i _tmp_export.sql

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'PART 3: CITATIONS (Slim) ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 

DROP TABLE IF EXISTS citations_slim_temp;
CREATE TEMP TABLE citations_slim_temp AS
SELECT
    p.appln_id,
    p.pat_publn_id,
    c.cited_pat_publn_id,
    c.cited_appln_id
FROM tls212_citation AS c
JOIN tls211_pat_publn AS p ON c.pat_publn_id = p.pat_publn_id
WHERE c.pat_citn_seq_nr > 0
  AND c.citn_origin = 'APP'
GROUP BY
    p.appln_id,
    p.pat_publn_id,
    c.cited_pat_publn_id,
    c.cited_appln_id;

-- EXECUTE EXPORT (citations_slim.csv)
\pset format unaligned \pset tuples_only on
\o _tmp_export.sql
SELECT format('\copy citations_slim_temp TO ''%s/citations_slim.csv'' CSV HEADER NULL ''  '' DELIMITER '','' ENCODING ''UTF8'';', :'outdir_sql');
\o
\pset format aligned \pset tuples_only off
\i _tmp_export.sql

-- Cleanup
\! del _tmp_export.sql 2>NUL
-- End of script