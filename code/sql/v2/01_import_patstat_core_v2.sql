/***************************************************************************************************************************
 
This script uploads the updated raw PATSTAT data necessary to update the deRassenfosse imputation code. The only tables needed are:

tls201_appln
tls205_tech_rel
tls207_pers_appln
tls211_pat_publn
tls216_appln_contn
 
******************************************************************************************/

/*****************************************************************************************
TLS201_APPLN
******************************************************************************************/

DROP TABLE IF EXISTS tls201_appln;
CREATE TABLE tls201_appln (
  appln_id BIGINT NOT NULL DEFAULT 0, 
  appln_auth CHAR(2) DEFAULT '',
  appln_nr VARCHAR(15) DEFAULT '',
  appln_kind CHAR(2) DEFAULT '  ',
  appln_filing_date TIMESTAMP DEFAULT '9999-12-31 00:00:00',
  appln_filing_year BIGINT DEFAULT 9999,
  appln_nr_epodoc VARCHAR(20) DEFAULT '',
  appln_nr_original VARCHAR(100) DEFAULT '',
  ipr_type CHAR(2) DEFAULT '',
  receiving_office CHAR(2) DEFAULT '',
  internat_appln_id BIGINT DEFAULT 0,
  int_phase CHAR(1) DEFAULT 'N',
  reg_phase CHAR(1) DEFAULT 'N',
  nat_phase CHAR(1) DEFAULT 'N',
  earliest_filing_date TIMESTAMP DEFAULT '9999-12-31 00:00:00',
  earliest_filing_year BIGINT DEFAULT 9999,
  earliest_filing_id BIGINT DEFAULT 0,
  earliest_publn_date BIGINT DEFAULT 99991231,
  earliest_publn_year BIGINT DEFAULT 9999,
  earliest_pat_publn_id BIGINT DEFAULT 0,
  granted CHAR(1) DEFAULT 'N',
  docdb_family_id BIGINT DEFAULT 0,
  inpadoc_family_id BIGINT DEFAULT 0,
  docdb_family_size BIGINT DEFAULT 0,
  nb_citing_docdb_fam BIGINT DEFAULT 0,
  nb_applicants BIGINT DEFAULT 0,
  nb_inventors BIGINT DEFAULT 0,
  PRIMARY KEY (appln_id) 
);

DO $$ BEGIN RAISE NOTICE 'Importing data into tls201_appln...'; END $$;

\copy tls201_appln FROM 'C:/Users/jesse/OneDrive/Research/Cross-border Patenting, Globalization, and Development/Data/Updating Patstat Data (12-2024)/data/raw tables/tls201_appln.csv' WITH (FORMAT csv, HEADER true);

/*****************************************************************************************
TLS204_APPLN_PRIOR
******************************************************************************************/
DROP TABLE IF EXISTS tls204_appln_prior;
CREATE TABLE tls204_appln_prior (
  appln_id BIGINT NOT NULL DEFAULT 0,
  prior_appln_id BIGINT NOT NULL DEFAULT 0,
  prior_appln_seq_nr BIGINT DEFAULT ('0'),
  PRIMARY KEY (appln_id, prior_appln_id)
);

DO $$ BEGIN RAISE NOTICE 'Importing data into tls204_appln_prior...'; END $$;

\copy tls204_appln_prior FROM 'C:/Users/jesse/OneDrive/Research/Cross-border Patenting, Globalization, and Development/Data/Updating Patstat Data (12-2024)/data/raw tables/tls204_appln_prior.csv' WITH (FORMAT csv, HEADER true);



/*****************************************************************************************
TLS205_TECH_REL
******************************************************************************************/
DROP TABLE IF EXISTS tls205_tech_rel;
CREATE TABLE tls205_tech_rel (
  appln_id BIGINT NOT NULL DEFAULT 0,
  tech_rel_appln_id BIGINT NOT NULL DEFAULT 0,
  PRIMARY KEY (appln_id, tech_rel_appln_id)
);

DO $$ BEGIN RAISE NOTICE 'Importing data into tls205_tech_rel...'; END $$;

\copy tls205_tech_rel FROM 'C:/Users/jesse/OneDrive/Research/Cross-border Patenting, Globalization, and Development/Data/Updating Patstat Data (12-2024)/data/raw tables/tls205_tech_rel.csv' WITH (FORMAT csv, HEADER true);

/*****************************************************************************************
TLS206_PERSON
******************************************************************************************/
DROP TABLE IF EXISTS tls206_person;
CREATE TABLE tls206_person (
  person_id bigint NOT NULL DEFAULT 0,
  person_name varchar(500) DEFAULT '',
  person_name_orig_lg varchar(500) DEFAULT '',  
  person_address varchar(1000) DEFAULT '',
  person_ctry_code char(2) DEFAULT '',
  nuts varchar(5) DEFAULT '',
  nuts_level bigint DEFAULT '9',
  doc_std_name_id bigint DEFAULT '0',
  doc_std_name varchar(500) DEFAULT '',
  psn_id bigint DEFAULT '0',
  psn_name varchar(500) DEFAULT '',
  psn_level bigint DEFAULT '0',
  psn_sector varchar(50) DEFAULT '',
  han_id bigint DEFAULT '0',
  han_name varchar(500) DEFAULT '',
  han_harmonized bigint DEFAULT '0',
  PRIMARY KEY (person_id)
);

DO $$ BEGIN RAISE NOTICE 'Importing data into tls206_person...'; END $$;

\copy tls206_person FROM 'C:/Users/jesse/OneDrive/Research/Cross-border Patenting, Globalization, and Development/Data/Updating Patstat Data (12-2024)/data/raw tables/tls206_person.csv' WITH (FORMAT csv, HEADER true, ENCODING 'utf8');

/*****************************************************************************************
TLS207_PERS_APPLN
******************************************************************************************/
DROP TABLE IF EXISTS tls206_person;
CREATE TABLE tls206_person (
  person_id bigint NOT NULL DEFAULT 0,
  person_name varchar(500) DEFAULT '',
  person_name_orig_lg varchar(500) DEFAULT '',  
  person_address varchar(1000) DEFAULT '',
  person_ctry_code char(2) DEFAULT '',
  nuts varchar(5) DEFAULT '',
  nuts_level bigint DEFAULT '9',
  doc_std_name_id bigint DEFAULT '0',
  doc_std_name varchar(500) DEFAULT '',
  psn_id bigint DEFAULT '0',
  psn_name varchar(500) DEFAULT '',
  psn_level bigint DEFAULT '0',
  psn_sector varchar(50) DEFAULT '',
  han_id bigint DEFAULT '0',
  han_name varchar(500) DEFAULT '',
  han_harmonized bigint DEFAULT '0',
  PRIMARY KEY (person_id)
);

DO $$ BEGIN RAISE NOTICE 'Importing data into tls207_person...'; END $$;

\copy tls207_person FROM 'C:/Users/jesse/OneDrive/Research/Cross-border Patenting, Globalization, and Development/Data/Updating Patstat Data (12-2024)/data/raw tables/tls207_person.csv' WITH (FORMAT csv, HEADER true, ENCODING 'WIN1252');

/*****************************************************************************************
TLS211_PAT_PUBLN
******************************************************************************************/
DROP TABLE IF EXISTS tls211_pat_publn;
CREATE TABLE tls211_pat_publn (
  pat_publn_id BIGINT NOT NULL DEFAULT 0,
  publn_auth CHAR(2) DEFAULT '',
  publn_nr VARCHAR(15) DEFAULT '',
  publn_nr_original VARCHAR(100) DEFAULT '',
  publn_kind CHAR(2) DEFAULT '',
  appln_id BIGINT DEFAULT 0,
  publn_date BIGINT DEFAULT 99991231,
  publn_lg CHAR(2) DEFAULT '',
  publn_first_grant CHAR(1) DEFAULT 'N',
  publn_claims BIGINT DEFAULT 0,
  PRIMARY KEY (pat_publn_id)
);

DO $$ BEGIN RAISE NOTICE 'Importing data into tls211_pat_publn...'; END $$;

\copy tls211_pat_publn FROM 'C:/Users/jesse/OneDrive/Research/Cross-border Patenting, Globalization, and Development/Data/Updating Patstat Data (12-2024)/data/raw tables/tls211_pat_publn.csv' WITH (FORMAT csv, HEADER true);

/*****************************************************************************************
TLS216_APPLN_CONTN
******************************************************************************************/
DROP TABLE IF EXISTS tls216_appln_contn;
CREATE TABLE tls216_appln_contn (
  appln_id BIGINT NOT NULL DEFAULT 0,
  parent_appln_id BIGINT NOT NULL DEFAULT 0,
  contn_type CHAR(3) DEFAULT '',
  PRIMARY KEY (appln_id, parent_appln_id)
);

DO $$ BEGIN RAISE NOTICE 'Importing data into tls216_appln_contn...'; END $$;

\copy tls216_appln_contn FROM 'C:/Users/jesse/OneDrive/Research/Cross-border Patenting, Globalization, and Development/Data/Updating Patstat Data (12-2024)/data/raw tables/tls216_appln_contn.csv' WITH (FORMAT csv, HEADER true);