/*

 * NAME

    blast2taxon.sql

 * DESCRIPTION

    Create database 'blast2taxon'.

  * AUTHOR

    zeroliu-at-gmail-dot-com

  * VERSION

    0.0.1   2015-12-29
    0.0.2   2016-01-20  Bug fix

*/

-- Table 'analysis'

-- Basic information and statistics.

CREATE TABLE analysis (
    id          INTEGER PRIMARY KEY,
    anlys_desc  TEXT NOT NULL DEFAULT '',
    blastprg    TEXT NOT NULL DEFAULT '',
    total_seq   INTEGER NOT NULL DEFAULT 0, -- Number of sequences/reads
    hit_seq     INTEGER NOT NULL DEFAULT 0, -- Number of sequences with hit
    anlys_date  TEXT NOT NULL DEFAULT CURRENT_DATE
);

-- Indices for table 'analysis'

-- CREATE INDEX idx_anlys_barcode ON analysis (barcode);
CREATE INDEX idx_anlys_blastprg ON analysis (blastprg);
CREATE INDEX idx_anlys_date ON analysis (anlys_date);

-- Table 'result'

-- Details for BLAST query and hit.

CREATE TABLE result (
    id          INTEGER PRIMARY KEY,
    anlys_id    INTEGER NOT NULL DEFAULT 0, -- Xref to 'analysis:id'
    qry_name    TEXT NOT NULL DEFAULT '',   -- Query name
    qry_id      TEXT NOT NULL DEFAULT '',   -- Query id
    qry_desc    TEXT NOT NULL DEFAULT '',   -- Query description
    qry_len     INTEGER NOT NULL DEFAULT 0, -- Query length
    hit_name    TEXT NOT NULL DEFAULT '',   -- Hit name
    hit_gi      INTEGER NOT NULL DEFAULT 0, -- Hit NCBI GI
    hit_tax_id  INTEGER NOT NULL DEFAULT 0, -- Hit taxonomy ID
    hit_acc     TEXT NOT NULL DEFAULT '',   -- Hit accession number
    hit_desc    TEXT NOT NULL DEFAULT '',   -- Hit description
    hit_len     TEXT NOT NULL DEFAULT '',   -- Hit length
    evalue      REAL NOT NULL DEFAULT 0,    -- E-value
    score       REAL NOT NULL DEFAULT 0,    -- Raw score
    iden        REAL NOT NULL DEFAULT 0,    -- Identity%
    conv        REAL NOT NULL DEFAULT 0,    -- Similarity%
    hsp_len     INTEGER NOT NULL DEFAULT 0  -- HSP length
);

-- Indices for table 'result'

CREATE INDEX idx_result_anlys_id ON result (anlys_id);
CREATE INDEX idx_result_qry_name ON result (qry_name);
CREATE INDEX idx_result_qry_id ON result (qry_id);
CREATE INDEX idx_result_qry_desc ON result (qry_desc);
CREATE INDEX idx_result_qry_len ON result (qry_len);
CREATE INDEX idx_result_hit_name ON result (hit_name);
CREATE INDEX idx_result_hit_gi ON result (hit_gi);
CREATE INDEX idx_result_hit_acc ON result (hit_acc);
CREATE INDEX idx_result_hit_desc ON result (hit_desc);
CREATE INDEX idx_result_hit_len ON result (hit_len);
CREATE INDEX idx_result_evalue ON result (evalue);
CREATE INDEX idx_result_score ON result (score);
CREATE INDEX idx_result_sim ON result (iden, conv);
CREATE INDEX idx_result_hsp_len ON result (hsp_len);

-- Table 'taxon'

-- Taxonomy of each result

CREATE TABLE taxon (
    id              INTEGER PRIMARY KEY,
--    result_id       INTEGER NOT NULL DEFAULT 0, -- Xref to 'result:id'
    tax_id          INTEGER NOT NULL DEFAULT 0, -- NCBI taxonomy ID
    tax_hier        TEXT NOT NULL DEFAULT '',   -- Hierarchy
    tax_hier_name   TEXT NOT NULL DEFAULT '',   -- Hierarchy name
    hit_superkingdom    TEXT NOT NULL DEFAULT '',   -- Superkingdom
    hit_kingdom     TEXT NOT NULL DEFAULT '',
    hit_phylum      TEXT NOT NULL DEFAULT '',
    hit_class       TEXT NOT NULL DEFAULT '',
    hit_order       TEXT NOT NULL DEFAULT '',
    hit_family      TEXT NOT NULL DEFAULT '',
    hit_genus       TEXT NOT NULL DEFAULT '',
    hit_species     TEXT NOT NULL DEFAULT '',   -- species
    hit_division    TEXT NOT NULL DEFAULT ''    -- Division
);

-- Indices

--CREATE INDEX idx_taxon_result_id ON taxon (result_id);
CREATE INDEX idx_taxon_tax_id ON taxon (tax_id);
CREATE INDEX idx_taxon_tax_hier ON taxon (tax_hier);
CREATE INDEX idx_taxon_tax_hiername ON taxon (tax_hier_name);
CREATE INDEX idx_taxon_hit ON taxon (hit_superkingdom, hit_kingdom, hit_phylum, hit_class, hit_order, hit_family, hit_genus, hit_species, hit_division);

