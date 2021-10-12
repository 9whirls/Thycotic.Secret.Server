function Connect-TSS {
  param(
    [Parameter(Mandatory = $true)]
    [string] 
      $fqdn,
    [Parameter(Mandatory = $true)]
    [pscredential] 
      $credential,
    [Parameter(Mandatory = $true)]  
    [string]
      $domain
  )
  
  [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
  [Net.ServicePointManager]::SecurityProtocol = 'Tls12'
  $proxy = New-WebServiceProxy -uri "https://$fqdn/webservices/sswebservice.asmx" -UseDefaultCredential -Namespace "ss"
  $proxy.CookieContainer = New-Object System.Net.CookieContainer
  $token = $proxy.authenticate($Credential.UserName, 
    ($Credential.GetNetworkCredential()).Password, '', $domain) | select -expandproperty token
  
  $proxy | add-member -name 'token' -MemberType NoteProperty -value $token
  
  $Global:defaultTss = $proxy
  return $proxy
}

function Get-TssSubFolder {
  param(
    [Parameter(
      Helpmessage = 'Parent Folder ID'
    )]
    [int]
      $id = -1,
      
    $tss = $defaultTss
  )
  
  $folders = $tss.foldergetallchildren($defaulttss.token, $id) | select -ExpandProperty folders | ?{$_.id -ne 1}
  $folders
  foreach ($f in $folders) {
    Get-TssSubFolder $f.id $tss
  }  
}

function Get-TssSecretInFolder {
  param(
    [Parameter(
      Mandatory = $true,
      ValueFromPipeline = $true,
      ValueFromPipelineByPropertyName = $true,
      Helpmessage = 'Parent Folder ID'
    )]
    [int]
      $id,
   
    $tss = $defaultTss
  )
  begin {}
  process {
    $folderPath = Get-TssFolderPath $id $tss
    $tss.SearchSecretsByFolder($tss.token, '*', $id, $false, $false, $true) | 
      select -ExpandProperty secretsummaries |
      select *, @{ n='Path'; e={"{0}/{1}" -f $folderPath, $_.SecretName} }
  }
  end {}
}

function Get-TssFolderPath {
  param(
    [Parameter(
      Mandatory = $true,
      ValueFromPipeline = $true,
      ValueFromPipelineByPropertyName = $true
    )]
    [int]
      $Id,
      
    $tss = $defaultTss
  )
  begin {}
  process {
    $thisFolder = $tss.folderGet($tss.token, $id) | select -ExpandProperty folder
    if ($thisFolder.parentFolderId -eq -1) {$thisFolder.name}
    else { 
      (Get-TssFolderPath $thisFolder.parentFolderId) + "/" + $thisFolder.name
    }
  }
  end {}
}

function Get-TssSecretData {
  param(
    [Parameter(
      Mandatory = $true,
      ValueFromPipeline = $true,
      ValueFromPipelineByPropertyName = $true,
      Helpmessage = 'Secret ID'
    )]
    [int]
      $SecretId,
   
    $tss = $defaultTss
  )
  begin {}
  process {
    $tss.GetSecretLegacy($tss.token, $SecretId) | select -ExpandProperty secret
  }
  end {}
}

function Get-TssRestToken {
  param(
    [Parameter(Mandatory = $true)]
    [string] 
      $fqdn,
    [Parameter(Mandatory = $true)]
    [pscredential] 
      $credential
  )
  
  [Net.ServicePointManager]::SecurityProtocol = 'Tls12'
  $uri = "https://$fqdn/oauth2/token"
  $data = @{
    'username' = $Credential.UserName
    'password' = ($Credential.GetNetworkCredential()).Password
    'grant_type' = 'password' 
  }
  return (Invoke-RestMethod -Uri $uri -Method Post -body $data).access_token
}

function Get-TssRestSecretPassword {
  param(
    [Parameter(Mandatory = $true)]
    [string] 
      $fqdn,
    [Parameter(Mandatory = $true)]
    [string] 
      $token,
    [Parameter(Mandatory = $true)]
    [string]
      $secretId
  )
  
  [Net.ServicePointManager]::SecurityProtocol = 'Tls12'
  $uri = "https://$fqdn/api/v1/secrets/$secretId/fields/Password"
  $head = @{
    'Authorization' = "Bearer $token" 
  }
  return (Invoke-RestMethod -Uri $uri -Method Get -Headers $head)
}
