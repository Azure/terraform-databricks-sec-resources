#!/bin/bash

# This script downloads any custom Python package whls using links in 
# variables.cluster_default_packages, and re-uploads them to DBFS for cluster installation.

#NOTE: this assumes network connectivity to the provided URIs

echo "Downloading custom whls for clusters..."

# Ready output file
> "whl_names.txt"

mkdir ./custom-whls && cd ./custom-whls

# First argument should be a comma-separated string of remote URIs
IFS=', '
read -ra ADDR <<< "$1"
for uri in "${ADDR[@]}"; 
do
    # Download whl
    curl --remote-name $uri

    #TODO: successful checksum validation or quit

    # Append whl filenames to output
    echo $(basename $uri) >> "../whl_names.txt"
done

cd ..

echo "Downloaded. Uploading to dbfs..."

# dbfs auth
export DATABRICKS_ADDRESS=$2 # host
export DATABRICKS_API_TOKEN=$3 # PAT

# Upload ./custom-whls to dbfs
dbfs cp -r ./custom-whls dbfs:/mnt/custom-whls

echo "Uploaded!"

rm -rf ./custom-whls