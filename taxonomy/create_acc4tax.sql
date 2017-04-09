/*

  * NAME:   
    
    create_acc4tax.sql

  * SYNOPSIS:

  * DESCRIPTION:

    ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/accession2taxid/README

    **The NCBI has phased out use of gi numbers since September 2016.**

    Create a SQLite3 empty database for storing accession and taxonomy ID
    in NCBI taxonomy database.

    File content:

    All files have 4 columns separated by a TAB character. 

    The first line in each file is a header line:

    accession<TAB>accession.version<TAB>taxid<TAB>gi

    Columns:

    (1) Accession:
        Accession of the sequence record, w/o a version.
        e.g., BA000005

    (2) Accession.version:
        Accession of the sequence record togther with the version numnber.
        e.g., BA000005.3

        Some dead sequence records do not have any version numner in which
        case the value in this column will be the accession followed by
        a dot. e.g., X53318

    (3) TaxID
        Taxonomy identifier of the source organism for the sequence record,
        e.g., 9606.

        If for some reason the source organism cannot be mapped to the
        taxonomy database, the column will contain "0".

    (4) GI
        GI of the sequence record.
        e.g., 55417888

        NCBI is phasing out use of gi numbers, see:
        http://www.ncbi.nlm.nih.gov/news/03-02-2016-phase-out-of-GI-numbers/

        Some sequences such as unannotated WGS and TSA records already lack
        a GI. If a sequence record does not have a GI assigned, the column
        will contain "na".

    The contents of the files is unsorted.

*/

-- Create tables

CREATE TABLE release (
    rel_id      INTEGER PRIMARY KEY AUTOINCREMENT,
    rel_date    DATETIME DEFAULT CURRENT_DATE
);

CREATE TABLE acc4tax (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    acc         TEXT NOT NULL DEFAULT '',
    acc_ver     TEXT NOT NULL DEFAULT '',
    tax_id      INTEGER NOT NULL DEFAULT 0,
    gi          TEXT NOT NULL DEFAULT 'na'
);

-- Create indices
CREATE INDEX idx_acc4tax_acc ON acc4tax(acc);
CREATE INDEX idx_acc4tax_acc_ver ON acc4tax(acc_ver);
CREATE INDEX idx_acc4tax_tax_id ON acc4tax(tax_id);
CREATE INDEX idx_acc4tax_gi ON acc4tax(gi);

