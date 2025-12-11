# Accept the input parameter
param (
    [string]$pfxPath,
	[string]$pfxPassword
)

# Path to the PFX file
# $pfxPath = ".\files\mypasscode-2024.pfx\mypasscode-2024.pfx"

# Password for the PFX file
 #$pfxPassword = "Lydsec"

#Write-Host "($pfxPath)"
#Write-Host $pfxPassword

# Load the PFX file as an X509Certificate2 object
$pfx = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
$pfx.Import($pfxPath, $pfxPassword, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable)

# Display the SHA-1 fingerprint
Write-Host "$($pfx.Thumbprint)"