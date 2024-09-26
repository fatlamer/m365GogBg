@description('Set the local VNet name')
param vnetName string

@description('Set the remote VNet name')
param remoteVnetName string

@description('Sets the remote VNet Resource group')
param remoteVnetRgName string

@description('Whether the VMs in the local virtual network space would be able to access the VMs in remote virtual network space.')
param allowVirtualNetworkAccess bool

@description('Whether the forwarded traffic from the VMs in the local virtual network will be allowed/disallowed in remote virtual network.')
param allowForwardedTraffic bool

@description('If gateway links can be used in remote virtual networking to link to this virtual network.')
param allowGatewayTransit bool

@description('If remote gateways can be used on this virtual network. If the flag is set to true, and allowGatewayTransit on remote peering is also true, virtual network will use gateways of remote virtual network for transit. Only one peering can have this flag set to true. This flag cannot be set if virtual network already has a gateway.')
param useRemoteGateways bool

resource vnet 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: vnetName
}

resource remoteVnet 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: remoteVnetName
  scope: resourceGroup(remoteVnetRgName)
}

resource vnetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-02-01' = {
  name: '${vnetName}-${remoteVnetName}'
  parent: vnet
  properties: {
    allowVirtualNetworkAccess: allowVirtualNetworkAccess
    allowForwardedTraffic: allowForwardedTraffic
    allowGatewayTransit: allowGatewayTransit
    useRemoteGateways: useRemoteGateways
    remoteVirtualNetwork: {
      id: remoteVnet.id
    }
  }
}

output resId string = vnetPeering.id
output res object = vnetPeering
