# DownLord-Ps
Status: Pre-release 
Needs work on progress indication, the challenge is suppressing output from cmdlet/class at same time as having other code doing stats at same time.

## Description
DownLord-Ps is a streamlined PowerShell tool designed for downloading large and essential files, such as language models, especially on unreliable connections. It offers a customizable options menu with persistent settings, supports download resumption, and automatically maintains a history, removing items from its list when manually deleted from the folder. Unlike browser-based downloads, DownLord-Ps ensures that users don't return hours later to find incomplete downloads or accidentally cancel them. It's tailored for substantial downloads rather than smaller files that can be handled by the browser.

## Features
- **Connection Speed Selection**: Choose from speeds of 1MB/s, 5MB/s, 10MB/s, 25MB/s, or 50MB/s.
- **Download Resumption**: If a download is interrupted, it can be resumed from where it left off.
- **Setup Menu**: Configure connection speed, maximum retries, download method, and other settings.
- **Reading of Complex URLs**: Extracts filenames from simple or complex URLs using multiple methods, such as those URLs found on HuggingFace or NexusMods.
- **Configuration Persistence**: The last used URLs and settings are saved in a configuration file.
- **Download Method Selection**: Choose between methods, WebRequest, WebClient, and BITS_Service Method, with options for automatic toggling and suppress output.
- **File Management**: Automatically cleans up configuration and removes entries for missing or <1MB incomplete files.
- **Automatic Retries**: Configurable retries for downloads, ensuring persistence in case of interruptions.
- **Interactive Menus**: User-friendly interface with main and setup menus for easy navigation and configuration.
- **Batch File Support**: Includes a batch file for easy execution and administrative privilege handling.


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

## Disclaimer
"DownLord-Ps" is provided "as is," and the creators make no warranties regarding its use. Users are solely responsible for the content they download and any potential damages to their equipment. The use of "DownLord-Ps" for unauthorized activities is strictly at the user's own risk, and all legal responsibilities lie with the user.