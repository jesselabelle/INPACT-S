DROP TABLE IF EXISTS citations_slim;
CREATE TABLE citations_slim AS
SELECT appln_id, tls211_pat_publn.pat_publn_id, cited_pat_publn_id, cited_appln_id
FROM tls212_citation
JOIN tls211_pat_publn ON tls212_citation.pat_publn_id = tls211_pat_publn.pat_publn_id
WHERE pat_citn_seq_nr > 0
AND citn_origin = 'APP'
GROUP BY appln_id, tls211_pat_publn.pat_publn_id, cited_pat_publn_id, cited_appln_id;
\copy citations_slim TO 'H:/RTAs_SupplyChainPatenting/raw/citations/citations_data_slim.csv' csv header


DROP TABLE IF EXISTS publn_appln_crosswalk;
CREATE TABLE publn_appln_crosswalk AS
SELECT appln_id, pat_publn_id
FROM tls211_pat_publn
GROUP BY appln_id, pat_publn_id;
\copy publn_appln_crosswalk TO 'H:/RTAs_SupplyChainPatenting/raw/citations/publn_appln_crosswalk.csv' csv header