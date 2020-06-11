#!/bin/bash

# This script downloads any custom Python package whls using links in 
# variables.cluster_default_packages, and re-uploads them to DBFS for cluster installation.

# NOTE: this assumes network connectivity to the provided URIs

echo "Downloading custom whls for clusters..."

mkdir ./custom-whls && cd ./custom-whls

# First argument should be a comma-separated string of remote URIs
IFS=', '
read -ra ADDR <<< "$1"
for uri in "${ADDR[@]}"; 
do
    # Download whl
    curl --remote-name $uri

    # Checksum validation
    sha256sum $(basename $uri) > shasum.txt
    sha256sum -c shasum.txt
    rm shasum.txt
done

cd ..

echo "Downloaded. Uploading to dbfs..."

# dbfs auth
export DATABRICKS_HOST=$2 # host
export DATABRICKS_TOKEN=$3 # PAT

# Upload ./custom-whls to dbfs
dbfs cp -r ./custom-whls dbfs:/mnt/custom-whls

echo "Uploaded!"

rm -rf ./custom-whls