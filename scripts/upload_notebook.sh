#!/bin/bash

# $1 - Databricks Host Url
# $2 - Databricks Authorisation Token
# $3 - The path and name to upload the notebook to in Databricks 
# $4 - Base64 encoded Jupyter notebook

set -e

IMPORT_PAYLOAD='{"content": '"\""$4"\""',"path": '"\""$3"\""',"overwrite": true,"format": "JUPYTER"}'

IMPORT_URL="$1/api/2.0/workspace/import/"

echo $IMPORT_PAYLOAD

echo "Uploading Notebook to $1".

curl --request POST --header "Authorization:Bearer $2" --header "Content-Type:application/json" --data "$IMPORT_PAYLOAD" $IMPORT_URL

echo "Finished Uploading Notebook"