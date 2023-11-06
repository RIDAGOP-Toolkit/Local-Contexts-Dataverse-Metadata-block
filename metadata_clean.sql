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
DECLARE
    rows_deleted INTEGER := 0;
    temp_rows_deleted INTEGER := 0;
BEGIN
    -- Create a temporary table to store the result of find_metadatablock(search_name)
    CREATE TEMPORARY TABLE temp_related_rows ON COMMIT DROP AS
        SELECT * FROM find_metadatablock(search_name);

    -- Start of the loop
    LOOP
        -- Reset the rows_deleted count at the start of each loop
        rows_deleted := 0;

        -- Delete from datasetfield_controlledvocabularyvalue
        DELETE FROM datasetfield_controlledvocabularyvalue
        WHERE controlledvocabularyvalues_id IN (SELECT controlledvocabularyvalue_id FROM temp_related_rows);
        GET DIAGNOSTICS temp_rows_deleted = ROW_COUNT;
        rows_deleted := rows_deleted + temp_rows_deleted;

        -- Delete from controlledvocabularyvalue
        DELETE FROM controlledvocabularyvalue
        WHERE id IN (SELECT controlledvocabularyvalue_id FROM temp_related_rows);
        GET DIAGNOSTICS temp_rows_deleted = ROW_COUNT;
        rows_deleted := rows_deleted + temp_rows_deleted;

        -- Delete from datasetfieldvalue
        DELETE FROM datasetfieldvalue
        WHERE datasetfield_id IN (SELECT datasetfield_id FROM temp_related_rows);
        GET DIAGNOSTICS temp_rows_deleted = ROW_COUNT;
        rows_deleted := rows_deleted + temp_rows_deleted;

        -- Delete from datasetfield where parentdatasetfieldcompoundvalue_id is in temp_related_rows
        DELETE FROM datasetfield
        WHERE parentdatasetfieldcompoundvalue_id IN (SELECT datasetfield_id FROM temp_related_rows);
        GET DIAGNOSTICS temp_rows_deleted = ROW_COUNT;
        rows_deleted := rows_deleted + temp_rows_deleted;

        -- Delete from datasetfieldcompoundvalue
        DELETE FROM datasetfieldcompoundvalue
        WHERE parentdatasetfield_id IN (SELECT datasetfield_id FROM temp_related_rows);
        GET DIAGNOSTICS temp_rows_deleted = ROW_COUNT;
        rows_deleted := rows_deleted + temp_rows_deleted;

        -- Delete from datasetfield
        DELETE FROM datasetfield
        WHERE id IN (SELECT datasetfield_id FROM temp_related_rows);
        GET DIAGNOSTICS temp_rows_deleted = ROW_COUNT;
        rows_deleted := rows_deleted + temp_rows_deleted;

        -- Delete from datasetfieldtype
        DELETE FROM datasetfieldtype
        WHERE id IN (SELECT datasetfieldtype_id FROM temp_related_rows);
        GET DIAGNOSTICS temp_rows_deleted = ROW_COUNT;
        rows_deleted := rows_deleted + temp_rows_deleted;

        -- Delete from metadatablock
        DELETE FROM metadatablock
        WHERE id IN (SELECT metadatablock_id FROM temp_related_rows);
        GET DIAGNOSTICS temp_rows_deleted = ROW_COUNT;
        rows_deleted := rows_deleted + temp_rows_deleted;

        -- Exit the loop when no more rows are deleted
        EXIT WHEN rows_deleted = 0;
    END LOOP;
END;
$$ LANGUAGE plpgsql;



-- suggested usage:
-- make a first search
SELECT * FROM find_metadatablock('local_contexts_test');
-- if there is a dataverse, print its alias
SELECT alias FROM dataverse WHERE id IN (SELECT dataverse_id FROM find_metadatablock('local_contexts_test'));
-- there should be no dataverse and no DATASET using the metadatablock... then this should work
SELECT delete_related_rows('local_contexts_test');