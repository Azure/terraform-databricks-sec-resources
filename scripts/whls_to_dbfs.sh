#!/bin/bash

# This script downloads any custom Python package whls using links in 
# variables.cluster_default_packages, and re-uploads them to DBFS for cluster installation.

# NOTE: this assumes network connectivity to the provided URIs

set -ex

echo "Downloading Packages."

mkdir -p defaultpackages && cd defaultpackages

# First argument should be a comma-separated string of remote URIs
IFS=', '

#NOT IDEAL:Databricks expects to see a .whl file in the zip. To avoid string manipulation when a passed array has URL parameters
#we just give the curled library a fixed name based on a moving iterator. TEMPORARY FIX. Planned implementation negates need for 
#URLS entirely.
ITERATOR=0

read -ra ADDR <<< "$1"
for uri in "${ADDR[@]}"; 
do
    PACKAGE_NAME="package-"$ITERATOR".whl"

    # Download whl
    curl -o $PACKAGE_NAME $uri

    ((ITERATOR++))
done

ls -la

echo "Downloaded Packages."

cd ..

echo "Zip Package Folder to defaultpackages.wheelhouse.zip"
# Upload ./defaultpackages wheelhouse to dbfs
zip -r defaultpackages.wheelhouse.zip defaultpackages

echo "Packages Zipped."

ls -la

az storage blob upload --container-name "$3" --file "defaultpackages.wheelhouse.zip" --name "defaultpackages.wheelhouse.zip" --account-name "$2" --auth-mode "login" --subscription "$ARM_SUBSCRIPTION_ID"

echo "defaultpackes.wheelhouse.zip Uploaded."

rm -rf defaultpackages
rm -rf defaultpackages.wheelhouse.zip
