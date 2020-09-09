#!/bin/bash

# This script downloads any custom Python package whls using links in 
# variables.cluster_default_packages, and re-uploads them to DBFS for cluster installation.

# NOTE: this assumes network connectivity to the provided URIs

set -e

echo "Downloading Packages."

mkdir -p defaultpackages && cd defaultpackages

# First argument should be a comma-separated string of remote URIs
IFS=', '

read -ra ADDR <<< "$1"
for uri in "${ADDR[@]}"; 
do
    #Remove the domain from the URL
    REMOTE_NAME=$(basename $uri)

    #Keep everything up to the .whl, exclude the .whl and any additional url parameters to be safe. Reappend .whl. 
    PACKAGE_NAME=${REMOTE_NAME%%.whl*}".whl"

    # Download whl
    curl -o $PACKAGE_NAME $uri
done

ls -la

echo "Downloaded Packages."

cd ..

echo "Zip Package Folder to defaultpackages.wheelhouse.zip"
# Upload ./defaultpackages wheelhouse to dbfs
zip -r defaultpackages.wheelhouse.zip defaultpackages

echo "Packages Zipped."

ls -la

#az storage blob upload --container-name "$3" --file "defaultpackages.wheelhouse.zip" --name "defaultpackages.wheelhouse.zip" --account-name "$2" --auth-mode "login" --subscription "$ARM_SUBSCRIPTION_ID"

echo "defaultpackes.wheelhouse.zip Uploaded."

#rm -rf defaultpackages
#rm -rf defaultpackages.wheelhouse.zip
