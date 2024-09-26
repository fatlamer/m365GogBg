targetScope = 'subscription'

metadata displayName = 'Azure Platform Hub'
metadata version = '1.0.0'
metadata releaseNotes = 'Initial release'
metadata description = 'Template for deploying azure platform hub in my company'

@description('Specify the environment name')
@allowed(['demo'])
param environmentType string = 'demo'

@description('Specify the number of the respective Change')
param changeId string

@description('Specify the ipaddress range of the spoke network')
param ipAddressRange string

var environmentConfig = loadJsonContent('../../config/environment.jsonc')
var hubRgName = environmentConfig[environmentType].azure.hubRgName
var hubLawsName = environmentConfig[environmentType].azure.hubLawsName
var hubVnetName = environmentConfig[environmentType].azure.hubVnetName
var hubSubnetName = 'hub-${hubRgName}-sn-01'

module hubRg '../../bicepModules/resourceGroup/resourceGroup.bicep' = {
  name: 'deploy-rg-${hubRgName}'
  params: {
    name: hubRgName
    location: environmentConfig[environmentType].azure.location
    tags: { changeId: changeId }
  }
}

module hubVnet '../../bicepModules/virtualNetwork/virtualNetwork.bicep' = {
  name: 'deploy-vnet-${hubVnetName}'
  params: {
    name: hubVnetName
    tags: { changeId: changeId }
    location: environmentConfig[environmentType].azure.location
    addressPrefixes: [
      ipAddressRange
    ]
  }
  scope: resourceGroup(hubRgName)
  dependsOn: [
    hubRg
  ]
}

module hubSubnet '../../bicepModules/subnet/subnet.bicep' = {
  name: 'deploy-subnet-${hubSubnetName}'
  params: {
    subnetName: hubSubnetName
    subnetPrefix: ipAddressRange
    vnetName: hubVnetName
  }
  scope: resourceGroup(hubRgName)
  dependsOn: [
    hubVnet
  ]
}

module hubLaws '../../bicepModules/logAnalyticsWorkspace/logAnalyticsWorkspace.bicep' = {
  name: 'deploy-laws-${hubLawsName}'
  params: {
    name: hubLawsName
    location: environmentConfig[environmentType].azure.location
    retentionInDays: 180
    tags: {
      changeId: changeId
    }
  }
  scope: resourceGroup(hubRgName)
  dependsOn: [
    hubRg
  ]
}
