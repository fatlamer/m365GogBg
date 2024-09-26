@description('Specify the name of the key vault')
param name string

@description('Specify location of the key vault')
param location string = resourceGroup().location

@description('Specify the resource id of the log analytics workspace that will be used for diagnostic purposes')
param lawsResourceId string

@description('Specify the initial access policy for the key vault')
param accessPolicies array = []

@description('Enable or disable the Key Vault for deployments')
@allowed([ true, false ])
param enabledForDeployment bool = false

@description('Enable or disable the Key Vault for disk encryption')
@allowed([ true, false ])
param enabledForDiskEncryption bool = false

@description('Enable or disable the key vault for template Deployments')
@allowed([ true, false ])
param enabledForTemplateDeployment bool = false

@description('Allow trusted azure services to bypass the firewall')
param allowAzureServices bool = false

@description('Select the SKU for the Key Vault')
@allowed([ 'standard', 'premium' ])
param sku string = 'standard'

@description('Specfy the tags')
param tags object = {}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    accessPolicies: accessPolicies
    createMode: 'default'
    enabledForDeployment: enabledForDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enabledForTemplateDeployment: enabledForTemplateDeployment
    enablePurgeProtection: true
    enableSoftDelete: true
    provisioningState: 'string'
    publicNetworkAccess: 'disabled'
    sku: {
      family: 'A'
      name: sku
    }
    softDeleteRetentionInDays: 90
    tenantId: subscription().tenantId
    networkAcls: {
      bypass: allowAzureServices ? 'AzureServices' : 'None'
      defaultAction: 'Deny'
    }
  }
}

resource keyVaultDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: keyVault
  name: '${name}-dgs'
  properties: {
    workspaceId: lawsResourceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
}

output resId string = keyVault.id
output res object = keyVault
