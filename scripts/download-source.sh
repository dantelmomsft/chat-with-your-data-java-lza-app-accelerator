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



if [ ! -d './src/azure-search-openai-demo-java' ]; then
    cd src
    if [ ! -z $tag ]; then
        echo "Downloading Chat With Your Data - Java source code from tag: https://github.com/Azure-Samples/azure-search-openai-demo-java/archive/refs/tags/v$tag.tar.gz"
        curl -LJ https://github.com/Azure-Samples/azure-search-openai-demo-java/archive/refs/tags/v$tag.tar.gz -o azure-search-openai-demo-java.tar.gz
        # Extract only the required folders
        tar -xvzf azure-search-openai-demo-java.tar.gz --wildcards 'azure-search-openai-demo-java*/app'
        tar -xvzf azure-search-openai-demo-java.tar.gz --wildcards 'azure-search-openai-demo-java*/data'
        tar -xvzf azure-search-openai-demo-java.tar.gz --wildcards 'azure-search-openai-demo-java*/scripts'
    fi
    if [ ! -z $branch ]; then
        echo "Downloading Chat With Your Data - Java source code from tag: https://github.com/Azure-Samples/azure-search-openai-demo-java/tarball/$branch "
        curl -LJ https://github.com/Azure-Samples/azure-search-openai-demo-java/tarball/$branch -o azure-search-openai-demo-java.tar.gz
        # Extract only the required folders
        tar -xvzf azure-search-openai-demo-java.tar.gz --wildcards 'Azure-Samples-azure-search-openai-demo-java*/app'
        tar -xvzf azure-search-openai-demo-java.tar.gz --wildcards 'Azure-Samples-azure-search-openai-demo-java*/data'
        tar -xvzf azure-search-openai-demo-java.tar.gz --wildcards 'Azure-Samples-azure-search-openai-demo-java*/scripts'
    fi

    
    
    # Get the directory with the prefix
    dir=$(ls -d *azure-search-openai-demo-java-* 2>/dev/null)

    # Check if directory exists
    if [ -n "$dir" ]; then
        # Rename the directory
        mv "$dir" "azure-search-openai-demo-java"
    else
        echo "No directory found with prefix appservice-landing-zone-accelerator-"
    fi
    
    # Remove the downloaded file
    rm azure-search-openai-demo-java.tar.gz 
    cd ..
else
    echo "Chat With Your Data - Java source code already downloaded"
fi

