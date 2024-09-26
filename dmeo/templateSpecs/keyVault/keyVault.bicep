targetScope = 'subscription'

metadata displayName = 'Azure Key Vault'
metadata version = '1.0.0'
metadata releaseNotes = 'Initial release'
metadata description = 'Template for deploying azure key vault in Azure Landing Zone'

@description('Specify the number of the respective Change')
param changeId string

@description('Specify the name of the Key Vault')
param name string

@description('Specify the name of the resourceGroup where the key vault will be deployed')
param resourceGroupName string

@description('Specify the subnet for the key vault private connectivity')
param subnetResourceId string

@description('Enable or disable the Key Vault for deployments')
@allowed([true, false])
param enabledForDeployment bool = false

@description('Enable or disable the Key Vault for disk encryption')
@allowed([true, false])
param enabledForDiskEncryption bool = false

@description('Enable or disable the key vault for template Deployments')
@allowed([true, false])
param enabledForTemplateDeployment bool = false

@description('Allow trusted azure services to bypass the firewall')
param allowAzureServices bool = false

@description('Select the SKU for the Key Vault')
@allowed(['standard', 'premium'])
param sku string = 'standard'

@description('Specify the environment name')
@allowed(['demo'])
param environmentType string = 'demo'

var environmentConfig = loadJsonContent('../../config/environment.jsonc')
var hubRgName = environmentConfig[environmentType].azure.hubRgName
var keyVaultPrivateEndpointName = 'pe-${name}'

resource hubLaws 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: environmentConfig[environmentType].azure.hubLawsName
  scope: resourceGroup(hubRgName)
}

resource vnet 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {
  name: split(subnetResourceId, '/')[8]
  scope: resourceGroup(split(subnetResourceId, '/')[2], split(subnetResourceId, '/')[4])
}

module keyVaultRg '../../bicepModules/resourceGroup/resourceGroup.bicep' = {
  name: 'deploy-rg-${resourceGroupName}'
  params: {
    name: resourceGroupName
    location: environmentConfig[environmentType].azure.location
    tags: {
      changeId: changeId
    }
  }
  scope: subscription()
}

module keyVault '../../bicepModules/keyVault/keyVault.bicep' = {
  name: 'deploy-keyVault'
  params: {
    name: name
    location: environmentConfig[environmentType].azure.location
    lawsResourceId: hubLaws.id
    sku: sku
    enabledForDeployment: enabledForDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enabledForTemplateDeployment: enabledForTemplateDeployment
    allowAzureServices: allowAzureServices
    tags: {
      changeId: changeId
    }
  }
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    keyVaultRg
  ]
}

module keyVaultPrivateDnsZone '../../bicepModules/privateDnsZone/privateDnsZone.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'deploy-pdnsz-vaultcore'
  params: {
    name: 'privatelink.vaultcore.azure.net'
    vnetResourceIds: [
      vnet.id
    ]
  }
  dependsOn: [
    keyVaultRg
  ]
}

module keyVaultPrivateEndpoint '../../bicepModules/privateEndpoint/privateEndpoint.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'deploy-pe-${keyVaultPrivateEndpointName}'
  params: {
    name: keyVaultPrivateEndpointName
    location: environmentConfig[environmentType].azure.location
    privateLinkGroupId: ['vault']
    privateLinkResourceId: keyVault.outputs.resId
    subnetResourceId: subnetResourceId
    privateDnsZoneResourceId: keyVaultPrivateDnsZone.outputs.resId
  }
}

output resId string = keyVault.outputs.resId
