# Script "interface.ps1"

# Display the main menu
function Display-MainMenu {
    param (
        $config,
        $temporaryUrl,
        $menuMode = 'normal' # Default mode is 'normal'
    )
	Clear-Host
	if ($null -eq $config) {
        Write-Host "Config is null!"
        return
    }
	Write-Host "`n`n                           Main Menu"
    Write-Host "                           -=-=-=-=-`n"
    Write-Host "Recent Downloads:`n"
    if ($null -ne $temporaryUrl) {
        Write-Host "    1. $temporaryUrl"
    }
    1..8 | ForEach-Object { # Change to 8 to avoid going up to 10
        $index = $_
        if ($null -ne $temporaryUrl) {
            $index++
        }
        $key = "filename_$index"
        $filename = $config[$key]
        if ($filename -ne $null -and $filename -ne "") {
            Write-Host "    $index. $filename"
        } else {
            Write-Host "    $index. Empty"
        }
    }

    switch ($menuMode) {
        'normal' {
            if ($null -eq $temporaryUrl) {
                Write-Host -NoNewline "`n`nNew URL = 0, Continue = 1-9, Refresh = r, Setup = s, Quit = q :"
            } else {
                Write-Host ""
            }
        }
        'extracting' {
            Write-Host "`nExtracting filename from URL. Please wait..."
        }
        'downloading' {
            Write-Host "`nDownloads are in progress. Please wait..."
        }
        default {
            Write-Host "`nUnknown menu mode."
        }
    }
}

# Display the setup menu
function Setup-Menu {
    while ($true) {
        Clear-Host
        Write-Host "`n                             Setup Menu"
        Write-Host "                             -=-=--=-=-`n"
        Write-Host "                        1. Connection Speed"
        Write-Host "                        2. Method Used"
        Write-Host "                        3. Maximum Retries`n`n"
        $choice = Read-Host "Setup Sub-Menus = 1-3, Back = b "
        switch ($choice) {
            '1' { Connection-SpeedMenu }
            '2' { Method-Menu }
            '3' { Max-RetriesMenu }
            'b' { return }
            default { Write-Host "Invalid choice. Please try again." }
        }
    }
}

# Maximum retries menu
function Max-RetriesMenu {
    $config = Load-Config
    Clear-Host
    Write-Host "`n                           Retries Menu"
    Write-Host "                            -=-=-=-=-=-`n"
    $currentRetries = $config["retries"]
    Write-Host "                    Current Maximum Retries: $currentRetries`n`n"
    $retries = Read-Host "Maximum Retries = number, Back = b "
    if ($retries -ne 'b') {
        $config["retries"] = [int]$retries
        Save-Config $config
        Write-Host "Maximum retries updated successfully."
    }
}

# Connection speed menu
function Connection-SpeedMenu {
    $config = Load-Config
    Clear-Host
    Write-Host "`n                            Connection Menu"
    Write-Host "                            -=-=-=-=-=-=-=-`n"
    Write-Host "                   1. Slow  ~1MBit/s (Chunk  1024KB)"
    Write-Host "                   2. Okay  ~5MBit/s (Chunk  4096KB)"
    Write-Host "                   3. Good ~10MBit/s (Chunk  8192KB)"
    Write-Host "                   4. Fast ~25MBit/s (Chunk 20480KB)"
    Write-Host "                   5. Uber ~50MBit/s (Chunk 40960KB)`n`n"
    $choice = Read-Host "Connection Speed = 1-5, Back = b "
    switch ($choice) {
        '1' { $config["chunk"] = 1024 }
        '2' { $config["chunk"] = 4096 }
        '3' { $config["chunk"] = 8192 }
        '4' { $config["chunk"] = 20480 }
        '5' { $config["chunk"] = 40960 }
        'b' { return }
        default { Write-Host "Invalid choice. Please try again." }
    }
    Save-Config $config
    Write-Host "Connection speed updated successfully."
}

# Method menu
function Method-Menu {
    $config = Load-Config
    while ($true) {
        Clear-Host
        Write-Host "`n                             Method Menu"
        Write-Host "                             -=-=-=-=-=-`n"
        Write-Host "                1. Cmdlet Method Used ($($config['method']))"
        Write-Host "                2. Alternate on Fail ($($config['automatic']))"
        Write-Host "                3. Suppress Cmdlet Output ($($config['Suppress']))`n`n"
        $choice = Read-Host "Toggle Option = 1-3, Back = b"
        switch ($choice) {
            '1' {
                $config['method'] = if ($config['method'] -eq 'WebRequest') { 'WebClient' } else { 'WebRequest' }
                Save-Config $config
                Write-Host "Method toggled successfully."
            }
            '2' {
                $config['automatic'] = if ($config['automatic'] -eq 'True') { 'False' } else { 'True' }
                Save-Config $config
                Write-Host "Alternate on Fail updated successfully."
            }
            '3' {
                $config['Suppress'] = if ($config['Suppress'] -eq 'True') { 'False' } else { 'True' }
                Save-Config $config
                Write-Host "Suppress Cmdlet Output updated successfully."
            }
            'b' { return }
            default { Write-Host "Invalid choice. Please try again." }
        }
    }
}