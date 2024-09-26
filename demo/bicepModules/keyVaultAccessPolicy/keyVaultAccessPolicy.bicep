@description('Specify KeyVault name')
param keyVaultName string

@description('Specify access policies')
param accessPolicies array

@description('Specify the type of access policy change to make, add, remove, or replace')
@allowed([ 'add', 'remove', 'replace' ])
param changeType string

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource keyVaultPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2022-07-01' = {
  name: changeType
  parent: keyVault
  properties: {
    accessPolicies: accessPolicies
  }
}
