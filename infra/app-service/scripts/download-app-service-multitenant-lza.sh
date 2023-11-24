#!/bin/sh


#check parameters
    case "$1" in
        --branch*)
            shift
            branch="$1"
            ;;
        --tag*)
            shift
            tag="$1"
            ;;
        *)
            printf "Invalid argument: %s\n" "$1"
            exit 1
            ;;
    esac



if [ ! -d './bicep/lza-libs/appservice-landing-zone-accelerator' ]; then
    cd bicep/lza-libs
    if [ ! -z $tag ]; then
        echo "Downloading App Service Multitenant Secure Scenario from tag: https://github.com/Azure/appservice-landing-zone-accelerator/archive/refs/tags/v$tag.tar.gz"
        curl -LJ https://github.com/Azure/appservice-landing-zone-accelerator/archive/refs/tags/v$tag.tar.gz -o appservice-landing-zone-accelerator.tar.gz
        # Extract only the required folders
        tar -xvzf appservice-landing-zone-accelerator.tar.gz --wildcards 'appservice-landing-zone-accelerator*/scenarios/secure-baseline-multitenant/bicep'
        tar -xvzf appservice-landing-zone-accelerator.tar.gz --wildcards 'appservice-landing-zone-accelerator*/scenarios/shared/bicep' 
    fi
    if [ ! -z $branch ]; then
        echo "Downloading App Service Multitenant Secure Scenario from branch: https://api.github.com/repos/Azure/appservice-landing-zone-accelerator/tarball/$branch "
        curl -LJ https://api.github.com/repos/Azure/appservice-landing-zone-accelerator/tarball/$branch -o appservice-landing-zone-accelerator.tar.gz
        # Extract only the required folders
         tar -xvzf appservice-landing-zone-accelerator.tar.gz --wildcards 'Azure-appservice-landing-zone-accelerator*/scenarios/secure-baseline-multitenant/bicep'
         tar -xvzf appservice-landing-zone-accelerator.tar.gz --wildcards 'Azure-appservice-landing-zone-accelerator*/scenarios/shared/bicep' 
    fi

    
    
    # Get the directory with the prefix
    dir=$(ls -d *appservice-landing-zone-accelerator-* 2>/dev/null)

    # Check if directory exists
    if [ -n "$dir" ]; then
        # Rename the directory
        mv "$dir" "appservice-landing-zone-accelerator"
    else
        echo "No directory found with prefix appservice-landing-zone-accelerator-"
    fi
    
    # Remove the downloaded file
    rm appservice-landing-zone-accelerator.tar.gz   
    cd ../..
else
    echo "App Service Multitenant Secure Scenario already downloaded"
fi

