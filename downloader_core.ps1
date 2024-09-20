# Script "main.ps1"

# Import required modules
. .\scripts\interface.ps1
. .\scripts\manager.ps1

# Configuration file path
$configFile = ".\data\persistence.psd1"
$DownloadsPath = "Downloads"

function Start-DownLordPs {
    if (-Not (Test-Path $DownloadsPath)) {
        New-Item -Path $DownloadsPath -ItemType Directory
    }
    $config = Load-Config
    if ($null -eq $config) {
        Write-Host "Configuration is null! Please check the configuration file."
        return
    }
    Show-MainMenu -Config $config
}

# Function to parse URL
function Validate-Input {
    param (
        $url
    )
    try {
        $uri = New-Object System.Uri($url)
        if ($uri.Scheme -eq "http" -or $uri.Scheme -eq "https" -or $uri.Scheme -eq "ftp") {
            return $true
        } else {
            Write-Host "URL must use 'http', 'https', or 'ftp' scheme. Please try again."
            return $false
        }
    }
    catch {
        Write-Host "Invalid URL format. Please try again."
        return $false
    }
}

# Clean configuration
function Clean-Config {
    param (
        [hashtable]$config
    )
    1..9 | ForEach-Object {
        $filenameKey = "filename_$_"
        $urlKey = "url_$_"
        $filename = $config[$filenameKey]
        $filePath = Join-Path $DownloadsPath $filename
        if ($filename -ne $null -and $filename -ne "") {
            if (-Not (Test-Path $filePath)) {
                Write-Host "File $filename not found in Downloads directory. Removing from configuration."
                $config[$filenameKey] = $null
                $config[$urlKey] = $null
            } else {
                $fileSize = (Get-Item $filePath).Length / 1MB
                if ($fileSize -lt 1) {
                    Write-Host "File $filename is in .\Downloads and less than 1MB."
                    Write-Host "Removing file and entries for $filename..."
                    Remove-Item $filePath -Force -Confirm:$false
                    $config[$filenameKey] = $null
                    $config[$urlKey] = $null
                }
            }
        }
    }
    Save-Config -Config $config
}

# Update configuration
function Update-Config {
    param (
        [hashtable]$config,
        [string]$filename,
        [string]$url
    )
    1..9 | ForEach-Object {
        if ($config["filename_$_"] -eq $filename -and $config["url_$_"] -eq $url) {
            Write-Host "Entry for $filename already exists at position $_."
            return $true
        }
    }
    9..2 | ForEach-Object {
        $config["filename_$_"] = $config["filename_$($_ - 1)"]
        $config["url_$_"] = $config["url_$($_ - 1)"]
    }
    $config["filename_1"] = $filename
    $config["url_1"] = $url
    Save-Config -Config $config
    return $true
}

# Load configuration
function Load-Config {
    if (Test-Path $configFile) {
        $config = Import-PowerShellDataFile -Path $configFile
        return $config
    } else {
        Write-Host "Configuration file not found! Using default configuration."
        return @{
            retries = 3
            Chunk = 4096
            Suppress = 'False'
        }
    }
}

# Save configuration
function Save-Config {
    param (
        [hashtable]$config
    )
    $configFile = ".\data\config.psd1"
    $content = "@{`n"
    $keysOrder = @('Retries', 'Chunk', 'Suppress', 'FileName_1', 'Url_1', 'FileName_2', 'Url_2', 'FileName_3', 'Url_3', 'FileName_4', 'Url_4', 'FileName_5', 'Url_5', 'FileName_6', 'Url_6', 'FileName_7', 'Url_7', 'FileName_8', 'Url_8', 'FileName_9', 'Url_9')
    $keysOrder | ForEach-Object {
        if ($_ -eq 'Retries' -or $_ -eq 'Chunk') {
            $content += "    $_ = $($config[$_])`n"
        } else {
            $content += "    $_ = '$($config[$_])'`n"
        }
    }
    $content += "}"
    Set-Content -Path $configFile -Value $content
}

# Main entry point
if (-Not (Test-Path $DownloadsPath)) {
    New-Item -Path $DownloadsPath -ItemType Directory
}
Start-DownLordPs