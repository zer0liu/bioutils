#!/usr/bin/Rscript

#
# NAME
#
#   plot_var2pdf.R - Plot variation site information into a PDF file
#
# DESCRIPTION
#
# AUTHOR
#
#   zeroliu-at-gmail-dot-com
#
# VERSION
#
#   0.0.1   2018-04-30
#   0.1.0   2018-07-20
#   0.1.1   2018-07-25  More details for legend
#   0.2.0   2020-03-14  More options for fine tuning of plot

library(ggplot2)
suppressPackageStartupMessages( library(R.utils) )

# Usage information
usage <- "
Plot SNP information according to the output of script 'stat_var_codon.pl'.
Usage:
  Rscript plot_var2pdf.R --in=<fin> [--out=<fout>] [--strname] [--grid]
Arguments:
  --in=<fin>    Input file, created by the script 'stat_var_codon.pl'
  --out=<fout>  Output file. Optional. 
                Default 'vsite.pdf'.
Options:
  --strname     Show strain/sequence name.
                Default do not show.
  --grid        Show gray grid.
                Default do not show.
"

# Parse command arguments
args <- commandArgs( trailingOnly = TRUE, asValues = TRUE )

if ( length(args$`in` ) == 0 ) {
    stop(paste("[ERROR] At least one argument must be supplied (input file)!\n", usage), 
        call.=FALSE)
} else {
    fin = args$`in`
}

if ( length(args$out ) == 0 ) {
    # default output file
    print("[NOTE] Default output file 'vsites.pdf'.\n")
    fout    <- "vsites.pdf"
} else {
    fout    <- args$out
}

# Read input file
vsite <- read.table(fin, header = TRUE)

# Operation on viste$Strain, for headmap plot in given order
vsite$Strain <- as.character( vsite$Strain )
vsite$Strain <- factor(vsite$Strain, levels = unique(vsite$Strain) )

# Plotting
p <- ggplot(vsite, aes(x=Location, y=Strain, fill=Value))  

# Whether show/hide gray grid
if ( args$grid == TRUE ) {  # Show 
    p <- p + geom_tile( color = "gray" )
} else {    # Hide
    p <- p + geom_tile()
}

# Hide background grid
p <- p + theme_classic()

# Whether show/hide strain/sequence name
if ( args$strname == TRUE ) {   # Show 
    p <- p + theme(
        axis.title.y = element_blank(), 
        # axis.text.y = element_blank(), 
        axis.ticks.y = element_blank(), 
        axis.line.y = element_blank() ) +
        ylim( rev( levels( vsite$Strain ) ) )   # Plot heatmap y label in line order
} else {    # Hide
    p <- p + theme(
        axis.title.y = element_blank(), 
        axis.text.y = element_blank(), 
        axis.ticks.y = element_blank(), 
        axis.line.y = element_blank() ) 
}

p <- p + scale_fill_manual(
        values = c("grey30", "white", "#4daf4a", "#e41a1c", "#377eb8", "#ff7f00"), 
        breaks=c("-", "a", "i", "n", "s", "u"), 
        labels=c("Gap", "Not changed", "Intergenic Region", "Nonsynonymous", "Synonymous", "UTR"), name=NULL)

ggsave(fout, p, device = "pdf")

