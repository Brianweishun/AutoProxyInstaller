
param (
	#[Parameter(Mandatory=$true)]
    [string]$ApiServer,
    #[Parameter(Mandatory=$true)]
    [string]$CertName,
    #[Parameter(Mandatory=$true)]
    [string]$CertPassword
)

if (-not $CertName -or -not $CertPassword -or -not $ApiServer) {
    Write-Host "Info: .\GenerateInstallV2.ps1 -ApiServer server_name -CertName icp_name -CertPassword password"
    exit 1
}


$nsisCompiler = "C:\Program Files (x86)\NSIS\makensis.exe"
$icpFolder = $PSScriptRoot
$p12Path = $PSScriptRoot + "\..\routes\certs\"
$p12FileName = ".p12"
$installFolder = $PSScriptRoot + "\KeypascoProxyInstallerV2"
$installScript = $PSScriptRoot + "\ProxyInstaller.nsi"
$scriptPath = "C:\MyProject\setup.nsi"
$proxyName = $PSScriptRoot + "\ProxyV2\universal-1.019.08-1.43.4\universal-1.019.08-1.43.4.zip"
$dbName = $PSScriptRoot + "\ProxyV2\universal-1.019.08-1.43.4\sqliteDB.sqlite"


$parts = $CertName -split "_"

$icp = $parts[0]
$username = $parts[1]

Write-Host $icp   # test
Write-Host $username   # icpadmin
Write-Host $CertName   # icpadmin

$icpFolder = $icpFolder + "\" + $icp
$p12FileName = $CertName + $p12FileName

$scriptPath = $icpFolder + "\ProxyInstaller.nsi"

Write-Host $icpFolder   # icpadmin
Write-Host $p12FileName   # icpadmin


if (-not (Test-Path $p12Path$p12FileName)) {
    Write-Host "Error: p12 file is not exist"
    exit 1
}

if (-not (Test-Path $installFolder)) {
    Write-Host "Error: Source installer folder is not exist"
    exit 1
}

if (-not (Test-Path $installScript)) {
    Write-Host "Error: install script is not exist"
    exit 1
}


# create folder if not exist
if (-not (Test-Path $icpFolder)) {
    New-Item -ItemType Directory -Path $icpFolder
}

$icpInstallerFilePath = $icpFolder + "\KeypascoProxyInstaller\files"
$InstalliniDataPath = $icpInstallerFilePath + ".\iniData.json"

Copy-Item -Path $installFolder -Destination $icpFolder\KeypascoProxyInstaller -Recurse -Force
Copy-Item -Path $proxyName -Destination $icpFolder\KeypascoProxyInstaller
Copy-Item -Path $installScript -Destination $icpFolder
Copy-Item -Path $p12Path$p12FileName -Destination $icpInstallerFilePath
Copy-Item -Path $dbName -Destination $icpInstallerFilePath

#replace p12 path&filename
$pattern = "default_p12"
$newString = $CertName
(Get-Content $InstalliniDataPath) -replace $pattern, $newString | Set-Content $InstalliniDataPath

#replace p12 password
$pattern = "default_password"
$newString = $CertPassword
(Get-Content $InstalliniDataPath) -replace $pattern, $newString | Set-Content $InstalliniDataPath

#replace icp name
$pattern = "default_icp"
$newString = $icp
(Get-Content $InstalliniDataPath) -replace $pattern, $newString | Set-Content $InstalliniDataPath

#replace server name
$pattern = "api2tokyo.keypascoid.com"
$newString = $ApiServer
(Get-Content $InstalliniDataPath) -replace $pattern, $newString | Set-Content $InstalliniDataPath

if (-not (Test-Path $nsisCompiler)) {
    Write-Host "Error: cannot find NSIS compiler ($nsisCompiler)"
    exit 1
}

if (-not (Test-Path $scriptPath)) {
    Write-Host "Error: cannot file NSIS script ($scriptPath)"
    exit 1
}

# generate exe
& $nsisCompiler $scriptPath
