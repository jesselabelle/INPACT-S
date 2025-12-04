DROP TABLE IF EXISTS families;
CREATE TABLE families AS
SELECT tls201_appln.appln_id, earliest_pat_publn_id, publn_nr,publn_auth, publn_kind, docdb_family_id
FROM tls201_appln
JOIN tls211_pat_publn ON tls201_appln.appln_id = tls211_pat_publn.appln_id
GROUP BY tls201_appln.appln_id, earliest_pat_publn_id, publn_nr,publn_auth, publn_kind, docdb_family_id;

\copy families TO 'H:/LMS_replication/Data/families/families.csv' csv header