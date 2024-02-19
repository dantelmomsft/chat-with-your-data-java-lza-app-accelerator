param (
    [string]$branch = "",
    [string]$tag = ""
)

if (-not (Test-Path './bicep/lza-libs/aca-landing-zone-accelerator')) {
    Set-Location -Path './bicep/lza-libs'
    
    if (-not [string]::IsNullOrEmpty($tag)) {
        Write-Host "Downloading ACA Internal Secure Scenario from tag: https://github.com/Azure/aca-landing-zone-accelerator/archive/refs/tags/v$tag.tar.gz"
        Invoke-WebRequest -Uri "https://github.com/Azure/aca-landing-zone-accelerator/archive/refs/tags/v$tag.tar.gz" -OutFile 'aca-landing-zone-accelerator.tar.gz'
        # Extract only the required folders
        tar -xf aca-landing-zone-accelerator.tar.gz 'aca-landing-zone-accelerator*/scenarios/aca-internal/bicep'
        tar -xf aca-landing-zone-accelerator.tar.gz 'aca-landing-zone-accelerator*/scenarios/shared/bicep'
    }
    
    if (-not [string]::IsNullOrEmpty($branch)) {
        Write-Host "Downloading ACA Internal Secure Scenario from branch: https://api.github.com/repos/Azure/aca-landing-zone-accelerator/tarball/$branch"
        Invoke-WebRequest -Uri "https://api.github.com/repos/Azure/aca-landing-zone-accelerator/tarball/$branch" -OutFile 'aca-landing-zone-accelerator.tar.gz'
        # Extract only the required folders
        tar -xf aca-landing-zone-accelerator.tar.gz 'Azure-aca-landing-zone-accelerator*/scenarios/aca-intenal/bicep'
        tar -xf aca-landing-zone-accelerator.tar.gz 'Azure-aca-landing-zone-accelerator*/scenarios/shared/bicep'
    }
    
    # Get the directory with the prefix
    $dir = Get-ChildItem -Directory | Where-Object { $_.Name -like '*aca-landing-zone-accelerator-*' }
    
    # Check if directory exists
    if ($dir) {
        # Rename the directory
        Rename-Item -Path $dir.FullName -NewName 'aca-landing-zone-accelerator'
    }
    else {
        Write-Host "No directory found with prefix aca-landing-zone-accelerator-"
    }
    
    # Remove the downloaded file
    Remove-Item -Path 'aca-landing-zone-accelerator.tar.gz'
    
    Set-Location -Path '../..'
}
else {
    Write-Host "ACA Internal Secure Scenario already downloaded"
}

Write-Host "ACA LZA setup completed"