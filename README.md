# Thycotic.Secret.Server
Powershell module for Thycotic Secret Server

Example
=============
```
$cred = Get-Credential
Connect-Tss -fqdn my_secret_server_address -credential $cred -domain my_domain
Get-TssSubFolder | Get-TssSecretInFolder
Get-TssSubFolder | Get-TssSecretInFolder | Get-TssSecret
