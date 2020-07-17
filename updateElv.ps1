## Update Elvui

cls
## Dank banner
"13,10,32,32,9608,9608,9608,9608,9608,9608,9608,9559,9608,9608,9559,32,32,32,32,9608,9608,9559,32,32,32,9608,9608,9559,9608,9608,9559,32,32,32,9608,9608,9559,9608,9608,9559,13,10,32,32,9608,9608,9556,9552,9552,9552,9552,9565,9608,9608,9553,32,32,32,32,9608,9608,9553,32,32,32,9608,9608,9553,9608,9608,9553,32,32,32,9608,9608,9553,9608,9608,9553,13,10,32,32,9608,9608,9608,9608,9608,9559,32,32,9608,9608,9553,32,32,32,32,9608,9608,9553,32,32,32,9608,9608,9553,9608,9608,9553,32,32,32,9608,9608,9553,9608,9608,9553,13,10,32,32,9608,9608,9556,9552,9552,9565,32,32,9608,9608,9553,32,32,32,32,9562,9608,9608,9559,32,9608,9608,9556,9565,9608,9608,9553,32,32,32,9608,9608,9553,9608,9608,9553,13,10,32,32,9608,9608,9608,9608,9608,9608,9608,9559,9608,9608,9608,9608,9608,9608,9608,9559,9562,9608,9608,9608,9608,9556,9565,32,9562,9608,9608,9608,9608,9608,9608,9556,9565,9608,9608,9553,13,10,32,32,9562,9552,9552,9552,9552,9552,9552,9565,9562,9552,9552,9552,9552,9552,9552,9565,32,9562,9552,9552,9552,9565,32,32,32,9562,9552,9552,9552,9552,9552,9565,32,9562,9552,9565,13,10,32,32,32,32,32,32,32,32,32,85,80,68,65,84,69,82,32,86,101,114,115,105,111,110,32,49,46,48,13,10" -split "," | % {
    Write-Host "$([char][int]$_)" -NoNewline 
}
Write-Host

## Check for classic wow install directory and previously installed ELVui
try {
    $wowPath = $(Get-ItemProperty -Path 'HKLM:\SOFTWARE\WOW6432Node\Blizzard Entertainment\World of Warcraft' -ErrorAction Stop ).InstallPath
    $elvUIToc = Get-ChildItem -Recurse -Path "$wowPath\Interface\AddOns\*" -Filter "Elvui.Toc" -ErrorAction SilentlyContinue
    $installDrive = $wowPath.Split("\")[0]
    Write-Host "--WOW Directory " -NoNewline; Write-Host -ForegroundColor Yellow $wowPath
    if ( $elvUIToc ) {
       $installedVersion = $(($(Get-Content $elvUIToc | Select-String "Version:") -split ": ")[-1]).substring(0,4)
       Write-Host "--Installed ELV Version " -NoNewline; Write-Host -ForegroundColor Yellow $installedVersion
    }
} catch {
    endScript -msg "`n`nCould not find registry path HKLM:\SOFTWARE\WOW6432Node\Blizzard Entertainment\World of Warcraft!" -col "Red"
}

## Check TUKUI for lastest ELVui version
Write-Host "--Web Version " -NoNewline
Add-Type -Assembly System.IO.Compression.FileSystem
$zipPath = "$($env:temp)\elvUI"
$zipFile = "$($zipPath)\elvui.zip"
$dlLink = "https://www.tukui.org/classic-addons.php?download=2"
if ( Test-Path -Path $zipPath ) { Remove-Item $zipPath -Force -Recurse }
New-Item -Path $zipPath -ItemType Directory -Force | Out-Null
Invoke-WebRequest -Uri $dlLink -OutFile "$($zipPath)\elvui.zip"
if ( Test-Path -Path $zipFile ) {
    $zip = [IO.Compression.ZipFile]::OpenRead($zipFile)
    $zip.Entries | where {$_.Name -match 'ElvUI.toc$'} | foreach {[System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, "$zipPath\ElvUI.toc", $true)}
    $zip.Dispose()
    if ( Test-Path -Path "$zipPath\ElvUI.toc" ) {
        $dlVersion = $(($(Get-Content "$($zipPath)\ElvUI.toc" | Select-String "Version:") -split ": ")[-1]).substring(0,4)
        Write-Host -ForegroundColor Yellow $dlVersion
    } else {
    endScript -msg "`n`nCould not get downloaded version from ElvUI.toc!" -col "Red"
    }
} else { endScript -msg "`n`nDownload of the latest version failed!" -col "Red" }


## Backup current ELVui addon
function backupElvUI {
    New-Item -Path "$installDrive\ElvUI_Backups" -ItemType Directory -Force | Out-Null
    if ( Test-Path -Path "$installDrive\ElvUI_Backups\$(Get-Date -Format ddMyy)" ) {
        Remove-Item -Path "$installDrive\ElvUI_Backups\$(Get-Date -Format ddMyy)" -Confirm:$false -Recurse -Force
    }
    New-Item -Path "$installDrive\ElvUI_Backups\$(Get-Date -Format ddMyy)" -ItemType Directory -Force | Out-Null
    Write-Host "`n--Backup location - $installDrive\ElvUI_Backups\$(Get-Date -Format ddMyy)"
    Get-ChildItem -Path "$wowPath\Interface\AddOns\*" | ? { $_.name -like "*Elvui*" } | % {
         Write-Host -ForegroundColor Cyan "--Backing up - " -NoNewline; Write-Host -ForegroundColor Yellow "$($_.fullname)"
         Move-Item $_ -Destination "$installDrive\ElvUI_Backups\$(Get-Date -Format ddMyy)\$($_.Name)" -Force -Confirm:$false
}}

## Extract downloaded ELVui addon
function InstallElvUI {
    Write-Host -ForegroundColor Cyan "--Extracting addon to " -NoNewline; Write-Host -ForegroundColor Yellow "$($wowPath)Interface\AddOns\"
    Expand-Archive -Path "$($zipFile)" -DestinationPath "$($wowPath)Interface\AddOns\"
    Remove-Item -Path $zipPath -Recurse -Force
}

## Exit
function endScript ($msg, $col) {
    Write-Host -ForegroundColor $col "$msg`n`n`n"
    pause
    exit
}

## Begin main
if ( $installedVersion ) {    
    if ($installedVersion -ne $dlVersion) {
        Write-Host -ForegroundColor Cyan "--Found new version!"
        backupElvUI
        InstallElvUI
        endScript -msg "`n  Installed ElvUI version $dlLink" -col "Green"
    } else {
        endScript -msg "`n  The most current version is installed." -col "Green"
    }
} else {
    InstallElvUI
    endScript -msg "`n  Installed ElvUI version $dlVersion" -col "Green"
}