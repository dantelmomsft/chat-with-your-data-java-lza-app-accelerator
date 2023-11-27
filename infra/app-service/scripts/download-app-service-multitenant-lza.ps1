param (
    [string]$branch = "",
    [string]$tag = ""
)

if (-not (Test-Path './bicep/lza-libs/appservice-landing-zone-accelerator')) {
    Set-Location -Path './bicep/lza-libs'
    
    if (-not [string]::IsNullOrEmpty($tag)) {
        Write-Host "Downloading App Service Multitenant Secure Scenario from tag: https://github.com/Azure/appservice-landing-zone-accelerator/archive/refs/tags/v$tag.tar.gz"
        Invoke-WebRequest -Uri "https://github.com/Azure/appservice-landing-zone-accelerator/archive/refs/tags/v$tag.tar.gz" -OutFile 'appservice-landing-zone-accelerator.tar.gz'
        # Extract only the required folders
        tar -xf appservice-landing-zone-accelerator.tar.gz 'appservice-landing-zone-accelerator*/scenarios/secure-baseline-multitenant/bicep'
        tar -xf appservice-landing-zone-accelerator.tar.gz 'appservice-landing-zone-accelerator*/scenarios/shared/bicep'
    }
    
    if (-not [string]::IsNullOrEmpty($branch)) {
        Write-Host "Downloading App Service Multitenant Secure Scenario from branch: https://api.github.com/repos/Azure/appservice-landing-zone-accelerator/tarball/$branch"
        Invoke-WebRequest -Uri "https://api.github.com/repos/Azure/appservice-landing-zone-accelerator/tarball/$branch" -OutFile 'appservice-landing-zone-accelerator.tar.gz'
        # Extract only the required folders
        tar -xf appservice-landing-zone-accelerator.tar.gz 'Azure-appservice-landing-zone-accelerator*/scenarios/secure-baseline-multitenant/bicep'
        tar -xf appservice-landing-zone-accelerator.tar.gz 'Azure-appservice-landing-zone-accelerator*/scenarios/shared/bicep'
    }
    
    # Get the directory with the prefix
    $dir = Get-ChildItem -Directory | Where-Object { $_.Name -like '*appservice-landing-zone-accelerator-*' }
    
    # Check if directory exists
    if ($dir) {
        # Rename the directory
        Rename-Item -Path $dir.FullName -NewName 'appservice-landing-zone-accelerator'
    }
    else {
        Write-Host "No directory found with prefix appservice-landing-zone-accelerator-"
    }
    
    # Remove the downloaded file
    Remove-Item -Path 'appservice-landing-zone-accelerator.tar.gz'
    
    Set-Location -Path '../..'
}
else {
    Write-Host "App Service Multitenant Secure Scenario already downloaded"
}

Write-Host "App Service LZA download completed"