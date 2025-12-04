DROP TABLE IF EXISTS citations;
CREATE TABLE citations AS
SELECT pat_publn_id, citn_id, citn_origin, cited_pat_publn_id, cited_appln_id, pat_citn_seq_nr, citn_gener_auth
FROM tls212_citation
WHERE pat_citn_seq_nr > 0
AND citn_origin = 'APP'
ORDER BY pat_publn_id, citn_id;
\copy citations TO 'H:/RTAs_SupplyChainPatenting/raw/citations/citations_data.csv' csv header