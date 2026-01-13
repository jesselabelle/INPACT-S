/*****************************************************************************************
  04_first_and_subsequent_filings.sql
  Purpose:
    Create a bridge file between first filings and all subsequent filings.
    
  DBMS: PostgreSQL (via psql)
******************************************************************************************/

SET search_path TO :patstat_schema, public;

-- Performance Optimization
SET work_mem = '1GB';
SET maintenance_work_mem = '2047MB';

\echo '--------------------------------------------------------------------------------'
\echo 'ASSIGNING FAMILY IDS AND PATENT NUMBERS TO FIRST FILINGS'
\echo '--------------------------------------------------------------------------------'

DROP TABLE IF EXISTS first_and_subsequent_filings;
CREATE UNLOGGED TABLE first_and_subsequent_filings AS
SELECT DISTINCT t1.prior_appln_id, t2.*, t3.appln_auth, t3.appln_kind, t3.appln_filing_date, t3.appln_filing_year, t3.earliest_publn_date, t3.earliest_publn_year, t3.earliest_pat_publn_id, t3.granted, t3.docdb_family_id, t3.inpadoc_family_id  
FROM tls204_appln_prior t1 
JOIN tls211_pat_publn t2 ON t1.appln_id = t2.appln_id
JOIN tls201_appln t3 ON t1.appln_id = t3.appln_id
UNION
SELECT DISTINCT t1.prior_appln_id, t2.*, t3.appln_auth, t3.appln_kind, t3.appln_filing_date, t3.appln_filing_year, t3.earliest_publn_date, t3.earliest_publn_year, t3.earliest_pat_publn_id, t3.granted, t3.docdb_family_id, t3.inpadoc_family_id  
FROM tls204_appln_prior t1
JOIN tls211_pat_publn t2 ON t1.prior_appln_id = t2.appln_id
JOIN tls201_appln t3 ON t1.prior_appln_id = t3.appln_id;

\echo '--------------------------------------------------------------------------------'
\echo 'ALTER TABLE: ADD PRIORITY....'
\echo '--------------------------------------------------------------------------------'

ALTER TABLE first_and_subsequent_filings ADD COLUMN TYPE TEXT;
UPDATE first_and_subsequent_filings set TYPE = 'PRIORITY';

\echo '--------------------------------------------------------------------------------'
\echo 'INSERTING SUBSEQUENT FILINGS (1/7) ...'
\echo '--------------------------------------------------------------------------------'

INSERT INTO first_and_subsequent_filings
SELECT DISTINCT t1.appln_id, t2.*, t1.appln_auth, t1.appln_kind, t1.appln_filing_date, t1.appln_filing_year, t1.earliest_publn_date, t1.earliest_publn_year, t1.earliest_pat_publn_id, t1.granted, t1.docdb_family_id, t1.inpadoc_family_id, 'PCT'  
FROM tls201_appln t1
JOIN tls211_pat_publn t2 ON t1.appln_id = t2.appln_id
LEFT OUTER JOIN first_and_subsequent_filings t3 on t1.appln_id = t3.appln_id
WHERE internat_appln_id = 0 and t1.appln_kind = 'W' and t3.appln_id is null and t1.appln_id = t1.earliest_filing_id;

\echo '--------------------------------------------------------------------------------'
\echo 'INSERTING SUBSEQUENT FILINGS (2/7) ...'
\echo '--------------------------------------------------------------------------------'

INSERT INTO first_and_subsequent_filings
SELECT DISTINCT t1.internat_appln_id, t2.*, t1.appln_auth, t1.appln_kind, t1.appln_filing_date, t1.appln_filing_year, t1.earliest_publn_date, t1.earliest_publn_year, t1.earliest_pat_publn_id, t1.granted, t1.docdb_family_id, t1.inpadoc_family_id, 'PCT'  
FROM tls201_appln t1
JOIN tls211_pat_publn t2 ON t1.appln_id = t2.appln_id
JOIN first_and_subsequent_filings t3 on t1.internat_appln_id = t3.prior_appln_id
WHERE internat_appln_id != 0 and (t1.reg_phase = 'Y' or t1.nat_phase = 'Y')  
and t3.TYPE = 'PCT';

\echo '--------------------------------------------------------------------------------'
\echo 'INSERTING SUBSEQUENT FILINGS (3/7) ...'
\echo '--------------------------------------------------------------------------------'


INSERT INTO first_and_subsequent_filings
SELECT DISTINCT t1.parent_appln_id, t2.*, t3.appln_auth, t3.appln_kind, t3.appln_filing_date, t3.appln_filing_year, t3.earliest_publn_date, t3.earliest_publn_year, t3.earliest_pat_publn_id, t3.granted, t3.docdb_family_id, t3.inpadoc_family_id, 'CONTINUAL'  
FROM TLS216_APPLN_CONTN t1
JOIN tls211_pat_publn t2 ON t1.parent_appln_id = t2.appln_id
JOIN tls201_appln t3 ON t1.parent_appln_id = t3.appln_id
LEFT OUTER JOIN first_and_subsequent_filings t4 on t1.parent_appln_id = t4.appln_id
WHERE t4.appln_id is null;

\echo '--------------------------------------------------------------------------------'
\echo 'INSERTING SUBSEQUENT FILINGS (4/7) ...'
\echo '--------------------------------------------------------------------------------'

INSERT INTO first_and_subsequent_filings
SELECT DISTINCT t1.parent_appln_id, t2.*, t3.appln_auth, t3.appln_kind, t3.appln_filing_date, t3.appln_filing_year, t3.earliest_publn_date, t3.earliest_publn_year, t3.earliest_pat_publn_id, t3.granted, t3.docdb_family_id, t3.inpadoc_family_id, 'CONTINUAL'  
FROM TLS216_APPLN_CONTN t1
JOIN tls211_pat_publn t2 ON t1.appln_id = t2.appln_id
JOIN tls201_appln t3 ON t1.appln_id = t3.appln_id
JOIN first_and_subsequent_filings t4 on t1.parent_appln_id = t4.prior_appln_id;

\echo '--------------------------------------------------------------------------------'
\echo 'INSERTING SUBSEQUENT FILINGS (5/7) ...'
\echo '--------------------------------------------------------------------------------'

INSERT INTO first_and_subsequent_filings
SELECT DISTINCT t1.tech_rel_appln_id, t2.*, t3.appln_auth, t3.appln_kind, t3.appln_filing_date, t3.appln_filing_year, t3.earliest_publn_date, t3.earliest_publn_year, t3.earliest_pat_publn_id, t3.granted, t3.docdb_family_id, t3.inpadoc_family_id, 'TECH_REL'  
FROM TLS205_TECH_REL t1
JOIN tls211_pat_publn t2 ON t1.tech_rel_appln_id = t2.appln_id
JOIN tls201_appln t3 ON t1.tech_rel_appln_id = t3.appln_id
LEFT OUTER JOIN first_and_subsequent_filings t4 on t1.tech_rel_appln_id = t4.appln_id
WHERE t4.appln_id is null;

\echo '--------------------------------------------------------------------------------'
\echo 'INSERTING SUBSEQUENT FILINGS (6/7) ...'
\echo '--------------------------------------------------------------------------------'

INSERT INTO first_and_subsequent_filings
SELECT DISTINCT t1.tech_rel_appln_id, t2.*, t3.appln_auth, t3.appln_kind, t3.appln_filing_date, t3.appln_filing_year, t3.earliest_publn_date, t3.earliest_publn_year, t3.earliest_pat_publn_id, t3.granted, t3.docdb_family_id, t3.inpadoc_family_id, 'TECH_REL'  
FROM TLS205_TECH_REL t1
JOIN tls211_pat_publn t2 ON t1.appln_id = t2.appln_id
JOIN tls201_appln t3 ON t1.appln_id = t3.appln_id
JOIN first_and_subsequent_filings t4 on t1.tech_rel_appln_id = t4.prior_appln_id;

\echo '--------------------------------------------------------------------------------'
\echo 'INSERTING SUBSEQUENT FILINGS [Singletons] (7/7) ...'
\echo '--------------------------------------------------------------------------------'

-- Singletons

INSERT INTO first_and_subsequent_filings
SELECT DISTINCT t1.appln_id, t2.*, t1.appln_auth, t1.appln_kind, t1.appln_filing_date, t1.appln_filing_year, t1.earliest_publn_date, t1.earliest_publn_year, t1.earliest_pat_publn_id, t1.granted, t1.docdb_family_id, t1.inpadoc_family_id, 'SINGLE' 
FROM tls201_appln t1
JOIN tls211_pat_publn t2 ON t1.appln_id = t2.appln_id
JOIN (select docdb_family_id
from tls201_appln
group by docdb_family_id
having count(distinct appln_id) = 1) as t3
on t1.docdb_family_id = t3.docdb_family_id
LEFT OUTER JOIN first_and_subsequent_filings t4 on t1.appln_id = t4.appln_id
WHERE t4.appln_id is null;

\echo '--------------------------------------------------------------------------------'
\echo 'CREATING INDICES ...'
\echo '--------------------------------------------------------------------------------'

CREATE INDEX first_and_subsequent_filings_prior_appln_id on first_and_subsequent_filings(prior_appln_id);
CREATE INDEX first_and_subsequent_filings_appln_id on first_and_subsequent_filings(appln_id);

\echo '--------------------------------------------------------------------------------'
\echo 'ALTER TABLE: ADD LAST UPDATE TIMESTAMP....'
\echo '--------------------------------------------------------------------------------'

ALTER TABLE first_and_subsequent_filings ADD COLUMN lastupdate TIMESTAMP; 
UPDATE first_and_subsequent_filings SET lastupdate = CURRENT_TIMESTAMP;  

\echo '--------------------------------------------------------------------------------'
\echo 'EXPORTING DATA...'
\echo '--------------------------------------------------------------------------------'

-- Configure output
\pset format unaligned
\pset tuples_only on

-- Redirect to temp file
\o _tmp_export_bridge.sql

-- Generate the \copy command with the dynamic output path
SELECT format('\echo ''Exporting to: %s/imputed/first_and_subsequent_filings.csv''', :'outdir_sql');
SELECT format('\copy (SELECT * FROM first_and_subsequent_filings) TO ''%s/imputed/first_and_subsequent_filings.csv'' CSV HEADER NULL ''  '' DELIMITER '','' ENCODING ''UTF8'';', :'outdir_sql');

-- Reset output
\o
\pset format aligned
\pset tuples_only off

-- Execute the generated command
\i _tmp_export_bridge.sql

\echo '--------------------------------------------------------------------------------'
\echo 'FINISHED.'
\echo '--------------------------------------------------------------------------------'

-- Cleanup
\! del _tmp_export_bridge.sql 2>NUL