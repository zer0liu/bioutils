README.txt

:Author: zeroliu
:Email: zeroliu@R7050
:Date: 2020-06-01 14:20

Scripts under this folder were used to parse the annotation results of 
eggnog-mapper (https://github.com/eggnogdb/eggnog-mapper).

For eggNOG mapper v2, it outputs reports in 22 columns:

1. query_name
2. seed eggNOG ortholog
3. seed ortholog evalue
4. seed ortholog score
5. Predicted taxonomic group
6. Predicted protein name
7. Gene Ontology terms 
8. EC number
9. KEGG_ko
10. KEGG_Pathway
11. KEGG_Module
12. KEGG_Reaction
13. KEGG_rclass
14. BRITE
15. KEGG_TC
16. CAZy 
17. BiGG Reaction
18. tax_scope: eggNOG taxonomic level used for annotation
19. eggNOG OGs 
20. bestOG (deprecated, use smallest from eggnog OGs)
21. COG Functional Category
22. eggNOG free text description

(From eggNOG-mapper v2 documentation: https://github.com/eggnogdb/eggnog-mapper/wiki/eggNOG-mapper-v2).

