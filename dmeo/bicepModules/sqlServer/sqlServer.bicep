@description('Specify the name of the Sql server')
param name string

@description('Specify location of the Container Registry')
param location string = resourceGroup().location

@description('Specify the Name the Azure AD group that will have administrative permissions on the sql server')
param administratorAadGroupName string

@description('Specify the id the Azure AD group that will have administrative permissions on the sql server')
param administratorAadGroupId string

@description('Specify the transperant data encryption with customer managed key settings. Expected properties are: enabled, keyVaultResourceId, keyName, sqlServerPrincipalId')
param tdeSettings object = {
  enabled: false
  keyVaultResourceId: 'bogus'
  keyName: 'bogus'
}

@description('Specify the resource id of the log analytics workspace that will be used for diagnostic purposes')
param lawsResourceId string

@description('Specfy the tags')
param tags object = {}

resource tdeKeyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = if (tdeSettings.enabled) {
  name: split(tdeSettings.keyVaultResourceId, '/')[8]
  resource tdeKey 'keys@2023-02-01' existing = {
    name: tdeSettings.keyName
    resource keyVer 'versions@2023-02-01' existing = {
      name: split(tdeKeyVault::tdeKey.properties.keyUriWithVersion, '/')[5]
    }
  }
  scope: resourceGroup(split(tdeSettings.keyVaultResourceId, '/')[2], split(tdeSettings.keyVaultResourceId, '/')[4])
}

resource sqlserver 'Microsoft.Sql/servers@2021-11-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    administrators: {
      administratorType: 'ActiveDirectory'
      azureADOnlyAuthentication: true
      principalType: 'Group'
      login: administratorAadGroupName
      sid: administratorAadGroupId
      tenantId: tenant().tenantId
    }
    keyId: (tdeSettings.enabled ? tdeKeyVault::tdeKey.properties.keyUriWithVersion : null)
    publicNetworkAccess: 'Disabled'
    minimalTlsVersion: '1.2'
    restrictOutboundNetworkAccess: 'Enabled'
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource sqlServerEncProtector 'Microsoft.Sql/servers/encryptionProtector@2021-11-01' = if (tdeSettings.enabled) {
  name: 'current'
  parent: sqlserver
  properties: {
    autoRotationEnabled: true
    serverKeyType: 'AzureKeyVault'
    serverKeyName: tdeSettings.enabled ? '${tdeKeyVault.name}_${tdeSettings.keyName}_${tdeKeyVault::tdeKey::keyVer.name}' : null
  }
}

resource sqlServerMasterDb 'Microsoft.Sql/servers/databases@2021-11-01' = {
  name: 'master'
  location: location
  parent: sqlserver
}

resource sqlserverMasterDbDiag 'microsoft.insights/diagnosticSettings@2021-05-01-preview' = {
  scope: sqlServerMasterDb
  name: '${sqlServerMasterDb.name}-dgs'
  properties: {
    workspaceId: lawsResourceId
    logs: [
      {
        category: 'SQLSecurityAuditEvents'
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: false
        }
      }
    ]
  }
}

resource sqlServerDiagnostics 'Microsoft.Sql/servers/auditingSettings@2021-11-01' = {
  name: 'default'
  parent: sqlserver
  properties: {
    state: 'Enabled'
    auditActionsAndGroups: [
      'BATCH_COMPLETED_GROUP'
      'SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP'
      'FAILED_DATABASE_AUTHENTICATION_GROUP'
    ]
    isAzureMonitorTargetEnabled: true
  }
}

resource sqlServerDefender 'Microsoft.Sql/servers/securityAlertPolicies@2021-11-01' = {
  name: 'sqlServerDefenderSettings'
  parent: sqlserver
  properties: {
    state: 'Enabled'
  }
}

output resId string = sqlserver.id
output res object = sqlserver
