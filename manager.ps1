# Script "manager.ps1"

Add-Type -AssemblyName System.Web

# function to download file
function Download-File {
    param (
        $RemoteUrl,
        $OutPath,
        $Config,
        $Filename,
        $StartPosition = 0
    )
    $DestinationPath = Join-Path $OutPath $Filename
    $retries = $Config['Retries']
    $method = $Config['Method']
    $Suppress = $Config['Suppress']
    $success = $false

    while ($retries -gt 0 -and -not $success) {
        switch ($method) {
            'WebRequest' {
                Write-Host "Using method: WebRequest"
                $success = InvokeWebRequestMethod -RemoteUrl $RemoteUrl -DestinationPath $DestinationPath -StartPosition $StartPosition -ChunkSize $Config['Chunk'] -Config $Config -Filename $Filename -Suppress $Suppress
            }
            'WebClient' {
                Write-Host "Using method: WebClient"
                $success = WebClientMethod -RemoteUrl $RemoteUrl -DestinationPath $DestinationPath -Suppress $Suppress
            }
            'BITS_Service' {
                Write-Host "Using method: BITS_Service"
                $success = BITSMethod -RemoteUrl $RemoteUrl -DestinationPath $DestinationPath -Suppress $Suppress
            }
        }
        $retries--
    }

    if ($retries -eq 0 -and -not $success) {
        Write-Host "Retries exhausted. Returning to Main Menu."
        return $false
    }

    return $success
}

function BITSMethod {
    param (
        $RemoteUrl,
        $DestinationPath,
        $Suppress
    )
    try {
        if ($Suppress -eq 'True') {
            $ProgressPreference = 'SilentlyContinue'
        } else {
            $ProgressPreference = 'Continue'
        }
        Start-BitsTransfer -Source $RemoteUrl -Destination $DestinationPath
        $downloadSuccess = "True"
    } catch {
        Write-Host "Error downloading file using BITS_Service: $_"
        $downloadSuccess = "False"
    }
    return $downloadSuccess
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
        if ($Suppress -eq 'True') {
            $ProgressPreference = 'SilentlyContinue'
            $response = Invoke-WebRequest -Uri $RemoteUrl -Method Get -Headers $headers -UseBasicParsing
        } else {
            $ProgressPreference = 'Continue'
            $response = Invoke-WebRequest -Uri $RemoteUrl -Method Get -Headers $headers -UseBasicParsing
        }
        $fileStream = [System.IO.File]::OpenWrite($DestinationPath)
        $fileStream.Seek($StartPosition, [System.IO.SeekOrigin]::Begin)
        $buffer = New-Object byte[] $ChunkSize
        $totalRead = $StartPosition
        $totalSize = $response.Content.Length
        $responseStream = New-Object System.IO.MemoryStream
        $responseStream.Write($response.Content, 0, $totalSize)
        $responseStream.Position = 0
        do {
            $read = $responseStream.Read($buffer, 0, $ChunkSize)
            $fileStream.Write($buffer, 0, $read)
            $totalRead += $read
            $progress = ($totalRead / $totalSize) * 100
            Write-Progress -PercentComplete $progress -Status "Downloading" -Activity "$Filename"
        } while ($read -gt 0)
        $fileStream.Close()
        $responseStream.Close()
        $downloadSuccess = "True"
    } catch {
        Write-Host "An error occurred during download: $_"
        $downloadSuccess = "False"
    }
    return $downloadSuccess
}

# Function to download file using WebClient
function WebClientMethod {
    param (
        $RemoteUrl,
        $DestinationPath,
        $Suppress
    )
    try {
        $webClient = New-Object System.Net.WebClient
        if ($Suppress -ne "True") {
            Register-ObjectEvent -InputObject $webClient -EventName DownloadProgressChanged -Action {
                Write-Progress -PercentComplete $EventArgs.ProgressPercentage -Status "Downloading" -Activity $RemoteUrl
            }
        }
        $webClient.DownloadFile($RemoteUrl, $DestinationPath)
        $downloadSuccess = "True"
    } catch {
        Write-Host "Error downloading file: $_"
        $downloadSuccess = "False"
    }
    return $downloadSuccess
}

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
