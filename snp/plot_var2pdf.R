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
#

library(ggplot2)

# Parse command arguments
args <- commandArgs( trailingOnly = TRUE)

if (length(args)==0) {
    stop("[ERROR] At least one argument must be supplied (input file)!\n", call.=FALSE)
} else if (length(args)==1) {
    fin     <- args[1]
    # default output file
    print("[NOTE] Default output file 'vsite.pdf'.\n")
    fout    <- "vsite.pdf"
} else {
    fin     <- args[1]
    fout    <- args[2]
}

# Read input file
vsite <- read.table(fin, header = TRUE)

# p <- ggplot(vsite, aes(x=Location, y=Strain, fill=Value)) + geom_tile() + theme_classic() + scale_fill_manual(values = c("grey30", "white", "#4daf4a", "#e41a1c", "#377eb8", "#ff7f00")) + theme(axis.title.y = element_blank(), axis.text.y = element_blank(), axis.ticks.y = element_blank(), axis.line.y = element_blank())

p <- ggplot(vsite, aes(x=Location, y=Strain, fill=Value)) + geom_tile() + theme_classic() +  theme(axis.title.y = element_blank(), axis.text.y = element_blank(), axis.ticks.y = element_blank(), axis.line.y = element_blank() ) + scale_fill_manual(values = c("grey30", "white", "#4daf4a", "#e41a1c", "#377eb8", "#ff7f00"), breaks=c("-", "a", "i", "n", "s", "u"), labels=c("Gap", "Not changed", "Iner-gene", "Nonsynonymous", "Synonymous", "UTR"), name=NULL)

ggsave(fout, p, device = "pdf")

