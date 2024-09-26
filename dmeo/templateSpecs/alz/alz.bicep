targetScope = 'subscription'

metadata displayName = 'Azure Landing Zone'
metadata version = '1.0.1'
metadata releaseNotes = 'Add Custom UI'
metadata description = 'Template for deploying azure landing zones in my company'

@description('Specify the environment name')
@allowed(['demo'])
param environmentType string = 'demo'

@description('Specify the number of the respective Change')
param changeId string

@description('Specify the name of the resource group')
param name string

@description('Specify the ipaddress range of the spoke network')
param ipAddressRange string

@description('Sets the lifespan of the spoke resources in days')
@minValue(1)
@maxValue(90)
param expiryTime int

@description('Gets current time')
param dateTime string = utcNow('d')

var environmentConfig = loadJsonContent('../../config/environment.jsonc')
var addDays = dateTimeAdd(dateTime, 'P${expiryTime}D', 'd')
var rgName = 'alz-${name}-spoke'
var vNetName = 'alz-${name}-vnet-01'
var subnetName = 'alz-${name}-sn-01'

resource hubRg 'Microsoft.Resources/resourceGroups@2023-07-01' existing = {
  name: environmentConfig[environmentType].azure.hubRgName
}

resource hubVnet 'Microsoft.ScVmm/virtualNetworks@2024-06-01' existing = {
  name: environmentConfig[environmentType].azure.hubVnetName
  scope: hubRg
}

module alzRg '../../bicepModules/resourceGroup/resourceGroup.bicep' = {
  name: 'deploy-rg-${rgName}'
  params: {
    name: rgName
    location: environmentConfig[environmentType].azure.location
    tags: {
      changeId: changeId
      expiresOn: addDays
    }
  }
}

module spokeVnet '../../bicepModules/virtualNetwork/virtualNetwork.bicep' = {
  name: 'deploy-vnet-${vNetName}'
  params: {
    name: vNetName
    tags: { changeId: changeId }
    location: environmentConfig[environmentType].azure.location
    addressPrefixes: [
      ipAddressRange
    ]
  }
  scope: resourceGroup(rgName)
  dependsOn: [
    alzRg
  ]
}

module spokeSubnet '../../bicepModules/subnet/subnet.bicep' = {
  name: 'deploy-subnet-${subnetName}'
  params: {
    subnetName: subnetName
    subnetPrefix: ipAddressRange
    vnetName: vNetName
  }
  scope: resourceGroup(rgName)
  dependsOn: [
    spokeVnet
  ]
}

module spokeAndHubPeering '../../bicepModules/vnetPeering/vnetPeering.bicep' = {
  name: 'deploy-peering-spokToHub'
  scope: resourceGroup(rgName)
  params: {
    vnetName: vNetName
    remoteVnetName: hubVnet.name
    remoteVnetRgName: hubRg.name
    allowForwardedTraffic: true
    allowGatewayTransit: false
    allowVirtualNetworkAccess: true
    useRemoteGateways: false
  }
  dependsOn: [
    spokeSubnet
  ]
}

module hubAndSpokePeering '../../bicepModules/vnetPeering/vnetPeering.bicep' = {
  name: 'deploy-peering-HubToSpoke'
  scope: hubRg
  params: {
    vnetName: hubVnet.name
    remoteVnetName: vNetName
    remoteVnetRgName: rgName
    allowForwardedTraffic: false
    allowGatewayTransit: false
    allowVirtualNetworkAccess: true
    useRemoteGateways: false
  }
  dependsOn: [
    spokeAndHubPeering
  ]
}
