/*-------------------------------------------------------------------------
code/master.do
Master script for INPACT replication
Usage: do code/master.do <data_version> <code_version>
Example: do code/master.do 1 0
----------------------------------------------------------------------------*/

*------------------------------
* Choose data and code version
*------------------------------
args data_version code_version

if "`data_version'" == "" | "`code_version'" == "" {
    di as error "Usage: do code/master.do <data_version> <code_version>"
    di as error "Example: do code/master.do 1 0   // PATSTAT v1, code v0"
    exit 198
}

*-------------------------------------------------
* Store versions as globals for downstream scripts
*-------------------------------------------------
global DATA_VERSION "`data_version'"
global CODE_VERSION "`code_version'"

* -----
* Paths
* -----
global ROOT "."
global CODE  "$ROOT/code"
global DATA  "$ROOT/data"

* ----------------------------------------
* Raw data depends only on PATSTAT version
* e.g. data/raw/D1/, data/raw/D2/
* ----------------------------------------
global RAW      "$DATA/raw/D$DATA_VERSION"

* ------------------------------------------------
* Outputs depend on both data and code versions
* e.g. data/intermediate/D1_C0/, data/final/D1_C0/
* ------------------------------------------------
global EXTERNAL "$DATA/external"
global INTER    "$DATA/intermediate/D$DATA_VERSION_C$CODE_VERSION"
global FINAL    "$DATA/final/D$DATA_VERSION_C$CODE_VERSION"

* ------------------------------------------------
* Create versioned output dirs if they don't exist
* ------------------------------------------------
cap mkdir "$DATA/intermediate"
cap mkdir "$DATA/final"
cap mkdir "$INTER"
cap mkdir "$FINAL"
