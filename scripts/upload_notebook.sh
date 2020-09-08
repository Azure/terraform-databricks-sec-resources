#!/bin/bash

# $1 - Databricks Host Url
# $2 - The path and name to upload the notebook to in Databricks 
# $3 - File path to Jupyter notebook

set -e

#Visual check for presence of notebook.ipynb
pwd
ls -la $3

BASE64_CONTENT="$(base64 < $3)"

IMPORT_PAYLOAD='{"content": '"\""$BASE64_CONTENT"\""',"path": '"\""$2"\""',"overwrite": true,"format": "JUPYTER"}'

echo $IMPORT_PAYLOAD > payload.json

IMPORT_URL="$1/api/2.0/workspace/import/"

echo "Uploading Notebook to $1".

curl --request POST --header "Authorization:Bearer $DATABRICKS_TOKEN" --header "Content-Type:application/json" --data @payload.json $IMPORT_URL

echo "Finished Uploading Notebook"
