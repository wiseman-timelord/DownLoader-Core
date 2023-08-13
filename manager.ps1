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
    $retries = $Config['retries']
    $method = $Config['method'] # Initialize with the method from the configuration
    $Suppress = $Config['Suppress']
    $success = $false

    while ($retries -gt 0 -and -not $success) {
        if ($Config['automatic'] -eq 'True') { # Check if automatic mode is enabled
            Write-Host "Using method: $method" # Indicate the method being used
            if ($method -eq 'WebRequest') {
                $success = InvokeWebRequestMethod -RemoteUrl $RemoteUrl -DestinationPath $DestinationPath -StartPosition $StartPosition -ChunkSize $Config['chunk'] -Config $Config -Filename $Filename -Suppress $Suppress
            } else {
                $success = WebClientMethod -RemoteUrl $RemoteUrl -DestinationPath $DestinationPath -Suppress $Suppress
            }
            # Toggle between WebRequest and WebClient for Automatic method
            $method = if ($method -eq 'WebRequest') { 'WebClient' } else { 'WebRequest' }
        } elseif ($method -eq 'WebRequest') {
            Write-Host "Using method: WebRequest" # Indicate the method being used
            $success = InvokeWebRequestMethod -RemoteUrl $RemoteUrl -DestinationPath $DestinationPath -StartPosition $StartPosition -ChunkSize $Config['chunk'] -Config $Config -Filename $Filename -Suppress $Suppress
        } else {
            Write-Host "Using method: WebClient" # Indicate the method being used
            $success = WebClientMethod -RemoteUrl $RemoteUrl -DestinationPath $DestinationPath -Suppress $Suppress
        }
        $retries--
    }

    if ($retries -eq 0 -and -not $success) {
        Write-Host "Retries exhausted. Returning to Main Menu."
        return $false # Return false if download failed
    }

    return $success
}

# Function to download file using Invoke-WebRequest
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
            $response = Invoke-WebRequest -Uri $RemoteUrl -Method Get -Headers $headers -UseBasicParsing
            $response | Out-Null
        } else {
            $response = Invoke-WebRequest -Uri $RemoteUrl -Method Get -Headers $headers -UseBasicParsing
        }
        $fileStream = [System.IO.File]::OpenWrite($DestinationPath)
        $fileStream.Seek($StartPosition, [System.IO.SeekOrigin]::Begin)
        $buffer = New-Object byte[] $ChunkSize
        $totalRead = $StartPosition
        $responseStream = $response.Content.ReadAsStream()
        do {
            $read = $responseStream.Read($buffer, 0, $ChunkSize)
            $fileStream.Write($buffer, 0, $read)
            $totalRead += $read
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
        if ($Suppress -eq "True") {
            $webClient.DownloadFile($RemoteUrl, $DestinationPath) | Out-Null
        } else {
            $webClient.DownloadFile($RemoteUrl, $DestinationPath)
        }
        $downloadSuccess = "True"
    } catch {
        Write-Host "An error occurred during download: $_"
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

        # Fallback mechanism to extract filename from the last part of the URL path
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

function Save-Config {
    param (
        [hashtable]$config
    )
    $configFile = "config.psd1"
    $content = "@{`n"
    $keysOrder = @('Retries', 'Chunk', 'Method', 'Automatic', 'Suppress', 'FileName_1', 'Url_1', 'FileName_2', 'Url_2', 'FileName_3', 'Url_3', 'FileName_4', 'Url_4', 'FileName_5', 'Url_5', 'FileName_6', 'Url_6', 'FileName_7', 'Url_7', 'FileName_8', 'Url_8', 'FileName_9', 'Url_9')
    $keysOrder | ForEach-Object {
        if ($_ -eq 'retries' -or $_ -eq 'chunk') {
            $content += "    $_ = $($config[$_])`n"
        } else {
            $content += "    $_ = '$($config[$_])'`n"
        }
    }
    $content += "}"
    Set-Content -Path $configFile -Value $content
}

