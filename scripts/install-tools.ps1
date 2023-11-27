$basePath = "$env:LOCALAPPDATA\Temp\lza-tools-install"
$logsFolder = "$($basePath)"
if ((Test-Path -Path $logsFolder) -ne $true) {
    mkdir $logsFolder
}

$date = Get-Date -Format "yyyyMMdd-HHmmss"
Start-Transcript ($logsFolder + "install-tools-script" + $date + ".log")

$downloads = @()


##############################################################################################################
## install Java
if ($install_java_tools) {
    $javaInstallPath = "C:\Program Files\Java\jdk-17"

    $downloads += @{
        name            = "Java JDK 17"
        url             = "https://download.oracle.com/java/17/latest/jdk-17_windows-x64_bin.msi"
        path            = "$($basePath)\java\"
        file            = "jdk-17_windows-x64_bin.msi"
        installCmd      = "Start-Process msiexec.exe -Wait -ArgumentList '/i D:\java\jdk-17_windows-x64_bin.msi /qn /quiet'"
        testInstallPath = "$($javaInstallPath)\bin\java.exe"
        postInstallCmd  = "" 
    }

    $env:Path += ";$($javaInstallPath)\bin\"
    [Environment]::SetEnvironmentVariable("JAVA_HOME", "$($javaInstallPath)", "Machine")

    # install maven
    $mavenInstallPath = "C:\Program Files\apache-maven-3.9.5"
    
    $downloads += @{
        name            = "Maven 3.9.5"
        url             = "https://dlcdn.apache.org/maven/maven-3/3.9.5/binaries/apache-maven-3.9.5-bin.zip"
        path            = "$($basePath)\maven\"
        file            = "apache-maven-3.9.5-bin.zip"
        installCmd      = "Add-Type -AssemblyName System.IO.Compression.FileSystem; " +
        "[System.IO.Compression.ZipFile]::ExtractToDirectory(`"$($basePath)\maven\apache-maven-3.9.5-bin.zip`", `"C:\Program Files\`");"
        testInstallPath = "$($mavenInstallPath)\bin\mvn.cmd"
        postInstallCmd  = "" 
    }

    

    $env:Path += ";$($mavenInstallPath)\bin\"
}


##############################################################################################################

$downloadJob = {
    param($url, $filePath)

    Invoke-WebRequest -Uri $url -OutFile $filePath
    Write-Host "Download from $($url) completed!"
}

$jobs = @()
foreach ($download in $downloads) {

    $filePath = $download.path + $download.file

    if ((Test-Path -Path $download.path) -ne $true) {
        mkdir $download.path | Out-Null
    }

    Write-Host "Checking if file is already present: $filePath"
    if ((Test-Path -Path $filePath) -eq $true) {
        Write-Host "File already exists, skipping download."
        continue
    }

    Write-Host "File not present, downloading from: $($download.url)"
    $job = Start-Job -Name $download.name -ScriptBlock $downloadJob -ArgumentList $download.url, $filePath 
    $jobs += $job
}

# Wait for all downloads to complete
if ($jobs.Count -gt 0) {
    while ($jobs | Where-Object { $_.State -eq 'Running' }) {
        Start-Sleep -Seconds 5
        Write-Host "Installers are still downloading:"
        $jobs | Format-Table -Property Name, State
    }

    # Get the output from each job and add it to an array
    $output = $jobs | Receive-Job | Sort-Object

    # Display the output
    Write-Host $output
}

foreach ($download in $downloads) {
    $filePath = $download.path + $download.file

    Write-Host "Checking if $($download.name) is already installed in $($download.testInstallPath)."
    if ((Test-Path -Path $download.testInstallPath) -eq $true) {
        Write-Host "$($download.name) is already installed, skipping install."
        continue
    }

    Write-Host "Running install command: $($download.installCmd)"
    Invoke-Expression $download.installCmd
}

foreach ($download in $downloads) {
    if (-not [string]::IsNullOrEmpty($download.postInstallCmd)) {
        Write-Host "Running post install command: $($download.postInstallCmd)"
        Invoke-Expression $download.postInstallCmd
        Write-Host "Post install command completed: $($download.postInstallCmd)"
    }
}

Write-Host "All done!"