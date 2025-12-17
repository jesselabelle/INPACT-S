/*****************************************************************************************
 Import PATSTAT core tables needed for the cleaning pipeline.

 This script:
   - Creates a dedicated schema (name given by :patstat_schema).
   - Creates the PATSTAT core tables used by the SQL + Stata pipeline.
   - Loads them from CSV files dynamically located in :srcdir.

 Requirements:
   1) Called from 0_master_clean_patstat.sql (which sets variables).
******************************************************************************************/

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'Create schema if needed'
\echo '----------------------------------------------------------------------------------------------------------------------'

CREATE SCHEMA IF NOT EXISTS :patstat_schema;

SET search_path TO :patstat_schema, public;

\echo 'USING SCHEMA: ' :patstat_schema
\echo 'USING CSV SOURCE DIRECTORY: ' :srcdir

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'TABLE DEFINITIONS (Structure Only)'
\echo '----------------------------------------------------------------------------------------------------------------------'

\echo 'Defining TLS201_APPLN...'
DROP TABLE IF EXISTS tls201_appln;
CREATE TABLE tls201_appln (
  appln_id              BIGINT NOT NULL DEFAULT 0,
  appln_auth            CHAR(2)      DEFAULT '',
  appln_nr              VARCHAR(15)  DEFAULT '',
  appln_kind            CHAR(2)      DEFAULT '  ',
  appln_filing_date     TIMESTAMP    DEFAULT '9999-12-31 00:00:00',
  appln_filing_year     BIGINT       DEFAULT 9999,
  appln_nr_epodoc       VARCHAR(20)  DEFAULT '',
  appln_nr_original     VARCHAR(100) DEFAULT '',
  ipr_type              CHAR(2)      DEFAULT '',
  receiving_office      CHAR(2)      DEFAULT '',
  internat_appln_id     BIGINT       DEFAULT 0,
  int_phase             CHAR(1)      DEFAULT 'N',
  reg_phase             CHAR(1)      DEFAULT 'N',
  nat_phase             CHAR(1)      DEFAULT 'N',
  earliest_filing_date  TIMESTAMP    DEFAULT '9999-12-31 00:00:00',
  earliest_filing_year  BIGINT       DEFAULT 9999,
  earliest_filing_id    BIGINT       DEFAULT 0,
  earliest_publn_date   BIGINT       DEFAULT 99991231,
  earliest_publn_year   BIGINT       DEFAULT 9999,
  earliest_pat_publn_id BIGINT       DEFAULT 0,
  granted               CHAR(1)      DEFAULT 'N',
  docdb_family_id       BIGINT       DEFAULT 0,
  inpadoc_family_id     BIGINT       DEFAULT 0,
  docdb_family_size     BIGINT       DEFAULT 0,
  nb_citing_docdb_fam   BIGINT       DEFAULT 0,
  nb_applicants         BIGINT       DEFAULT 0,
  nb_inventors          BIGINT       DEFAULT 0,
  PRIMARY KEY (appln_id)
);

\echo 'Defining TLS204_APPLN_PRIOR...'
DROP TABLE IF EXISTS tls204_appln_prior;
CREATE TABLE tls204_appln_prior (
  appln_id           BIGINT NOT NULL DEFAULT 0,
  prior_appln_id     BIGINT NOT NULL DEFAULT 0,
  prior_appln_seq_nr BIGINT DEFAULT 0,
  PRIMARY KEY (appln_id, prior_appln_id)
);

\echo 'Defining TLS205_TECH_REL...'
DROP TABLE IF EXISTS tls205_tech_rel;
CREATE TABLE tls205_tech_rel (
  appln_id          BIGINT NOT NULL DEFAULT 0,
  tech_rel_appln_id BIGINT NOT NULL DEFAULT 0,
  PRIMARY KEY (appln_id, tech_rel_appln_id)
);

\echo 'Defining TLS206_PERSON...'
DROP TABLE IF EXISTS tls206_person;
CREATE TABLE tls206_person (
  person_id           BIGINT        NOT NULL DEFAULT 0,
  person_name         VARCHAR(500)  DEFAULT '',
  person_name_orig_lg VARCHAR(500)  DEFAULT '',
  person_address      VARCHAR(1000) DEFAULT '',
  person_ctry_code    CHAR(2)       DEFAULT '',
  nuts                VARCHAR(5)    DEFAULT '',
  nuts_level          BIGINT        DEFAULT 9,
  doc_std_name_id     BIGINT        DEFAULT 0,
  doc_std_name        VARCHAR(500)  DEFAULT '',
  psn_id              BIGINT        DEFAULT 0,
  psn_name            VARCHAR(500)  DEFAULT '',
  psn_level           BIGINT        DEFAULT 0,
  psn_sector          VARCHAR(50)   DEFAULT '',
  han_id              BIGINT        DEFAULT 0,
  han_name            VARCHAR(500)  DEFAULT '',
  han_harmonized      BIGINT        DEFAULT 0,
  PRIMARY KEY (person_id)
);

\echo 'Defining TLS207_PERS_APPLN...'
DROP TABLE IF EXISTS tls207_pers_appln;
CREATE TABLE tls207_pers_appln (
  person_id    BIGINT NOT NULL DEFAULT 0,
  appln_id     BIGINT NOT NULL DEFAULT 0,
  applt_seq_nr BIGINT DEFAULT 0,
  invt_seq_nr  BIGINT DEFAULT 0,
  PRIMARY KEY (person_id, appln_id, applt_seq_nr, invt_seq_nr)
);

\echo 'Defining TLS209_APPLN_IPC...'
DROP TABLE IF EXISTS tls209_appln_ipc;
CREATE TABLE tls209_appln_ipc (
  appln_id         BIGINT      NOT NULL,
  ipc_class_symbol VARCHAR(16) NOT NULL,
  ipc_class_level  CHAR(1),
  ipc_version      VARCHAR(32),
  ipc_value        CHAR(1),
  ipc_position     CHAR(1),
  ipc_gener_auth   CHAR(2),
  PRIMARY KEY (appln_id, ipc_class_symbol)
);

\echo 'Defining TLS211_PAT_PUBLN...'
DROP TABLE IF EXISTS tls211_pat_publn;
CREATE TABLE tls211_pat_publn (
  pat_publn_id  BIGINT      NOT NULL DEFAULT 0,
  publn_auth    CHAR(2)     DEFAULT '',
  publn_nr      VARCHAR(15) DEFAULT '',
  publn_nr_original VARCHAR(100) DEFAULT '',
  publn_kind    CHAR(2)     DEFAULT '',
  appln_id      BIGINT      DEFAULT 0,
  publn_date    BIGINT      DEFAULT 99991231,
  publn_lg      CHAR(2)     DEFAULT '',
  publn_first_grant CHAR(1) DEFAULT 'N',
  publn_claims  BIGINT      DEFAULT 0,
  PRIMARY KEY (pat_publn_id)
);

\echo 'Defining TLS212_CITATION...'
DROP TABLE IF EXISTS tls212_citation;
CREATE TABLE tls212_citation (
    pat_publn_id       BIGINT       NOT NULL,
    citn_replenished   BIGINT       DEFAULT 0,
    citn_id            SMALLINT     DEFAULT 0,
    citn_origin        VARCHAR(3)   DEFAULT '',
    cited_pat_publn_id BIGINT       DEFAULT 0,
    cited_appln_id     BIGINT       DEFAULT 0,
    pat_citn_seq_nr    SMALLINT     DEFAULT 0,
    cited_npl_publn_id VARCHAR(32)  DEFAULT '',
    npl_citn_seq_nr    SMALLINT     DEFAULT 0,
    citn_gener_auth    VARCHAR(3)   DEFAULT '',
    PRIMARY KEY (pat_publn_id, citn_replenished, citn_id)
);

\echo 'Defining TLS216_APPLN_CONTN...'
DROP TABLE IF EXISTS tls216_appln_contn;
CREATE TABLE tls216_appln_contn (
  appln_id        BIGINT NOT NULL DEFAULT 0,
  parent_appln_id BIGINT NOT NULL DEFAULT 0,
  contn_type      CHAR(3) DEFAULT '',
  PRIMARY KEY (appln_id, parent_appln_id)
);


\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'GENERATING DATA LOAD SCRIPT...'
\echo '----------------------------------------------------------------------------------------------------------------------'

-- Configure output to generate clean SQL
\pset format unaligned
\pset tuples_only on

-- Redirect output to temporary file
\o _tmp_load_data.sql

-- Generate dynamic COPY commands
SELECT format('\echo ''Importing data into tls201_appln...''');
SELECT format('\copy tls201_appln FROM ''%s/tls201_appln.csv'' WITH (FORMAT csv, HEADER true);', :'srcdir');

SELECT format('\echo ''Importing data into tls204_appln_prior...''');
SELECT format('\copy tls204_appln_prior FROM ''%s/tls204_appln_prior.csv'' WITH (FORMAT csv, HEADER true);', :'srcdir');

SELECT format('\echo ''Importing data into tls205_tech_rel...''');
SELECT format('\copy tls205_tech_rel FROM ''%s/tls205_tech_rel.csv'' WITH (FORMAT csv, HEADER true);', :'srcdir');

SELECT format('\echo ''Importing data into tls206_person...''');
SELECT format('\copy tls206_person FROM ''%s/tls206_person.csv'' WITH (FORMAT csv, HEADER true, ENCODING ''UTF8'');', :'srcdir');

SELECT format('\echo ''Importing data into tls207_pers_appln...''');
SELECT format('\copy tls207_pers_appln FROM ''%s/tls207_pers_appln.csv'' WITH (FORMAT csv, HEADER true);', :'srcdir');

SELECT format('\echo ''Importing data into tls209_appln_ipc...''');
SELECT format('\copy tls209_appln_ipc FROM ''%s/tls209_appln_ipc.csv'' WITH (FORMAT csv, HEADER true);', :'srcdir');

SELECT format('\echo ''Importing data into tls211_pat_publn...''');
SELECT format('\copy tls211_pat_publn FROM ''%s/tls211_pat_publn.csv'' WITH (FORMAT csv, HEADER true);', :'srcdir');

SELECT format('\echo ''Importing data into tls212_citation...''');
SELECT format('\copy tls212_citation FROM ''%s/tls212_citation.csv'' WITH (FORMAT csv, HEADER true);', :'srcdir');

SELECT format('\echo ''Importing data into tls216_appln_contn...''');
SELECT format('\copy tls216_appln_contn FROM ''%s/tls216_appln_contn.csv'' WITH (FORMAT csv, HEADER true);', :'srcdir');

-- Reset output configuration
\o
\pset format aligned
\pset tuples_only off

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'EXECUTING DATA LOAD SCRIPT...'
\echo '----------------------------------------------------------------------------------------------------------------------'

\i _tmp_load_data.sql

\echo '----------------------------------------------------------------------------------------------------------------------'
\echo 'OPTIMIZING DATABASE (VACUUM ANALYZE)'
\echo '----------------------------------------------------------------------------------------------------------------------'

VACUUM (ANALYZE);
\! del _tmp_load_data.sql 2>NUL