@description('Specify the virtual network resource id.')
param vnetName string

@description('Specify the subnet address prefix.')
param subnetPrefix string

@description('Specify the subnet name.')
param subnetName string

@description('Specify the route table resource id for this subnet')
param routeTableResourceId string = ''

@description('Specify the NSG resource Id for this subnet')
param nsgId string = ''

@description('Specify delegations for this subnet')
param delegations array = []

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-06-01' existing = {
  name: vnetName
}

resource vSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-05-01' = {
  name: subnetName
  parent: virtualNetwork
  properties: {
    addressPrefix: subnetPrefix
    routeTable: (routeTableResourceId == '' ? null : {
      id: routeTableResourceId
    })
    networkSecurityGroup: (nsgId == '' ? null : {
      id: nsgId
    })
    delegations: [for delegation in delegations: {
      name: delegation
      properties: {
        serviceName: delegation
      }
    }]
  }
}

output resId string = vSubnet.id
output res object = vSubnet
