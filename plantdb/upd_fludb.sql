--
--  upd_fludb.sql   - Update fludb database.
--
--  After influenza A virus sequences, in GenBank format, has been loaded
--  into a virdb database, this SQLite3 script could be used to fix errors
--  tables:
--  (1) Missing or wrong 'gene' name in 'feature' table
--  (2) Missing or wrong 'segment' in 'sequence' table
--
--  NOTE: feature type 'gene' does NOT have field 'product', whereas 'CDS'
--        has 'product' field.
--
--  ======================================================== 
--
-- Update table 'feature' according to field 'product'
--
-- Of which, product 'RNA polymerase', 'polymerase' and 'polymerase basic 
-- protein' has multiple related genes.



-- PB2 protein

UPDATE feature
SET
    gene = 'PB2'
WHERE
    ftype = 'CDS' 
  AND
    product IN (
        'PB2',
        'PB2 polymerase protein',
        'PB2 protein',
        'Polymerase basic protein 2',
        'basic polymerase protein 2',
        'basic protein 2',
        'polymerase 2',
        'polymerase B2',
        'polymerase PB2',
        'polymerase Pb2',
        'polymerase baseic protein 2',
        'polymerase basic 2',
        'polymerase basic 2 protein',
        'polymerase basic protein2',
        'polymerase basic protein 2',
        'polymerase basic protein subunit 2',
        'polymerase basic subunit 2',
        'polymerase protein PB2',
        'polymerase subunit PB2',
        'protein basic 2'
    );



-- PB1 and PB1-F2 proteins

UPDATE feature
SET
    gene = 'PB1'
WHERE
    ftype = 'CDS'
  AND
    product IN (
        'PB1', 
        'PB1 polymerase protein',
        'PB1 protein',
        'Polymerase PB1',
        'Polymerase basic protein 1',
        'basic polymerase 1',
        'basic polymerase protein 1',
        'basic protein 1',
        'polymerase 1',
        'polymerase B1',
        'polymerase PB1',
        'polymerase Pb1',
        'polymerase basic protein 1',
        'polymerase basic protein subunit 1',
        'polymerase basic protein1',
        'polymerase basic subunit 1',
        'polymerase basic 1',
        'polymerase basic 1 protein',
        'polymerase protein PB1',
        'polymerase subunit PB1'
    );

UPDATE feature
SET
    gene = 'PB1-F2'
WHERE
    ftype = 'CDS'
  AND
    product IN (
        'PB1-F2',
        'PB1-F2 polymerase protein',
        'PB1-F2 protein',
        'polymerase basic protein 1 F2',
        'polymerase basic protein 1-F2',
        'putative PB1-F2',
        'putative PB1-F2 protein'
    );



-- PA and PA-X proteins

UPDATE feature
SET
    gene = 'PA'
WHERE 
    ftype = 'CDS'
  AND
    product IN (
        'PA',
        'PA protein',
        'Polymerase A Protein',
        'Polymerase PA',
        'Polymerase acidic protein',
        'RNA polymerase A',
        'acidic polymerase',
        'plymerase acidic protein',
        'polymerase 3',
        'polymerase A',
        'polymerase PA',
        'polymerase acid',
        'polymerase acid protein',
        'polymerase acidic',
        'polymerase acidic proptein',
        'polymerase acidic protein',
        'polymerase acidic protein 2',
        'polymerase protein',
        'polymerase protein A',
        'polymerase protein PA'
    );

UPDATE feature
SET
    gene = 'PA-X'
WHERE
    ftype = 'CDS'
  AND
    product IN (
        'PA-X protein'
    );



-- HA protein

UPDATE feature
SET
    gene = 'HA'
WHERE
    ftype = 'CDS' 
  AND
    product IN (
        'H5 hemagglutinin',
        'HA',
        'Haemagglutinin',
        'Hemagglutinin',
        'haemagglutinin',
        'haemmagglutinin',
        'hemaggluinin',
        'hemagglutinin',
        'hemagglutinin 1 chain',
        'hemagglutinin 5',
        'hemagglutinin H5',
        'hemagglutinin HA',
        'hemagglutinin HA1',
        'hemagglutinin esterase precursor',
        'hemagglutinin precursor',
        'hemagglutinin prepropeptide',
        'hemagglutinin protein',
        'hemagglutinin protein subunit 1',
        'hemagglutinin subtype H5',
        'hemaglutinin',
        'hemmagglutinin',
        'hemmaglutinin',
        'truncated hemagglutinin'
    );



-- NP protein

UPDATE feature
SET
    gene = 'NP'
WHERE
    ftype = 'CDS'
  AND
    product IN (
       'NP',
        'Nucleoprotein',
        'nucelocapsid protein',
        'nuclear protein',
        'nucleocapsid',
        'nucleocapsid protein',
        'nucleoprotein',
        'nucleoprotein NP' 
    );



-- NA protein

UPDATE feature
SET
    gene = 'NA'
WHERE
    ftype = 'CDS'
  AND
    product IN (
       'NA',
        'Neuraminidase',
        'neuramidase',
        'neuraminadase',
        'neuramindase',
        'neuraminidase',
        'neuraminidase 1',
        'neuraminidase N1',
        'neuraminidase NA',
        'neuraminidase protein',
        'neuraminidase protein N1',
        'neuraminidase subtype 1',
        'nueraminidase',
        'truncated neuraminidase' 
    );



-- M1 and M2 proteins

UPDATE feature
SET
    gene = 'M1'
WHERE
    ftype = 'CDS'
  AND
    product IN (
        'M1 matrix protein',
        'M1 protein',
        'Matrix protein 1',
        'MP',
        'matix protein',
        'matrix',
        'matrix protein',
        'matrix protein 1',
        'matrix protein M1',
        'matrixprotein 1',
        'matrixprotein1',
        'membrane matrix protein M1',
        'membrane protein',
        'membrane protein M1',
        'truncated matrix protein 1' 
    );

UPDATE feature
SET
    gene = 'M2'
WHERE
    ftype = 'CDS'
  AND
    product IN (
		'M2',
		'M2 ion channel',
		'M2 matrix protein',
		'M2 protein',
		'Matrix protein 2',
		'matrix protein 2',
		'matrix protein M2',
		'matrix protein2',
		'membrane ion channel',
		'membrane ion channel 2',
		'membrane ion channel M2',
		'membrane ion channel protein',
		'membrane ion channel protein M2',
		'membrane ion channel; M2',
		'truncated matrix protein 2' 
    );



-- NS1 and NS2 proteins

UPDATE feature
SET
    gene = 'NS1'
WHERE
    ftype = 'CDS'
  AND
    product IN (
		'NS',
		'NS1',
		'NS1 nonstructural protein',
		'NS1 protein',
		'Nonstructural protein 1',
		'non structural protein 1',
		'non-structural 1',
		'non-structrual 1 protein',
		'non-structural protein',
		'non-structural protein 1',
		'non-structural protein NS1',
		'nonstractual protein',
		'nonstrucral protein 1',
		'nonstructual protein',
		'nonstructual protein 1',
		'nonstructural protein',
		'nonstructural protein 1',
		'nonstructural protein NS1',
		'nonstructural protein1',
		'truncated nonstructural protein 1',
		'truncated nonstructural protein NS1' 
    );

UPDATE feature
SET
    gene = 'NS2'        -- Also known as 'NEP'
WHERE
    ftype = 'CDS'
  AND
    product IN (
		'NEP/NS2',
		'NS2',
		'NS2 nonstructural protein',
		'NS2/NEP',
		'Nonstructural protein 2',
		'non structural protein 2',
		'non-structural protein 2',
		'non-structural protein NS2',
		'nonstructual protein 2',
		'nonstructural protein 2',
		'nonstructural protein NS2',
		'nonstructural protein2',
		'nucelar export protein',
		'nuclear export protein',
		'nuclear export protein 2',
		'nuclear export protein NS2' 
    );



-- Patches

-- 'AB557634' and 'DQ449635', although annotated as 'nucleoprotein', 
-- in fact, it is NA protein.

UPDATE feature
SET
    gene = 'NA'
WHERE
    ftype = 'CDS'
  AND
    seq_id IN (
        SELECT id FROM sequence WHERE accession IN ('AB557634', 'DQ449635')
    );

-- 'AY646171', 'AY646179', 'AY770995', 'EU008580', 'EU008588', 'EU008596',
-- of which 'gene' fields were blank, but all of them are 'PA'

UPDATE feature
SET
    gene = 'PA'
WHERE
    ftype = 'CDS'
  AND
    seq_Id IN (
        SELECT id 
        FROM sequence 
        WHERE
            accession IN (
				'AY646171',
				'AY646179',
				'AY770995',
				'EU008580',
				'EU008588',
				'EU008596'
            )
    );

-- Some PA genes were named as 'pa'

UPDATE feature
SET
    gene = 'PA'
WHERE
    gene = 'pa';

--  ========================================================
--
--  Update table 'segment' according to field 'gene' of ftype 'CDS' in
--  table 'feature'.
--

-- Segment PB2

UPDATE sequence
SET
    segment = 'PB2'
WHERE
    id IN (
        SELECT seq_id 
        FROM feature
        WHERE 
            ftype = 'CDS' 
          AND
            gene = 'PB2'
    );

-- Segment PB1

UPDATE sequence
SET
    segment = 'PB1'
WHERE
    id IN (
        SELECT seq_id 
        FROM feature
        WHERE 
            ftype = 'CDS' 
          AND
            ( gene = 'PB1' OR gene = 'PB1-F2' )
    );

-- Segment PA

UPDATE sequence
SET
    segment = 'PA'
WHERE
    id IN (
        SELECT seq_id 
        FROM feature
        WHERE 
            ftype = 'CDS' 
          AND
            ( gene = 'PA' OR gene = 'PA-X' )
    );

-- Segment HA

UPDATE sequence
SET
    segment = 'HA'
WHERE
    id IN (
        SELECT seq_id 
        FROM feature
        WHERE 
            ftype = 'CDS' 
          AND
            gene = 'HA'
    );

-- Segment NP

UPDATE sequence
SET
    segment = 'NP'
WHERE
    id IN (
        SELECT seq_id 
        FROM feature
        WHERE 
            ftype = 'CDS' 
          AND
            gene = 'NP'
    );

-- Segment NA

UPDATE sequence
SET
    segment = 'NA'
WHERE
    id IN (
        SELECT seq_id 
        FROM feature
        WHERE 
            ftype = 'CDS' 
          AND
            gene = 'NA'
    );

-- Segment MP

UPDATE sequence
SET
    segment = 'MP'
WHERE
    id IN (
        SELECT seq_id 
        FROM feature
        WHERE 
            ftype = 'CDS' 
          AND
            ( gene = 'M1' OR gene = 'M2' )
    );

-- Segment NS

UPDATE sequence
SET
    segment = 'NS'
WHERE
    id IN (
        SELECT seq_id 
        FROM feature
        WHERE 
            ftype = 'CDS' 
          AND
            ( gene = 'NS1' OR gene = 'NS2' )
    );


