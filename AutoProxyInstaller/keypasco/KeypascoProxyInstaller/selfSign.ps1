#param (
#	[string]$DnsName,
#	[string]$CertPassword
#)

#Write-Host $PSCmdlet.MyInvocation.BoundParameters.Count -ForegroundColor Green
#Write-Host $args.Count -ForegroundColor Green
#exit 1

#if ($args.Count -ne 2) {
#	Write-Host "Error: You must provide exactly 2 parameters." -ForegroundColor Red
#	Write-Host "    self_sign.ps1 domain_name cert_password" -ForegroundColor Green
#	exit 1
#}

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

# $DnsName = $($args[0])
$CertPassword = $($args[1])

# $DnsName = Read-Host "DNS name for self-signed certificate"
# $CertEncryPassword = Read-Host "certificate password" -AsSecureString

# $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($CertEncryPassword)
# $CertPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
$CertPassword = "I5JVFvB%M'"

# certificate parameters
$certName = "selfSignedCert"
$certFile = ".\files\self_signed.pfx"
$password = ConvertTo-SecureString -String "$CertPassword" -Force -AsPlainText

# generate self signed certificate
$cert = New-SelfSignedCertificate `
     -DnsName "$DnsName" `
	 -NotAfter (Get-Date).AddYears(5) `
	 -CertStoreLocation "Cert:\LocalMachine\My"

# move cert from My folder to Root folder
Move-Item -Path "Cert:\LocalMachine\My\$($cert.Thumbprint)" -Destination "Cert:\LocalMachine\Root"

# export pfx certificate
Export-PfxCertificate -Cert $cert -FilePath $certFile -Password $password

Write-Host "Self Signed Certificate: $certFile"

# convert to base64 for special character(!@#$)
#$Bytes = [System.Text.Encoding]::UTF8.GetBytes($CertPassword)
#$Base64 = [Convert]::ToBase64String($Bytes)
Write-Output "$CertPassword $DnsName"