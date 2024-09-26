targetScope = 'subscription'

@description('Specify name of Resource Group')
param name string

@description('Specify location of the Resource Group')
param location string

@description('Specfy the tags')
param tags object = {}

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: name
  location: location
  tags: tags
}

output resId string = rg.id
output res object = rg
