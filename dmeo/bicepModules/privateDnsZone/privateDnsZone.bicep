@description('Specify name of Container Registry')
param name string

@description('Specify virtual network resource Ids to link the zone to')
param vnetResourceIds array = []

@description('Specfy the tags')
param tags object = {}

//deploy private dns zone
resource pdnsz 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: name
  location: 'global'
  tags: tags
}

resource pdnszvnetlink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for vnetResId in vnetResourceIds: {
  name: 'pdnszl-${name}-${split(vnetResId, '/')[8]}'
  location: 'global'
  parent: pdnsz
  properties: {
    virtualNetwork: {
      id: vnetResId
    }
    registrationEnabled: false
  }
}]

output resId string = pdnsz.id
output res object = pdnsz
