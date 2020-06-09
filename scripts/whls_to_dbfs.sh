#!/bin/bash

# This script downloads any custom Python package whls using links in 
# variables.cluster_default_packages, and re-uploads them to DBFS for cluster installation.

#NOTE: this assumes network connectivity to the provided URIs

echo "Downloading custom whls for clusters..."

mkdir ./custom-whls && cd ./custom-whls

#TODO: ensure checksum validation on all downloads
#TODO: if uris changes, this should rerun - trigger on that TF variable
# First argument should be a list of remote URIs
for uri in $1
do
    curl --remote-name $uri
done

cd ..

echo "Downloaded. Uploading to dbfs..."

# Login to Databricks CLI (without prompt or config file)

export DATABRICKS_ADDRESS=$2
export DATABRICKS_API_TOKEN=$3

# Upload ./custom-whls to dbfs

dbfs cp -r ./custom-whls dbfs:/custom-whls

echo "Uploaded!"

rm -rf ./custom-whls