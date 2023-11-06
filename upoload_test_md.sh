#!/bin/bash
# rsync a local file to ridagop (in ssh config  to /home/dv)
rsync  -avz  localcontexts_dv_metadatablock_swap.tsv ridagop:/home/dataverse/test_upload


remote_command="curl http://localhost:8080/api/admin/datasetfield/load -H "Content-type: text/tab-separated-values" -X POST --upload-file /home/dataverse/test_upload/localcontexts_dv_metadatablock_swap.tsv"

#ssh  ridagop $remote_command


#curl "http://localhost:8080/api/admin/index/solr/schema" | /usr/local/solr/solr-8.11.1/server/solr/collection1/conf/schema.xml
# curl "http://localhost:8983/solr/admin/cores?action=RELOAD&core=collection1"