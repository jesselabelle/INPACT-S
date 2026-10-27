# INPACT-S: Cross-Border Patenting and Citation Datasets

> **Current release: INPACT-S V2.2**  
> **Dataset release last updated: June 2026**  
> **PATSTAT source vintage: Spring 2024**

This repository contains the **data-construction code** for INPACT-S. It is
separate from the paper's empirical replication package. See
[VERSION_HISTORY.md](VERSION_HISTORY.md) for a precise description of the
differences among V1.0, V2.0, V2.1, and V2.2.

### Authors
Jesse LaBelle, Inmaculada Martínez-Zarzoso, Ana Maria Santacreu, and Yoto Yotov

### Paper Citation
Any use of this dataset should be accompanied with citation of the following paper:

LaBelle, Jesse and Martinez-Zarzoso, Inmaculada and Santacreu, Ana Maria Maria and Yotov, Yoto, Cross-Border Patenting, Globalization, and Development (2023). CESifo Working Paper No. 10850, Available at SSRN: https://ssrn.com/abstract=4676768 or http://dx.doi.org/10.2139/ssrn.4676768

### Dataset Access
To access the latest version of this dataset please visit: https://sites.google.com/uji.es/inma-martinez-zarzoso/home/datasets. Past versions of the dataset are available upon request.

---

## 1. Overview
This repository contains the code used to construct INPACT-S. The workflow
integrates PostgreSQL for high-performance processing of raw PATSTAT data and
Stata for fractional counting, missing-country imputation, and bilateral-flow
construction. The default configuration reproduces **INPACT-S V2.2**.

## 2. Prerequisites
* PostgreSQL: Installed and configured (scripts optimized for Windows psql).
* Stata: Version 16 or higher required.
* Hardware: STATA code is extremely RAM intensive and makes extensive use of frames. This code was written and run using Northwestern Universities Quest high-performance computing cluster. Authors recommend using HPC clusters if possible to avoid issues with RAM/Disk memory and optimize performance. SQL scripts are tuned to use 1GB work_mem and 2047MB maintenance_work_mem to stay within Windows memory limits and can be run on a standard work laptop.

## 3. Repository Structure
The repository is organized to maintain a clear separation between source code and generated data:

* code/sql/: Core scripts for database import, country imputation, and data extraction.
* code/stata/: Analysis scripts for building fractional counts and final bilateral flows.
* data/raw/crosswalks/: (Included) Essential mapping files (WIPO ST.3, Regional Authorities, etc.).
* data/sql_output/: (User Created) Target directory for all SQL exports.

Note: Some necessary but publicly available data is not included in this repository. In such cases, detailed information on how and where to find this data is included.
---

## 4. Replication Steps

### Phase 1: PostgreSQL Extraction
1. Ensure your raw PATSTAT CSV files are grouped by tls and placed in data/raw/patstat_[vintage]/.
2. Open code/sql/0_master_clean_patstat.sql and set your :patstat_schema to match your folder name.
3. Run the master SQL script via command line:
   psql -U postgres -f code/sql/0_master_clean_patstat.sql
   
   *This generates the 5-year application windows required for Stata processing.*

### Phase 2: Stata Construction
1. Open Stata and set your working directory to the project root.
2. Run code/stata/0 -- Master For Public Folder.do.
3. The master script will automatically handle the execution of:
   * 1 -- deRassenfosse Imputation.do: Cleans and fills missing country codes.
   * 2 -- Bilateral Patent Flows Construction.do: Constructs the final dataset using fractional counting and all methods described in the paper.

---

## 5. Data Privacy Note
This repository uses a .gitignore policy that excludes heavy raw data (PATSTAT) and local archives. Only code and small, non-proprietary crosswalk files are tracked. To replicate the full dataset, you must provide your own PATSTAT source files in the data/raw/ directory.

---
