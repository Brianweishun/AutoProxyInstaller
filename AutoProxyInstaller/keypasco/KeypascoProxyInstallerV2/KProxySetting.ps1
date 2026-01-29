$rootPath = ".\"
$filePath = ".\files\"
$lydsecPath = "C:\Lydsec\"
$mfasettingPath = "C:\mfaproxy-setting\"

$selfSignScript = "selfSign.ps1"
$fingerPrintScript = "fingerprint.ps1"
$lydsecFolder = "C:\Lydsec\"
$mfaProxySettingFolder = "C:\mfaproxy-setting\"
$iisInstallXML = ".\files\IISforProxy.xml"
$siteName = "MFA"
$proxyFileSetting = ".\ProxyFileSetting.ps1"

$IISCheckTaskName = "IIS CheckPool"
$IISCheckScriptPath = "`"$mfaProxySettingFolder\iis-checkpool.bat`""

$IISCheckRotateTaskName = "IIS CheckPool LogRotate"
$IISCheckRotateScriptPath = "`"$mfaProxySettingFolder\logrotate.bat`""

$selfSignCA = $true

$hostname = $env:COMPUTERNAME.ToLower()
# Write-Host "Host Name: $hostname"

$domain = (Get-WmiObject Win32_ComputerSystem).Domain
# Write-Host "Domain Name: $domain"

if ($domain -eq "WORKGROUP") {
	Write-Host "Not join domain"
	$DnsName = "localhost"
} else {
	$fqdn = "$hostname.$domain"
	$DnsName = "$fqdn"
	Write-Host "FQDN: $fqdn"
}

# find only one Lydsecmfa zip file
$mfaFile = Get-ChildItem -Path $rootPath -File | Where-Object { $_.Name -like "universal-*.zip" }

if ($mfaFile.Count -eq 1) {
    Write-Host "Lydsecmfa: $($mfaFile.Name)" -ForegroundColor Green
} elseif ($mfaFile.Count -gt 1) {
    Write-Host "Error: More than one Lydsecmfa found in $rootPath!" -ForegroundColor Red
	exit 1
} else {
    Write-Host "Error: No Lydsecmfa found in $rootPath!" -ForegroundColor Red
	exit 1
}

# check pfx(certificate) file
$pfxFile = Get-ChildItem -Path $filePath -File | Where-Object { $_.Name -like "*.pfx" }

if ($pfxFile.Count -eq 1) {
    Write-Host "pfx: $($pfxFile.Name)" -ForegroundColor Green
} elseif ($pfxFile.Count -gt 1) {
    Write-Host "Error: More than one pfx found in $filePath!" -ForegroundColor Red
	$pfxFile = ""
} else {
    Write-Host "Error: No pfx found in $filePath!"
}

if (-not [string]::IsNullOrEmpty($pfxFile)) {
    Write-Host "pfx File exists!"
	# check pwd file
	$pwdFile = Get-ChildItem -Path $filePath -File | Where-Object { $_.Name -match "pfx.pwd" }
	
	if ($pwdFile.Count -eq 1) {
		# Write-Host "password: $($pwdFile.Name)"
		$password = Get-Content $filePath$pwdFile
		Write-Host "pfx password: $password" -ForegroundColor Green
		$selfSignCA = $false
	} elseif ($pwdFile.Count -gt 1) {
		Write-Host "Error: More than one password found in $filePath!" -ForegroundColor Red
		$pfxFile = ""
	} else {
		Write-Host "Error: No password found in $filePath!" -ForegroundColor Red
	}
} else {    
	Write-Host "pfx File does NOT exist!"
}

# create self-signed certificate
if ($selfSignCA -eq $true) {
	Write-Host "use self-signed certificate" -ForegroundColor Green
	$temp = $PSScriptRoot + "\" + $selfSignScript
	$selfSigned = & "$temp"
	# parse password from $selfSigned result after " "
	$tempOutput = $selfSigned -split " "
	$fqdn = $tempOutput[2]
	$password = $tempOutput[1]
	$pfxPath = $filePath + "self_signed.pfx"
} else {
	Write-Host "use customer certificate" -ForegroundColor Green
	$pfxPath = $filePath + $pfxFile
}

# Get thumbprint
$fullPfxPath = $PSScriptRoot + $pfxPath.TrimStart(".")
# Write-Host "$fullPfxPath" -ForegroundColor Yellow
$pfx = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
$pfx.Import($fullPfxPath, $password, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable)

Write-Host "Thumbprint: $($pfx.Thumbprint)" -ForegroundColor Green

# Ensure the folder C:\Lydsec\ exists (Create if not)
if (!(Test-Path $lydsecFolder)) {
    New-Item -ItemType Directory -Path $lydsecFolder | Out-Null
}

# Extract Lydsecmfa using Expand-Archive
Expand-Archive -Path "$($mfaFile.Name)" -DestinationPath $lydsecFolder -Force

$mfafolderName = $($mfaFile.Name)
$mfafolderName = $mfafolderName -replace ".zip", ""

# install IIS
$edition = (Get-ComputerInfo).WindowsProductName
Write-Host "This is $edition"

if ($edition -match "Server") {
	Write-Host "This is server"
	Install-WindowsFeature -ConfigurationFilepath $iisInstallXML
} else {
	Write-Host "This is home edition"
	dism.exe /online /enable-feature /featurename:IIS-WebServerRole /all
	
	dism.exe /online /enable-feature /featurename:IIS-ASPNET45 /all
	dism.exe /online /enable-feature /featurename:IIS-ISAPIFilter /all
	dism.exe /online /enable-feature /featurename:IIS-ISAPIExtensions /all
	
	# dism.exe /online /enable-feature /featurename:NetFx3 /all
}


# import IIS SSL certification
Import-PfxCertificate -FilePath $pfxPath -CertStoreLocation "Cert:\LocalMachine\My" -Password (ConvertTo-SecureString -String $password -AsPlainText -Force)

# Stop default web site
C:\Windows\System32\inetsrv\AppCmd.exe stop site /site.name:"Default Web Site"
# add site
C:\Windows\System32\inetsrv\AppCmd.exe add site /name:$siteName /physicalPath:$lydsecFolder$mfafolderName /bindings:"http/*:80:,https/*:443:"
# add application pool
C:\Windows\System32\inetsrv\AppCmd.exe add apppool /name:$siteName
# add ssl certificate
netsh.exe http add sslcert ipport=0.0.0.0:443 certhash=$($pfx.Thumbprint)

C:\Windows\System32\inetsrv\appcmd.exe set apppool /apppool.name:$siteName /startMode:AlwaysRunning

# set idle time out to 120
C:\Windows\System32\inetsrv\appcmd.exe set apppool /apppool.name:$siteName /ProcessModel.idleTimeout:02:00:00

C:\Windows\System32\inetsrv\appcmd.exe set apppool /apppool.name:$siteName /ProcessModel.idleTimeoutAction:Suspend

C:\Windows\System32\inetsrv\appcmd.exe set apppool /apppool.name:$siteName /ProcessModel.loadUserProfile:true

C:\Windows\System32\inetsrv\appcmd.exe set apppool /apppool.name:$siteName /recycling.periodicRestart.time:00:00:00

# list settings
# C:\Windows\System32\inetsrv\AppCmd.exe list site /name:$siteName /text:*

C:\Windows\System32\inetsrv\appcmd.exe set app /app.name:$siteName/ /preloadEnabled:true
C:\Windows\System32\inetsrv\appcmd.exe set app /app.name:$siteName/ /applicationPool:MFA

# Start web site
C:\Windows\System32\inetsrv\AppCmd.exe start site /site.name:$siteName

# Ensure the folder C:\mfaproxy-setting\ exists (Create if not)
if (!(Test-Path $mfaProxySettingFolder)) {
    New-Item -ItemType Directory -Path $mfaProxySettingFolder | Out-Null
}

# Write-Host "$mfafolderName" -ForegroundColor Yellow

# Copy-Item "$lydsecFolder/$mfafolderName\initConfig.ini" -Destination $mfaProxySettingFolder
Copy-Item "$filePath\sqliteDB.sqlite" -Destination $mfaProxySettingFolder
Copy-Item "$filePath\initConfig.ini" -Destination $mfaProxySettingFolder

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$proxyFileSetting" -lydmfaZIP $mfafolderName

if ([string]::IsNullOrEmpty($fqdn)) {
	# Get-Process msedge -ErrorAction SilentlyContinue | Stop-Process -Force
	# Start-Sleep -Seconds 2
	$URL = "https://localhost"
	Write-Host $URL
	Start-Process "msedge.exe" "https://localhost"
} else {
	# Get-Process msedge -ErrorAction SilentlyContinue | Stop-Process -Force
	# Start-Sleep -Seconds 2
	$URL = "https://$fqdn"
	Write-Host $URL
	Start-Process "msedge.exe" "https://$fqdn"
}

$path = "$mfaProxySettingFolder\sqliteDB.sqlite"

# create Access Rule：Everyone = FullControl
$acl = Get-Acl $path
$identity = "Everyone"
$rights = "FullControl"
$inheritance = "None"
$propagation = "None"
$type = "Allow"

$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($identity, $rights, $inheritance, $propagation, $type)

# add permission for everyone
$acl.SetAccessRule($rule)
Set-Acl -Path $path -AclObject $acl

# add IIS check application pool task scheduler
Copy-Item "$filePath\logrotate.bat" -Destination $mfaProxySettingFolder
Copy-Item "$filePath\iis-checkpool.bat" -Destination $mfaProxySettingFolder

$action = New-ScheduledTaskAction -Execute "$IISCheckScriptPath"
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).Date.AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 1)
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
Register-ScheduledTask -TaskName $IISCheckTaskName -Action $action -Trigger $trigger -Principal $principal -Description "Run IIS checkpool script every 1 minute"

$action = New-ScheduledTaskAction -Execute "$IISCheckRotateScriptPath"
$trigger = New-ScheduledTaskTrigger -Daily -At 11:59PM
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
Register-ScheduledTask -TaskName $IISCheckRotateTaskName -Action $action -Trigger $trigger -Principal $principal -Description "Run IIS checkpool logrotate at 11:59 PM"