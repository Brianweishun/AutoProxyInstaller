
param (
    #[Parameter(Mandatory=$true)]
    [string]$CertName,
    #[Parameter(Mandatory=$true)]
    [string]$CertPassword
)

if (-not $CertName -or -not $CertPassword) {
    Write-Host "Info: .\GenerateInstall.ps1 -CertName icp_name -CertPassword password"
    exit 1
}

#Write-Host "file name $CertName."

$nsisCompiler = "C:\Program Files (x86)\NSIS\makensis.exe"
$icpFolder = $PSScriptRoot
$p12Path = $PSScriptRoot + "\..\routes\certs\"
$p12FileName = ".p12"
$installFolder = $PSScriptRoot + "\KeypascoProxyInstaller"
$installScript = $PSScriptRoot + "\ProxyInstaller.nsi"
$scriptPath = "C:\MyProject\setup.nsi"


$parts = $CertName -split "_"

$icp = $parts[0]
$username = $parts[1]

Write-Host $icp   # test
Write-Host $username   # icpadmin

$icpFolder = $icpFolder + "\" + $icp
$p12FileName = $CertName + $p12FileName

$scriptPath = $icpFolder + "\ProxyInstaller.nsi"

Write-Host $icpFolder   # icpadmin
Write-Host $p12FileName   # icpadmin


if (-not (Test-Path $p12Path$p12FileName)) {
    Write-Host "Error¡Gp12 file is not exist"
    exit 1
}

if (-not (Test-Path $installFolder)) {
    Write-Host "Error¡GSource installer folder is not exist"
    exit 1
}

if (-not (Test-Path $installScript)) {
    Write-Host "Error¡Ginstall script is not exist"
    exit 1
}


# create folder if not exist
if (-not (Test-Path $icpFolder)) {
    New-Item -ItemType Directory -Path $icpFolder
}

$icpInstallerFilePath = $installFolder + "\files"
$InstalliniDataPath = $icpInstallerFilePath + ".\iniData.json"

Copy-Item -Path $installFolder -Destination $icpFolder -Recurse -Force
Copy-Item -Path $installScript -Destination $icpFolder
Copy-Item -Path $p12Path$p12FileName -Destination $icpInstallerFilePath

#replace p12 path&filename
$pattern = "keypasco-demo_mfaproxy-new"
$newString = $CertName
(Get-Content $InstalliniDataPath) -replace $pattern, $newString | Set-Content $InstalliniDataPath

#replace p12 password
$pattern = "mfaproxy"
$newString = $CertPassword
(Get-Content $InstalliniDataPath) -replace $pattern, $newString | Set-Content $InstalliniDataPath

#replace icp name
$pattern = "keypasco-demo"
$newString = $icp
(Get-Content $InstalliniDataPath) -replace $pattern, $newString | Set-Content $InstalliniDataPath

if (-not (Test-Path $nsisCompiler)) {
    Write-Host "Error¡Gcannot find NSIS compiler ($nsisCompiler)"
    exit 1
}

if (-not (Test-Path $scriptPath)) {
    Write-Host "Error¡Gcannot file NSIS script ($scriptPath)"
    exit 1
}

# generate exe
& $nsisCompiler $scriptPath
