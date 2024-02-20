## Install Azure CLI

$ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi

## Install Package Manager Chocolatey 

Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) 

## Install Docker Desktop 
## This is not working on the current Windows Datacenter 2016 VM created by ACA LZA.

# Using PowerShell 
Invoke-WebRequest -Uri https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe -OutFile "Docker Desktop Installer.exe"

Start-Process 'Docker Desktop Installer.exe' -Wait install

## Install Java and Maven

choco install microsoft-openjdk17 -y
choco install maven 3.9.6 -y

## Install Azure Developer CLI
choco install azd -y