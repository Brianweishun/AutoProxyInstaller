# Accept the input parameter
param (
    [string]$lydmfaZIP
)
$vcInstallerPath = ".\files\VC_redist.x64.exe"
$arguments = "/quiet /norestart"
$icpUser = "mfaproxy"
# Set the file paths
#$webConfigPath = "$PSScriptRoot\files"		#for debug
#$initConfigPath = "$PSScriptRoot\files"		#for debug
$webConfigPath = "C:\Lydsec\Lydsecmfa-Vxxx"
$initConfigPath = "C:\mfaproxy-setting"

$webConfigName = "Web.config"
# $initconfigName = "initConfig.ini"

#$webConfigOutputFile = "$PSScriptRoot\WebConfigOutput.txt"		#for debug
#$initconfigOutputFile = "$PSScriptRoot\initConfigOutput.txt"		#for debug
$webConfigOutputFile = "$webConfigPath\$webConfigName"
# $initconfigOutputFile = "$initConfigPath\$initconfigName"

# for Web.config
$pgServer = "10.0.1.244"
$pgDB = "proxyuser"
$pgUId = "proxyuser"
$pgPWD = "123456"

# Set the target string and the new line to insert
$pgDbSearchString = "10.0.1.246"
$pgDbNewLine1 = "	<connectionStrings>"
$pgDbNewLine2 = ""#"		<add name=""LydsecMfaDBEntities"" connectionString=""Server=$pgServer;Database=$pgDB; User Id=$pgUId;Password=$pgPWD;"" providerName=""Npgsql"" />"
$pgDbNewLine3 = "	</connectionStrings>"

$logSearchString = "logPath"
$logNewContent = ""#"    <add key=""logPath"" value=""C:\mfaproxy-setting"" />"

$endPointSearchString = "api2tokyo.keypascoid.com"
$endPointNewContent = ""#"apistart.keypascode.com"

# for initConfig.ini
$credentialIDSearchString = "MichCredentialID"
$credentialIDOldContent = 'C:\\mfaproxy-setting\\keypasco-demo_mfaproxy-apistar.p12'
$credentialIDNewContent = ""#'C:\mfaproxy-setting\keypasco-demo_mfaproxy-165.p12'

$credentialPwdSearchString = "MichCredentialPwd"
$credentialPwdOldContent = "mfaproxy"
$credentialPwdNewContent = ""#"mfaproxy123456"

$CustomerIdSearchString = "MichCustomerId"
$CustomerIdOldContent = "keypasco-demo"
$CustomerIdNewContent = ""#"keypasco-demo2"

$MeDomainSearchString = "MichMeDomain"
$MeDomainOldContent = "http://kxmfa.es2016.lydsec.com"
$MeDomainNewContent = ""#"http://mfa.xxxx.lydsec.com"

$ADSearchString = "MichAD="
$ADOldContent = "es2016.lydsec.com"
$ADNewContent = ""#"xxxx.lydsec.com"

$ADAccount3SearchString = "ADAccount3"
$ADAccount3OldContent = "sean"
$ADAccount3NewContent = ""#"xxxx"

$ClientApiSearchString = "ClientApi"
$ClientApiOldContent = "api2.keypascoid.com"
$ClientApiNewContent = ""#"xxxx"

function Check-File {
    param([string]$Path)
    if (Test-Path $Path) {
        return "File exists"
    } else {
        return "File does not exist"
    }
}

#Set backup file surffix
$backupSurrfix = (Get-Date).ToString('MM-dd-yyyy.hhmmss')


$webConfigExist = Check-File "$PSScriptRoot\backup\$webConfigName.ori"
# $initconfigExist = Check-File "$PSScriptRoot\backup\$initconfigName.ori"
$iniDataExist = Check-File "$PSScriptRoot\files\iniData.json"

#$mfaFileName = Read-Host "Input full proxy program name(Lydsecmfa-V1.xxx.xx-x.xx.xip)"
#if([string]::IsNullOrEmpty($mfaFileName)) {
#	Write-Host "Invalid parameter. proxy program name can not be empty."  -ForegroundColor Red
#	exit 1
#} else {
#	$fileWithoutExtension = $mfaFileName -replace "\.zip$", ""
#	$webConfigPath = "C:\Lydsec\" + $fileWithoutExtension
#	$webConfigOutputFile = "$webConfigPath\$webConfigName"
#	Write-Host "Log path: " $webConfigPath
#	Write-Host "Log path: " $webConfigOutputFile
#}

$fileWithoutExtension = $lydmfaZIP -replace "\.zip$", ""
$webConfigPath = "C:\Lydsec\" + $fileWithoutExtension
$webConfigOutputFile = "$webConfigPath\$webConfigName"

# check if original file backup exist
if($webConfigExist -eq "File does not exist") {
    Copy-Item $webConfigPath\$webConfigName -Destination "$PSScriptRoot\backup\$webConfigName.ori"
}else{
	Copy-Item $webConfigPath\$webConfigName -Destination "$PSScriptRoot\backup\$webConfigName.$backupSurrfix"
	$RestoreWebconfig = Read-Host "Restore Web.config(Default: Yes) [Y/N]"
    if($RestoreWebconfig -ine "N") {
	    Copy-Item "$PSScriptRoot\backup\$webConfigName.ori" -Destination $webConfigPath\$webConfigName
    }
}
# if($initconfigExist -eq "File does not exist") {
    # Copy-Item $webConfigPath\$initconfigName -Destination "$PSScriptRoot\backup\$initconfigName.ori"
# }else{
	# Copy-Item $webConfigPath\$initconfigName -Destination "$PSScriptRoot\backup\$initconfigName.$backupSurrfix"
	# $RestoreInitconf = Read-Host "Restore initConfig.ini(Default: Yes) [Y/N]"
    # if($RestoreInitconf -ine "N") {
	    # Copy-Item "$PSScriptRoot\backup\$initconfigName.ori" -Destination $webConfigPath\$initconfigName
    # }
# }

# $ChangeLogPath = Read-Host "Change proxy log path(Default: No) [Y/N]"
# if($ChangeLogPath -ieq "Y") {
	# $LogPath = Read-Host "Proxy log path [Default: C:\mfaproxy-setting]"
	# if([string]::IsNullOrEmpty($LogPath)) {
		# $LogPath = 'C:\mfaproxy-setting'
	# }
	# $logNewContent = "    <add key=""logPath"" value=""$LogPath"" />"
	# Write-Host "Log path: " $LogPath
# }
$LogPath = 'C:\mfaproxy-setting'
$logNewContent = "    <add key=""logPath"" value=""$LogPath"" />"

#Write-Host "Log NewContent: " $logNewContent

$UsePostgreDB = Read-Host "Use PostgreSQL(Default: No) [Y/N]"
if($UsePostgreDB -ieq "Y") {
	$pgServer = Read-Host "PostgreSql Server [Example: 10.0.1.244]"
	if([string]::IsNullOrEmpty($pgServer)) {
		Write-Host "Invalid parameter."  -ForegroundColor Red
		exit 1
	}
	
	$pgDB = Read-Host "PostgreSql DB name"
	if([string]::IsNullOrEmpty($pgDB)) {
		Write-Host "Invalid parameter."  -ForegroundColor Red
		exit 1
	}
	
	$pgUId = Read-Host "PostgreSql user name"
	if([string]::IsNullOrEmpty($pgUId)) {
		Write-Host "Invalid parameter."  -ForegroundColor Red
		exit 1
	}
	
	$pgPWD = Read-Host "PostgreSql user password"
	if([string]::IsNullOrEmpty($pgPWD)) {
		Write-Host "Invalid parameter."  -ForegroundColor Red
		exit 1
	}
	$pgDbNewLine2 = "		<add name=""LydsecMfaDBEntities"" connectionString=""Server=$pgServer;Database=$pgDB; User Id=$pgUId;Password=$pgPWD;"" providerName=""Npgsql"" />"
}
#Write-Host "pg NewContent: " $pgDbNewLine2

if($iniDataExist -eq "File does not exist") {
	$endPointNewContent = Read-Host "Borgen server FQDN"

	#Write-Host "Borgen server domain: " $endPointNewContent

	$credentialIDNewContent = Read-Host "Certificate(P12) full path"

	#Write-Host "Certificate full path: " $credentialIDNewContent

	$credentialPwdEncryContent = Read-Host "Certificate(P12) password"  -AsSecureString

	$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($credentialPwdEncryContent)
	$credentialPwdNewContent = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)


	#Write-Host "Certificate password: " $credentialPwdNewContent

	$CustomerIdNewContent = Read-Host "Customer ID(ICP)"
	
	$ClientApiNewContent = Read-Host "ClientApi: "
} else {
	$jsonData = Get-Content ".\files\iniData.json" -Raw | ConvertFrom-json

	Write-Host "Borgen server FQDN: $($jsonData.BorgenServer)"
	Write-Host "Certificate(P12) full path: $($jsonData.P12Path)"
	Write-Host "Certificate(P12) password: $($jsonData.P12Password)"
	Write-Host "Customer ID(ICP): $($jsonData.ICP)"
	Write-Host "ClientApi: $($jsonData.ClientApi)"
	$endPointNewContent = $($jsonData.BorgenServer)
	$credentialIDNewContent = $($jsonData.P12Path)
	$credentialPwdNewContent = $($jsonData.P12Password)
	$CustomerIdNewContent = $($jsonData.ICP)
	$ClientApiNewContent = $($jsonData.ClientApi)
}

#Write-Host "Customer ID: " $CustomerIdNewContent

$ADNewContent = Read-Host "AD Domain"
if(-not [string]::IsNullOrEmpty($ADNewContent)) {
	$MeDomainNewContent = "http://mfa.$ADNewContent"
}

#Write-Host "AD Domain: " $ADNewContent

#Write-Host "mfa AD Domain: " $MeDomainNewContent

# $ADAccount3NewContent = Read-Host "Add user name"
$ADAccount3NewContent = "kpadmin"

#Write-Host "Add user name: " $ADAccount3NewContent

$CertificateSearchString = "Certificate="
$CertificateOldContent = 'C:\\mfaproxy-setting\\cert\\test-private.p12'
$CertificateNewContent = $credentialIDNewContent

# parse file name
$P12fileName = Split-Path $credentialIDNewContent -Leaf

#Write-Host "other1: " $credentialIDNewContent

$CertificatePasswordSearchString = "CertificatePassword="
$CertificatePasswordOldContent = '123456'
$CertificatePasswordNewContent = $credentialPwdNewContent

#Write-Host "other2: " $credentialPwdNewContent

# copy p12 to C:\\mfaproxy-setting\
Copy-Item -Path $CertificateNewContent -Destination $initConfigPath -Force

# Read for Web.config
$content = Get-Content $webConfigPath\$webConfigName -Encoding UTF8
$found = $false

# Open output file for writing
$streamWriter = New-Object System.IO.StreamWriter($webConfigOutputFile, $false)

$lineCounter = 0
$insertFlag = $false

foreach ($line in $content) {
#<#	 open log
	if (($line -like "*$logSearchString*") -and ($logNewContent)) {
		$line = $logNewContent
    }
#>  #open log

#<#	borgen domain
	if (($endPointSearchString) -and ($line -like "*$endPointSearchString*") -and ($endPointNewContent)) {
		$line = $line -replace $endPointSearchString, $endPointNewContent
    }
#>	#borgen domain
	
	$streamWriter.WriteLine($line)

#<#	for postgres DB
	if ($insertFlag) {
        $lineCounter++
        # add new line after 1 lines
        if ($lineCounter -eq 1) {
            $streamWriter.WriteLine($pgDbNewLine1)
			$streamWriter.WriteLine($pgDbNewLine2)
			$streamWriter.WriteLine($pgDbNewLine3)
            $insertFlag = $false
        }
    }
    
    # Check if the current line matches the search string
    if (($line -like "*$pgDbSearchString*") -and (!$found) -and ($pgDbNewLine1) -and ($pgDbNewLine2) -and ($pgDbNewLine3)) {
		$insertFlag = $true
		$lineCounter = 0
    }
#>  # for postgres DB
}
#> #Read for Web.config

# Close the stream writer
$streamWriter.Close()

# Read the file and process each line
# $content = Get-Content $initConfigPath\$initconfigName -Encoding UTF8
#$found = $false

# Open output file for writing
# $streamWriter = New-Object System.IO.StreamWriter($initconfigOutputFile, $false)

# foreach ($line in $content) {
	# if (($line -like "*$credentialIDSearchString*") -and ($credentialIDOldContent) -and ($credentialIDNewContent)) {
		# $line = $line -replace $credentialIDOldContent, "$initConfigPath\$P12fileName"
    # }
	
	# if (($line -like "*$credentialPwdSearchString*") -and ($credentialPwdOldContent) -and ($credentialPwdNewContent)) {
		# $line = $line -replace $credentialPwdOldContent, $credentialPwdNewContent
    # }
	
	# if (($line -like "*$CustomerIdSearchString*") -and ($CustomerIdOldContent) -and ($CustomerIdNewContent)) {
		# $line = $line -replace $CustomerIdOldContent, $CustomerIdNewContent
    # }
	
	# if (($line -like "*$MeDomainSearchString*") -and ($MeDomainOldContent) -and ($MeDomainNewContent)) {
		# $line = $line -replace $MeDomainOldContent, $MeDomainNewContent
    # }
	
	# if (($line -like "*$ADSearchString*") -and ($ADOldContent) -and ($ADNewContent)) {
		# $line = $line -replace $ADOldContent, $ADNewContent
    # }
	
	# if (($line -like "*$ADAccount3SearchString*") -and ($ADAccount3OldContent) -and ($ADAccount3NewContent)) {
		# $line = $line -replace $ADAccount3OldContent, $ADAccount3NewContent
    # }
	
	# if (($line -like "*$CertificateSearchString*") -and ($CertificateOldContent) -and ($CertificateNewContent)) {
		# $line = $line -replace $CertificateOldContent, "$initConfigPath\$P12fileName"
    # }
	
	# if (($line -like "*$CertificatePasswordSearchString*") -and ($CertificatePasswordOldContent) -and ($CertificatePasswordNewContent)) {
		# $line = $line -replace $CertificatePasswordOldContent, $CertificatePasswordNewContent
    # }
 
	# if (($line -like "*$ClientApiSearchString*") -and ($ClientApiOldContent) -and ($ClientApiNewContent)) {
		# $line = $line -replace $ClientApiOldContent, $ClientApiNewContent
    # }

	# $streamWriter.WriteLine($line)
# }

# $streamWriter.Close()


#Write-Host (Get-Date).ToString('MM-dd-yyyy.hhmmss')

$exe   = "$PSScriptRoot\files\AESTool.exe"
$args  = @("-e", $CertificatePasswordNewContent)

# Check if the file exists
if (-Not (Test-Path $vcInstallerPath)) {
    Write-Error "Installer not found at $vcInstallerPath"
    exit 1
}

# Start the installer process
Start-Process -FilePath $vcInstallerPath -ArgumentList $arguments -Wait -NoNewWindow

# 2>&1 會把 stderr 也導到 stdout，一起收回
$output = & $exe @args 2>&1

$EncPwd = $output.Split(':')[1].Trim()
# Write-Host $EncPwd

Unblock-File -Path $PSScriptRoot\files\System.Data.SQLite.dll
Unblock-File -Path $PSScriptRoot\files\System.Data.SQLite.dll
# 匯入 SQLite DLL
Add-Type -Path "$PSScriptRoot\files\System.Data.SQLite.dll"

# 建立 SQLite 連線
$connectionString = "Data Source=C:\mfaproxy-setting\sqliteDB.sqlite;Version=3;"
$connection = New-Object System.Data.SQLite.SQLiteConnection($connectionString)
$connection.Open()

$command = $connection.CreateCommand()
$command.CommandText = "UPDATE ProxtConfig SET MichCredentialID = '$CertificateNewContent';"
$rowsAffected = $command.ExecuteNonQuery()

$command = $connection.CreateCommand()
$command.CommandText = "UPDATE ProxtConfig SET MichCredentialPwd = '$EncPwd';"
$rowsAffected = $command.ExecuteNonQuery()

$command = $connection.CreateCommand()
$command.CommandText = "UPDATE ProxtConfig SET MichCustomerID = '$icpUser';"
$rowsAffected = $command.ExecuteNonQuery()

$command = $connection.CreateCommand()
$command.CommandText = "UPDATE ProxtConfig SET CustomerApiUsername = '$CustomerIdNewContent|$icpUser';"
$rowsAffected = $command.ExecuteNonQuery()

$command = $connection.CreateCommand()
$command.CommandText = "UPDATE ProxtConfig SET CustomerApiPassword = '$EncPwd';"
$rowsAffected = $command.ExecuteNonQuery()

$command = $connection.CreateCommand()
$command.CommandText = "UPDATE ProxtConfig SET ClientApiUsername = '$CustomerIdNewContent|$icpUser';"
$rowsAffected = $command.ExecuteNonQuery()

$command = $connection.CreateCommand()
$command.CommandText = "UPDATE ProxtConfig SET ClientApiPassword = '$EncPwd';"
$rowsAffected = $command.ExecuteNonQuery()

$command = $connection.CreateCommand()
$command.CommandText = "UPDATE ProxtConfig SET ClientApi = 'https//$endPointNewContent/api/clientapi/5';"
$rowsAffected = $command.ExecuteNonQuery()

$command = $connection.CreateCommand()
$command.CommandText = "UPDATE UserAccount SET MfaProxyAccPwd = '$EncPwd' WHERE MfaProxyAccount = 'kpadmin';"
$rowsAffected = $command.ExecuteNonQuery()

# 關閉連線
$connection.Close()
Write-Host "Operation complete!"