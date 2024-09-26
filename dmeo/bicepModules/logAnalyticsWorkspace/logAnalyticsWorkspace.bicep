@description('Specify the log analytics worksapce name')
param name string

@description('Specify the log analytics worksapce location')
param location string = resourceGroup().location

@description('Specify the log analytics worksapce data retention in days')
param retentionInDays int = 180

@description('Specfy the tags')
param tags object = {}

resource laws 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    retentionInDays: retentionInDays
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

output resId string = laws.id
output res object = laws
