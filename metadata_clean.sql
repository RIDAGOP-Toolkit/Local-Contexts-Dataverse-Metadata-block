-- Function to perform the desired task using variables
DROP FUNCTION IF EXISTS find_metadatablock(VARCHAR);

CREATE OR REPLACE FUNCTION find_metadatablock(search_name VARCHAR)
RETURNS TABLE (metadatablock_id INTEGER, dataverse_id BIGINT, datasetfieldtype_id INTEGER, datasetfield_id INTEGER, datasetfieldcompoundvalue_id INTEGER, controlledvocabularyvalue_id INTEGER) AS $$
BEGIN
    RETURN QUERY
    SELECT m.id, dvmdb.dataverse_id, dft.id, ds.id, dfcv.id, cvv.id
    FROM metadatablock AS m
    LEFT JOIN dataverse_metadatablock as dvmdb ON dvmdb.metadatablocks_id = m.id
    LEFT JOIN datasetfieldtype AS dft ON dft.metadatablock_id = m.id
    LEFT JOIN datasetfield AS ds ON ds.datasetfieldtype_id = dft.id
    LEFT JOIN datasetfieldcompoundvalue as dfcv ON dfcv.parentdatasetfield_id = ds.id
    LEFT JOIN controlledvocabularyvalue AS cvv ON cvv.datasetfieldtype_id = dft.id
    WHERE m.name = search_name;
END;
$$ LANGUAGE plpgsql;


-- Function to delete rows from all tables using search_name parameter
DROP FUNCTION IF EXISTS delete_related_rows(VARCHAR);

CREATE OR REPLACE FUNCTION delete_related_rows(search_name VARCHAR)
RETURNS VOID AS $$
BEGIN
    -- Create a temporary table to store the result of find_metadatablock(search_name)
    CREATE TEMPORARY TABLE temp_related_rows ON COMMIT DROP AS
        SELECT * FROM find_metadatablock(search_name);

    DELETE FROM datasetfield
    WHERE datasetfield.id IN (SELECT datasetfield_id FROM temp_related_rows);

    DELETE FROM datasetfieldcompoundvalue
    WHERE datasetfieldcompoundvalue.id IN (SELECT datasetfieldcompoundvalue_id FROM temp_related_rows);

    DELETE FROM controlledvocabularyvalue
    WHERE controlledvocabularyvalue.id IN (SELECT controlledvocabularyvalue_id FROM temp_related_rows);

    DELETE FROM datasetfieldtype
    WHERE datasetfieldtype.id IN (SELECT datasetfieldtype_id FROM temp_related_rows);

    DELETE FROM metadatablock
    WHERE metadatablock.id IN (SELECT metadatablock_id FROM temp_related_rows);
END;
$$ LANGUAGE plpgsql;

-- suggested usage:
-- make a first search
-- SELECT * FROM find_metadatablock('my-metadata-block-name');
-- if there is a dataverse, print its alias
-- SELECT alias FROM dataverse WHERE id IN (SELECT dataverse_id FROM find_metadatablock('my-metadata-block-name'));
-- there should be no dataverse and no DATASET using the metadatablock... then this should work
-- SELECT delete_related_rows('my-metadata-block-name');