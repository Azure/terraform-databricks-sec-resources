#!/bin/bash

# This script downloads any custom Python package whls using links in 
# variables.cluster_default_packages, and re-uploads them to DBFS for cluster installation.

#NOTE: this assumes network connectivity to the provided URIs

echo "Downloading custom whls for clusters..."

mkdir ./custom-whls && cd ./custom-whls

# First argument should be a list of remote URIs
whlnames=()

IFS=', '
read -ra ADDR <<< "$1"
for uri in "${ADDR[@]}"; 
do
    # Download whl
    curl --remote-name $uri

    #TODO: successful checksum validation or quit

    # Gather whl filenames for retrieval
    whlnames+=($(basename $uri))
done

cd ..

# Append whl filenames to file
echo $TF_VAR_whlnames >> "whl_names.txt"

echo "Downloaded. Uploading to dbfs..."

# Login to Databricks CLI (without prompt or config file)

export DATABRICKS_ADDRESS=$2 # host
export DATABRICKS_API_TOKEN=$3 # PAT

# Upload ./custom-whls to dbfs

dbfs cp -r ./custom-whls dbfs:/custom-whls

echo "Uploaded!"

rm -rf ./custom-whls