# INPACT-S Version History

## How version numbers work

The major version identifies the PATSTAT source vintage. The subversion
identifies changes to the construction method within that vintage.

- **V1.x** uses PATSTAT Autumn 2021.
- **V2.x** uses PATSTAT Spring 2024.
- **x.0** uses the original construction method.
- **x.1** adds the first-and-subsequent-filings bridge method.
- **x.2** also retains applications that have no IPC classification.

## Releases

| Version | PATSTAT vintage | Construction method | Main difference from the preceding release |
|---|---|---|---|
| **V1.0** | Autumn 2021 | Original method | First public version of INPACT-S. |
| **V2.0** | Spring 2024 | Original method | Updates the underlying PATSTAT vintage and extends the available filing-year coverage. |
| **V2.1** | Spring 2024 | Bridge method | Adds a first-and-subsequent-filings bridge. When an application's origin is missing, the code can recover it from a related priority or parent application with a known country. |
| **V2.2** | Spring 2024 | Bridge method plus no-IPC recovery | Retains applications that have no IPC code instead of losing them at the IPC join. These applications are tagged with `ZZZZ` during extraction and assigned to the explicit **Unknown** sector (`isic_rev3_2 = 99`) during construction. |

## Current release

**INPACT-S V2.2 is the current public release and was last updated in June
2026.** Its default settings are:

- PATSTAT Spring 2024 source data;
- the first-and-subsequent-filings bridge enabled; and
- recovery of applications without an IPC classification enabled.

The Stata master script derives the version suffix from these settings. For the
current release, output files use the suffix `_V2_2`.

## Reproducibility note

One origin-imputation step uses WIPO aggregate patent data. Because WIPO updates
those data over time, downloading a different WIPO vintage can produce small
differences. The V2 construction used WIPO data downloaded in November 2025.

The first public V1.0 files were originally imported with Stata 15 SE. Running
the same raw text files through the newer Stata 17 import engine produces small
technical differences because the newer parser handles malformed quotation
marks more reliably. See
`datasets/Discrepancies in INPACT-S V1.0 Using New Code.log` for the comparison.
