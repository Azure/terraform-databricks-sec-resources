#!/bin/bash

# $1 - Databricks Host Url
# $2 - The path and name to upload the notebook to in Databricks 
# $3 - File path to Jupyter notebook

set -e

pwd

BASE64_CONTENT="$(base64 < $3)"

IMPORT_PAYLOAD='{"content": '"\""$BASE64_CONTENT"\""',"path": '"\""$2"\""',"overwrite": true,"format": "JUPYTER"}'

IMPORT_URL="$1/api/2.0/workspace/import/"

echo $IMPORT_PAYLOAD

echo "Uploading Notebook to $1".

curl --request POST --header "Authorization:Bearer $DATABRICKS_TOKEN" --header "Content-Type:application/json" --data "$IMPORT_PAYLOAD" $IMPORT_URL

echo "Finished Uploading Notebook"
