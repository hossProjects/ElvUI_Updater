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
try {
    Write-Host "--Web Version " -NoNewline
    $webRequest = Invoke-WebRequest -Uri "https://www.tukui.org/classic-addons.php?id=2" -ErrorAction Stop
    $webVersion = $webRequest.ParsedHtml.IHTMLDocument3_documentElement.innerText -split "`n" | Select-string -Pattern 'Version \d.{2}\d?' -AllMatches | % { $_.Matches.Value } 
    Write-Host -ForegroundColor Yellow $webVersion[0].Split(" ")[-1]
} catch {
    endScript -msg "`n`nCould not reach https://www.tukui.org/classic-addons.php?id=2" -col "Red"
}

## Download leastest ELVui
function getElvUI {
    Write-Host -ForegroundColor Cyan "--Downloading web version " -NoNewline; Write-Host -ForegroundColor Yellow "$($webVersion[0].Split("Version ")[-1])..."
    $dlLink = "https://www.tukui.org/classic-addons.php?download=2"
    Invoke-WebRequest -Uri $dlLink -OutFile $env:temp\elvui$($webVersion[0].Split("Version ")[-1]).zip
}

## Backup current ELVui addon
function backupElvUI {
    New-Item -Path "$installDrive\ElvUI_Backups" -ItemType Directory -Force | Out-Null
    if ( Test-Path -Path "$installDrive\ElvUI_Backups\$(Get-Date -Format ddMyy)" ) {
        Remove-Item -Path "$installDrive\ElvUI_Backups\$(Get-Date -Format ddMyy)" -Confirm:$false -Recurse -Force
    }
    New-Item -Path "$installDrive\ElvUI_Backups\$(Get-Date -Format ddMyy)" -ItemType Directory -Force | Out-Null
    Get-ChildItem -Path "$wowPath\Interface\AddOns\*" | ? { $_.name -like "*Elvui*" } | % {
         Write-Host -ForegroundColor Cyan "--Backing up - " -NoNewline; Write-Host -ForegroundColor Yellow "$($_.fullname)"
         Move-Item $_ -Destination "$installDrive\ElvUI_Backups\$(Get-Date -Format ddMyy)\$($_.Name)" -Force -Confirm:$false
}}

## Extract downloaded ELVui addon
function InstallElvUI {
    Write-Host -ForegroundColor Cyan "--Extracting addon to " -NoNewline; Write-Host -ForegroundColor Yellow "$($wowPath)Interface\AddOns\"
    Expand-Archive -Path $env:temp\elvui$($webVersion[0].Split("Version ")[-1]).zip -DestinationPath "$($wowPath)Interface\AddOns\"
    Remove-Item -Path $env:temp\elvui$($webVersion[0].Split("Version ")[-1]).zip -Force
}

## Exit
function endScript ($msg, $col) {
    Write-Host -ForegroundColor $col "$msg`n`n`n"
    pause
    exit
}

## Begin main
if ( $installedVersion ) {    
    if ($webVersion[0].Split("Version ")[-1] -ne $installedVersion) {
        Write-Host -ForegroundColor Cyan "--Found new version!"
        backupElvUI
        getElvUI
        InstallElvUI
        endScript -msg "`n  Installed ElvUI version $($webVersion[0].Split("Version ")[-1])!" -col "Green"
    } else {
        endScript -msg "`n  The most current version is installed." -col "Green"
    }
} else {
    getElvUI
    InstallElvUI
    endScript -msg "`n  Installed ElvUI version $($webVersion[0].Split("Version ")[-1])!" -col "Green"
}