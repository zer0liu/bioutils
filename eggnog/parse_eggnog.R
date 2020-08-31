#!/usr/bin/Rscript

#
# NAME
#
#   plot_eggNOG.R - Plot statistics of COG, GO annotation from a
#                   eggnog-mapper output.
#
# DESCRIPTION
#
# AUTHOR
#
#   zeroliu-at-gmail-dot-com
#
# VERSION
#
#   0.0.1   2020-06-01

library(ggolot2)
suppressPackageStartupMessages(library(R.utils))

# Usage information
Usage <- "
Plot COG, GO statistics annotation from a eggnog-mapper output.
Usage:
  Rscript plot_eggnog.R --in=<file> [--outdir=<dir>]
Arguments;
  --in=<file>     Input eggnog-mapper annotation report.
  --outdir=<dir>  Output directory name.
                  Default current directory.

"

# Parse command arguments
args <- commandArgs(trailingOnly = TRUE, asValues = TRUE)

if ( length(args$`in` ) == 0 ) {
  stop(paste("[ERROR] No input file found!\n", usage), 
       call.=FALSE)
} else {
  fin = args$`in`
}

if ( length(args$outdir ) == 0 ) {
  # default output file
  print("[NOTE] Output to current directory.\n")
  outdir    <- "."
} else {
  outdir    <- args$outdir
}

# Read input file
annot <- read.table(fin, header = FALSE, comment.char = "#", sep = "\t", quote = "")

# eggNOG annotation 22 column names
colnames(annot) <- c("query_name", 
                     "seed_eggNOG_ortholog", 
                     "seed_ortholog_evalue", 
                     "seed_ortholog_score", 
                     "Predicted_taxonomic_group", 
                     "Predicted_protein_name", 
                     "GO_terms", 
                     "EC_number", 
                     "KEGG_ko", 
                     "KEGG_Pathway", 
                     "KEGG_Module", 
                     "KEGG_Reaction", 
                     "KEGG_rclass", 
                     "BRITE", 
                     "KEGG_TC", 
                     "CAZy", 
                     "BiGG_Reaction", 
                     "tax_scope", 
                     "eggNOG_OGs", 
                     "bestOG", 
                     "COG_Category", 
                     "eggNOG_description")

