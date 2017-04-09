CREATE TABLE release (
    rel_id              INTEGER PRIMARY KEY AUTOINCREMENT,
    rel_date            DATETIME DEFAULT CURRENT_DATE
);
CREATE TABLE nodes (
    tax_id              INTEGER PRIMARY KEY,
    parent_tax_id       INTEGER NOT NULL,  -- parent node id
    rank                TEXT NOT NULL DEFAULT '',
    embl_code           TEXT NOT NULL DEFAULT '',
    div_id              INTEGER NOT NULL,     -- Division id
    inh_div_flag        INTEGER NOT NULL,
    gc_id               INTEGER NOT NULL,
    inh_gc_flag         INTEGER NOT NULL,
    mgc_id              INTEGER NOT NULL,
    inh_mgc_flag        INTEGER NOT NULL,
    gb_hid_flag         INTEGER NOT NULL,
    hid_sub_root_flag   INTEGER NOT NULL,
    comment             TEXT DEFAULT ''
);
CREATE TABLE names (
    name_id             INTEGER PRIMARY KEY AUTOINCREMENT,
    tax_id              INTEGER NOT NULL,
    name                TEXT NOT NULL DEFAULT '',
    uniq_name           TEXT NOT NULL DEFAULT '',
    class               TEXT NOT NULL DEFAULT ''
);
CREATE TABLE division (
    div_id              INTEGER PRIAMRY KEY,
    div_code            TEXT NOT NULL DEFAULT '',
    name                TEXT NOT NULL DEFAULT '',
    comment             TEXT DEFAULT ''
);
CREATE TABLE gencode (
    gc_id               INTEGER PRIMARY KEY, 
    abbr                TEXT NOT NULL DEFAULT '',
    name                TEXT NOT NULL DEFAULT '',
    cde                 TEXT NOT NULL DEFAULT '',
    starts              TEXT NOT NULL DEFAULT ''
);
CREATE TABLE citations (
    cit_id              INTEGER PRIMARY KEY,
    cit_key             TEXT NOT NULL DEFAULT '',
    pmid                INTEGER NOT NULL DEFAULT 0,
    medline_id          INTEGER NOT NULL DEFAULT 0,
    url                 TEXT NOT NULL DEFAULT '',
    cit_text            TEXT NOT NULL DEFAULT '',
    taxids              TEXT NOT NULL DEFAULT ''
);
CREATE INDEX idx_nodes_parent_tax_id ON nodes ( parent_tax_id );
CREATE INDEX idx_nodes_rank ON nodes ( rank );
CREATE INDEX idx_nodes_embl_code ON nodes ( embl_code );
CREATE INDEX idx_nodes_div_id ON nodes ( div_id );
CREATE INDEX idx_nodes_inh_div_flag ON nodes ( inh_div_flag );
CREATE INDEX idx_nodes_gc_id ON nodes ( gc_id );
CREATE INDEX idx_nodes_inh_gc_flag ON nodes ( inh_gc_flag );
CREATE INDEX idx_nodes_mgc_id ON nodes ( mgc_id );
CREATE INDEX idx_nodes_inh_mgc_flag ON nodes ( inh_mgc_flag );
CREATE INDEX idx_nodes_gb_hid_flag ON nodes ( gb_hid_flag );
CREATE INDEX idx_nodes_hid_sub_root_flag ON nodes ( hid_sub_root_flag );
CREATE INDEX idx_nodes_comment ON nodes ( comment );
CREATE INDEX idX_names_tax_id ON names ( tax_id );
CREATE INDEX idx_names_name ON names ( name );
CREATE INDEX idx_names_uniq_name ON names ( uniq_name );
CREATE INDEX idx_names_class ON names ( class );
CREATE INDEX idx_division_div_code ON division ( div_code );
CREATE INDEX idx_division_name ON division ( name );
CREATE INDEX idx_division_comment ON division ( comment );
CREATE INDEX idx_gencode_abbr ON gencode ( abbr );
CREATE INDEX idx_gencode_name ON gencode ( name );
CREATE INDEX idx_gencode_cde ON gencode ( cde );
CREATE INDEX idx_gencode_starts ON gencode ( starts );
CREATE INDEX idx_citations_cit_key ON citations ( cit_key );
CREATE INDEX idx_citations_pmid ON citations ( pmid );
CREATE INDEX idx_citations_url ON citations ( url );
CREATE INDEX idx_citations_cit_text ON citations ( cit_text );
CREATE INDEX idx_ciataions_taxids ON citations ( taxids );
