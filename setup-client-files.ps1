if(!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList "-File `"$($MyInvocation.MyCommand.Path)`"  `"$($MyInvocation.MyCommand.UnboundArguments)`""
    Exit
}

# Set protocol to tls version 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Push location to the current script directory
Push-Location $PSScriptRoot

# Define the download locations with filenames
$downloadLocations = @(
    @{
        Url = "https://www.curseforge.com/api/v1/mods/521932/files/3797980/download"
        Destination = "./mods/"
        FileName = "zmedievalmusic-1.18.2-1.4.jar"
    }
)

# Create the destination directories if they do not exist
foreach ($location in $downloadLocations) {
    $destinationPath = $location.Destination
    if (-not (Test-Path -Path $destinationPath)) {
        New-Item -ItemType Directory -Path $destinationPath -Force
    }
}

# Function to download files
function Download-File {
    param (
        [string]$url,
        [string]$destination,
        [string]$fileName
    )

    # Combine the destination path with the specified file name
    $fullPath = Join-Path -Path $destination -ChildPath $fileName

    # Check if the file already exists
    if (Test-Path -Path $fullPath) {
        Write-Host "File already exists: $fullPath. Skipping download."
        return
    }

    # Download the file
    try {
        # Show the filename being downloaded
        Write-Host "Downloading: $fileName"

        # If the URL is a Google Drive link, handle the confirmation token
        if ($url -like "https://drive.google.com/*") {
            $pattern = "id=([^&]+)"
            # Extract the file ID from the URL
            if ($url -match $pattern) {
                $fileId = $matches[1] # Captured group 1 contains the file ID
            } else {
                Write-Host "Invalid Google Drive URL format."
                return
            }

            # Download the Virus Warning html (content) file
            $htmlContent = Invoke-WebRequest -Uri $url -SessionVariable googleDriveSession

            # Regex pattern to match the uuid value
            $pattern = '<input type="hidden" name="uuid" value="(.+?)">'
            if ($htmlContent -match $pattern) {
                $uuidValue = $matches[1] # Captured group 1 contains the uuid value
                $downloadUrl = "https://drive.usercontent.google.com/download?id=$fileid&export=download&confirm=t&uuid=$uuidValue"
                Write-Host "Downloading: $downloadUrl"
                Invoke-WebRequest -Uri $downloadUrl -OutFile $fullPath -WebSession $googleDriveSession
            } else {
                Write-Output "UUID value not found."
                return
            }

        } else {
            Invoke-WebRequest -Uri $url -OutFile $fullPath
        }

        Write-Host "Downloaded: $fullPath"
    } catch {
        Write-Host "Failed to download: $url"
        Write-Host "Error: $_"
        Remove-Item $fullPath
    }
}

# Download each file
foreach ($location in $downloadLocations) {
    Download-File -url $location.Url -destination $location.Destination -fileName $location.FileName
}

Read-Host "Press any key to exit"
