# Thycotic.Secret.Server
Powershell module for Thycotic Secret Server

Example
=============
```
$cred = Get-Credential 
Connect-Tss -address my_secret_server_address -credential $cred
Get-TssSubFolder | Get-TssSecretInFolder
Get-TssSubFolder | Get-TssSecretInFolder | Get-TssSecret
