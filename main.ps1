# Script "main.ps1"

# Import required modules
. .\interface.ps1
. .\manager.ps1

# Configuration file path
$configFile = "config.psd1"

# Define the Downloads directory
$DownloadsPath = "Downloads"

# function to organize download
function Prompt-ForDownload {
    $config = Load-Config
    if ($null -eq $config) {
        Write-Host "Configuration is null! Please check the configuration file."
        return
    }
    Clean-Config -Config $config # Clean up the configuration based on existing files
    $temporaryUrl = $null
    while ($true) {
        try {
            Display-MainMenu $config $temporaryUrl
            $choice = Read-Host
            switch ($choice.ToLower()) {
                's' { Setup-Menu; continue }
                'r' { Clean-Config -Config $config; continue } # Call Clean-Config to refresh
                'q' { Write-Host "Quitting..."; return }
                default {
                    if ($choice -match '^\d$' -and [int]$choice -ge 0 -and [int]$choice -le 9) {
                        if ([int]$choice -eq 0) {
                            $url = Read-Host "`nEnter the URL to download (or 'b' to go back)"
                            if ($url.ToLower() -eq "b") {
                                continue
                            }
                            $temporaryUrl = $url # Store the temporary URL
                            $filename = ExtractFileName -url $url # Extract filename
                            Update-Config -Config $config -Filename $filename -Url $url
                            $startPosition = 0
                        }
                        else {
                            $urlKey = "url_$choice"
                            $url = $config.$urlKey
                            $filename = ExtractFileName -url $url
                            $filePath = Join-Path $DownloadsPath $filename
                            if (Test-Path $filePath) {
                                $fileSize = (Get-Item $filePath).Length / 1MB
                                if ($fileSize -gt 10) {
                                    Write-Host "Download already completed."
                                    continue
                                } else {
                                    $userChoice = Read-Host "`nFile is incomplete. Press c for Continue Download, r for Restart Download, b for Back to Main Menu :"
                                    switch ($userChoice.ToLower()) {
                                        'c' { $startPosition = (Get-Item $filePath).Length }
                                        'r' { Remove-Item $filePath -Force; $startPosition = 0 }
                                        'b' { continue }
                                        default { Write-Host "Invalid choice. Returning to main menu."; continue }
                                    }
                                }
                            } else {
                                $startPosition = 0
                            }
                        }
                        if (Validate-Input $url) {
                            if (-Not $filename) {
                                Write-Host "Unable to extract filename from the URL. Please try again."
                                continue
                            }
                            $temporaryUrl = $null # Clear the temporary URL
                            Download-File -RemoteUrl $url -OutPath $DownloadsPath -Config $config -Filename $filename -StartPosition $startPosition
                            Write-Host "Download complete for file: $filename"
                            continue
                        }
                        Write-Host "Invalid choice. Please try again."
                    }
                }
            }
        } catch {
            Write-Host "An error occurred: $_" -ForegroundColor Red
            Write-Host "Press any key to return to the main menu..." -ForegroundColor Yellow
            $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
    }
}

# function to parse URL
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

# Maintain, keys and downloads
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
                    Write-Host "File $filename is, in .\Downloads and less than 1MB."
                    Write-Host "Removing, files and entries, for $filename..."
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

    # Check if the entry already exists
    1..9 | ForEach-Object {
        if ($config["filename_$_"] -eq $filename -and $config["url_$_"] -eq $url) {
            Write-Host "Entry for $filename already exists at position $_."
            return $true
        }
    }

    # Shift existing entries down by one position
    9..2 | ForEach-Object {
        $config["filename_$_"] = $config["filename_$($_ - 1)"]
        $config["url_$_"] = $config["url_$($_ - 1)"]
    }

    # Place the new URL and filename at the first position
    $config["filename_1"] = $filename
    $config["url_1"] = $url
    Save-Config -Config $config
    return $true
}

# Load configuration
function Load-Config {
    if (Test-Path $configFile) {
        return Import-PowerShellDataFile -Path $configFile
    } else {
        Write-Host "Configuration file not found! Using default configuration."
        return @{
            retries = 3
        }
    }
}

# Save configuration
function Save-Config {
    param (
        [hashtable]$config
    )
    $content = "@{`n"
    $keysOrder = @('Retries', 'Chunk', 'Method', 'Automatic', 'Suppress', 'FileName_1', 'Url_1', 'FileName_2', 'Url_2', 'FileName_3', 'Url_3', 'FileName_4', 'Url_4', 'FileName_5', 'Url_5', 'FileName_6', 'Url_6', 'FileName_7', 'Url_7', 'FileName_8', 'Url_8', 'FileName_9', 'Url_9')
    $keysOrder | ForEach-Object {
        if ($_ -eq 'retries') {
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
Prompt-ForDownload