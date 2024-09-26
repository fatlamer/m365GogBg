@description('Specify name of Container Registry')
param name string

@description('Specify location of the Container Registry')
param location string = resourceGroup().location

@description('Specify the resourceId of the subnet where private endpoint will be created')
param subnetResourceId string

@description('Specify the resourceId of the resource this private endpoints connects to')
param privateLinkResourceId string

@description('Specify the groupIds of the resource this private endpoints connects to')
param privateLinkGroupId array

@description('Specify the resourceId of private dns zone if you want to automatically create A record there')
param privateDnsZoneResourceId string = ''

resource vnet 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {
  name: split(subnetResourceId, '/')[8]
  scope: resourceGroup(split(subnetResourceId, '/')[2], split(subnetResourceId, '/')[4])
}

resource snet 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' existing = {
  name: split(subnetResourceId, '/')[10]
  parent: vnet
}

resource pe 'Microsoft.Network/privateEndpoints@2022-01-01' = {
  name: name
  location: location
  properties: {
    subnet: {
      id: snet.id
    }
    privateLinkServiceConnections: [
      {
        name: name
        properties: {
          groupIds: privateLinkGroupId
          privateLinkServiceId: privateLinkResourceId
        }
      }
    ]
  }
}

resource pdnsz 'Microsoft.Network/privateDnsZones@2020-06-01' existing = if (!(empty(privateDnsZoneResourceId))) {
  name: split(privateDnsZoneResourceId, '/')[8]
  scope: resourceGroup(split(privateDnsZoneResourceId, '/')[2], split(privateDnsZoneResourceId, '/')[4])
}

resource pezg 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-01-01' = if (!(empty(privateDnsZoneResourceId))) {
  name: 'default'
  parent: pe
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${pe.name}-${pdnsz.name}'
        properties: {
          privateDnsZoneId: pdnsz.id
        }
      }
    ]
  }
}

output resId string = pe.id
output res object = pe
