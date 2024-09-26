targetScope = 'subscription'

metadata displayName = 'Azure Sql Server'
metadata version = '1.0.0'
metadata releaseNotes = 'Initial release'
metadata description = 'Template for deploying azure sql server in Azure Landing Zone'

@description('Specify the number of the respective Change')
param changeId string

@description('Specify the name of the Sql server')
param name string

@description('Specify the name of the resourceGroup where sql server will be deployed')
param resourceGroupName string

@description('Specify the name of the Azure AD group that will have administrative permissions on the sql server')
param sqlAadAdministratorGroupName string

@description('Specify the objectId of the Azure AD group that will have administrative permissions on the sql server')
param sqlAadAdministratorGroupObjectId string

@description('Specify the subnet for sql server private connectivity')
param subnetResourceId string

@description('Specify the customer managed key vault resource id that will be used for transperant data encryption')
param tdeKeyVaultResourceId string

@description('Specify the customer managed key vault key name that will be used for transperant data encryption')
param tdeKeyVaultKeyName string

@description('Specify the environment name')
@allowed(['demo'])
param environmentType string = 'demo'

var environmentConfig = loadJsonContent('../../config/environment.jsonc')
var hubRgName = environmentConfig[environmentType].azure.hubRgName
var sqlServerPrivateEndpointName = 'pe-${name}'

resource hubLaws 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: environmentConfig[environmentType].azure.hubLawsName
  scope: resourceGroup(hubRgName)
}

module sqlServerRg '../../bicepModules/resourceGroup/resourceGroup.bicep' = {
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

module sqlServer '../../bicepModules/sqlServer/sqlServer.bicep' = {
  name: 'deploy-sqlServer'
  params: {
    administratorAadGroupName: sqlAadAdministratorGroupName
    administratorAadGroupId: sqlAadAdministratorGroupObjectId
    tags: {
      changeId: changeId
    }
    lawsResourceId: hubLaws.id
    name: name
    location: environmentConfig[environmentType].azure.location
  }
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    sqlServerRg
  ]
}

module keyVaultAccessPolicy '../../bicepModules/keyVaultAccessPolicy/keyVaultAccessPolicy.bicep' = {
  name: 'update-keyVaultAccessPolicy'
  params: {
    keyVaultName: split(tdeKeyVaultResourceId, '/')[8]
    changeType: 'add'
    accessPolicies: [
      {
        tenantId: tenant().tenantId
        objectId: sqlServer.outputs.res.identity.principalId
        permissions: {
          keys: [
            'Get'
            'WrapKey'
            'UnwrapKey'
          ]
        }
      }
    ]
  }
  scope: resourceGroup(split(tdeKeyVaultResourceId, '/')[2], split(tdeKeyVaultResourceId, '/')[4])
}

module sqlServerUpdate '../../bicepModules/sqlServer/sqlServer.bicep' = {
  name: 'update-sqlServer'
  params: {
    administratorAadGroupName: sqlAadAdministratorGroupName
    administratorAadGroupId: sqlAadAdministratorGroupObjectId
    lawsResourceId: hubLaws.id
    name: name
    location: environmentConfig[environmentType].azure.location
    tdeSettings: {
      enabled: true
      keyVaultResourceId: tdeKeyVaultResourceId
      keyName: tdeKeyVaultKeyName
    }
    tags: {
      changeId: changeId
    }
  }
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    keyVaultAccessPolicy
  ]
}

module sqlServerPrivateEndpoint '../../bicepModules/privateEndpoint/privateEndpoint.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'deploy-sqlServerPrivateEndpoint'
  params: {
    name: sqlServerPrivateEndpointName
    location: environmentConfig[environmentType].azure.location
    privateLinkGroupId: ['sqlServer']
    privateLinkResourceId: sqlServer.outputs.resId
    subnetResourceId: subnetResourceId
  }
}

output resId string = sqlServer.outputs.resId
