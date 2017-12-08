SELECT
    a.blastprg           AS BLAST_Program,
    r.qry_name           AS Contig_NAME,
    r.hit_acc            AS Hit_Accession_Number,
    r.hit_desc           AS Hit_Description,
    r.hit_len            AS Hit_Length,
    r.evalue             AS E_Value,
    r.score              AS Score,
    r.iden * 100         AS Identity,
    r.conv * 100         AS Similarity,
    r.hsp_len            AS HSP_length,
    t.hit_superkingdom   AS Superkingdom,
    t.hit_family         AS Family,
    t.hit_genus          AS Genus,
    t.hit_species        AS Species
FROM
    analysis AS a,
    result AS r,
    taxon AS t
WHERE
    a.id                  = r.anlys_id
  AND
    r.hit_tax_id          = t.tax_id

