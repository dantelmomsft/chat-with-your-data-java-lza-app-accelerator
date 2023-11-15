#!/bin/sh

version=$1



if [ -z "$version" ]; then
    echo "Version parameter is empty"
    exit 1
fi

if [ ! -d appservice-landing-zone-accelerator-$version ]; then
    echo "Downloading App Service Multitenant Secure Scenario v$version"
    cd infra
    curl -LJ https://github.com/Azure/appservice-landing-zone-accelerator/archive/refs/tags/v$version.tar.gz -o appservice-landing-zone-accelerator.tar.gz
    tar -xvzf appservice-landing-zone-accelerator.tar.gz --wildcards 'appservice-landing-zone-accelerator*/scenarios/secure-baseline-multitenant/bicep'
    tar -xvzf appservice-landing-zone-accelerator.tar.gz --wildcards 'appservice-landing-zone-accelerator*/scenarios/shared/bicep'
    mv appservice-landing-zone-accelerator-$version appservice-landing-zone-accelerator
    rm appservice-landing-zone-accelerator.tar.gz
    cd ..
else
    echo "App Service Multitenant Secure Scenario v$version already downloaded"
fi

