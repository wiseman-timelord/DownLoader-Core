# Script "manager.ps1"

Add-Type -AssemblyName System.Web

# Function to extract filename
function ExtractFileName {
    param (
        $url
    )
    Write-Host ""
    Write-Host "Extracting FileName from URL..."
    try {
        $uri = [System.Uri]::new($url)
        $queryParameters = [System.Web.HttpUtility]::ParseQueryString($uri.Query)

        Write-Host "Trying local path method..."
        $filename = [System.IO.Path]::GetFileName($uri.LocalPath)
        if ($filename -ne "") {
            Write-Host "FileName is $filename"
            Write-Host ""
            return [System.Net.WebUtility]::UrlDecode($filename)
        }
        Write-Host "Failed."
        Write-Host "Trying content disposition method..."
        if ($queryParameters["response-content-disposition"]) {
            $contentDisposition = $queryParameters["response-content-disposition"]
            $params = [System.Net.Mime.ContentDisposition]::new($contentDisposition)
            if ($params.FileNameStar) {
                $filename = $params.FileNameStar.Split("''")[-1]
                Write-Host "FileName is $filename"
                Write-Host ""
                return [System.Net.WebUtility]::UrlDecode($filename)
            }
            elseif ($params.FileName) {
                Write-Host "Success - $filename"
                Write-Host ""
                return [System.Net.WebUtility]::UrlDecode($params.FileName)
            }
        }
        Write-Host "Failed."
        Write-Host "Trying query parameter filename method..."
        if ($queryParameters["filename"]) {
            Write-Host "FileName is $filename"
            Write-Host ""
            return [System.Net.WebUtility]::UrlDecode($queryParameters["filename"])
        }
        Write-Host "Failed."
        Write-Host "Trying fragment method..."
        if ($uri.Fragment -match 'filename\*?=(.*)') {
            $filename = $matches[1].Split("''")[-1]
            Write-Host "FileName is $filename"
            Write-Host ""
            return [System.Net.WebUtility]::UrlDecode($filename)
        }
        Write-Host "Failed."
        Write-Host "Trying extension matching method..."
        $extensions = ".zip, .7z, .bin, .iso, .tar, .rar, .deb, .rpm, .mp4, .mpg, .mpeg, .ace, .bz2, .cab, .dmg, .gz, .lha, .paq, .pea, .udf, .wim, .zst, .jar, .xz, .tgz"
        $regexPattern = [regex]::Escape($extensions).Replace(",", "|").Replace(" ", "")
        if ($url -match $regexPattern) {
            $filename = $url.Substring($url.LastIndexOf("/") + 1)
            Write-Host "FileName is $filename"
            Write-Host ""
            return [System.Net.WebUtility]::UrlDecode($filename)
        }
        Write-Host "Failed."
        Write-Host "Trying fallback method..."
        $filename = $uri.Segments[-1]
        if ($filename -ne "") {
            Write-Host "FileName is $filename"
            Write-Host ""
            return [System.Net.WebUtility]::UrlDecode($filename)
        }
        Write-Host "Unable to extract filename."
        return $null
    }
    catch {
        Write-Host "Error extracting filename: $_"
        return $null
    }
}

function Update-DownloadProgress {
    param (
        [long]$BytesTransferred,
        [long]$TotalBytes,
        [datetime]$StartTime,
        [string]$FileName
    )
    
    $elapsedTime = (Get-Date) - $StartTime
    $speedBps = $BytesTransferred / $elapsedTime.TotalSeconds
    $remainingBytes = $TotalBytes - $BytesTransferred
    $eta = New-TimeSpan -Seconds ($remainingBytes / $speedBps)
    
    $progressPercentage = ($BytesTransferred / $TotalBytes) * 100
    $speedMbps = $speedBps / 1MB
    $downloadedMB = $BytesTransferred / 1MB
    $totalMB = $TotalBytes / 1MB
    
    $status = @(
        "{0:N2}%" -f $progressPercentage,
        "{0:N2} MB / {1:N2} MB" -f $downloadedMB, $totalMB,
        "Speed: {0:N2} MB/s" -f $speedMbps,
        "ETA: {0:hh\:mm\:ss}" -f $eta
    ) -join " | "
    
    Write-Progress -Activity "Downloading $FileName" -Status $status -PercentComplete $progressPercentage
}

# Function to download file
function Download-File {
    param (
        [string]$RemoteUrl,
        [string]$OutPath,
        [hashtable]$Config,
        [string]$Filename,
        [long]$StartPosition = 0
    )
    $DestinationPath = Join-Path $OutPath $Filename
    $retries = $Config['Retries']
    $Suppress = $Config['Suppress']
    $success = $false

    while ($retries -gt 0 -and -not $success) {
        $success = InvokeWebRequestMethod -RemoteUrl $RemoteUrl -DestinationPath $DestinationPath -StartPosition $StartPosition -ChunkSize $Config['Chunk'] -Config $Config -Filename $Filename -Suppress $Suppress
        if (-not $success) {
            $retries--
            Write-Host "Download failed. Retrying... ($retries attempts left)"
        }
    }

    if ($success) {
        Write-Host "Download completed successfully."
    } else {
        Write-Host "Download failed after all retries."
    }
}

# Function to download file using WebRequest
function InvokeWebRequestMethod {
    param (
        $RemoteUrl,
        $DestinationPath,
        $StartPosition,
        $ChunkSize,
        $Config,
        $Filename,
        $Suppress
    )
    try {
        $headers = @{}
        if ($StartPosition -gt 0) {
            $headers["Range"] = "bytes=$StartPosition-"
        }
        $ProgressPreference = if ($Suppress -eq 'True') { 'SilentlyContinue' } else { 'Continue' }
        
        $response = Invoke-WebRequest -Uri $RemoteUrl -Method Get -Headers $headers -UseBasicParsing -OutFile $DestinationPath -Resume

        $downloadSuccess = $true
    } catch {
        Write-Host "An error occurred during download: $_"
        $downloadSuccess = $false
    }
    return $downloadSuccess
}


