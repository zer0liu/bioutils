-- NAME
--
-- create_taxonmy.sql
--
-- DESCRIPTION
--
-- Create database 'taxonomy' according to the NCBI taxonomy database
-- information.
-- Dump files downloaded from NCBI ftp:
-- ftp://ftp.ncbi.nih.gov/pub/taxonomy/
--
-- AUTHOR
--
-- zeroliu-at-gmail-dot-com
--
-- HISTORY
--
-- 2008-10-17	0.1

-- Create user

CREATE USER 'taxon'@'%' IDENTIFIED BY 'tax0n';

GRANT USAGE ON *.* TO 'taxon' IDENTIFIED BY 'tax0n' WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;

-- Create Database

CREATE DATABASE IF NOT EXISTS `taxon` DEFAULT COLLATE utf8_general_ci;

GRANT ALL PRIVILEGES ON `taxon`.* TO 'taxon'@'%';

-- Change database

use taxon;

-- Create tables

-- Table: nodes
-- NCBI TAXONOMY file: nodes.dmp

CREATE TABLE IF NOT EXISTS `nodes` (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    tax_id INT UNSIGNED NOT NULL,     -- Genbank taxonomy node id
    parent_id INT UNSIGNED NOT NULL,  -- parent node id
    rank VARCHAR(50) NOT NULL DEFAULT '',
    embl_code VARCHAR(50) NOT NULL DEFAULT '',
    div_id INT UNSIGNED NOT NULL,     -- Division id
    inherited_div BOOL NOT NULL,
    gencode INT UNSIGNED NOT NULL,
    inherited_gc BOOL NOT NULL,
    mit_gcode INT UNSIGNED NOT NULL,
    inherited_mgc BOOL NOT NULL,
    gb_flag BOOL NOT NULL,             -- 1 if name is suppressed in GenBank entry lineage
    hidden_sub_root BOOL NOT NULL,
    comment VARCHAR(10000) DEFAULT '',

    PRIMARY KEY (id),
    INDEX idx_taxid(tax_id),
    INDEX idx_pid (parent_id),
    INDEX idx_rank (rank),
    INDEX idx_embl (embl_code),
    INDEX idx_div (div_id),
    INDEX idx_gc (gencode),
    INDEX idx_mit_gc (mit_gcode)
) ENGINE=InnoDB;

-- Table: Names
-- NCBI taxonomy file: names.dmp

CREATE TABLE IF NOT EXISTS `names` (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    tax_id INT UNSIGNED NOT NULL,
    name VARCHAR(200) NOT NULL DEFAULT '',
    unique_name VARCHAR(200) NOT NULL DEFAULT '',
    class VARCHAR(200) NOT NULL DEFAULT '',

    PRIMARY KEY (id),
    INDEX idx_taxid(tax_id),
    INDEX idx_name (name(20)),
    INDEX idx_unique (unique_name(20)),
    INDEX idx_class (class(20))
) ENGINE=InnoDB;

-- Table: division
-- NCBI taxonomy file: division.dmp


CREATE TABLE IF NOT EXISTS `division` (
    div_id INT UNSIGNED NOT NULL,
    div_code CHAR(3) NOT NULL DEFAULT '',
    name VARCHAR(100) NOT NULL DEFAULT '',
    comment VARCHAR(10000) DEFAULT '',

    PRIMARY KEY (div_id),
    INDEX idx_code (div_code),
    INDEX idx_name (name(20))
) ENGINE=InnoDB;

-- Table: gencode
-- NCBI taxonomy file: gencode.dmp

CREATE TABLE IF NOT EXISTS `gencode` (
    gc_id INT UNSIGNED NOT NULL,
    abbr VARCHAR(100) NOT NULL DEFAULT '',
    name VARCHAR(100) NOT NULL DEFAULT '',
    cde VARCHAR(200) NOT NULL DEFAULT '',
    starts VARCHAR(200) NOT NULL DEFAULT '',

    PRIMARY KEY (gc_id),
    INDEX idx_abbr (abbr(20)),
    INDEX idx_name (name(20))
) ENGINE=InnoDB;

-- Table: citations
-- NCBI taxomony file: citations.dmp

CREATE TABLE IF NOT EXISTS `citations` (
    cit_id INT UNSIGNED NOT NULL,
    cit_key VARCHAR(5000) NOT NULL DEFAULT '',
    pubmed INT UNSIGNED,
    medline INT UNSIGNED,
    url VARCHAR(1000) NOT NULL DEFAULT '',
    cit_text VARCHAR(10000) NOT NULL DEFAULT '',
    taxids VARCHAR(500) NOT NULL DEFAULT '',

    PRIMARY KEY (cit_id),
    INDEX idx_pubmed (pubmed),
    INDEX idx_medline (medline)
) ENGINE=InnoDB;

-- End of creation
