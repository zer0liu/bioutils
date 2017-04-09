/*
- NAME

  create_keggdb.sql
  
- DESCRIPTION

  PostgreSQL script to create a database 'keggdb' for KEGG data

- DATABASE

  keggdb

- AUTHOR

  zeroliu-at-gmail-dot-com

- Version

  0.1   2010-07-19  Initial creation.
  0.2   2010-09-20  New design of 'gene' related tables.
  0.25  2011-01-07  More tables for 'gene'.
                    Use 'TEXT' type to replace some 'VAR CHAR'.
  0.26  2011-01-08  Remove 'ko_id' reference constraint from table
                    'ko_gene_xref' because of the missing KO entries in ko
                    file, but which exist in other entries (e.g. gene).
                    Such as KO entry 'K14347'.
*/

-- {{{ genome
/*--------------------------------------------------------------------

Genome Tables

--------------------------------------------------------------------*/

-- Table genome

CREATE TABLE genome (
    genome_id CHAR(6) PRIMARY KEY, -- KEGG genome entry
    org VARCHAR(8) UNIQUE NOT NULL DEFAULT '',  -- 3-char KEGG genome name abbreviation
--    description VARCHAR(1024) NOT NULL DEFAULT '',
    description TEXT NOT NULL DEFAULT '',
    taxid INTEGER NOT NULL DEFAULT 0,
--    taxonomy VARCHAR(512) NOT NULL DEFAULT '',
    taxonomy TEXT NOT NULL DEFAULT '',
    num_nt INTEGER NOT NULL DEFAULT 0,
    num_prn INTEGER NOT NULL DEFAULT 0,
    num_rna INTEGER NOT NULL DEFAULT 0,
--    comment VARCHAR(1024) DEFAULT ''
    comment TEXT NOT NULL DEFAULT ''
);

-- CREATE INDEX idx_genome_entry ON genome (entry);
CREATE INDEX idx_genome_org ON genome (org);
CREATE INDEX idx_genome_taxid ON genome (taxid);
CREATE INDEX idx_genome_taxonomy ON genome (taxonomy);
CREATE INDEX idx_genome_nt ON genome (num_nt);
CREATE INDEX idx_genome_prn ON genome (num_prn);
CREATE INDEX idx_genome_rna ON genome (num_rna);

-- Table genome_component

CREATE TABLE genome_component (
    genome_component_id SERIAL PRIMARY KEY,
    genome_id CHAR(6) NOT NULL DEFAULT '',
    category VARCHAR(32) NOT NULL DEFAULT '', -- enum: ('chromosome', 'plasmid')
    name VARCHAR(64) NOT NULL DEFAULT '', -- e.g., 'I', 'plABSDF', etc.
    refseq_id VARCHAR(64) DEFAULT '',                -- NCBI RefSeq id
    is_circular BOOL DEFAULT TRUE,
    length INTEGER DEFAULT 0,

    FOREIGN KEY (genome_id) REFERENCES genome (genome_id) ON DELETE CASCADE
);

CREATE INDEX idx_genome_component_genome_id ON genome_component (genome_id);
CREATE INDEX idx_genome_component_type ON genome_component (category);
CREATE INDEX idx_genome_component_name ON genome_component (name);
CREATE INDEX idx_genome_component_rsid ON genome_component (refseq_id);

-- Table genome_pub

CREATE TABLE genome_pub_xref (
    genome_pub_id SERIAL PRIMARY KEY,
    genome_id CHAR(6) NOT NULL DEFAULT '',
    pmid VARCHAR(32) DEFAULT '',       -- NCBI PubMed id

    FOREIGN KEY (genome_id) REFERENCES genome (genome_id) ON DELETE CASCADE
);

CREATE INDEX idx_genome_pub_xref_genome_id ON genome_pub_xref (genome_id);
CREATE INDEX idx_genome_xref_pmid ON genome_pub_xref (pmid);

-- Table genome_disease_xref

CREATE TABLE genome_disease_xref (
    genome_disease_id SERIAL PRIMARY KEY,
    genome_id CHAR(6) NOT NULL DEFAULT '',
    disease_id CHAR(6) NOT NULL DEFAULT '',
    
    FOREIGN KEY (genome_id) REFERENCES genome (genome_id) ON DELETE CASCADE
);

CREATE INDEX idx_genome_disease_xref_genome_id ON genome_disease_xref (genome_id);
CREATE INDEX idx_genome_disease_xref_disease_id ON genome_disease_xref (disease_id);

-- }}}

-- {{{ ko
/*--------------------------------------------------------------------

Ko Tables

--------------------------------------------------------------------*/

-- Table ko

CREATE TABLE ko (
    ko_id CHAR(6) PRIMARY KEY,
    name VARCHAR(64) DEFAULT '',
--    description VARCHAR(512) DEFAULT ''
    description TEXT NOT NULL DEFAULT ''
);

CREATE INDEX idx_ko_name ON ko (name);
CREATE INDEX idx_ko_d3esc ON ko (description);

-- {{{ Deprecated
/*-------------------------------------------------------------------
-- Deprecated 

-- Table ko_gene_xref

CREATE TABLE ko_gene_xref (
    ko_gene_id SERIAL PRIMARY KEY,
    ko_id CHAR(6) NOT NULL DEFAULT '',
    org VARCHAR(8) NOT NULL DEFAULT '',    -- Abbrivated 3 or 4-char organism
    gene_entry VARCHAR(64) NOT NULL DEFAULT '',
    
    FOREIGN KEY (ko_id) REFERENCES ko (ko_id) ON DELETE CASCADE
);

CREATE INDEX idx_ko_gene_xref_ko_id ON ko_gene_xref (ko_id);
CREATE INDEX idx_ko_gene_xref_org ON ko_gene_xref (org);
CREATE INDEX idx_ko_gene_xref_gene_entry ON ko_gene_xref (gene_entry);

-- Table gene_name

-- This table stores multiple names for a gene.
-- Contents of this table came from file 'pathway'

CREATE TABLE gene_name (
    gene_name_id SERIAL PRIMARY KEY,
    entry VARCHAR(64) NOT NULL DEFAULT '',
    name VARCHAR(64) NOT NULL DEFAULT ''
);

CREATE INDEX idx_gene_name_entry ON gene_name (entry);
CREATE INDEX idx_gene_name_name ON gene_name (name);

-------------------------------------------------------------------*/
--}}}



-- Table ko_ec_xref

CREATE TABLE ko_ec_xref (
    ko_ec_id SERIAL PRIMARY KEY,
    ko_id CHAR(6) NOT NULL DEFAULT '',
    ec VARCHAR(64) NOT NULL DEFAULT '',
    
    FOREIGN KEY (ko_id) REFERENCES ko (ko_id) ON DELETE CASCADE
);

CREATE INDEX ko_ec_xref_ko_id ON ko_ec_xref (ko_id);
CREATE INDEX ko_ec_xref_ec ON ko_ec_xref (ec);

-- TABLE ko_dbxref

CREATE TABLE ko_dbxref (
    ko_dbxref_id SERIAL PRIMARY KEY,
    ko_id CHAR(6) NOT NULL DEFAULT '',
    db VARCHAR(64) NOT NULL DEFAULT '',
    entry VARCHAR(64) NOT NULL DEFAULT '',
    
    FOREIGN KEY (ko_id) REFERENCES ko (ko_id) ON DELETE CASCADE
);

CREATE INDEX ko_dbxref_ko_id ON ko_dbxref (ko_id);
CREATE INDEX ko_dbxref_db ON ko_dbxref (db);
CREATE INDEX ko_dbxref_entry ON ko_dbxref (entry);

-- Table ko_pathway_xref

CREATE TABLE ko_pathway_xref (
    ko_pathway_id SERIAL PRIMARY KEY,
    ko_id CHAR(6) NOT NULL DEFAULT '',
    pathway_id VARCHAR(32) NOT NULL DEFAULT '',
    
    FOREIGN KEY (ko_id) REFERENCES ko (ko_id) ON DELETE CASCADE
--    FOREIGN KEY (pathway_id) REFERENCES pathway (pathway_id) ON DELETE CASCADE
);

CREATE INDEX ko_pathway_xref_ko_id ON ko_pathway_xref (ko_id);
CREATE INDEX ko_pathway_xref_pathway_id ON ko_pathway_xref (pathway_id);

-- Table ko_module_xref

CREATE TABLE ko_module_xref (
    ko_module_id SERIAL PRIMARY KEY,
    ko_id CHAR(6) NOT NULL DEFAULT '',
    module_id CHAR(6) NOT NULL DEFAULT '',
    
    FOREIGN KEY (ko_id) REFERENCES ko (ko_id) ON DELETE CASCADE
);

CREATE INDEX ko_module_xref_ko_id ON ko_module_xref (ko_id);
CREATE INDEX ko_module_xref_module_id ON ko_module_xref (module_id);

-- Table ko_disease_xref

CREATE TABLE ko_disease_xref (
    ko_disease_id SERIAL PRIMARY KEY,
    ko_id CHAR(6) NOT NULL DEFAULT '',
    disease_id CHAR(6) NOT NULL DEFAULT '',
    
    FOREIGN KEY (ko_id) REFERENCES ko (ko_id) ON DELETE CASCADE
);

CREATE INDEX ko_disease_xref_ko_id ON ko_disease_xref (ko_id);
CREATE INDEX ko_disease_xref_disease_id ON ko_disease_xref (disease_id);

-- Table ko_class_xref

CREATE TABLE ko_class_xref (
    ko_class_id SERIAL PRIMARY KEY,
    ko_id CHAR(6) NOT NULL DEFAULT '',
--    class_desc VARCHAR(1024) DEFAULT '',
    class_desc TEXT NOT NULL DEFAULT '',
    
    FOREIGN KEY (ko_id) REFERENCES ko (ko_id) ON DELETE CASCADE
);

CREATE INDEX idx_ko_class_xref_ko_id ON ko_class_xref (ko_id);
CREATE INDEX idx_ko_class_xref_desc ON ko_class_xref (class_desc);

-- }}}

-- {{{ pathway

/*--------------------------------------------------------------------

Pathway Tables

--------------------------------------------------------------------*/

-- Table pathway

CREATE TABLE pathway (
    pathway_id VARCHAR(32) PRIMARY KEY,
    name TEXT NOT NULL DEFAULT '',
    description TEXT NOT NULL DEFAULT '',
    map_id VARCHAR(32) DEFAULT '',
    organism TEXT NOT NULL DEFAULT '',
    org VARCHAR(8) NOT NULL DEFAULT '',
    ko_pathway VARCHAR(32) NOT NULL DEFAULT ''
);

CREATE INDEX idx_pathway_name ON pathway (name);
CREATE INDEX idx_pathway_desc ON pathway (description);
CREATE INDEX idx_pathway_map_id ON pathway (map_id);
CREATE INDEX idx_pathway_org ON pathway (org);
CREATE INDEX idx_pathway_ko_pathway ON pathway (ko_pathway);

-- Table pathway_pub_xref

CREATE TABLE pathway_pub_xref (
    pathway_pub_id SERIAL PRIMARY KEY,
    pathway_id VARCHAR(32) NOT NULL DEFAULT '',
    pmid VARCHAR(32) NOT NULL DEFAULT '',
    
    FOREIGN KEY (pathway_id) REFERENCES pathway (pathway_id) ON DELETE CASCADE
);

CREATE INDEX idx_pathway_pub_xref_pathway_id ON pathway_pub_xref (pathway_id);
CREATE INDEX idx_pathway_pub_xref_pmid ON pathway_pub_xref (pmid);

-- Table pathway_module_xref

CREATE TABLE pathway_module_xref (
    pathway_module_id SERIAL PRIMARY KEY,
    pathway_id VARCHAR(32) NOT NULL DEFAULT '',
    module_id CHAR(6) NOT NULL DEFAULT '',
    
    FOREIGN KEY (pathway_id) REFERENCES pathway (pathway_id) ON DELETE CASCADE
);

CREATE INDEX idx_pathway_module_xref_pathway_id ON pathway_module_xref (pathway_id);
CREATE INDEX idx_pathway_module_xref_module_id ON pathway_module_xref (module_id);

-- Table pathway_ec_xref

CREATE TABLE pathway_ec_xref (
    pathway_ec_id SERIAL PRIMARY KEY,
    pathway_id VARCHAR(32) NOT NULL DEFAULT '',
    ec VARCHAR(64) NOT NULL DEFAULT '',
    
    FOREIGN KEY (pathway_id) REFERENCES pathway (pathway_id) ON DELETE CASCADE    
);

CREATE INDEX idx_pathway_ec_xref_pathway_id ON pathway_ec_xref (pathway_id);
CREATE INDEX idx_pathway_ec_xref_ec ON pathway_ec_xref (ec);

-- Table pathway_disease_xref

CREATE TABLE pathway_disease_xref (
    pathway_disease_id SERIAL PRIMARY KEY,
    pathway_id VARCHAR(32) NOT NULL DEFAULT '',
    disease_id CHAR(6) NOT NULL DEFAULT '',
    
    FOREIGN KEY (pathway_id) REFERENCES pathway (pathway_id) ON DELETE CASCADE    
);

CREATE INDEX idx_pathway_disease_xref_pathway_id ON pathway_disease_xref (pathway_id);
CREATE INDEX idx_pathway_disease_xref_disease_id ON pathway_disease_xref (disease_id);

-- Table pathway_drug_xref

CREATE TABLE pathway_drug_xref (
    pathway_drug_id SERIAL PRIMARY KEY,
    pathway_id VARCHAR(32) NOT NULL DEFAULT '',
    drug_id CHAR(6) NOT NULL DEFAULT '',
    
    FOREIGN KEY (pathway_id) REFERENCES pathway (pathway_id) ON DELETE CASCADE    
);

CREATE INDEX idx_pathway_drug_xref_pathway_id ON pathway_drug_xref (pathway_id);
CREATE INDEX idx_pathway_drug_xref_drug_id ON pathway_drug_xref (drug_id);

-- Table pathway_dbxref

CREATE TABLE pathway_dbxref (
    pathway_dbxref_id SERIAL PRIMARY KEY,
    pathway_id VARCHAR(32) NOT NULL DEFAULT '',
    db VARCHAR(16) NOT NULL DEFAULT '',
    entry VARCHAR(128) NOT NULL DEFAULT '',
    
    FOREIGN KEY (pathway_id) REFERENCES pathway (pathway_id) ON DELETE CASCADE 
);

CREATE INDEX idx_pathway_dbxref_pathway_id ON pathway_dbxref (pathway_id);
CREATE INDEX idx_pathway_dbxref_db ON pathway_dbxref (db);
CREATE INDEX idx_pathway_dbxref_entry ON pathway_dbxref (entry);

-- Table pathway_reaction_xref

CREATE TABLE pathway_reaction_xref (
    pathway_reaction_id SERIAL PRIMARY KEY,
    pathway_id VARCHAR(32) NOT NULL DEFAULT '',
    reaction_id CHAR(6) NOT NULL DEFAULT '',
    
    FOREIGN KEY (pathway_id) REFERENCES pathway (pathway_id) ON DELETE CASCADE 
);

CREATE INDEX idx_pathway_reaction_xref_pathway_id ON pathway_reaction_xref (pathway_id);
CREATE INDEX idx_pathway_reaction_xref_reaction_id ON pathway_reaction_xref (reaction_id);

-- Table pathway_compound_xref

CREATE TABLE pathway_compound_xref (
    pathway_compound_id SERIAL PRIMARY KEY,
    pathway_id VARCHAR(32) NOT NULL DEFAULT '',
    compound_id CHAR(6) NOT NULL DEFAULT '',
    
    FOREIGN KEY (pathway_id) REFERENCES pathway (pathway_id) ON DELETE CASCADE 
);

CREATE INDEX idx_pathway_cpd_xref_pathway_id ON pathway_compound_xref (pathway_id);
CREATE INDEX idx_pathway_cpd_xref_compound_id ON pathway_compound_xref (compound_id);

-- Table pathway_class_xref

CREATE TABLE pathway_class_xref (
    pathway_class_id SERIAL PRIMARY KEY,
    pathway_id VARCHAR(32) NOT NULL DEFAULT '',
    class_desc TEXT NOT NULL DEFAULT '',
    
    FOREIGN KEY (pathway_id) REFERENCES pathway (pathway_id) ON DELETE CASCADE     
);

CREATE INDEX idx_pathway_class_xref_pathway_id ON pathway_class_xref (pathway_id);

-- Table pathway_rel_xref: Related pathway

CREATE TABLE pathway_rel_xref (
    pathway_rel_id SERIAL PRIMARY KEY,
    pathway_id VARCHAR(32) NOT NULL DEFAULT '',
    rel_pathway_id VARCHAR(32) NOT NULL DEFAULT '',

    FOREIGN KEY (pathway_id) REFERENCES pathway (pathway_id) ON DELETE CASCADE   
);

CREATE INDEX idx_pathway_rel_xref_pathway_id ON pathway_rel_xref (pathway_id);
CREATE INDEX idx_pathway_rel_xref_rel_pathway_id ON pathway_rel_xref (rel_pathway_id);

-- }}}

-- {{{ gene

/*--------------------------------------------------------------------

gene tables

--------------------------------------------------------------------*/

-- Table gene

CREATE TABLE gene (
    gene_id SERIAL PRIMARY KEY,
    org VARCHAR(8) NOT NULL DEFAULT '',     -- abbreviated organism name
    entry VARCHAR(64) NOT NULL DEFAULT '',  -- gene unique entry
    name VARCHAR(64) NOT NULL DEFAULT '',   -- primary gene name
    type VARCHAR(32) NOT NULL DEFAULT '',   -- Gene type, such as 'CDS'
    description TEXT NOT NULL DEFAULT '',   -- 'DEFINITION'
    position TEXT NOT NULL DEFAULT '',      -- 'POSITION'
    aalen INTEGER NOT NULL DEFAULT 0,       -- Amino acid sequence length
    aaseq TEXT,
    ntlen INTEGER NOT NULL DEFAULT 0,       -- Nucleotide sequence length
    ntseq TEXT
);

CREATE INDEX idx_gene_org ON gene (org);
CREATE INDEX idx_gene_entry ON gene (entry);
CREATE INDEX idx_gene_name ON gene (name);
CREATE INDEX idx_gene_type ON gene (type);
CREATE INDEX idx_gene_desc ON gene (description);
CREATE INDEX idx_gene_pos ON gene (position);
CREATE INDEX idx_gene_aalen ON gene (aalen);
CREATE INDEX idx_gene_ntlen ON gene (ntlen);

-- Table gene_name: Gene alternative names

CREATE TABLE gene_name (
    gene_name_id SERIAL PRIMARY KEY,
    gene_id INTEGER NOT NULL DEFAULT 0,
    name VARCHAR(64) NOT NULL DEFAULT '',
    rank SMALLINT DEFAULT 0,    -- 0: Primary name. Redundant to 'gene.name'
                                -- 1: Alternative name

    FOREIGN KEY (gene_id) REFERENCES gene (gene_id) ON DELETE CASCADE
);

CREATE INDEX idx_gene_name_gene_id ON gene_name (gene_id);
CREATE INDEX idx_gene_name_name ON gene_name (name);
CREATE INDEX idx_gene_name_rank ON gene_name (rank);

-- Table 'gene_motif_xref

CREATE TABLE gene_motif_xref (
    gene_motif_id SERIAL PRIMARY KEY,
    gene_id INTEGER NOT NULL DEFAULT 0,
    db VARCHAR(32) NOT NULL DEFAULT '',
    entry VARCHAR(128) NOT NULL DEFAULT '',
    
    FOREIGN KEY (gene_id) REFERENCES gene (gene_id) ON DELETE CASCADE
);

CREATE INDEX idx_gene_motif_gene_id ON gene_motif_xref (gene_id);
CREATE INDEX idx_gene_motif_db ON gene_motif_xref (db);
CREATE INDEX idx_gene_motif_entry ON gene_motif_xref (entry);

-- Table 'gene_dbxref'

CREATE TABLE gene_dbxref (
    gene_dbxref_id SERIAL PRIMARY KEY,
    gene_id INTEGER NOT NULL DEFAULT 0,
    db VARCHAR(32) NOT NULL DEFAULT '',
    entry VARCHAR(128) NOT NULL DEFAULT '',
    
    FOREIGN KEY (gene_id) REFERENCES gene (gene_id) ON DELETE CASCADE
);

CREATE INDEX idx_gene_dbxref_gene_id ON gene_dbxref (gene_id);
CREATE INDEX idx_gene_dbxref_db ON gene_dbxref (db);
CREATE INDEX idx_gene_dbxref_entry ON gene_dbxref (entry);

-- Table 'gene_struct_xref'

CREATE TABLE gene_struct_xref (
    gene_struct_id SERIAL PRIMARY KEY,
    gene_id INTEGER NOT NULL DEFAULT 0,
    db VARCHAR(32) NOT NULL DEFAULT '',
    entry VARCHAR(128) NOT NULL DEFAULT '',
    
    FOREIGN KEY (gene_id) REFERENCES gene (gene_id) ON DELETE CASCADE
);

CREATE INDEX idx_gene_struct_gene_id ON gene_struct_xref (gene_id);
CREATE INDEX idx_gene_struct_db ON gene_struct_xref (db);
CREATE INDEX idx_gene_entry ON gene_struct_xref (entry);

-- }}}

-- {{{ xref

/*------------------------------------------------------------------

Cross reference tables

------------------------------------------------------------------*/

-- Table pathway_gene_xref

CREATE TABLE pathway_gene_xref (
    pathway_gene_id SERIAL PRIMARY KEY,
    pathway_id VARCHAR(32) NOT NULL DEFAULT '',
    gene_id INTEGER NOT NULL DEFAULT 0,

    FOREIGN KEY (pathway_id) REFERENCES pathway (pathway_id),
    FOREIGN KEY (gene_id) REFERENCES gene (gene_id)
);

CREATE INDEX idx_pathway_gene_xref_pathway_id ON pathway_gene_xref (pathway_id);
CREATE INDEX idx_pathway_gene_xref_gene_id ON pathway_gene_xref (gene_id);

-- Table ko_gene_xref

CREATE TABLE ko_gene_xref (
    ko_gene_id SERIAL PRIMARY KEY,
    ko_id CHAR(6) NOT NULL DEFAULT '',
    gene_id INTEGER NOT NULL DEFAULT 0,

--    FOREIGN KEY (ko_id) REFERENCES ko (ko_id) ON DELETE CASCADE,
    FOREIGN KEY (gene_id) REFERENCES gene (gene_id) ON DELETE CASCADE
);

CREATE INDEX idx_ko_gene_xref_ko_id ON ko_gene_xref (ko_id);
CREATE INDEX idx_ko_gene_xref_gene_id ON ko_gene_xref (gene_id);

-- }}}
