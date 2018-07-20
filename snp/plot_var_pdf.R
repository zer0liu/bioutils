#!/usr/bin/Rscript
library(ggplot2)

# Parse command arguments
args <- commandArgs( trailingOnly = TRUE)

fin <- args[1]

vsite <- read.table(fin, header = TRUE)

p <- ggplot(vsite, aes(x=Location, y=Strain, fill=Value)) + geom_tile() + theme_classic() + scale_fill_manual(values = c("grey30", "white", "#4daf4a", "#e41a1c", "#377eb8", "#ff7f00")) + theme(axis.title.y = element_blank(), axis.text.y = element_blank(), axis.ticks.y = element_blank(), axis.line.y = element_blank())

ggsave("vsite.pdf", p, device = "pdf")

