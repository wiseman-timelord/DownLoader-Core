# Script "interface.ps1"

# Display the main menu
function Display-MainMenu {
    param (
        $config,
        $temporaryUrl,
        $menuMode = 'normal'
    )
	if ($null -eq $config) {
        Write-Host "Config is null!"
        return
    }
    Clear-Host
    Write-Host "`n    ________                      .____                    .___"
    Write-Host "    \______ \   ______  _  ______ |    |    ___________  __| _/"
    Write-Host "    |     |  \ /  _ \ \/ \/ /    \|    |   /  _ \_  __ \/ __ | "
    Write-Host "    |     \   (  <_> )     /   |  \    |__(  <_> )  | \/ /_/ | "
    Write-Host "    /_______  /\____/ \/\_/|___|  /_______ \____/|__|  \____ | "
    Write-Host "            \/                  \/        \/                \/ "	
	Write-Host "`n                           Main Menu"
    Write-Host "                           -=-=-=-=-`n"
    Write-Host "Recent Downloads:`n"
    if ($null -ne $temporaryUrl) {
        Write-Host "    1. $temporaryUrl"
    }
    1..8 | ForEach-Object {
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
    $config = Load-Config
    while ($true) {
        Clear-Host
        Write-Host "`n    ________                      .____                    .___"
        Write-Host "    \______ \   ______  _  ______ |    |    ___________  __| _/"
        Write-Host "    |     |  \ /  _ \ \/ \/ /    \|    |   /  _ \_  __ \/ __ | "
        Write-Host "    |     \   (  <_> )     /   |  \    |__(  <_> )  | \/ /_/ | "
        Write-Host "    /_______  /\____/ \/\_/|___|  /_______ \____/|__|  \____ | "
        Write-Host "            \/                  \/        \/                \/ "	
        Write-Host "`n                             Setup Menu"
        Write-Host "                             -=-=--=-=-`n"
        
        $connectionSpeed = switch ($config['chunk']) {
            1024 { "1MBit/s" }
            4096 { "5MB/s" }
            8192 { "10MBit/s" }
            20480 { "25MBit/s" }
            40960 { "50MBit/s" }
        }
        
        $methodDisplayName = switch ($config['method']) {
            'WebRequest' { 'WebRequests' }
            'WebClient' { 'WebClient' }
            'BITS_Service' { 'BITS_Service' }
        }

        Write-Host "                    1. Internet Speed ($connectionSpeed)"
        Write-Host "                    2. Maximum Retries ($($config['retries']) Times)"
        Write-Host "                    3. Method Used ($methodDisplayName)"
        Write-Host "                    4. Suppress Output ($($config['Suppress']))`n`n"
        
        $choice = Read-Host "Setup Sub-Menus = 1-4, Back = b "
        switch ($choice) {
            '1' {
                $config['chunk'] = switch ($config['chunk']) {
                    1024 { 4096 }
                    4096 { 8192 }
                    8192 { 20480 }
                    20480 { 40960 }
                    40960 { 1024 }
                }
                Save-Config $config
                Write-Host "Connection speed updated successfully."
            }
            '2' {
                $retries = Read-Host "Maximum Retries = number, Back = b "
                if ($retries -ne 'b') {
                    $config["retries"] = [int]$retries
                    Save-Config $config
                    Write-Host "Maximum retries updated successfully."
                }
            }
            '3' {
                $config['method'] = switch ($config['method']) {
                    'WebRequest' { 'WebClient' }
                    'WebClient' { 'BITS_Service' }
                    'BITS_Service' { 'WebRequest' }
                }
                Save-Config $config
                Write-Host "Method toggled successfully."
            }
            '4' {
                $config['Suppress'] = if ($config['Suppress'] -eq 'True') { 'False' } else { 'True' }
                Save-Config $config
                Write-Host "Suppress Output updated successfully."
            }
            'b' { return }
            default { Write-Host "Invalid choice. Please try again." }
        }
    }
}
