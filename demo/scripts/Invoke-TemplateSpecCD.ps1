<#
.SYNOPSIS
Invoke the Continuous Delivery script for particular Template Spec

.DESCRIPTION
Invoke the Continuous Delivery script for particular Template Spec. It will publish the template spec to specified environment

.PARAMETER TemplateSpecName
Specify the bicep solution name that should be a folder underneath the /src folder

.PARAMETER EnvironmentType
Specify the environment name. Should be key from the EnvironmentFile document

.EXAMPLE
./Invoke-TemplateSpecCD TemplateSpecName <name of the template spec>

#>
[CmdletBinding(DefaultParameterSetName = 'local')]
param
(
  [Parameter(Mandatory)]
  [ArgumentCompleter(
    {
      param(
        [Parameter()]
        $CmdName,

        [Parameter()]
        $ParamName,

        [Parameter()]
        $WordToComplete
      )

      $tsPath = Split-Path -Path $PSScriptRoot -Parent | Join-Path -ChildPath templateSpecs -AdditionalChildPath "${WordToComplete}*"
      (Get-ChildItem -Path $tsPath -Directory).BaseName
    }
  )]
  [ValidateScript(
    {
      $tsPath = Split-Path -Path $PSScriptRoot -Parent | Join-Path -ChildPath templateSpecs
      $_ -in (Get-ChildItem -Path $tsPath -Directory).BaseName
    }
  )]
  [string] $TemplateSpecName,

  [Parameter()]
  [ValidateSet('demo')]
  [string] $EnvironmentType = 'demo'
)

#variables
$repoRoot = Split-Path -Path $PSScriptRoot -Parent
$configPath = Join-Path -Path $repoRoot -ChildPath config

#Get environment settings
$environmentFilePath = Join-Path -Path $configPath 'environment.jsonc'
$environmentConfigAsJson = Get-Content -Path $environmentFilePath -Raw -ErrorAction Stop
$environmentConfig = $environmentConfigAsJson | ConvertFrom-Json -AsHashtable -Depth 20 -ErrorAction Stop
$tenantId = $environmentConfig[$EnvironmentType].azure.tenantId
$subscriptionId = $environmentConfig[$EnvironmentType].azure.subscriptionId
$templateSpecsResourceGroup = $environmentConfig[$EnvironmentType].azure.templateSpecsRgName

#Install required modules
Write-Information -MessageData 'Install required modules'
Install-PSResource -RequiredResource @{
  'Az.Resources' = @{
    Version    = '7.4.0'
    Repository = 'PSGallery'
  }
  Bicep          = @{
    version    = '2.6.1'
    repository = 'PSGallery'
  }
} -Quiet -AcceptLicense -TrustRepository -Scope CurrentUser -ErrorAction Stop

#connect to azure
$null = Disable-AzContextAutosave -Scope Process
$existingAzContexts = Get-AzContext -ListAvailable
if ($existingAzContexts.Name -contains "local-$tenantId") {
  $currentContext = Select-AzContext -Name "local-$tenantId"
  if ($currentContext.Subscription.id -ne $SubscriptionId) {
    Set-AzContext -SubscriptionId $SubscriptionId
  }
}
else {
  $connectAzAccountParams = @{
    TenantId                = $TenantId
    SkipContextPopulation = $true
    Scope                 = 'Process'
    SubscriptionId        = $SubscriptionId
    ContextName           = "local-$tenantId"
  }
  $null = Connect-AzAccount @connectAzAccountParams -ErrorAction Stop
}

#Publish new template spec
$templateSpecFolderPath = Join-Path -Path $repoRoot -ChildPath 'templateSpecs' -AdditionalChildPath $TemplateSpecName
$templateSpecFilePath = Join-Path -Path $templateSpecFolderPath -ChildPath "${TemplateSpecName}.bicep"
$templateSpecUIFilePath = Join-Path -Path $templateSpecFolderPath -ChildPath "${TemplateSpecName}.ui.jsonc"
$templateSpecMetadata = Get-BicepMetadata -Path $templateSpecFilePath -OutputType Hashtable
$newAzTemplateSpecParams = @{
  ResourceGroupName  = $templateSpecsResourceGroup
  Name               = $TemplateSpecName
  TemplateFile       = $templateSpecFilePath
  Version            = $templateSpecMetadata['version']
  Description        = $templateSpecMetadata['description']
  DisplayName        = $templateSpecMetadata['displayName']
  VersionDescription = $templateSpecMetadata['releaseNotes']
  Location           = 'northeurope'
}
if (Test-Path -Path $templateSpecUIFilePath) {
  $newAzTemplateSpecParams += @{
    UIFormDefinitionString = Get-Content -Path $templateSpecUIFilePath -Raw -ErrorAction Stop
  }
}
New-AzTemplateSpec @newAzTemplateSpecParams -ErrorAction Stop
