if ($env:SKIP_CERTIFICATE_CHECK -eq 'true') {
  $global:scc = $true
} else {
  $global:scc = $false
}

function Connect-TSS {
  param(
    [Parameter(Mandatory = $true)]
    [string] 
      $address,
    [Parameter(Mandatory = $true)]
    [pscredential] 
      $credential
  )

  $uri = "https://$address/oauth2/token"
  $data = @{
    'username' = $Credential.UserName
    'password' = ($Credential.GetNetworkCredential()).Password
    'grant_type' = 'password' 
  }

  $token = Invoke-RestMethod -Uri $uri -Method Post -body $data -SkipCertificateCheck:$scc | 
    select -expandproperty access_token
  
  $tss = new-object PSObject -Property @{
    address = $address
    head = @{
      'Authorization' = "Bearer $token" 
    }
  }
  
  $Global:defaultTss = $tss
  return $tss
}

function Get-TssSubFolder {
  param(
    [Parameter(
      Helpmessage = 'Parent Folder ID'
    )]
    [int] $parentFolderId = -1,

    [int] $take = [int32]::MaxValue,

    $tss = $defaultTss
  )
  
  $uri = "https://$($tss.address)/api/v1/folders?filter.parentFolderId=$parentFolderId&take=$take"
  
  Invoke-RestMethod -Uri $uri -Method Get -Headers $tss.head -SkipCertificateCheck:$scc |
    select -ExpandProperty records
}

function Get-TssFolder {
  param(
    [Parameter(
      Helpmessage = 'Folder ID',
      Mandatory = $true
    )]
    [int] $id,

    $tss = $defaultTss
  )
  
  $uri = "https://$($tss.address)/api/v1/folders/$id"
  
  Invoke-RestMethod -Uri $uri -Method Get -Headers $tss.head -SkipCertificateCheck:$scc
}

function Get-TssFolderPermission {
  param(
    [Parameter(
      Helpmessage = 'Folder ID',
      Mandatory = $true
    )]
    [int] $id,

    $tss = $defaultTss
  )
  
  $uri = "https://$($tss.address)/api/v1/folder-permissions?filter.folderId=$id"
  
  Invoke-RestMethod -Uri $uri -Method Get -Headers $tss.head -SkipCertificateCheck:$scc |
    select -ExpandProperty records
}

function Get-TssSecretInFolder {
  param(
    [Parameter(
      Mandatory = $true,
      ValueFromPipeline = $true,
      ValueFromPipelineByPropertyName = $true,
      Helpmessage = 'Parent Folder ID'
    )]
    [int] $id,

    [int] $take = [int32]::MaxValue,

    $tss = $defaultTss
  )
  begin {}
  process {
    $uri = "https://$($tss.address)/api/v1/secrets?filter.folderId=$id&take=$take"
    $folderPath = Get-TssFolder $id $tss | select -ExpandProperty folderPath
    Invoke-RestMethod -Uri $uri -Method Get -Headers $tss.head -SkipCertificateCheck:$scc |
      select -ExpandProperty records |
      select *, @{ n='path'; e={"{0}\{1}" -f $folderPath, $_.name} }
  }
  end {}
}

function Get-TssSecret {
  param(
    [Parameter(
      Mandatory = $true,
      ValueFromPipeline = $true,
      ValueFromPipelineByPropertyName = $true,
      Helpmessage = 'Secret ID'
    )]
    [int]
      $id,

    $tss = $defaultTss
  )
  begin {}
  process {
    $uri = "https://$($tss.address)/api/v1/secrets/$id"
  
    Invoke-RestMethod -Uri $uri -Method Get -Headers $tss.head -SkipCertificateCheck:$scc
  }
  end {}
}

function Get-TssSecretPassword {
  param(
    [Parameter(Mandatory = $true)]
    [int]
      $id,

    $tss = $defaultTss
  )
  
  $uri = "https://$($tss.address)/api/v1/secrets/$id/fields/Password"
  
  Invoke-RestMethod -Uri $uri -Method Get -Headers $tss.head -SkipCertificateCheck:$scc
}
