DROP TABLE IF EXISTS applications1;
CREATE TABLE applications1 AS
SELECT tls201_appln.appln_id, tls207_pers_appln.person_id, earliest_pat_publn_id, appln_auth, person_ctry_code, appln_filing_year, publn_nr, publn_nr_original, publn_auth, publn_kind, granted, SUBSTRING(ipc_class_symbol,1,4) AS ipc4, COUNT(SUBSTRING(ipc_class_symbol,1,4)) AS ipc4count, inpadoc_family_id
FROM tls201_appln
JOIN tls207_pers_appln ON tls201_appln.appln_id = tls207_pers_appln.appln_id
JOIN tls206_person ON tls207_pers_appln.person_id = tls206_person.person_id
JOIN tls209_appln_ipc ON tls201_appln.appln_id = tls209_appln_ipc.appln_id
JOIN tls211_pat_publn ON tls201_appln.appln_id = tls211_pat_publn.appln_id
WHERE appln_filing_year >= 1940 AND appln_filing_year <= 1944
AND appln_kind = 'A '
AND invt_seq_nr > 0
GROUP BY tls201_appln.appln_id, tls207_pers_appln.person_id, appln_auth, earliest_pat_publn_id, person_ctry_code, appln_filing_year, granted, SUBSTRING(ipc_class_symbol,1,4),  publn_nr, publn_nr_original, publn_auth, publn_kind, inpadoc_family_id;

\copy applications1 TO 'H:/RTAs_SupplyChainPatenting/raw/invt/applications1940_1944.csv' csv header

DROP TABLE IF EXISTS applications1;
CREATE TABLE applications1 AS
SELECT tls201_appln.appln_id, tls207_pers_appln.person_id, earliest_pat_publn_id, appln_auth, person_ctry_code, appln_filing_year, publn_nr, publn_nr_original, publn_auth, publn_kind, granted, SUBSTRING(ipc_class_symbol,1,4) AS ipc4, COUNT(SUBSTRING(ipc_class_symbol,1,4)) AS ipc4count, inpadoc_family_id
FROM tls201_appln
JOIN tls207_pers_appln ON tls201_appln.appln_id = tls207_pers_appln.appln_id
JOIN tls206_person ON tls207_pers_appln.person_id = tls206_person.person_id
JOIN tls209_appln_ipc ON tls201_appln.appln_id = tls209_appln_ipc.appln_id
JOIN tls211_pat_publn ON tls201_appln.appln_id = tls211_pat_publn.appln_id
WHERE appln_filing_year >= 1945 AND appln_filing_year <= 1949
AND appln_kind = 'A '
AND invt_seq_nr > 0
GROUP BY tls201_appln.appln_id, tls207_pers_appln.person_id, appln_auth, earliest_pat_publn_id, person_ctry_code, appln_filing_year, granted, SUBSTRING(ipc_class_symbol,1,4),  publn_nr, publn_nr_original, publn_auth, publn_kind, inpadoc_family_id;

\copy applications1 TO 'H:/RTAs_SupplyChainPatenting/raw/invt/applications1945_1949.csv' csv header

DROP TABLE IF EXISTS applications1;
CREATE TABLE applications1 AS
SELECT tls201_appln.appln_id, tls207_pers_appln.person_id, earliest_pat_publn_id, appln_auth, person_ctry_code, appln_filing_year, publn_nr, publn_nr_original, publn_auth, publn_kind, granted, SUBSTRING(ipc_class_symbol,1,4) AS ipc4, COUNT(SUBSTRING(ipc_class_symbol,1,4)) AS ipc4count, inpadoc_family_id
FROM tls201_appln
JOIN tls207_pers_appln ON tls201_appln.appln_id = tls207_pers_appln.appln_id
JOIN tls206_person ON tls207_pers_appln.person_id = tls206_person.person_id
JOIN tls209_appln_ipc ON tls201_appln.appln_id = tls209_appln_ipc.appln_id
JOIN tls211_pat_publn ON tls201_appln.appln_id = tls211_pat_publn.appln_id
WHERE appln_filing_year >= 1950 AND appln_filing_year <= 1954
AND appln_kind = 'A '
AND invt_seq_nr > 0
GROUP BY tls201_appln.appln_id, tls207_pers_appln.person_id, appln_auth, earliest_pat_publn_id, person_ctry_code, appln_filing_year, granted, SUBSTRING(ipc_class_symbol,1,4),  publn_nr, publn_nr_original, publn_auth, publn_kind, inpadoc_family_id;

\copy applications1 TO 'H:/RTAs_SupplyChainPatenting/raw/invt/applications1950_1954.csv' csv header

DROP TABLE IF EXISTS applications1;
CREATE TABLE applications1 AS
SELECT tls201_appln.appln_id, tls207_pers_appln.person_id, earliest_pat_publn_id, appln_auth, person_ctry_code, appln_filing_year, publn_nr, publn_nr_original, publn_auth, publn_kind, granted, SUBSTRING(ipc_class_symbol,1,4) AS ipc4, COUNT(SUBSTRING(ipc_class_symbol,1,4)) AS ipc4count, inpadoc_family_id
FROM tls201_appln
JOIN tls207_pers_appln ON tls201_appln.appln_id = tls207_pers_appln.appln_id
JOIN tls206_person ON tls207_pers_appln.person_id = tls206_person.person_id
JOIN tls209_appln_ipc ON tls201_appln.appln_id = tls209_appln_ipc.appln_id
JOIN tls211_pat_publn ON tls201_appln.appln_id = tls211_pat_publn.appln_id
WHERE appln_filing_year >= 1955 AND appln_filing_year <= 1959
AND appln_kind = 'A '
AND invt_seq_nr > 0
GROUP BY tls201_appln.appln_id, tls207_pers_appln.person_id, appln_auth, earliest_pat_publn_id, person_ctry_code, appln_filing_year, granted, SUBSTRING(ipc_class_symbol,1,4),  publn_nr, publn_nr_original, publn_auth, publn_kind, inpadoc_family_id;

\copy applications1 TO 'H:/RTAs_SupplyChainPatenting/raw/invt/applications1955_1959.csv' csv header

DROP TABLE IF EXISTS applications1;
CREATE TABLE applications1 AS
SELECT tls201_appln.appln_id, tls207_pers_appln.person_id, earliest_pat_publn_id, appln_auth, person_ctry_code, appln_filing_year, publn_nr, publn_nr_original, publn_auth, publn_kind, granted, SUBSTRING(ipc_class_symbol,1,4) AS ipc4, COUNT(SUBSTRING(ipc_class_symbol,1,4)) AS ipc4count, inpadoc_family_id
FROM tls201_appln
JOIN tls207_pers_appln ON tls201_appln.appln_id = tls207_pers_appln.appln_id
JOIN tls206_person ON tls207_pers_appln.person_id = tls206_person.person_id
JOIN tls209_appln_ipc ON tls201_appln.appln_id = tls209_appln_ipc.appln_id
JOIN tls211_pat_publn ON tls201_appln.appln_id = tls211_pat_publn.appln_id
WHERE appln_filing_year >= 1960 AND appln_filing_year <= 1964
AND appln_kind = 'A '
AND invt_seq_nr > 0
GROUP BY tls201_appln.appln_id, tls207_pers_appln.person_id, appln_auth, earliest_pat_publn_id, person_ctry_code, appln_filing_year, granted, SUBSTRING(ipc_class_symbol,1,4),  publn_nr, publn_nr_original, publn_auth, publn_kind, inpadoc_family_id;

\copy applications1 TO 'H:/RTAs_SupplyChainPatenting/raw/invt/applications1960_1964.csv' csv header

DROP TABLE IF EXISTS applications1;
CREATE TABLE applications1 AS
SELECT tls201_appln.appln_id, tls207_pers_appln.person_id, earliest_pat_publn_id, appln_auth, person_ctry_code, appln_filing_year, publn_nr, publn_nr_original, publn_auth, publn_kind, granted, SUBSTRING(ipc_class_symbol,1,4) AS ipc4, COUNT(SUBSTRING(ipc_class_symbol,1,4)) AS ipc4count, inpadoc_family_id
FROM tls201_appln
JOIN tls207_pers_appln ON tls201_appln.appln_id = tls207_pers_appln.appln_id
JOIN tls206_person ON tls207_pers_appln.person_id = tls206_person.person_id
JOIN tls209_appln_ipc ON tls201_appln.appln_id = tls209_appln_ipc.appln_id
JOIN tls211_pat_publn ON tls201_appln.appln_id = tls211_pat_publn.appln_id
WHERE appln_filing_year >= 1965 AND appln_filing_year <= 1969
AND appln_kind = 'A '
AND invt_seq_nr > 0
GROUP BY tls201_appln.appln_id, tls207_pers_appln.person_id, appln_auth, earliest_pat_publn_id, person_ctry_code, appln_filing_year, granted, SUBSTRING(ipc_class_symbol,1,4),  publn_nr, publn_nr_original, publn_auth, publn_kind, inpadoc_family_id;

\copy applications1 TO 'H:/RTAs_SupplyChainPatenting/raw/invt/applications1965_1969.csv' csv header

DROP TABLE IF EXISTS applications1;
CREATE TABLE applications1 AS
SELECT tls201_appln.appln_id, tls207_pers_appln.person_id, earliest_pat_publn_id, appln_auth, person_ctry_code, appln_filing_year, publn_nr, publn_nr_original, publn_auth, publn_kind, granted, SUBSTRING(ipc_class_symbol,1,4) AS ipc4, COUNT(SUBSTRING(ipc_class_symbol,1,4)) AS ipc4count, inpadoc_family_id
FROM tls201_appln
JOIN tls207_pers_appln ON tls201_appln.appln_id = tls207_pers_appln.appln_id
JOIN tls206_person ON tls207_pers_appln.person_id = tls206_person.person_id
JOIN tls209_appln_ipc ON tls201_appln.appln_id = tls209_appln_ipc.appln_id
JOIN tls211_pat_publn ON tls201_appln.appln_id = tls211_pat_publn.appln_id
WHERE appln_filing_year >= 1970 AND appln_filing_year <= 1974
AND appln_kind = 'A '
AND invt_seq_nr > 0
GROUP BY tls201_appln.appln_id, tls207_pers_appln.person_id, appln_auth, earliest_pat_publn_id, person_ctry_code, appln_filing_year, granted, SUBSTRING(ipc_class_symbol,1,4),  publn_nr, publn_nr_original, publn_auth, publn_kind, inpadoc_family_id;

\copy applications1 TO 'H:/RTAs_SupplyChainPatenting/raw/invt/applications1970_1974.csv' csv header

DROP TABLE IF EXISTS applications1;
CREATE TABLE applications1 AS
SELECT tls201_appln.appln_id, tls207_pers_appln.person_id, earliest_pat_publn_id, appln_auth, person_ctry_code, appln_filing_year, publn_nr, publn_nr_original, publn_auth, publn_kind, granted, SUBSTRING(ipc_class_symbol,1,4) AS ipc4, COUNT(SUBSTRING(ipc_class_symbol,1,4)) AS ipc4count, inpadoc_family_id
FROM tls201_appln
JOIN tls207_pers_appln ON tls201_appln.appln_id = tls207_pers_appln.appln_id
JOIN tls206_person ON tls207_pers_appln.person_id = tls206_person.person_id
JOIN tls209_appln_ipc ON tls201_appln.appln_id = tls209_appln_ipc.appln_id
JOIN tls211_pat_publn ON tls201_appln.appln_id = tls211_pat_publn.appln_id
WHERE appln_filing_year >= 1975 AND appln_filing_year <= 1979
AND appln_kind = 'A '
AND invt_seq_nr > 0
GROUP BY tls201_appln.appln_id, tls207_pers_appln.person_id, appln_auth, earliest_pat_publn_id, person_ctry_code, appln_filing_year, granted, SUBSTRING(ipc_class_symbol,1,4),  publn_nr, publn_nr_original, publn_auth, publn_kind, inpadoc_family_id;

\copy applications1 TO 'H:/RTAs_SupplyChainPatenting/raw/invt/applications1975_1979.csv' csv header

DROP TABLE IF EXISTS applications1;
CREATE TABLE applications1 AS
SELECT tls201_appln.appln_id, tls207_pers_appln.person_id, earliest_pat_publn_id, appln_auth, person_ctry_code, appln_filing_year, publn_nr, publn_nr_original, publn_auth, publn_kind, granted, SUBSTRING(ipc_class_symbol,1,4) AS ipc4, COUNT(SUBSTRING(ipc_class_symbol,1,4)) AS ipc4count, inpadoc_family_id
FROM tls201_appln
JOIN tls207_pers_appln ON tls201_appln.appln_id = tls207_pers_appln.appln_id
JOIN tls206_person ON tls207_pers_appln.person_id = tls206_person.person_id
JOIN tls209_appln_ipc ON tls201_appln.appln_id = tls209_appln_ipc.appln_id
JOIN tls211_pat_publn ON tls201_appln.appln_id = tls211_pat_publn.appln_id
WHERE appln_filing_year >= 1980 AND appln_filing_year <= 1984
AND appln_kind = 'A '
AND invt_seq_nr > 0
GROUP BY tls201_appln.appln_id, tls207_pers_appln.person_id, appln_auth, earliest_pat_publn_id, person_ctry_code, appln_filing_year, granted, SUBSTRING(ipc_class_symbol,1,4),  publn_nr, publn_nr_original, publn_auth, publn_kind, inpadoc_family_id;

\copy applications1 TO 'H:/RTAs_SupplyChainPatenting/raw/invt/applications1980_1984.csv' csv header

DROP TABLE IF EXISTS applications1;
CREATE TABLE applications1 AS
SELECT tls201_appln.appln_id, tls207_pers_appln.person_id, earliest_pat_publn_id, appln_auth, person_ctry_code, appln_filing_year, publn_nr, publn_nr_original, publn_auth, publn_kind, granted, SUBSTRING(ipc_class_symbol,1,4) AS ipc4, COUNT(SUBSTRING(ipc_class_symbol,1,4)) AS ipc4count, inpadoc_family_id
FROM tls201_appln
JOIN tls207_pers_appln ON tls201_appln.appln_id = tls207_pers_appln.appln_id
JOIN tls206_person ON tls207_pers_appln.person_id = tls206_person.person_id
JOIN tls209_appln_ipc ON tls201_appln.appln_id = tls209_appln_ipc.appln_id
JOIN tls211_pat_publn ON tls201_appln.appln_id = tls211_pat_publn.appln_id
WHERE appln_filing_year >= 1985 AND appln_filing_year <= 1989
AND appln_kind = 'A '
AND invt_seq_nr > 0
GROUP BY tls201_appln.appln_id, tls207_pers_appln.person_id, appln_auth, earliest_pat_publn_id, person_ctry_code, appln_filing_year, granted, SUBSTRING(ipc_class_symbol,1,4),  publn_nr, publn_nr_original, publn_auth, publn_kind, inpadoc_family_id;

\copy applications1 TO 'H:/RTAs_SupplyChainPatenting/raw/invt/applications1985_1989.csv' csv header

DROP TABLE IF EXISTS applications1;
CREATE TABLE applications1 AS
SELECT tls201_appln.appln_id, tls207_pers_appln.person_id, earliest_pat_publn_id, appln_auth, person_ctry_code, appln_filing_year, publn_nr, publn_nr_original, publn_auth, publn_kind, granted, SUBSTRING(ipc_class_symbol,1,4) AS ipc4, COUNT(SUBSTRING(ipc_class_symbol,1,4)) AS ipc4count, inpadoc_family_id
FROM tls201_appln
JOIN tls207_pers_appln ON tls201_appln.appln_id = tls207_pers_appln.appln_id
JOIN tls206_person ON tls207_pers_appln.person_id = tls206_person.person_id
JOIN tls209_appln_ipc ON tls201_appln.appln_id = tls209_appln_ipc.appln_id
JOIN tls211_pat_publn ON tls201_appln.appln_id = tls211_pat_publn.appln_id
WHERE appln_filing_year >= 1990 AND appln_filing_year <= 1994
AND appln_kind = 'A '
AND invt_seq_nr > 0
GROUP BY tls201_appln.appln_id, tls207_pers_appln.person_id, appln_auth, earliest_pat_publn_id, person_ctry_code, appln_filing_year, granted, SUBSTRING(ipc_class_symbol,1,4),  publn_nr, publn_nr_original, publn_auth, publn_kind, inpadoc_family_id;

\copy applications1 TO 'H:/RTAs_SupplyChainPatenting/raw/invt/applications1990_1994.csv' csv header

DROP TABLE IF EXISTS applications1;
CREATE TABLE applications1 AS
SELECT tls201_appln.appln_id, tls207_pers_appln.person_id, earliest_pat_publn_id, appln_auth, person_ctry_code, appln_filing_year, publn_nr, publn_nr_original, publn_auth, publn_kind, granted, SUBSTRING(ipc_class_symbol,1,4) AS ipc4, COUNT(SUBSTRING(ipc_class_symbol,1,4)) AS ipc4count, inpadoc_family_id
FROM tls201_appln
JOIN tls207_pers_appln ON tls201_appln.appln_id = tls207_pers_appln.appln_id
JOIN tls206_person ON tls207_pers_appln.person_id = tls206_person.person_id
JOIN tls209_appln_ipc ON tls201_appln.appln_id = tls209_appln_ipc.appln_id
JOIN tls211_pat_publn ON tls201_appln.appln_id = tls211_pat_publn.appln_id
WHERE appln_filing_year >= 1995 AND appln_filing_year <= 1999
AND appln_kind = 'A '
AND invt_seq_nr > 0
GROUP BY tls201_appln.appln_id, tls207_pers_appln.person_id, appln_auth, earliest_pat_publn_id, person_ctry_code, appln_filing_year, granted, SUBSTRING(ipc_class_symbol,1,4),  publn_nr, publn_nr_original, publn_auth, publn_kind, inpadoc_family_id;

\copy applications1 TO 'H:/RTAs_SupplyChainPatenting/raw/invt/applications1995_1999.csv' csv header

DROP TABLE IF EXISTS applications1;
CREATE TABLE applications1 AS
SELECT tls201_appln.appln_id, tls207_pers_appln.person_id, earliest_pat_publn_id, appln_auth, person_ctry_code, appln_filing_year, publn_nr, publn_nr_original, publn_auth, publn_kind, granted, SUBSTRING(ipc_class_symbol,1,4) AS ipc4, COUNT(SUBSTRING(ipc_class_symbol,1,4)) AS ipc4count, inpadoc_family_id
FROM tls201_appln
JOIN tls207_pers_appln ON tls201_appln.appln_id = tls207_pers_appln.appln_id
JOIN tls206_person ON tls207_pers_appln.person_id = tls206_person.person_id
JOIN tls209_appln_ipc ON tls201_appln.appln_id = tls209_appln_ipc.appln_id
JOIN tls211_pat_publn ON tls201_appln.appln_id = tls211_pat_publn.appln_id
WHERE appln_filing_year >= 2000 AND appln_filing_year <= 2004
AND appln_kind = 'A '
AND invt_seq_nr > 0
GROUP BY tls201_appln.appln_id, tls207_pers_appln.person_id, appln_auth, earliest_pat_publn_id, person_ctry_code, appln_filing_year, granted, SUBSTRING(ipc_class_symbol,1,4),  publn_nr, publn_nr_original, publn_auth, publn_kind, inpadoc_family_id;

\copy applications1 TO 'H:/RTAs_SupplyChainPatenting/raw/invt/applications2000_2004.csv' csv header

DROP TABLE IF EXISTS applications1;
CREATE TABLE applications1 AS
SELECT tls201_appln.appln_id, tls207_pers_appln.person_id, earliest_pat_publn_id, appln_auth, person_ctry_code, appln_filing_year, publn_nr, publn_nr_original, publn_auth, publn_kind, granted, SUBSTRING(ipc_class_symbol,1,4) AS ipc4, COUNT(SUBSTRING(ipc_class_symbol,1,4)) AS ipc4count, inpadoc_family_id
FROM tls201_appln
JOIN tls207_pers_appln ON tls201_appln.appln_id = tls207_pers_appln.appln_id
JOIN tls206_person ON tls207_pers_appln.person_id = tls206_person.person_id
JOIN tls209_appln_ipc ON tls201_appln.appln_id = tls209_appln_ipc.appln_id
JOIN tls211_pat_publn ON tls201_appln.appln_id = tls211_pat_publn.appln_id
WHERE appln_filing_year >= 2005 AND appln_filing_year <= 2009
AND appln_kind = 'A '
AND invt_seq_nr > 0
GROUP BY tls201_appln.appln_id, tls207_pers_appln.person_id, appln_auth, earliest_pat_publn_id, person_ctry_code, appln_filing_year, granted, SUBSTRING(ipc_class_symbol,1,4),  publn_nr, publn_nr_original, publn_auth, publn_kind, inpadoc_family_id;

\copy applications1 TO 'H:/RTAs_SupplyChainPatenting/raw/invt/applications2005_2009.csv' csv header

DROP TABLE IF EXISTS applications1;
CREATE TABLE applications1 AS
SELECT tls201_appln.appln_id, tls207_pers_appln.person_id, earliest_pat_publn_id, appln_auth, person_ctry_code, appln_filing_year, publn_nr, publn_nr_original, publn_auth, publn_kind, granted, SUBSTRING(ipc_class_symbol,1,4) AS ipc4, COUNT(SUBSTRING(ipc_class_symbol,1,4)) AS ipc4count, inpadoc_family_id
FROM tls201_appln
JOIN tls207_pers_appln ON tls201_appln.appln_id = tls207_pers_appln.appln_id
JOIN tls206_person ON tls207_pers_appln.person_id = tls206_person.person_id
JOIN tls209_appln_ipc ON tls201_appln.appln_id = tls209_appln_ipc.appln_id
JOIN tls211_pat_publn ON tls201_appln.appln_id = tls211_pat_publn.appln_id
WHERE appln_filing_year >= 2010 AND appln_filing_year <= 2014
AND appln_kind = 'A '
AND invt_seq_nr > 0
GROUP BY tls201_appln.appln_id, tls207_pers_appln.person_id, appln_auth, earliest_pat_publn_id, person_ctry_code, appln_filing_year, granted, SUBSTRING(ipc_class_symbol,1,4),  publn_nr, publn_nr_original, publn_auth, publn_kind, inpadoc_family_id;

\copy applications1 TO 'H:/RTAs_SupplyChainPatenting/raw/invt/applications2010_2014.csv' csv header

DROP TABLE IF EXISTS applications1;
CREATE TABLE applications1 AS
SELECT tls201_appln.appln_id, tls207_pers_appln.person_id, earliest_pat_publn_id, appln_auth, person_ctry_code, appln_filing_year, publn_nr, publn_nr_original, publn_auth, publn_kind, granted, SUBSTRING(ipc_class_symbol,1,4) AS ipc4, COUNT(SUBSTRING(ipc_class_symbol,1,4)) AS ipc4count, inpadoc_family_id
FROM tls201_appln
JOIN tls207_pers_appln ON tls201_appln.appln_id = tls207_pers_appln.appln_id
JOIN tls206_person ON tls207_pers_appln.person_id = tls206_person.person_id
JOIN tls209_appln_ipc ON tls201_appln.appln_id = tls209_appln_ipc.appln_id
JOIN tls211_pat_publn ON tls201_appln.appln_id = tls211_pat_publn.appln_id
WHERE appln_filing_year >= 2015 AND appln_filing_year <= 2019
AND appln_kind = 'A '
AND invt_seq_nr > 0
GROUP BY tls201_appln.appln_id, tls207_pers_appln.person_id, appln_auth, earliest_pat_publn_id, person_ctry_code, appln_filing_year, granted, SUBSTRING(ipc_class_symbol,1,4),  publn_nr, publn_nr_original, publn_auth, publn_kind, inpadoc_family_id;

\copy applications1 TO 'H:/RTAs_SupplyChainPatenting/raw/invt/applications2015_2019.csv' csv header

