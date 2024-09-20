# Script "interface.ps1"

# Display the main menu
function Show-MainMenu {
    param (
        [hashtable]$Config
    )
    $temporaryUrl = $null
    while ($true) {
        Clear-Host
        $header = @"
$('=' * 120)
    Downloader-Core - Main Menu
$('=' * 120)
"@
        Write-Host $header
        Write-Host "`nRecent Downloads:`n"
        if ($null -ne $temporaryUrl) {
            Write-Host "    0. $temporaryUrl"
        }
        1..9 | ForEach-Object {
            $index = $_
            if ($null -ne $temporaryUrl) {
                $index--
            }
            $key = "filename_$index"
            $filename = $Config[$key]
            if ($filename -ne $null -and $filename -ne "") {
                Write-Host "    $_. $filename"
            } else {
                Write-Host "    $_. Empty"
            }
        }

        $footer = @"

$('=' * 120)
Selection; New URL = 0, Continue = 1-9, Refresh = R, Setup = S, Quit = Q:
"@
        $choice = Read-Host $footer

        switch ($choice.ToLower()) {
            's' { Show-SetupMenu -Config $Config; continue }
            'r' { Clean-Config -Config $Config; continue }
            'q' { Write-Host "Quitting..."; return }
            default {
                if ($choice -match '^\d$' -and [int]$choice -ge 0 -and [int]$choice -le 9) {
                    if ([int]$choice -eq 0) {
                        $url = Read-Host "`nEnter the URL to download (or 'b' to go back)"
                        if ($url.ToLower() -eq "b") {
                            continue
                        }
                        $temporaryUrl = $url
                        $filename = ExtractFileName -url $url
                        Update-Config -Config $Config -Filename $filename -Url $url
                        $startPosition = 0
                    }
                    else {
                        $urlKey = "url_$choice"
                        $url = $Config.$urlKey
                        $filename = ExtractFileName -url $url
                        $filePath = Join-Path $DownloadsPath $filename
                        if (Test-Path $filePath) {
                            $fileSize = (Get-Item $filePath).Length / 1MB
                            if ($fileSize -gt 10) {
                                Write-Host "Download already completed."
                                continue
                            } else {
                                $userChoice = Read-Host "`nFile is incomplete. Press C for Continue Download, R for Restart Download, B for Back to Main Menu"
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
                        $temporaryUrl = $null
                        Download-File -RemoteUrl $url -OutPath $DownloadsPath -Config $Config -Filename $filename -StartPosition $startPosition
                        Write-Host "Download complete for file: $filename"
                        continue
                    }
                    Write-Host "Invalid choice. Please try again."
                }
            }
        }
    }
}

# Display the setup menu
function Show-SetupMenu {
    param (
        [hashtable]$Config
    )
    while ($true) {
        Clear-Host
        $header = @"
$('=' * 120)
    Downlord-Core - Setup Menu
$('=' * 120)
"@
        Write-Host $header

        $connectionSpeed = switch ($Config['chunk']) {
            1024 { "1MBit/s" }
            4096 { "5MB/s" }
            8192 { "10MBit/s" }
            20480 { "25MBit/s" }
            40960 { "50MBit/s" }
        }
        
        Write-Host "`n    1. Internet Speed ($connectionSpeed)"
        Write-Host "    2. Maximum Retries ($($Config['retries']) Times)"
        Write-Host "    3. Suppress Output ($($Config['Suppress']))"

        $footer = @"

$('=' * 120)
Selection; Setup Sub-Menus = 1-3, Back = B:
"@
        $choice = Read-Host $footer

        switch ($choice) {
            '1' {
                $Config['chunk'] = switch ($Config['chunk']) {
                    1024 { 4096 }
                    4096 { 8192 }
                    8192 { 20480 }
                    20480 { 40960 }
                    40960 { 1024 }
                }
                Save-Config $Config
                Write-Host "Connection speed updated successfully."
            }
            '2' {
                $retries = Read-Host "Maximum Retries = number, Back = b "
                if ($retries -ne 'b') {
                    $Config["retries"] = [int]$retries
                    Save-Config $Config
                    Write-Host "Maximum retries updated successfully."
                }
            }
            '3' {
                $Config['Suppress'] = if ($Config['Suppress'] -eq 'True') { 'False' } else { 'True' }
                Save-Config $Config
                Write-Host "Suppress Output updated successfully."
            }
            'b' { return }
            default { Write-Host "Invalid choice. Please try again." }
        }
        Start-Sleep -Seconds 1
    }
}
