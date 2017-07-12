-- {{{ Comments
-- NAME
--
-- create_flavidb.sql - Create flaviviruses viral sequences database for
--                      SQLite3.
--
-- DESCRIPTION
-- 
-- Store GenBank file information.
--
-- AUTHOR
--
-- zeroliu-at-gmail-dot-com
--
-- HISTORY
--
-- 1.00     2008-10-29  Created according to bacteria genome
--                      database
-- 1.01     2008-10-31  New field 'genome.seq', 'virus.map', 
--			'virus.tissue_type'.
-- 1.03	    2008-11-25	New fields 'virus.ecotype', 'virus.cell_line',
--			'virus.cell_type', 'virus.proviral' and
--			'virus.focus'.
-- 1.10     2008-11-26  New table 'reference', which contains informatin
--                      of previous table 'reference', 'author' and
--                      'xref_ra'. This change add field 'authors' into
--                      table 'reference'.
-- 2.00     2009-06-11  PostgreSQL script inherited from formal MySQL 
--                      script 
-- 2.10     2009-09-04  New fields 'segment' and 'pcr_primers' in table
--                      'sequence'.
--                      Modify 'pg_start' and 'pg_end' fields of table
--                      reference from 'INTEGER' to 'TEXT'.
--                      Create indices for all tables.
-- 3.00     2011-10-21  A SQLite version.
-- 3.01     2013-09-22  Fix bug
-- 3.02     2017-07-04  Remove 'CHECK (vir_id >=0 )' for 'taxon_id'in 
--                      Table 'virus'. Now the default 'taxon_id' is 0.
-- }}} Comments

-- {{{ Tables

-- Create tables

-- {{{ virus

-- Table:    virus
-- Contents: Describe virus information

CREATE  TABLE virus (
    id INTEGER PRIMARY KEY,
    organism TEXT NOT NULL DEFAULT '',
 --   subsp TEXT NOT NULL DEFAULT '',
    strain TEXT NOT NULL DEFAULT '',
    sub_strain TEXT NOT NULL DEFAULT '',
    clone TEXT NOT NULL DEFAULT '',
    genotype TEXT NOT NULL DEFAULT '',
    isolate TEXT NOT NULL DEFAULT '',
    serovar TEXT NOT NULL DEFAULT '',
    serotype TEXT NOT NULL DEFAULT '',
    ecotype TEXT NOT NULL DEFAULT '',
    country TEXT NOT NULL DEFAULT '',
    host TEXT NOT NULL DEFAULT '',
    lab_host TEXT NOT NULL DEFAULT '',
    spec_host TEXT NOT NULL DEFAULT '',
    isolate_src TEXT NOT NULL DEFAULT '',
    cell_line TEXT NOT NULL DEFAULT '',
    cell_type TEXT NOT NULL DEFAULT '',
    collect_date TEXT NOT NULL DEFAULT '0001-01-01',    -- Default year
    virion INTEGRE NOT NULL DEFAULT FALSE,
    proviral INTEGRE NOT NULL DEFAULT FALSE,
    focus INTEGRE NOT NULL DEFAULT FALSE,
    tissue_type TEXT NOT NULL DEFAULT '',
    map TEXT NOT NULL DEFAULT '',
    note TEXT NOT NULL DEFAULT '',
--    taxon_id INTEGER NOT NULL DEFAULT 0 CHECK (taxon_id > 0),		-- Xref NCBI Taxonomy id
    taxon_id INTEGER NOT NULL DEFAULT 0, 
    collected_by TEXT NOT NULL DEFAULT ''
);

-- }}} virus

-- {{{ sequence

-- Table:    sequence
-- Contents: sequence infomration

CREATE   TABLE sequence (
    id INTEGER PRIMARY KEY,
    definition TEXT NOT NULL DEFAULT '',
    accession TEXT NOT NULL DEFAULT '',
    vir_id INTEGER  NOT NULL DEFAULT 0 CHECK (vir_id >=0 ),    
					-- Xref to Table `bacteria`
    seq_start INTEGER NOT NULL DEFAULT 1 CHECK (seq_start >= 0),	
                    -- genome start position: '1'
    seq_end INTEGER NOT NULL DEFAULT 0 CHECK (seq_end >= 0),
                    -- genome end posotion.
    mol_type TEXT NOT NULL DEFAULT '',
                    -- Molecular type: 'genomic DNA'
    comment TEXT NOT NULL DEFAULT '',   -- COMMENT
    seq TEXT NOT NULL DEFAULT '',
    segment TEXT NOT NULL DEFAULT '',
    pcr_primers TEXT NOT NULL DEFAULT ''
);

-- }}} sequence

-- {{{ xref_sr

-- Table:    xref_sr
-- Contents: Cross mapping between tables 'sequence' & 'reference'

CREATE   TABLE xref_sr (
    id INTEGER PRIMARY KEY,
    seq_id INTEGER  NOT NULL DEFAULT 0 CHECK (seq_id >= 0),
    ref_id INTEGER  NOT NULL DEFAULT 0 CHECK (seq_id >= 0)
    
);

-- }}} xref_sr

-- {{{ feature

-- Table 'feature'
-- Contents: All features (primary tags), except 'source'.

CREATE   TABLE feature (
    id INTEGER PRIMARY KEY,
    seq_id INTEGER  NOT NULL DEFAULT 0 CHECK (seq_id >= 0),
				-- Xref to table `genome`
    ftype TEXT NOT NULL DEFAULT '',
                                -- Feature/primary tag
    location TEXT NOT NULL DEFAULT '',
                                -- Redundant for complex location
    feat_start INTEGER NOT NULL DEFAULT 0,
    feat_end INTEGER NOT NULL DEFAULT 0,
    strand CHAR NOT NULL DEFAULT '.',        -- '+', '-' or '.'
    gene TEXT NOT NULL DEFAULT '',      -- '/gene'
    locus TEXT NOT NULL DEFAULT '',     -- '/locus_tag'
    seq TEXT NOT NULL DEFAULT '',
    ec_num TEXT NOT NULL DEFAULT '',     -- '/EC_number'. 
    func TEXT NOT NULL DEFAULT '', -- '/function'
    note TEXT NOT NULL DEFAULT '',     -- '/note'
    codon_start INTEGER  NOT NULL DEFAULT 0,
                                -- '/codon_start'
    transl_table INTEGER  NOT NULL DEFAULT 0,
				-- '/transl_table'
    product TEXT NOT NULL DEFAULT '',   -- '/product'
    prn_id TEXT NOT NULL DEFAULT '',    -- '/protein_id'
    pseudo INTEGER NOT NULL DEFAULT 0,  -- '/pseudo'
    translation TEXT NOT NULL DEFAULT ''    -- Protein amino acid sequence
    
);

-- }}} feature

-- {{{ db_xref

-- Table 'db_xref'
-- For qualifier '/db_xref=DB:id'

CREATE   TABLE db_xref (
    id INTEGER PRIMARY KEY,
    feat_id INTEGER  NOT NULL DEFAULT 0 CHECK (feat_id >= 0),
                        -- Xref to 'gene.id', 'cds.id', 'rna.id', 'misc_feat.id'
    db TEXT NOT NULL DEFAULT '',
    value TEXT NOT NULL DEFAULT ''
    
);

-- }}} db_xref

-- {{{ misc_qualif

-- Table 'misc_qualif'
-- For qualifiers not exist in table 'feature'

CREATE   TABLE misc_qualif (
    id INTEGER PRIMARY KEY,
    feat_id INTEGER  NOT NULL DEFAULT 0 CHECK (feat_id >= 0),
                        -- Xref to 'feature.id'
    qualif TEXT NOT NULL DEFAULT '',
    value TEXT NOT NULL DEFAULT ''
    
);

-- }}} misc_qualif

-- {{{ reference

-- Table 'reference'

CREATE   TABLE reference (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL DEFAULT '',
    authors TEXT NOT NULL DEFAULT '',
    journal TEXT NOT NULL DEFAULT '',
    volume TEXT NOT NULL DEFAULT '',
    issue TEXT NOT NULL DEFAULT '',
    pg_start TEXT NOT NULL DEFAULT '',
    pg_end TEXT NOT NULL DEFAULT '',
    pub_date TEXT NOT NULL DEFAULT '0001-01-01',
                    -- For submit TEXT of 'Direct submission': YYYY-MM-DD
                    -- and publish TEXT of Journal: YYYY-01-01
    pmid TEXT NOT NULL DEFAULT '',
    location TEXT NOT NULL DEFAULT '', -- Redundant field
    db TEXT NOT NULL DEFAULT ''        -- 'Medline' or 'Pubmed'

);

-- }}} reference

-- }}} Tables

-- {{{ Indices

-- Create Indices

-- Indices for Table db_xref

CREATE INDEX idx_db_xref_db ON db_xref (db);
CREATE INDEX idx_db_xref_feat ON db_xref (feat_id);
CREATE INDEX idx_db_xref_val ON db_xref (value);

-- Indices for Table feature

CREATE INDEX idx_feat_cdn_start ON feature (codon_start);
CREATE INDEX idx_feat_ec_num ON feature (ec_num);
CREATE INDEX idx_feat_ftyle ON feature (ftype);
CREATE INDEX idx_feat_function ON feature (func);
CREATE INDEX idx_feat_gene ON feature (gene);
CREATE INDEX idx_feat_locus ON feature (locus);
CREATE INDEX idx_feat_prnid ON feature (prn_id);
CREATE INDEX idx_feat_product ON feature (product);
CREATE INDEX idx_feat_end ON feature (feat_end);
CREATE INDEX idx_feat_start ON feature (feat_start);
CREATE INDEX idx_feat_sid ON feature (seq_id);
CREATE INDEX idx_feat_strand ON feature (strand);

-- Indices for Table misc_qualif

CREATE INDEX idx_misc_qualif_fid ON misc_qualif (feat_id);
CREATE INDEX idx_misc_qualif_qualif ON misc_qualif (qualif);
CREATE INDEX idx_misc_value ON misc_qualif (value);

-- Indices for Table reference

CREATE INDEX idx_ref_authors ON reference (authors);
CREATE INDEX idx_ref_db ON reference (db);
CREATE INDEX idx_ref_issue ON reference (issue);
CREATE INDEX idx_ref_jr ON reference (journal);
CREATE INDEX idx_ref_location ON reference (location);
CREATE INDEX idx_ref_end ON reference (pg_end);
CREATE INDEX idx_ref_start ON reference (pg_start);
CREATE INDEX idx_ref_pmid ON reference (pmid);
CREATE INDEX idx_ref_pubdate ON reference (pub_date);
CREATE INDEX idx_ref_title ON reference (title);
CREATE INDEX idx_ref_volumr ON reference (volume);

-- Indices for Table sequence

CREATE INDEX idx_seq_acc ON sequence (accession);
CREATE INDEX idx_seq_commemt ON sequence (comment);
CREATE INDEX idx_seq_def ON sequence (definition);
CREATE INDEX idx_seq_mol_type ON sequence (mol_type);
CREATE INDEX idx_seq__end ON sequence (seq_end);
CREATE INDEX idx_seq__start ON sequence (seq_start);
CREATE INDEX idx_seq_vid ON sequence (vir_id);
CREATE INDEX idx_seq_seg ON sequence (segment);

-- Indices for Table virus

CREATE INDEX idx_virus_cell_line ON virus (cell_line);
CREATE INDEX idx_virus_cell_type ON virus (cell_type);
CREATE INDEX idx_virus_clone ON virus (clone);
CREATE INDEX idx_virus_coldate ON virus (collect_date);
CREATE INDEX idx_virus_colby ON virus (collected_by);
CREATE INDEX idx_virus_country ON virus (country);
CREATE INDEX idx_virus_genotype ON virus (genotype);
CREATE INDEX idx_virus_host ON virus (host);
CREATE INDEX idx_virus_isolate ON virus (isolate);
CREATE INDEX idx_virus_isolate_src ON virus (isolate_src);
CREATE INDEX idx_virus_labhost ON virus (lab_host);
CREATE INDEX idx_virus_note ON virus (note);
CREATE INDEX idx_virus_org ON virus (organism);
CREATE INDEX idx_virus_serotype ON virus (serotype);
CREATE INDEX idx_virus_serovar ON virus (serovar);
CREATE INDEX idx_virus_spec_host ON virus (spec_host);
CREATE INDEX idx_virus_strain ON virus (strain);
CREATE INDEX idx_virus_sub_strain ON virus (sub_strain);
CREATE INDEX idx_virus_taxid ON virus (taxon_id);

-- Indices for Table xref_sr

CREATE INDEX idx_xref_sr_rid ON xref_sr (ref_id);
CREATE INDEX idx_xref_se_sid ON xref_sr (seq_id);

-- }}} Indices

-- End of Creation

