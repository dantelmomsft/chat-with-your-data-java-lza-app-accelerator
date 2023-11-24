param (
    [string]$branch = "",
    [string]$tag = ""
)

if (-not (Test-Path './app/src/azure-search-openai-demo-java')) {
    Set-Location app/src

    if (-not [string]::IsNullOrEmpty($tag)) {
        Write-Host "Downloading Chat With Your Data - Java source code from tag: https://github.com/Azure-Samples/azure-search-openai-demo-java/archive/refs/tags/v$tag.tar.gz"
        Invoke-WebRequest -Uri "https://github.com/Azure-Samples/azure-search-openai-demo-java/archive/refs/tags/v$tag.tar.gz" -OutFile azure-search-openai-demo-java.tar.gz
        # Extract only the required folders
        tar -xf azure-search-openai-demo-java.tar.gz 'azure-search-openai-demo-java*/app'
        tar -xf azure-search-openai-demo-java.tar.gz 'azure-search-openai-demo-java*/data'
        tar -xf azure-search-openai-demo-java.tar.gz 'azure-search-openai-demo-java*/scripts'
    }

    if (-not [string]::IsNullOrEmpty($branch)) {
        Write-Host "Downloading Chat With Your Data - Java source code from tag: https://github.com/Azure-Samples/azure-search-openai-demo-java/tarball/$branch"
        Invoke-WebRequest -Uri "https://github.com/Azure-Samples/azure-search-openai-demo-java/tarball/$branch" -OutFile azure-search-openai-demo-java.tar.gz
        # Extract only the required folders
        tar -xf azure-search-openai-demo-java.tar.gz 'Azure-Samples-azure-search-openai-demo-java*/app'
        tar -xf azure-search-openai-demo-java.tar.gz 'Azure-Samples-azure-search-openai-demo-java*/data'
        tar -xf azure-search-openai-demo-java.tar.gz 'Azure-Samples-azure-search-openai-demo-java*/scripts'
    }

    # Get the directory with the prefix
    $dir = Get-ChildItem -Directory | Where-Object { $_.Name -like "*azure-search-openai-demo-java-*" }

    # Check if directory exists
    if ($dir) {
        # Rename the directory
        Rename-Item -Path $dir.FullName -NewName "azure-search-openai-demo-java"
    }
    else {
        Write-Host "No directory found with prefix azure-search-openai-demo-java-"
    }

    # Remove the downloaded file
    Remove-Item -Path azure-search-openai-demo-java.tar.gz
    Set-Location ../..
}
else {
    Write-Host "Chat With Your Data - Java source code already downloaded"
}
