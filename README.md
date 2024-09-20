# DownLoader-Core
Status: Re-Visiting NOW.

### DEVELOPMENT:
- It will now be, `Powershell Core ~v7.4` and `.net`.
- Currently my other program `Downlord-Py` is far-ahead, so the python version will become "DownLord", its the original anyhow.
- Time to re-imagine the powershell version instead. I want a, simple and reliable, windows downloader.
- All Menus and handling need, checking over and moving to `interface.ps1`.

### DONE FOR RELEASE:
- Refractored scripts.
- Streamlined to Invoke-WebRequest ONLY.
- Work done on progress indicator.
- Checking of Logic and Sanity.
- Auto-Creation of `.\Downloads` folder.

## Description
DownLord-Ps is a streamlined PowerShell tool designed for downloading large and essential files, such as language models, especially on unreliable connections. It offers a customizable options menu with persistent settings, supports download resumption, and automatically maintains a history, removing items from its list when manually deleted from the folder. Unlike browser-based downloads, DownLord-Ps ensures that users don't return hours later to find incomplete downloads or accidentally cancel them. It's tailored for substantial downloads rather than smaller files that can be handled by the browser.

## Features
- **Connection Speed Selection**: Choose from speeds of 1MB/s, 5MB/s, 10MB/s, 25MB/s, or 50MB/s.
- **Download Resumption**: If a download is interrupted, it can be resumed from where it left off.
- **Setup Menu**: Configure connection speed, maximum retries, download method, and other settings.
- **Reading of Complex URLs**: Extracts filenames from simple or complex URLs using multiple methods, such as those URLs found on HuggingFace or NexusMods.
- **Configuration Persistence**: The last used URLs and settings are saved in a configuration file.
- **Download Method Selection**: Choose between methods, WebRequest, WebClient, and BITS_Service Method, with options for automatic toggling and suppress output. Note, not all features work with all methods.
- **File Management**: Automatically cleans up configuration and removes entries for missing or <1MB incomplete files.
- **Automatic Retries**: Configurable retries for downloads, ensuring persistence in case of interruptions.
- **Interactive Menus**: User-friendly interface with main and setup menus for easy navigation and configuration.
- **Batch File Support**: Includes a batch file for easy execution and administrative privilege handling.

## 3 Methods
DownLord-Ps utilizes three different methods for downloading files...
- **1. WebRequest Method**: Utilizes the "Invoke-WebRequest" cmdlet, reads content into memory and writes to disk in chunks, enabling download resumption.
- **2. WebClient Method**: Utilizes the "System.Net.WebClient" class, downloads files directly to disk without chunking or resume capability.
- **3. BITS_Service Method**: Utilizes the "B.I.T.S." service, handles network interruptions and resumes downloads, but requires the service to be set to Manual or Automatic.

## INTERFACE
Output looks like this...

```
    ________                      .____                    .___
    \______ \   ______  _  ______ |    |    ___________  __| _/
    |     |  \ /  _ \ \/ \/ /    \|    |   /  _ \_  __ \/ __ |
    |     \   (  <_> )     /   |  \    |__(  <_> )  | \/ /_/ |
    /_______  /\____/ \/\_/|___|  /_______ \____/|__|  \____ |
            \/                  \/        \/                \/

                           Main Menu
                           -=-=-=-=-

Recent Downloads:

    1. Empty
    2. Empty
    3. Empty
    4. Empty
    5. Empty
    6. Empty
    7. Empty
    8. Empty


New URL = 0, Continue = 1-9, Refresh = r, Setup = s, Quit = q :

```

## Usage
1. Clone the repository or download the script.
2. Run the script, using `powershell .\main.ps1` or double click "DownLord.bat".
3. Take a look in the settings menu, make sure everything is optimal.
4. On Main Menu press 0 then enter the URL to download.
5. The file will be downloaded to the `Downloads` directory.
6. Edit folder properties in "DownLord-Ps.lnk", for batch launch on taskbar.

## Requirements
- PowerShell 5.1 or higher
- Internet connection
- URL linked to file

## DISCLAIMER
This software is subject to the terms in License.Txt, covering usage, distribution, and modifications. For full details on your rights and obligations, refer to License.Txt.
