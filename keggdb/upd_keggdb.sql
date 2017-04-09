/*
- NAME

    upd_keggdb.sql - Update database schema of keggdb.

- DESCRIPTION

- DATABASE
    
    keggdb
    
- AUTHOR
    
    zeroliu-at-gmail-dot-com
    
- HISTORY

    0.1     2011-01-07
*/

-- Update table 'gene'

ALTER TABLE gene
    ADD type VARCHAR(32) NOT NULL DEFAULT '',
    ADD description VARCHAR(256) NOT NULL DEFAULT '',
    ADD position VARCHAR(512) NOT NULL DEFAULT '',
    ADD aalen INTEGER NOT NULL DEFAULT 0,
    ADD aaseq TEXT,
    ADD ntlen INTEGER NOT NULL DEFAULT 0,
    ADD ntseq TEXT;
    
-- Create table 'gene_motif_xref'

CREATE TABLE gene_motif_xref (
    gene_motif_id SERIAL PRIMARY KEY,
    gene_id INTEGER NOT NULL DEFAULT 0,
    db VARCHAR(32) NOT NULL DEFAULT '',
    entry VARCHAR(128) NOT NULL DEFAULT '',
    
    FOREIGN KEY (gene_id) REFERENCES gene (gene_id) ON DELETE CASCADE
);

-- Create table 'gene_dbxref'

CREATE TABLE gene_dbxref (
    gene_dbxref_id SERIAL PRIMARY KEY,
    gene_id INTEGER NOT NULL DEFAULT 0,
    db VARCHAR(32) NOT NULL DEFAULT '',
    entry VARCHAR(128) NOT NULL DEFAULT '',
    
    FOREIGN KEY (gene_id) REFERENCES gene (gene_id) ON DELETE CASCADE
);

-- Create table 'gene_struct_xref'

CREATE TABLE gene_struct_xref (
    gene_struct_id SERIAL PRIMARY KEY,
    gene_id INTEGER NOT NULL DEFAULT 0,
    db VARCHAR(32) NOT NULL DEFAULT '',
    entry VARCHAR(128) NOT NULL DEFAULT '',
    
    FOREIGN KEY (gene_id) REFERENCES gene (gene_id) ON DELETE CASCADE
);

-- END
