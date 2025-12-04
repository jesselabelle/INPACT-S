\# Versioning scheme



We use a two-dimensional version number: V<data>.<code>



\- The first index (data version) tracks changes in the \*\*raw data source\*\*.

&nbsp; - Example: PATSTAT 2023b vs PATSTAT 2025a.

&nbsp; - V1.\* = PATSTAT vintage 1 (e.g. 2023b).

&nbsp; - V2.\* = PATSTAT vintage 2 (e.g. 2025a).



\- The second index (code version) tracks changes in the \*\*code\*\* that affect final numbers.

&nbsp; - V1.0, V1.1, V1.2 ... all use the same raw data, but the Stata/SQL pipeline differs.

&nbsp; - If the code change does not affect final reported results (e.g. refactoring, speedups only), we do not bump the code index.



\## Mapping to directory structure



We define:



\- `data/raw/D<data\_version>/`

&nbsp; - Example: `data/raw/D1/` contains the PATSTAT (and other) raw extracts for data version 1.



\- `data/intermediate/D<data\_version>\_C<code\_version>/`

&nbsp; - Example: `data/intermediate/D1\_C0/` contains intermediate files for data version 1, code version 0.



\- `data/final/D<data\_version>\_C<code\_version>/`

&nbsp; - Example: `data/final/D1\_C0/` contains final outputs (e.g. INPACT-S datasets) for data version 1, code version 0.



\## Stata master script



The Stata master script is called as:



&nbsp;   do code/master.do <data\_version> <code\_version>



Examples:



\- `do code/master.do 1 0`  → V1.0 (PATSTAT v1, code v0)

\- `do code/master.do 1 1`  → V1.1 (same PATSTAT as V1.0, updated code)

\- `do code/master.do 2 0`  → V2.0 (new PATSTAT vintage, initial code for that data)



