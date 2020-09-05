#!/bin/bash

# This script downloads any custom Python package whls using links in 
# variables.cluster_default_packages, and re-uploads them to DBFS for cluster installation.

# NOTE: this assumes network connectivity to the provided URIs

set -e

echo "Target Databricks Host:"
echo "$3"

echo "Downloading Packages."

mkdir -p defaultpackages && cd defaultpackages

# First argument should be a comma-separated string of remote URIs
IFS=', '
read -ra ADDR <<< "$2"
for uri in "${ADDR[@]}"; 
do
    # Download whl
    curl --remote-name $uri

    # Checksum validation
    sha256sum $(basename $uri) > shasum.txt
    sha256sum -c shasum.txt
    rm shasum.txt
done

ls -la

echo "Downloaded Packages."

cd ..

# dbfs auth
export DATABRICKS_HOST=$3 # host
export DATABRICKS_TOKEN=$4 # PAT

echo "Zip Package Folder to defaultpackages.wheelhouse.zip"
# Upload ./defaultpackages wheelhouse to dbfs
zip -r defaultpackages.wheelhouse.zip defaultpackages

echo "Packages Zipped."

ls -la

echo "Uploading to defaultpackages.wheelhouse.zip to:"
echo "$3"

dbfs cp -r --overwrite defaultpackages.wheelhouse.zip dbfs:/mnt/libraries/defaultpackages.wheelhouse.zip

echo "defaultpackes.wheelhouse.zip Uploaded."

rm -rf defaultpackages
rm -rf defaultpackages.wheelhouse.zip
