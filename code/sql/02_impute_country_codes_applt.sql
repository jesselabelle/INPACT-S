/***************************************************************************************************************************
 
  Algorithm to impute missing country codes of priority filings by applicants from subsequent filings
   
  This code builds on the work of: G. de Rassenfosse (EPFL Switzerland)
  It was written by Florian Seliger in February 2019 using PostgreSQL and Patstat Spring 2019.
 
  Please acknowledge the work and cite the companion paper:
  de Rassenfosse, G., Dernis, H., Guellec, D., Picci, L., van Pottelsberghe de la Potterie, B., 2013. 
  The worldwide count of priority patents: A new indicator of inventive activity. Research Policy
 
  Florian Seliger would like to thank Charles Clavadetscher (KOF ETHZ) and Matthias Bannert (KOF ETHZ) for their help.
 
  Description : PostgreSQL code for PATSTAT to impute missing country information (country) for priority filings based on the applicant criterion. 
  When the information on applicants' country codes is missing, the algorithm looks into direct equivalents and other subsequent filings for the information. 
  Information can also be retrieved from inventors' country code.
 
 NOTE: 
  - In contrast to prior versions of this code, we do not apply any filters on publication kind codes and years. The only filter is on patent offices (see below).
    Patstat may not be complete for early and recent years and the resulting data need to be checked critically against this! 
  - We also include filings where the publication information is missing in Patstat for whatever reasons.
  - You can re-activate all filters if needed. The code is simply commented out.  
  - In contrast to prior versions, we include the person_id from Patstat in the output file. The person_id may be useful for some purposes, but it does not allow to trace inventors over time.
 
  Output: table PF_APP_PERS_CTRY. The field 'source' indicates where the information on
  applicants come from :  1 = information available from the patent itself
                          2 = information availabe from the earliest direct equivalent
                          3 = information available from the earliest subsequent filing
                            4 = inventors' information from the patent itself 
                            5 = inventors' information from earliest direct equivalent
                            6 = inventors' information from earliest subsequent filing
                         
  The following 52 patent offices are browsed (EU27 + OECD + BRICS + EPO + WIPO): 
  AL,AT,AU,BE,BG,BR,CA,CH,CL,CN,CY,CZ,DE,DK,EE,EP,ES,FI,FR,GB,GR,HR, HU,IB,IE,IL,IN,IS,IT,JP,KR,LT,LU,LV,MK,MT,MX,NL,NO,NZ,PL,PT,RO,RS,RU,SE,SI,SK,SM,TR,US,ZA.
 
******************************************************************************************/

-- 1. Create the output folder (Windows command)
--    The '2>NUL' part hides the error if the folder already exists.
\! mkdir "data\sql_output\imputed" 2>NUL

SET search_path TO :patstat_schema, public;

-- 2. Performance Optimization (Tuned for 16GB RAM)
SET work_mem = '1GB';
SET maintenance_work_mem = '2GB';

/*
  CREATE ALL TABLES NEEDED
*/


\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'CREATING po (TABLE 1/27) ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 
 
-- table containing the patent offices to browse
DROP TABLE IF EXISTS po;
CREATE UNLOGGED TABLE po (
patent_office CHAR(2) DEFAULT NULL
) ; 
INSERT INTO po VALUES ('AL'), ('AT'), ('AU'), ('BE'), ('BG'),('BR'), ('CA'), ('CH'), ('CL'), ('CN'),('CY'), ('CZ'), ('DE'), ('DK'), ('EE'), ('EP'), ('ES'), ('FI'), ('FR'), ('GB'), ('GR'), ('HR'), ('HU'),('IB'), ('IE'), ('IL'), ('IN'), ('IS'), ('IT'), ('JP'), ('KR'), ('LT'), ('LU'), ('LV'), ('MK'), ('MT'), ('MX'), ('NL'), ('NO'), ('NZ'), ('PL'), ('PT'), ('RO'), ('RS'), ('RU'), ('SE'), ('SI'), ('SK'), ('SM'), ('TR'), ('US'), ('ZA');
CREATE INDEX po_idx ON po USING btree (patent_office);
 
-- table containing the appln_id to exclude from the analysis (e.g. petty patents) for a given patent office

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'CREATING toExclude (TABLE 2/27) ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 
 
DROP TABLE IF EXISTS toExclude;
CREATE UNLOGGED TABLE toExclude AS
SELECT DISTINCT appln_id, publn_auth, publn_kind FROM tls211_pat_publn
WHERE 
(publn_auth='AU' AND (publn_kind='A3' OR publn_kind='B3' OR publn_kind='B4' OR publn_kind='C1'
OR publn_kind='C4' OR publn_kind='D0'))
OR 
(publn_auth='BE' AND (publn_kind='A6' OR publn_kind='A7'))
OR 
(publn_auth='FR' AND (publn_kind='A3' OR publn_kind='A4' OR publn_kind='A7'))
OR
(publn_auth='IE' AND (publn_kind='A2' OR publn_kind='B2'))
OR
(publn_auth='NL' AND publn_kind='C1')
OR 
(publn_auth='SI' AND publn_kind='A2')
OR
(publn_auth='US' AND (publn_kind='E' OR publn_kind='E1' OR publn_kind='H' OR publn_kind='H1' OR publn_kind='I4' 
OR publn_kind='P' OR publn_kind='P1' OR publn_kind='P2' OR publn_kind='P3' OR publn_kind='S1'))
; 
CREATE INDEX exclude_idx ON toExclude USING btree (appln_id);
 
-- Table containing the priority filings of a given (patent office, year)

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'CREATING PRIORITY_FILINGS_app (TABLE 3/27) ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 

DROP TABLE IF EXISTS PRIORITY_FILINGS_app;
CREATE UNLOGGED TABLE PRIORITY_FILINGS_app (
appln_id INT,
appln_kind CHAR,
person_id INT,
patent_office VARCHAR(2),
appln_filing_year INT,
appln_filing_date DATE,
type TEXT
  );
  
\echo '----------------------------------------------------------------------------------------------------------------------'
\echo '-----INSERTING INTO PRIORITY_FILINGS_app (INSERT 1/9) ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 

INSERT INTO PRIORITY_FILINGS_app
SELECT DISTINCT t1.appln_id, t1.appln_kind, t6.person_id, t1.appln_auth, t1.appln_filing_year, t1.appln_filing_date, 'priority'
FROM tls201_appln t1 
JOIN tls204_appln_prior t2 ON t1.appln_id = t2.prior_appln_id
JOIN po t5 ON t1.appln_auth = t5.patent_office
JOIN tls207_pers_appln t6 ON t1.appln_id = t6.appln_id
WHERE (t1.appln_kind != 'W ')
AND t1.internat_appln_id = 0
AND applt_seq_nr > 0
AND t1.appln_filing_year >=1939 AND t1.appln_filing_year<:max_imputation_year_excl;

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo '-----INSERTING INTO PRIORITY_FILINGS_app (INSERT 2/9) ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 

INSERT INTO PRIORITY_FILINGS_app 
SELECT DISTINCT t1.appln_id, t1.appln_kind, t6.person_id, t1.appln_auth, t1.appln_filing_year, t1.appln_filing_date, 'priority'
FROM tls201_appln t1 
JOIN tls204_appln_prior t2 ON t1.appln_id = t2.prior_appln_id
JOIN po t5 ON t1.receiving_office = t5.patent_office
JOIN tls207_pers_appln t6 ON t1.appln_id = t6.appln_id
WHERE (t1.appln_kind = 'W ')
AND t1.internat_appln_id = 0
AND applt_seq_nr > 0
AND t1.appln_filing_year >=1939 AND t1.appln_filing_year<:max_imputation_year_excl;

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo '-----INSERTING INTO PRIORITY_FILINGS_app (INSERT 3/9) ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 
 
INSERT INTO PRIORITY_FILINGS_app
SELECT DISTINCT t1.appln_id, t1.appln_kind, t6.person_id, t1.appln_auth AS patent_office, t1.appln_filing_year, t1.appln_filing_date, 'pct'
FROM tls201_appln t1 
JOIN po t5 ON t1.receiving_office = t5.patent_office
JOIN tls207_pers_appln t6 ON t1.appln_id = t6.appln_id
  LEFT OUTER JOIN PRIORITY_FILINGS_app t7 on t1.appln_id = t7.appln_id 
WHERE (t1.appln_kind = 'W ')
AND t1.internat_appln_id = 0 and nat_phase = 'N' and reg_phase = 'N'
AND t1.appln_id = t1.earliest_filing_id
AND applt_seq_nr > 0
AND t1.appln_filing_year >=1939 AND t1.appln_filing_year<:max_imputation_year_excl
AND t7.appln_id is null;

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo '-----INSERTING INTO PRIORITY_FILINGS_app (INSERT 4/9) ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 

INSERT INTO PRIORITY_FILINGS_app
SELECT DISTINCT t1.appln_id, t1.appln_kind, t6.person_id, t1.appln_auth, t1.appln_filing_year, t1.appln_filing_date, 'continual'
FROM tls201_appln t1 
JOIN tls216_appln_contn t2 ON t1.appln_id = t2.parent_appln_id
JOIN po t5 ON t1.appln_auth = t5.patent_office
JOIN tls207_pers_appln t6 ON t1.appln_id = t6.appln_id
    LEFT OUTER JOIN PRIORITY_FILINGS_app t7 on t1.appln_id = t7.appln_id 
WHERE (t1.appln_kind != 'W ')
AND t1.internat_appln_id = 0
AND applt_seq_nr > 0
AND t1.appln_filing_year >=1939 AND t1.appln_filing_year<:max_imputation_year_excl
AND t7.appln_id is null
;

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo '-----INSERTING INTO PRIORITY_FILINGS_app (INSERT 5/9) ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 

INSERT INTO PRIORITY_FILINGS_app
SELECT DISTINCT t1.appln_id, t1.appln_kind, t6.person_id, t1.appln_auth, t1.appln_filing_year, t1.appln_filing_date, 'continual'
FROM tls201_appln t1 
JOIN tls216_appln_contn t2 ON t1.appln_id = t2.parent_appln_id
JOIN po t5 ON t1.receiving_office = t5.patent_office
JOIN tls207_pers_appln t6 ON t1.appln_id = t6.appln_id
      LEFT OUTER JOIN PRIORITY_FILINGS_app t7 on t1.appln_id = t7.appln_id 
WHERE (t1.appln_kind = 'W ')
AND t1.internat_appln_id = 0
AND applt_seq_nr > 0
AND t1.appln_filing_year >=1939 AND t1.appln_filing_year<:max_imputation_year_excl
AND t7.appln_id is null
;

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo '-----INSERTING INTO PRIORITY_FILINGS_app (INSERT 6/9) ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 

INSERT INTO PRIORITY_FILINGS_app
SELECT DISTINCT t1.appln_id, t1.appln_kind, t6.person_id, t1.appln_auth, t1.appln_filing_year, t1.appln_filing_date, 'tech_rel'
FROM tls201_appln t1 
JOIN tls205_tech_rel t2 ON t1.appln_id = t2.tech_rel_appln_id
JOIN po t5 ON t1.appln_auth = t5.patent_office
JOIN tls207_pers_appln t6 ON t1.appln_id = t6.appln_id
      LEFT OUTER JOIN PRIORITY_FILINGS_app t7 on t1.appln_id = t7.appln_id 
WHERE (t1.appln_kind != 'W ')
AND t1.internat_appln_id = 0
AND applt_seq_nr > 0
AND t1.appln_filing_year >=1939 AND t1.appln_filing_year<:max_imputation_year_excl
AND t7.appln_id is null
;

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo '-----INSERTING INTO PRIORITY_FILINGS_app (INSERT 7/9) ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 

INSERT INTO PRIORITY_FILINGS_app 
SELECT DISTINCT t1.appln_id, t1.appln_kind, t6.person_id, t1.appln_auth, t1.appln_filing_year, t1.appln_filing_date, 'tech_rel'
FROM tls201_appln t1 
JOIN tls205_tech_rel t2 ON t1.appln_id = t2.tech_rel_appln_id
JOIN po t5 ON t1.receiving_office = t5.patent_office
JOIN tls207_pers_appln t6 ON t1.appln_id = t6.appln_id
      LEFT OUTER JOIN PRIORITY_FILINGS_app t7 on t1.appln_id = t7.appln_id 
WHERE (t1.appln_kind = 'W ')
AND t1.internat_appln_id = 0
AND applt_seq_nr > 0
AND t1.appln_filing_year >=1939 AND t1.appln_filing_year<:max_imputation_year_excl
AND t7.appln_id is null
;

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo '-----INSERTING INTO PRIORITY_FILINGS_app (INSERT 8/9) ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 

-- Singletons
INSERT INTO PRIORITY_FILINGS_app
SELECT DISTINCT t1.appln_id, t1.appln_kind, t6.person_id, t1.appln_auth, t1.appln_filing_year, t1.appln_filing_date, 'single'
FROM tls201_appln t1 
JOIN (SELECT docdb_family_id from tls201_appln group by docdb_family_id having count(distinct appln_id) = 1) as t2
ON t1.docdb_family_id = t2.docdb_family_id
  JOIN po t5 ON t1.appln_auth = t5.patent_office
JOIN tls207_pers_appln t6 ON t1.appln_id = t6.appln_id
      LEFT OUTER JOIN PRIORITY_FILINGS_app t7 on t1.appln_id = t7.appln_id 
WHERE (t1.appln_kind != 'W ')
AND t1.internat_appln_id = 0
AND applt_seq_nr > 0
AND t1.appln_filing_year >=1939 AND t1.appln_filing_year<:max_imputation_year_excl
AND t7.appln_id is null
;

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo '-----INSERTING INTO PRIORITY_FILINGS_app (INSERT 9/9) ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 

INSERT INTO PRIORITY_FILINGS_app 
SELECT DISTINCT t1.appln_id, t1.appln_kind, t6.person_id, t1.appln_auth, t1.appln_filing_year, t1.appln_filing_date, 'single'
FROM tls201_appln t1 
JOIN (SELECT docdb_family_id from tls201_appln group by docdb_family_id having count(distinct appln_id) = 1) as t2
ON t1.docdb_family_id = t2.docdb_family_id
JOIN po t5 ON t1.receiving_office = t5.patent_office
JOIN tls207_pers_appln t6 ON t1.appln_id = t6.appln_id
      LEFT OUTER JOIN PRIORITY_FILINGS_app t7 on t1.appln_id = t7.appln_id 
WHERE (t1.appln_kind = 'W ')
AND t1.internat_appln_id = 0
AND applt_seq_nr > 0
AND t1.appln_filing_year >=1939 AND t1.appln_filing_year<:max_imputation_year_excl
AND t7.appln_id is null
;

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo '-----CREATE PRIORITY_FILINGS_app INDICES ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 

CREATE INDEX pfa_idx ON PRIORITY_FILINGS_app USING btree (appln_id);
CREATE INDEX pfa_idx2 ON PRIORITY_FILINGS_app USING btree (patent_office);
CREATE INDEX pfa_idx3 ON PRIORITY_FILINGS_app USING btree (appln_filing_year);

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'VACUUMING ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 

VACUUM ANALYZE PRIORITY_FILINGS_app;

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'CREATING country_codes_inv (TABLE 4/27) ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 
 
DROP TABLE IF EXISTS country_codes_inv;
CREATE UNLOGGED TABLE country_codes_inv AS
SELECT DISTINCT t1.appln_id, t1.person_id, t2.person_ctry_code AS ctry_code 
FROM tls207_pers_appln t1
JOIN tls206_person t2 ON t1.person_id = t2.person_id
WHERE invt_seq_nr > 0;

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'CREATING country_codes_app (TABLE 5/27) ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 

DROP TABLE IF EXISTS country_codes_app;
CREATE UNLOGGED TABLE country_codes_app AS
SELECT DISTINCT t1.appln_id, t1.person_id, t2.person_ctry_code AS ctry_code 
FROM tls207_pers_appln t1
JOIN tls206_person t2 ON t1.person_id = t2.person_id
WHERE applt_seq_nr > 0;

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo '-----CREATE country_codes_inv & country_codes_app INDICES ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 

CREATE INDEX country_codes_inv_idx ON country_codes_inv USING btree (appln_id);
CREATE INDEX country_codes_app_idx ON country_codes_app USING btree (appln_id);                  
CREATE INDEX country_codes_pers_inv_idx ON country_codes_inv USING btree (person_id);
CREATE INDEX country_codes_pers_app_idx ON country_codes_app USING btree (person_id);  

 
/* Create the tables that will be used to impute missing information
*/
 
-- Applicant information

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'APPLICANT INFORMATION'
\echo '----------------------------------------------------------------------------------------------------------------------' 

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'CREATING PRIORITY_FILINGS1 (TABLE 6/27) ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 
 
-- A. Information that is directly available (source = 1)
DROP TABLE IF EXISTS PRIORITY_FILINGS1;
CREATE UNLOGGED TABLE PRIORITY_FILINGS1 AS (
-- first of all we need all priority filings with address information in Patstat and country information
SELECT DISTINCT t1.appln_id, t1.person_id, t1.patent_office, t1.appln_filing_date, t1.appln_filing_year, ctry_code, type
FROM PRIORITY_FILINGS_app t1 
LEFT OUTER JOIN country_codes_app t2 ON t1.appln_id = t2.appln_id AND t1.person_id = t2.person_id) ;

CREATE INDEX pri1_idx ON PRIORITY_FILINGS1 USING btree (appln_id);
CREATE INDEX pri1_pers_idx ON PRIORITY_FILINGS1 USING btree (person_id);
CREATE INDEX pri1_office_idx ON PRIORITY_FILINGS1 USING btree (patent_office);
CREATE INDEX pri1_year_idx ON PRIORITY_FILINGS1 USING btree (appln_filing_year);

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo '-----CREATING t (from PRIORITY_FILINGS1) (TABLE 7/27) ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 
 
-- B. Prepare a pool of all potential second filings
DROP TABLE IF EXISTS t;
CREATE UNLOGGED TABLE t AS
SELECT t1.appln_id, t3.appln_id AS subsequent_id, t3.appln_filing_date AS subsequent_date, max(t4.prior_appln_seq_nr) AS nb_priorities
FROM PRIORITY_FILINGS_app t1 
INNER JOIN tls204_appln_prior t2 ON t2.prior_appln_id = t1.appln_id
INNER JOIN tls201_appln t3 ON t3.appln_id = t2.appln_id
INNER JOIN tls204_appln_prior t4 ON t4.appln_id = t3.appln_id
WHERE type = 'priority'
GROUP BY t1.appln_id, t3.appln_id, t3.appln_filing_date ;
CREATE INDEX t_appln_id ON t(appln_id);  

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'CREATING SUBSEQUENT_FILINGS1 (TABLE 8/27) ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 

DROP TABLE IF EXISTS SUBSEQUENT_FILINGS1;
CREATE UNLOGGED TABLE SUBSEQUENT_FILINGS1 AS (
SELECT DISTINCT t1.appln_id, t.subsequent_id, t2.person_id as subsequent_person_id, applt_seq_nr, invt_seq_nr, t1.patent_office, t1.appln_filing_year, t.subsequent_date, t.nb_priorities, type
FROM PRIORITY_FILINGS_app t1 
JOIN t ON (t1.appln_id = t.appln_id )
JOIN tls207_pers_appln t2 ON (t.subsequent_id = t2.appln_id)
ORDER BY t1.appln_id, t.subsequent_date, t2.person_id, applt_seq_nr, invt_seq_nr ASC);

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo '-----CREATING t (from PRIORITY_FILINGS_app) (TABLE 9/27) ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 

DROP TABLE t;
CREATE UNLOGGED TABLE t AS
SELECT t1.appln_id, t3.appln_id AS subsequent_id, t3.appln_filing_date AS subsequent_date, max(count) AS nb_priorities
FROM PRIORITY_FILINGS_app t1 
INNER JOIN tls216_appln_contn t2 ON t2.parent_appln_id = t1.appln_id
INNER JOIN tls201_appln t3 ON t3.appln_id = t2.appln_id
INNER JOIN (select appln_id, count(*) from tls216_appln_contn group by appln_id) as t4 ON t4.appln_id = t3.appln_id
WHERE type = 'continual'
GROUP BY t1.appln_id, t3.appln_id, t3.appln_filing_date ;
CREATE INDEX t_appln_id ON t(appln_id);      

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo '-----INSERTING INTO SUBSEQUENT_FILINGS1 (INSERT 1/4) ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 

INSERT INTO SUBSEQUENT_FILINGS1
SELECT DISTINCT t1.appln_id, t.subsequent_id, t2.person_id as subsequent_person_id, applt_seq_nr, invt_seq_nr, t1.patent_office, t1.appln_filing_year, t.subsequent_date, t.nb_priorities, type
FROM PRIORITY_FILINGS_app t1 
JOIN t ON (t1.appln_id = t.appln_id )
JOIN tls207_pers_appln t2 ON (t.subsequent_id = t2.appln_id)
ORDER BY t1.appln_id, t.subsequent_date, t2.person_id, applt_seq_nr, invt_seq_nr ASC;

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo '-----CREATING t (from PRIORITY_FILINGS_app) (TABLE 10/27) ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 

DROP TABLE t;
CREATE UNLOGGED TABLE t AS
SELECT t1.appln_id, t3.appln_id AS subsequent_id, t3.appln_filing_date AS subsequent_date, max(count) AS nb_priorities
FROM PRIORITY_FILINGS_app t1 
INNER JOIN TLS205_TECH_REL t2 ON t2.tech_rel_appln_id = t1.appln_id
INNER JOIN tls201_appln t3 ON t3.appln_id = t2.appln_id
INNER JOIN (select appln_id, count(*) from TLS205_TECH_REL group by appln_id) as t4 ON t4.appln_id = t3.appln_id
WHERE type = 'tech_rel'
GROUP BY t1.appln_id, t3.appln_id, t3.appln_filing_date ;
CREATE INDEX t_appln_id ON t(appln_id);  

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo '-----INSERTING INTO SUBSEQUENT_FILINGS1 (INSERT 2/4) ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 

INSERT INTO SUBSEQUENT_FILINGS1 
SELECT DISTINCT t1.appln_id, t.subsequent_id, t2.person_id as subsequent_person_id, applt_seq_nr, invt_seq_nr, t1.patent_office, t1.appln_filing_year, t.subsequent_date, t.nb_priorities, type
FROM PRIORITY_FILINGS_app t1 
JOIN t ON (t1.appln_id = t.appln_id )
JOIN tls207_pers_appln t2 ON (t.subsequent_id = t2.appln_id)
ORDER BY t1.appln_id, t.subsequent_date, t2.person_id, applt_seq_nr, invt_seq_nr ASC;

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo '-----CREATING t (from PRIORITY_FILINGS_app) (TABLE 11/27) ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 

DROP TABLE t;
CREATE UNLOGGED TABLE t AS
SELECT t1.appln_id, t2.appln_id AS subsequent_id, t2.appln_filing_date AS subsequent_date
FROM PRIORITY_FILINGS_app t1 
INNER JOIN tls201_appln t2 ON t1.appln_id = t2.internat_appln_id
WHERE type = 'pct'
AND t2.internat_appln_id != 0 and reg_phase = 'Y'
GROUP BY t1.appln_id, t2.appln_id, t2.appln_filing_date ;
CREATE INDEX t_appln_id ON t(appln_id);    

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo '-----INSERTING INTO SUBSEQUENT_FILINGS1 (INSERT 3/4) ...'
\echo '----------------------------------------------------------------------------------------------------------------------'   

INSERT INTO subsequent_filings1
SELECT DISTINCT t1.appln_id, t.subsequent_id, t2.person_id as subsequent_person_id, applt_seq_nr, invt_seq_nr, t1.patent_office, t1.appln_filing_year, t.subsequent_date, 1, type
FROM PRIORITY_FILINGS_app t1 
JOIN t ON (t1.appln_id = t.appln_id )
JOIN tls207_pers_appln t2 ON (t.subsequent_id = t2.appln_id)
ORDER BY t1.appln_id, t.subsequent_date, t2.person_id, applt_seq_nr, invt_seq_nr ASC;

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo '-----CREATING t (from PRIORITY_FILINGS_app) (TABLE 12/27) ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 

DROP TABLE t;
CREATE UNLOGGED TABLE t AS
SELECT t1.appln_id, t2.appln_id AS subsequent_id, t2.appln_filing_date AS subsequent_date
FROM PRIORITY_FILINGS_app t1 
INNER JOIN tls201_appln t2 ON t1.appln_id = t2.internat_appln_id
WHERE type = 'pct'
AND t2.internat_appln_id != 0 and nat_phase = 'Y'
GROUP BY t1.appln_id, t2.appln_id, t2.appln_filing_date ;
CREATE INDEX t_appln_id ON t(appln_id);      

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo '-----INSERTING INTO SUBSEQUENT_FILINGS1 (INSERT 4/4) ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 

INSERT INTO subsequent_filings1
SELECT DISTINCT t1.appln_id, t.subsequent_id, t2.person_id as subsequent_person_id, applt_seq_nr, invt_seq_nr, t1.patent_office, t1.appln_filing_year, t.subsequent_date, 2, type
FROM PRIORITY_FILINGS_app t1 
JOIN t ON (t1.appln_id = t.appln_id )
JOIN tls207_pers_appln t2 ON (t.subsequent_id = t2.appln_id)
ORDER BY t1.appln_id, t.subsequent_date, t2.person_id, applt_seq_nr, invt_seq_nr ASC;

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo '-----CREATE SUBSEQUENT_FILINGS1 INDICES ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 

CREATE INDEX sec1_idx ON SUBSEQUENT_FILINGS1 USING btree (appln_id);
CREATE INDEX sec1_sub_idx ON SUBSEQUENT_FILINGS1 USING btree (subsequent_id);
CREATE INDEX sec1_sub_pers_idx ON SUBSEQUENT_FILINGS1 USING btree (subsequent_person_id);
CREATE INDEX sec1_office_idx ON SUBSEQUENT_FILINGS1 USING btree (patent_office);
CREATE INDEX sec1_year_idx ON SUBSEQUENT_FILINGS1 USING btree (appln_filing_year);	
CREATE INDEX sec1_nb_prior_idx ON SUBSEQUENT_FILINGS1 USING btree (nb_priorities);
CREATE INDEX sec1_applt_idx ON SUBSEQUENT_FILINGS1 USING btree (applt_seq_nr);
CREATE INDEX sec1_invt_idx ON SUBSEQUENT_FILINGS1 USING btree (invt_seq_nr);
DROP TABLE t;

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'VACUUMING ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 

VACUUM ANALYZE SUBSEQUENT_FILINGS1;

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'CREATING EQUIVALENTS2 (TABLE 13/27) ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 
 
-- B.1 Information from equivalents (source = 2)
-- B.1.1 Find all the relevant information
DROP TABLE IF EXISTS EQUIVALENTS2;
CREATE UNLOGGED TABLE EQUIVALENTS2 AS (
SELECT  t1.appln_id,  t1.subsequent_id, t1.subsequent_person_id, t1.subsequent_date, t1.patent_office, t1.appln_filing_year, ctry_code, type
FROM SUBSEQUENT_FILINGS1 t1 
JOIN country_codes_app t2 ON (t1.subsequent_id = t2.appln_id and t1.subsequent_person_id = t2.person_id)
WHERE t1.nb_priorities = 1 AND applt_seq_nr >0 AND NULLIF(ctry_code, '  ') IS NOT NULL );

CREATE INDEX equ2_idx ON EQUIVALENTS2 USING btree (appln_id);
CREATE INDEX equ2_sub_idx ON EQUIVALENTS2 USING btree (subsequent_id);
CREATE INDEX equ2_sub_pers_idx ON EQUIVALENTS2 USING btree (subsequent_person_id);
CREATE INDEX equ2_office_idx ON EQUIVALENTS2 USING btree (patent_office);
CREATE INDEX equ2_year_idx ON EQUIVALENTS2 USING btree (appln_filing_year); 

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'CREATING EARLIEST_EQUIVALENT2 (TABLE 14/27) ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 
 
-- B.1.2 Select the most appropriate (i.e. earliest) equivalent
DROP TABLE IF EXISTS EARLIEST_EQUIVALENT2;
CREATE UNLOGGED TABLE EARLIEST_EQUIVALENT2 AS 
SELECT t1.appln_id, subsequent_id, subsequent_person_id, ctry_code, type, min
FROM EQUIVALENTS2 t1
JOIN (SELECT appln_id, min(subsequent_date) AS min
FROM EQUIVALENTS2
GROUP BY appln_id) AS t2 ON (t1.appln_id = t2.appln_id AND t1.subsequent_date = t2.min);

CREATE INDEX eequ2_idx ON EARLIEST_EQUIVALENT2 USING btree (appln_id);
CREATE INDEX eequ2_sub_idx ON EARLIEST_EQUIVALENT2 USING btree (subsequent_id);
CREATE INDEX eequ2_sub_pers_idx ON EARLIEST_EQUIVALENT2 USING btree (subsequent_person_id);

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'CREATING EARLIEST_EQUIVALENT2_ (TABLE 15/27) ...'
\echo '----------------------------------------------------------------------------------------------------------------------'

-- deal with cases where we have several earliest equivalents (select only one)
DROP TABLE IF EXISTS EARLIEST_EQUIVALENT2_;
CREATE UNLOGGED TABLE EARLIEST_EQUIVALENT2_ AS
SELECT t1.* FROM earliest_equivalent2 t1 JOIN 
(SELECT appln_id, min(subsequent_id) 
FROM EARLIEST_EQUIVALENT2
GROUP BY appln_id) AS t2
ON t1.appln_id = t2.appln_id AND t1.subsequent_id = t2.min;

CREATE INDEX eequ2_idx_ ON EARLIEST_EQUIVALENT2_ USING btree (appln_id);
CREATE INDEX eequ2_sub_idx_ ON EARLIEST_EQUIVALENT2_ USING btree (subsequent_id);
CREATE INDEX eequ2_sub_pers_idx_ ON EARLIEST_EQUIVALENT2_ USING btree (subsequent_person_id);

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'CREATING OTHER_SUBSEQUENT_FILINGS3 (TABLE 16/27) ...'
\echo '----------------------------------------------------------------------------------------------------------------------'

-- B.2 Information from other subsequent filings (source = 3)
-- B.2.1 Find information on applicants from subsequent filings for patents that have not yet been identified via their potential equivalent(s)
DROP TABLE IF EXISTS OTHER_SUBSEQUENT_FILINGS3;
CREATE UNLOGGED TABLE OTHER_SUBSEQUENT_FILINGS3 AS (
SELECT  t1.appln_id,  t1.subsequent_id, t1.subsequent_person_id, t1.subsequent_date, t1.patent_office, t1.appln_filing_year, ctry_code, type
FROM SUBSEQUENT_FILINGS1 t1 
JOIN country_codes_app t2 ON (t1.subsequent_id = t2.appln_id and t1.subsequent_person_id = t2.person_id)
WHERE t1.nb_priorities > 1 AND applt_seq_nr >0 AND NULLIF(ctry_code, '  ') IS NOT NULL);

CREATE INDEX other3_idx ON OTHER_SUBSEQUENT_FILINGS3 USING btree (appln_id);
CREATE INDEX other3_sub_idx ON OTHER_SUBSEQUENT_FILINGS3 USING btree (subsequent_id);
CREATE INDEX other3_sub_pers_idx ON OTHER_SUBSEQUENT_FILINGS3 USING btree (subsequent_person_id);
CREATE INDEX other3_office_idx ON OTHER_SUBSEQUENT_FILINGS3 USING btree (patent_office);
CREATE INDEX other3_year_idx ON OTHER_SUBSEQUENT_FILINGS3 USING btree (appln_filing_year); 

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'CREATING EARLIEST_SUBSEQUENT_FILING3 (TABLE 17/27) ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 
 
-- B.2.2 Select the most appropriate (i.e. earliest) subsequent filing
DROP TABLE IF EXISTS EARLIEST_SUBSEQUENT_FILING3;
CREATE UNLOGGED TABLE EARLIEST_SUBSEQUENT_FILING3 AS 
SELECT t1.appln_id, subsequent_id, subsequent_person_id, ctry_code, type, min
FROM OTHER_SUBSEQUENT_FILINGS3 t1
JOIN (SELECT appln_id, min(subsequent_date) AS min
FROM OTHER_SUBSEQUENT_FILINGS3
GROUP BY appln_id) AS t2 ON (t1.appln_id = t2.appln_id AND t1.subsequent_date = t2.min);

CREATE INDEX esub3_idx ON EARLIEST_SUBSEQUENT_FILING3 USING btree (appln_id);
CREATE INDEX esub3_sub_idx ON EARLIEST_SUBSEQUENT_FILING3 USING btree (subsequent_id);
CREATE INDEX esub3_sub_pers_idx ON EARLIEST_SUBSEQUENT_FILING3 USING btree (subsequent_person_id);

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'CREATING EARLIEST_SUBSEQUENT_FILING3_ (TABLE 18/27) ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 
 
-- deal with cases where we have several earliest equivalents (select only one)
DROP TABLE IF EXISTS EARLIEST_SUBSEQUENT_FILING3_;
CREATE UNLOGGED TABLE EARLIEST_SUBSEQUENT_FILING3_ AS
SELECT t1.* FROM EARLIEST_SUBSEQUENT_FILING3 t1 JOIN 
(SELECT appln_id, min(subsequent_id) 
FROM EARLIEST_SUBSEQUENT_FILING3
GROUP BY appln_id) AS t2
ON t1.appln_id = t2.appln_id AND t1.subsequent_id = t2.min;

CREATE INDEX esub3_idx_ ON EARLIEST_SUBSEQUENT_FILING3_ USING btree (appln_id);
CREATE INDEX esub3_sub_idx_ ON EARLIEST_SUBSEQUENT_FILING3_ USING btree (subsequent_id);
CREATE INDEX esub3_sub_pers_idx_ ON EARLIEST_SUBSEQUENT_FILING3_ USING btree (subsequent_person_id);
 
-- Inventor information

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'INVENTOR INFORMATION
\echo '----------------------------------------------------------------------------------------------------------------------' 

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'CREATING PRIORITY_FILINGS4 (TABLE 18/27) ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 
 
-- C. Information that is directly available (source = 4)
DROP TABLE IF EXISTS PRIORITY_FILINGS4;
CREATE UNLOGGED TABLE PRIORITY_FILINGS4 AS (
SELECT DISTINCT t1.appln_id, t1.patent_office, t1.appln_filing_year, ctry_code, type
FROM PRIORITY_FILINGS_app t1 
JOIN country_codes_inv t2 ON (t1.appln_id = t2.appln_id)
WHERE NULLIF(t2.ctry_code, '  ') IS NOT NULL) ;

CREATE INDEX pri4_idx ON PRIORITY_FILINGS4 USING btree (appln_id);
CREATE INDEX pri4_office_idx ON PRIORITY_FILINGS4 USING btree (patent_office);
CREATE INDEX pri4_year_idx ON PRIORITY_FILINGS4 USING btree (appln_filing_year);  

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'CREATING EQUIVALENTS5 (TABLE 19/27) ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 
 
-- D.1 Use information from equivalents (source = 5)
-- D.1.1 Find all the relevant information
DROP TABLE IF EXISTS EQUIVALENTS5;
CREATE UNLOGGED TABLE EQUIVALENTS5 AS (
SELECT  t1.appln_id, t1.subsequent_id, t1.subsequent_date, t1.patent_office, t1.appln_filing_year, ctry_code, type
FROM SUBSEQUENT_FILINGS1 t1 
JOIN country_codes_inv t2 ON (t1.subsequent_id = t2.appln_id)
WHERE t1.nb_priorities = 1  AND invt_seq_nr > 0 AND NULLIF(ctry_code, '  ') IS NOT NULL);

CREATE INDEX equ5_idx ON EQUIVALENTS5 USING btree (appln_id);
CREATE INDEX equ5_sub_idx ON EQUIVALENTS5  USING btree (subsequent_id);
CREATE INDEX equ5_office_idx ON EQUIVALENTS5 USING btree (patent_office);
CREATE INDEX equ5_year_idx ON EQUIVALENTS5 USING btree (appln_filing_year); 

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'CREATING EARLIEST_EQUIVALENT5 (TABLE 20/27) ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 
 
-- D.1.2 Select the most appropriate (i.e. earliest) equivalent
DROP TABLE IF EXISTS EARLIEST_EQUIVALENT5;
CREATE UNLOGGED TABLE EARLIEST_EQUIVALENT5 AS 
SELECT t1.appln_id, subsequent_id, ctry_code, type, min
FROM EQUIVALENTS5 t1
JOIN (SELECT appln_id, min(subsequent_date) AS min
FROM EQUIVALENTS5
GROUP BY appln_id) AS t2 ON (t1.appln_id = t2.appln_id AND t1.subsequent_date = t2.min);

CREATE INDEX eequ5_idx ON EARLIEST_EQUIVALENT5 USING btree (appln_id);
CREATE INDEX eequ5_sub_idx ON EARLIEST_EQUIVALENT5 USING btree (subsequent_id);

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'CREATING EARLIEST_EQUIVALENT5_ (TABLE 21/27) ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 
 
-- deal with cases where we have several earliest equivalents (select only one)
DROP TABLE IF EXISTS EARLIEST_EQUIVALENT5_;
CREATE UNLOGGED TABLE EARLIEST_EQUIVALENT5_ AS
SELECT t1.* FROM earliest_equivalent5 t1 JOIN 
(SELECT appln_id, min(subsequent_id) 
FROM EARLIEST_EQUIVALENT5
GROUP BY appln_id) AS t2
ON t1.appln_id = t2.appln_id AND t1.subsequent_id = t2.min
;

CREATE INDEX eequ5_idx_ ON EARLIEST_EQUIVALENT5_ USING btree (appln_id);
CREATE INDEX eequ5_sub_idx_ ON EARLIEST_EQUIVALENT5_ USING btree (subsequent_id);

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'CREATING OTHER_SUBSEQUENT_FILINGS6 (TABLE 22/27) ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 
 
-- D.2 Use information from other subsequent filings (source = 6)
-- D.2.1 Find information on inventors from subsequent filings for patents that have not yet been identified via their potential equivalents
DROP TABLE IF EXISTS OTHER_SUBSEQUENT_FILINGS6;
CREATE UNLOGGED TABLE OTHER_SUBSEQUENT_FILINGS6 AS (
SELECT  t1.appln_id, t1.subsequent_id, t1.subsequent_date, t1.patent_office, t1.appln_filing_year, ctry_code, type 
FROM SUBSEQUENT_FILINGS1 t1 
JOIN country_codes_inv t2 ON (t1.subsequent_id = t2.appln_id)
WHERE t1.nb_priorities > 1  AND invt_seq_nr > 0 AND NULLIF(ctry_code, '  ') IS NOT NULL );

CREATE INDEX other6_idx ON OTHER_SUBSEQUENT_FILINGS6 USING btree (appln_id);
CREATE INDEX other6_sub_idx ON OTHER_SUBSEQUENT_FILINGS6 USING btree (subsequent_id);
CREATE INDEX other6_office_idx ON OTHER_SUBSEQUENT_FILINGS6 USING btree (patent_office);
CREATE INDEX other6_year_idx ON OTHER_SUBSEQUENT_FILINGS6 USING btree (appln_filing_year); 

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'CREATING EARLIEST_SUBSEQUENT_FILING6 (TABLE 23/27) ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 
 
-- D.2.2 Select the most appropriate (i.e. earliest) subsequent filing
DROP TABLE IF EXISTS EARLIEST_SUBSEQUENT_FILING6;
CREATE UNLOGGED TABLE EARLIEST_SUBSEQUENT_FILING6 AS 
SELECT t1.appln_id, subsequent_id, ctry_code, type, min
FROM OTHER_SUBSEQUENT_FILINGS6 t1
JOIN (SELECT appln_id, min(subsequent_date) AS min
FROM OTHER_SUBSEQUENT_FILINGS6
GROUP BY appln_id) AS t2 ON (t1.appln_id = t2.appln_id AND t1.subsequent_date = t2.min);

CREATE INDEX esub6_idx ON EARLIEST_SUBSEQUENT_FILING6 USING btree (appln_id);
CREATE INDEX esub6_sub_idx ON EARLIEST_SUBSEQUENT_FILING6 USING btree (subsequent_id);

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'CREATING EARLIEST_SUBSEQUENT_FILING6_ (TABLE 24/27) ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 
 
-- deal with cases where we have several earliest equivalents (select only one)
DROP TABLE IF EXISTS EARLIEST_SUBSEQUENT_FILING6_;
CREATE UNLOGGED TABLE EARLIEST_SUBSEQUENT_FILING6_ AS
SELECT t1.* FROM EARLIEST_SUBSEQUENT_FILING6 t1 JOIN 
(SELECT appln_id, min(subsequent_id) 
FROM EARLIEST_SUBSEQUENT_FILING6
GROUP BY appln_id) AS t2
ON t1.appln_id = t2.appln_id AND t1.subsequent_id = t2.min
;

CREATE INDEX esub6_idx_ ON EARLIEST_SUBSEQUENT_FILING6_ USING btree (appln_id);
CREATE INDEX esub6_sub_idx_ ON EARLIEST_SUBSEQUENT_FILING6_ USING btree (subsequent_id);

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'CREATING TABLE_APP (TABLE 25/27) ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 
 
-- table containing the information on priority filings and country information if available for priority filing
DROP TABLE IF EXISTS TABLE_APP;
CREATE TABLE TABLE_APP AS
SELECT * FROM priority_filings1; 
 
CREATE INDEX TABLE_APP_APPLN_ID ON TABLE_APP USING btree (appln_id);
CREATE INDEX TABLE_APP_PERSON_ID ON TABLE_APP USING btree (person_id);

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'CREATING TABLE_TO_BE_FILLED_APP (TABLE 26/27) ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 
 
DROP TABLE IF EXISTS TABLE_TO_BE_FILLED_APP;
CREATE  TABLE TABLE_TO_BE_FILLED_APP (
appln_id INTEGER DEFAULT NULL,
person_id INTEGER DEFAULT NULL,
ctry_code VARCHAR(2) DEFAULT NULL,
source SMALLINT DEFAULT NULL,
type TEXT DEFAULT NULL
);
 
 
 
 
/* MAIN PROCEDURE
*/

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'MAIN PROCEDURE'
\echo '----------------------------------------------------------------------------------------------------------------------' 
 
\echo '----------------------------------------------------------------------------------------------------------------------'
\echo '-----INSERTING INTO TABLE_TO_BE_FILLED_APP (INSERT 1/7) ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 
 
-- A Insert information that is directly available (source = 1)
INSERT INTO TABLE_TO_BE_FILLED_APP
SELECT  t_.appln_id, t_.person_id, ctry_code, 1, type
FROM TABLE_APP t_
WHERE NULLIF(t_.ctry_code, '  ') IS NOT NULL;
 
CREATE INDEX TABLE_TO_BE_FILLED_APP_appln_id ON TABLE_TO_BE_FILLED_APP(appln_id);

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo '----------DELETING INFO THAT WAS ADDED FROM FROM SOURCE ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 
 
-- delete information that has been added
DELETE FROM TABLE_APP t WHERE t.appln_id IN (SELECT appln_id FROM TABLE_TO_BE_FILLED_APP);    

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo '-----INSERTING INTO TABLE_TO_BE_FILLED_APP (INSERT 2/7) ...'
\echo '----------------------------------------------------------------------------------------------------------------------'             
 
-- B.1 Add the information from each selected equivalent
INSERT INTO TABLE_TO_BE_FILLED_APP
SELECT
t_.appln_id,
t_.subsequent_person_id,
t_.ctry_code,
2,
t_.type
FROM (
SELECT t1.appln_id, t1.subsequent_person_id, ctry_code, type
FROM EARLIEST_EQUIVALENT2_ t1
JOIN (
SELECT DISTINCT appln_id FROM
TABLE_APP) AS t2
ON t1.appln_id = t2.appln_id 
WHERE NULLIF(t1.ctry_code, '  ') IS NOT NULL 
) AS t_
;

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo '----------DELETING INFO THAT WAS ADDED FROM FROM SOURCE ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 
 
DELETE FROM TABLE_APP t WHERE t.appln_id IN (SELECT appln_id FROM TABLE_TO_BE_FILLED_APP);    

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo '-----INSERTING INTO TABLE_TO_BE_FILLED_APP (INSERT 3/7) ...'
\echo '----------------------------------------------------------------------------------------------------------------------'             
 
-- B.2 Add the information from each selected subsequent filing
INSERT INTO TABLE_TO_BE_FILLED_APP
SELECT
t_.appln_id,
t_.subsequent_person_id,
t_.ctry_code,
3,
t_.type 
FROM (
SELECT t1.appln_id, t1.subsequent_person_id, ctry_code, type
FROM EARLIEST_SUBSEQUENT_FILING3_ t1
JOIN (
SELECT DISTINCT appln_id FROM
TABLE_APP) AS t2
ON t1.appln_id = t2.appln_id 
WHERE NULLIF(t1.ctry_code, '  ') IS NOT NULL 
) AS t_
;

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo '----------DELETING INFO THAT WAS ADDED FROM FROM SOURCE ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 
 
DELETE FROM TABLE_APP t WHERE t.appln_id IN (SELECT appln_id FROM TABLE_TO_BE_FILLED_APP);  
 
-- Take information from applicants to recover missing information 

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo '-----INSERTING INTO TABLE_TO_BE_FILLED_APP (INSERT 4/7) ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 
 
-- C Insert information that is directly available (source = 4)
INSERT INTO TABLE_TO_BE_FILLED_APP
SELECT
t_.appln_id,
0,
t_.ctry_code,
4,
t_.type
FROM (
SELECT t1.appln_id, ctry_code, type
FROM PRIORITY_FILINGS4 t1
JOIN (
SELECT DISTINCT appln_id FROM
TABLE_APP) AS t2
ON t1.appln_id = t2.appln_id 
WHERE NULLIF(t1.ctry_code, '  ') IS NOT NULL 
) AS t_
;

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo '----------DELETING INFO THAT WAS ADDED FROM FROM SOURCE ...'
\echo '----------------------------------------------------------------------------------------------------------------------'
 
DELETE FROM TABLE_APP t WHERE t.appln_id IN (SELECT appln_id FROM TABLE_TO_BE_FILLED_APP);  

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo '-----INSERTING INTO TABLE_TO_BE_FILLED_APP (INSERT 5/7) ...'
\echo '----------------------------------------------------------------------------------------------------------------------'
 
-- D.1 Add the information from each selected equivalent
INSERT INTO TABLE_TO_BE_FILLED_APP
SELECT
t_.appln_id,
0,
t_.ctry_code,
5,
t_.type   
FROM (
SELECT t1.appln_id, ctry_code, type
FROM EARLIEST_EQUIVALENT5_ t1
JOIN (
SELECT DISTINCT appln_id FROM
TABLE_APP) AS t2
ON t1.appln_id = t2.appln_id 
WHERE NULLIF(t1.ctry_code, '  ') IS NOT NULL 
) AS t_
;

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo '----------DELETING INFO THAT WAS ADDED FROM FROM SOURCE ...'
\echo '----------------------------------------------------------------------------------------------------------------------'
 
DELETE FROM TABLE_APP t WHERE t.appln_id IN (SELECT appln_id FROM TABLE_TO_BE_FILLED_APP); 

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo '-----INSERTING INTO TABLE_TO_BE_FILLED_APP (INSERT 6/7) ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 
 
-- D.2 Add the information from each selected subsequent filing
INSERT INTO TABLE_TO_BE_FILLED_APP
SELECT
t_.appln_id,
0,
t_.ctry_code,
6,
t_.type
FROM (
SELECT t1.appln_id, ctry_code, type
FROM EARLIEST_SUBSEQUENT_FILING6_ t1
JOIN (
SELECT DISTINCT appln_id FROM
TABLE_APP) AS t2
ON t1.appln_id = t2.appln_id 
WHERE NULLIF(t1.ctry_code, '  ') IS NOT NULL 
) AS t_
;

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo '----------DELETING INFO THAT WAS ADDED FROM FROM SOURCE ...'
\echo '----------------------------------------------------------------------------------------------------------------------'
 
DELETE FROM TABLE_APP t WHERE t.appln_id IN (SELECT appln_id FROM TABLE_TO_BE_FILLED_APP);

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo '-----INSERTING INTO TABLE_TO_BE_FILLED_APP (INSERT 7/7) ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 
 
-- E. If country code is still missing, set it equal to a filing's patent office
INSERT INTO TABLE_TO_BE_FILLED_APP
SELECT
t_.appln_id,
0,
t_.patent_office,
7,
t_.type
FROM (
SELECT t1.appln_id, patent_office, type
FROM PRIORITY_FILINGS_app t1 
JOIN (
SELECT DISTINCT appln_id FROM
TABLE_APP) AS t2
ON (t1.appln_id = t2.appln_id) 
WHERE patent_office NOT IN ('EP', 'AP', 'EA', 'GC', 'OA', 'WO')
) AS t_  ;

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'CREATING PF_APP_PERS_CTRY_ALL (TABLE 27/27) ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 
 
-- Table with location information from all possible sources
DROP TABLE IF EXISTS PF_APP_PERS_CTRY_ALL;
CREATE TABLE PF_APP_PERS_CTRY_ALL (
appln_id INTEGER DEFAULT NULL,
person_id INTEGER DEFAULT NULL,
patent_office CHAR(2) DEFAULT NULL,
priority_date date DEFAULT NULL,
priority_year INTEGER DEFAULT NULL,
ctry_code TEXT DEFAULT NULL,
source SMALLINT DEFAULT NULL,
type TEXT DEFAULT NULL
); COMMENT ON TABLE PF_APP_PERS_CTRY_ALL IS 'Applicants from priority filings of a given (po, year)';

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo '-----INSERTING INTO PF_APP_PERS_CTRY_ALL (INSERT 1/1) ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 
 
-- F. Job done, insert into final table 
INSERT INTO PF_APP_PERS_CTRY_ALL
SELECT t1.appln_id, t1.person_id, t2.patent_office, t2.appln_filing_date, t2.appln_filing_year, ctry_code, source, type
FROM TABLE_TO_BE_FILLED_APP t1 JOIN (
SELECT DISTINCT appln_id, patent_office, appln_filing_date, appln_filing_year FROM PRIORITY_FILINGS_app) AS t2 ON t1.appln_id = t2.appln_id;

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo '-----CREATE PF_APP_PERS_CTRY_ALL INDICES ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 
 
CREATE INDEX PF_APP_PERS_CTRY_ALL_APPLN_ID ON PF_APP_PERS_CTRY_ALL(appln_id);
CREATE INDEX PF_APP_PERS_CTRY_ALL_PERS_ID ON PF_APP_PERS_CTRY_ALL(person_id);
CREATE INDEX PF_APP_PERS_CTRY_ALL_YEAR ON PF_APP_PERS_CTRY_ALL(priority_year);
 
ALTER TABLE PF_APP_PERS_CTRY_ALL ADD COLUMN lastupdate TIMESTAMP; 
UPDATE PF_APP_PERS_CTRY_ALL SET lastupdate = CURRENT_TIMESTAMP;  
 
\echo '----------------------------------------------------------------------------------------------------------------------'
\echo '-----UPDATING COUNTRY NAMES IN PF_APP_PERS_CTRY_ALL ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 
 
ALTER TABLE pf_app_pers_ctry_all ADD COLUMN country VARCHAR; 
UPDATE pf_app_pers_ctry_all SET country = 
CASE
WHEN ctry_code ='AU' THEN 'Australia'
WHEN ctry_code ='AT' THEN 'Austria'
WHEN ctry_code ='BE' THEN 'Belgium'
WHEN ctry_code ='BR' THEN 'Brazil'
WHEN ctry_code ='BG' THEN 'Bulgaria'
WHEN ctry_code ='CA' THEN 'Canada'
WHEN ctry_code ='CL' THEN 'Chile'
WHEN ctry_code ='CN' THEN 'China'
WHEN ctry_code ='HR' THEN 'Croatia'
WHEN ctry_code ='CZ' THEN 'Czech Republic'
WHEN ctry_code ='DK' THEN 'Denmark'
WHEN ctry_code ='EE' THEN 'Estonia'
WHEN ctry_code ='FI' THEN 'Finland'
WHEN ctry_code ='FR' THEN 'France'
WHEN ctry_code ='DE' THEN 'Germany'
WHEN ctry_code ='GR' THEN 'Greece'
WHEN ctry_code ='HU' THEN 'Hungary'
WHEN ctry_code ='IS' THEN 'Iceland'
WHEN ctry_code ='IN' THEN 'India'
WHEN ctry_code ='IE' THEN 'Ireland'
WHEN ctry_code ='IL' THEN 'Israel'
WHEN ctry_code ='IT' THEN 'Italy'
WHEN ctry_code ='JP' THEN 'Japan'
WHEN ctry_code ='KR' THEN 'South Korea'
WHEN ctry_code ='LV' THEN 'Latvia'
WHEN ctry_code ='MT' THEN 'Malta'
WHEN ctry_code ='MX' THEN 'Mexico'
WHEN ctry_code ='NL' THEN 'Netherlands'
WHEN ctry_code ='NZ' THEN 'New Zealand'
WHEN ctry_code ='NO' THEN 'Norway'
WHEN ctry_code ='PL' THEN 'Poland'
WHEN ctry_code ='PT' THEN 'Portugal'
WHEN ctry_code ='RO' THEN 'Romania'
WHEN ctry_code ='RU' THEN 'Russia'
WHEN ctry_code ='SK' THEN 'Slovakia'
WHEN ctry_code ='SI' THEN 'Slovenia'
WHEN ctry_code ='ZA' THEN 'South Africa'
WHEN ctry_code ='ES' THEN 'Spain'
WHEN ctry_code ='SE' THEN 'Sweden'
WHEN ctry_code ='CH' THEN 'Switzerland'
WHEN ctry_code ='TR' THEN 'Turkey'
WHEN ctry_code ='GB' THEN 'United Kingdom'
WHEN ctry_code ='US' THEN 'United States'
WHEN ctry_code ='LU' THEN 'Luxembourg'
WHEN ctry_code ='LT' THEN 'Lithuania'
WHEN ctry_code ='LI' THEN 'Liechtenstein'
WHEN ctry_code ='HK' THEN 'Hong Kong'
END  ;
 
CREATE INDEX PF_APP_PERS_CTRY_ALL_COUNTRY ON PF_APP_PERS_CTRY_ALL(country);

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'VACUUMING ...'
\echo '----------------------------------------------------------------------------------------------------------------------' 

VACUUM ANALYZE PF_APP_PERS_CTRY_ALL;

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo '-----JOB DONE!'
\echo '----------------------------------------------------------------------------------------------------------------------' 
 
\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'EXPORTING DATA (Dynamic Generation)'
\echo '----------------------------------------------------------------------------------------------------------------------' 

-- Configure output
\pset format unaligned
\pset tuples_only on

-- Redirect to temp file
\o _tmp_export_applt.sql

-- Generate the \copy command with the dynamic output path
SELECT format('\echo ''Exporting to: %s/imputed/ctry_applt_person.csv''', :'outdir_sql');
SELECT format('\copy (SELECT * FROM pf_app_pers_ctry_all ORDER BY appln_id) TO ''%s/imputed/ctry_applt_person.csv'' CSV HEADER NULL ''  '' DELIMITER '','' ENCODING ''UTF8'';', :'outdir_sql');

-- Reset output
\o
\pset format aligned
\pset tuples_only off

-- Execute the generated command
\i _tmp_export_applt.sql
  
\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'DROPPING TABLES'
\echo '----------------------------------------------------------------------------------------------------------------------' 
 
DROP TABLE if exists po;
DROP TABLE if exists toExclude;
DROP TABLE if exists PRIORITY_FILINGS_APP;
DROP TABLE if exists TABLE_TO_BE_FILLED_APP;
DROP TABLE if exists TABLE_APP;
DROP table if exists country_codes_app;
DROP table if exists country_codes_inv;
DROP table if exists PRIORITY_FILINGS1;
DROP table if exists SUBSEQUENT_FILINGS1;
DROP table if exists EQUIVALENTS2;
DROP table if exists EARLIEST_EQUIVALENT2;
DROP table if exists EARLIEST_EQUIVALENT2_;
DROP table if exists OTHER_SUBSEQUENT_FILINGS3;
DROP table if exists EARLIEST_SUBSEQUENT_FILING3;
DROP table if exists EARLIEST_SUBSEQUENT_FILING3_;
DROP table if exists PRIORITY_FILINGS4;
DROP table if exists EQUIVALENTS5;
DROP table if exists EARLIEST_EQUIVALENT5;
DROP table if exists EARLIEST_EQUIVALENT5_;
DROP table if exists OTHER_SUBSEQUENT_FILINGS6;
DROP table if exists EARLIEST_SUBSEQUENT_FILING6;
DROP table if exists EARLIEST_SUBSEQUENT_FILING6_;

\! del _tmp_export_applt.sql 2>NUL