README: Note on Data Import Discrepancies (Stata Versioning)
Date: October 2025 Software: Stata 15 SE vs. Stata 17 MP

THE LASTEST VERSION OF THE DATASET CAN BE ACCESS HERE: https://sites.google.com/uji.es/inma-martinez-zarzoso/home/datasets

Overview
This document addresses minor discrepancies between the first publicly available INPACT-S v1.0 and the same data produced with the code in this repository
driven by issues importing raw text files using Stata 17 MP compared to the original import performed in Stata 15 SE.

These differences are technical artifacts of the import engine and will not affect the substantive conclusions or replicability of any studies using the data.

Technical Explanation:

The original data processing was performed in Stata 15 SE. The import delimited parser in older versions of Stata (prior to v17) utilized a single-core engine that was 
susceptible to "quote binding." In instances where the raw text file contained unmatched quotation marks (e.g., 5'9" or O'Connor), Stata 15 would occasionally interpret 
a line break as part of a string, causing two distinct rows of data to merge into a single observation in rare cases.

The current data was processed using Stata 17 MP. Stata 17 introduced a parallelized import engine with improved heuristics for handling delimited text. 
This updated engine correctly identifies stray quotes as text characters rather than string delimiters, preventing row merging and resulting in a slightly higher, 
more accurate observation count.

Impact Assessment
Match Rate: 99.7% of the data matches exactly between the two versions.

Replicability: These differences do not pose a concern for the replicability of the results. The Stata 17 import represents the "cleaner" and more accurate reading 
of the raw source files but the differences are negligible. To see how minor this differences are please see 'Discrepancies in INPACT-S V1.0 Using New Code.log'