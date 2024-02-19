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



if [ ! -d './bicep/lza-libs/aca-landing-zone-accelerator' ]; then
    cd bicep/lza-libs
    if [ ! -z $tag ]; then
        echo "Downloading ACA Internal Scenario from tag: https://github.com/Azure/aca-landing-zone-accelerator/archive/refs/tags/v$tag.tar.gz"
        curl -LJ https://github.com/Azure/aca-landing-zone-accelerator/archive/refs/tags/v$tag.tar.gz -o aca-landing-zone-accelerator.tar.gz
        # Extract only the required folders
        tar -xvzf aca-landing-zone-accelerator.tar.gz --wildcards 'aca-landing-zone-accelerator*/scenarios/aca-internal/bicep'
        tar -xvzf aca-landing-zone-accelerator.tar.gz --wildcards 'aca-landing-zone-accelerator*/scenarios/shared/bicep' 
    fi
    if [ ! -z $branch ]; then
        echo "Downloading ACA Internal Scenario from branch: https://api.github.com/repos/Azure/aca-landing-zone-accelerator/tarball/$branch "
        curl -LJ https://api.github.com/repos/Azure/aca-landing-zone-accelerator/tarball/$branch -o aca-landing-zone-accelerator.tar.gz
        # Extract only the required folders
         tar -xvzf aca-landing-zone-accelerator.tar.gz --wildcards 'Azure-aca-landing-zone-accelerator*/scenarios/aca-internal/bicep'
         tar -xvzf aca-landing-zone-accelerator.tar.gz --wildcards 'Azure-aca-landing-zone-accelerator*/scenarios/shared/bicep' 
    fi

    
    
    # Get the directory with the prefix
    dir=$(ls -d *aca-landing-zone-accelerator-* 2>/dev/null)

    # Check if directory exists
    if [ -n "$dir" ]; then
        # Rename the directory
        mv "$dir" "aca-landing-zone-accelerator"
    else
        echo "No directory found with prefix aca-landing-zone-accelerator-"
    fi
    
    # Remove the downloaded file
    rm aca-landing-zone-accelerator.tar.gz   
    cd ../..
else
    echo "ACA Internal Secure Scenario already downloaded"
fi

echo "ACA LZA setup completed"