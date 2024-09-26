@description('Specify a virtual network name')
param name string

@description('Specify location of the Container Registry')
param location string = resourceGroup().location

@description('Specify one or more address prefixes')
param addressPrefixes array

@description('Specify one or more subnets')
param subnets array = []

@description('Specify dns servers')
param dnsServers array = []

@description('Specfy the existing vNet tags if vNet pre-exists so they are not erased. This is a workarround because of bicep limitation')
param tags object = {}

resource vNet 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
    subnets: subnets
    dhcpOptions: length(dnsServers) > 0 ? { dnsServers: dnsServers } : {}
  }
}

output resId string = vNet.id
output res object = vNet
