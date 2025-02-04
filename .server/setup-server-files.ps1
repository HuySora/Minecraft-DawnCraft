if(!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList "-File `"$($MyInvocation.MyCommand.Path)`"  `"$($MyInvocation.MyCommand.UnboundArguments)`""
    Exit
}

# Push location to the current script directory
Push-Location $PSScriptRoot

# Source directory and target link directory for each folder
$folders = @{
    "config" = @{
        "source" = "..\config"
        "ignoreNames" = @() # Add file or folder names to ignore
    }
    "defaultconfigs" = @{
        "source" = "..\defaultconfigs"
        "ignoreNames" = @()
    }
    "libraries" = @{
        "source" = "..\..\libraries"
        "target" = "libraries"
        "ignoreNames" = @()
        "link" = $true
    }
    "mods" = @{
        "source" = "..\mods"
        "ignoreNames" = @(
            "AmbientSounds_FORGE_v5.0.16_mc1.18.2.jar",
            "BHMenu-Forge-1.18.2-2.4.1.jar",
            "TravelersTitles-1.18.2-Forge-2.1.1.jar",
            "ToastControl-1.18.2-6.0.3.jar",
            "betterbiomeblend-1.18.2-1.3.5-forge.jar",
            "bwncr-3.13.21.jar",
            "celesteconfig-1.18.2-1.0.0.jar",
            "CompassCoords-1.4.0-mc1.18.2.jar",
            "Controlling-forge-1.18.2-9.0+23.jar",
            "CraftPresence-2.3.5+1.18.2.jar",
            "CTM-1.18.2-1.1.5+5.jar",
            "CullLessLeaves-Reforged-1.18.2-1.0.5.jar",
            "defaultoptions-forge-1.18.2-14.1.2.jar",
            "DripSounds-1.18-0.3.0.jar",
            "drippyloadingscreen_forge_3.0.1_MC_1.18.2.jar",
            "Effective_fg-1.2.4.jar",
            "embeddium-0.3.18+mc1.18.2.jar",
            "EnhancedBlockEntities-Reforged-1.18.2-0.8.0.jar",
            "EnchantmentDescriptions-Forge-1.18.2-10.0.12.jar",
            "Entity_Collision_FPS_Fix-forge-1.18.2-1.0.0.jar",
            "entityculling-forge-1.6.1-mc1.18.2.jar",
            "EquipmentCompare-1.18.2-forge-1.3.3.jar",
            "fancymenu_forge_3.1.2_MC_1.18.2.jar",
            "FpsReducer2-forge-1.18.2-2.0.jar",
            "gpumemleakfix-1.18.2-1.6.jar",
            "HealthOverlay-1.18.2-6.3.4.jar",
            "ImmediatelyFastReforged-1.18.2-1.1.10.jar",
            "inventoryhud.forge.1.18.2-3.4.26.jar",
            "lazydfu-1.0-1.18+.jar",
            "LegendaryTooltips-1.18.2-1.3.1.jar",
            "lightspeed-1.18.2-1.0.5.jar",
            "lootbeams-1.18.1-release-july1722.jar",
            "MouseTweaks-forge-mc1.18-2.21.jar",
            "NekosEnchantedBooks-1.18.2-1.8.0.jar",
            "notenoughanimations-forge-1.6.0-mc1.18.2.jar",
            "oculus-flywheel-compat-forge1.18.2+1.0.3.jar",
            "oculus-mc1.18.2-1.6.4.jar",
            "oculusparticlefix-1.0.jar",
            "PickUpNotifier-v3.2.1-1.18.2-Forge.jar",
            "radon-0.8.1.jar",
            "ReAuth-1.18-Forge-4.0.7.jar",
            "reforgium-1.18.2-1.0.12a.jar",
            "rubidium-extra-0.4.18+mc1.18.2-build.86.jar",
            "shutupexperimentalsettings-1.0.5.jar",
            "ShoulderSurfing-Forge-1.18.2-4.2.1.jar",
            "textrues_embeddium_options-0.1.1+mc1.18.2.jar",
            "TravelersTitles-1.18.2-Forge-2.1.1.jar"
        )
    }
    "global_packs" = @{
        "source" = "..\global_packs"
        "ignoreNames" = @()
    }
    "scripts" = @{
        "source" = "..\scripts"
        "ignoreNames" = @()
    }
}

# Function to copy files from source to target directory
function Copy-Files {
    param(
        [string]$sourceDirectory,
        [string]$targetDirectory,
        [string[]]$ignoreNames
    )

    # Get files and folders in the source directory
    $items = Get-ChildItem -Path $sourceDirectory

    # Loop through each item and copy it to the target directory
    foreach ($item in $items) {
        # Check if item is not in the ignore list
        if ($ignoreNames -notcontains $item.Name) {
            # Check if item is a directory or file
            if ($item.PSIsContainer) {
                # Copy directory to target directory
                Write-Host "Copying directory: Copy-Item -Path `"$($item.FullName)`" -Destination `"$targetDirectory\$($item.Name)`" -Recurse -Force"
                Copy-Item -Path $item.FullName -Destination "$targetDirectory\$($item.Name)" -Recurse -Force
            } else {
                # Copy file to target directory
                Write-Host "Copying file: Copy-Item -Path `"$($item.FullName)`" -Destination `"$targetDirectory`" -Force"
                Copy-Item -Path $item.FullName -Destination $targetDirectory -Force
            }
        }
    }
}

# Loop through each folder and create symbolic links or copy files
foreach ($folderName in $folders.Keys) {
    $folder = $folders[$folderName]
    $sourceDirectory = $folder["source"]
    $targetDirectory = $folderName
    $ignoreNames = $folder["ignoreNames"]

    # Remove previous symbolic link and folder if they exist
    if (Test-Path -Path $targetDirectory) {
        Write-Host "Removing previous symbolic link and folder: rmdir `"$targetDirectory`" /s /q"
        git rm --cached -r "$targetDirectory"
        # Check if item is a directory or file
        if (Test-Path -Path $targetDirectory -PathType Container) {
            cmd /c rmdir "$targetDirectory" /s /q
        } else {
            cmd /c del "$targetDirectory" /q
        }
    }

    # Check if symbolic link should be created
    if ($folder["link"]) {
        # Create symbolic link for directory
        Write-Host "Creating symbolic link for folder: mklink /D `"$targetDirectory`" `"$sourceDirectory`""
        cmd /c mklink /D "$targetDirectory" "$sourceDirectory"
        git reset HEAD -- "$targetDirectory"
    } else {
        # Create new target directory
        Write-Host "Creating target directory: New-Item -Path `"$targetDirectory`" -ItemType Directory"
        New-Item -Path $targetDirectory -ItemType Directory | Out-Null
        # Copy files from source to target directory
        Write-Host "Copying files to target directory..."
        Copy-Files -sourceDirectory $sourceDirectory -targetDirectory $targetDirectory -ignoreNames $ignoreNames
    }
}

# Pop back to the previous location
Pop-Location

pause
