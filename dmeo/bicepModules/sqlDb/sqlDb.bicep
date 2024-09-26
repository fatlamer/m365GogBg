@description('Specify the name of the Sql DB')
param name string

@description('Specify location of the SQL DB')
param location string = resourceGroup().location

@description('Specify the name of the logical sql server for the SQL DB')
param sqlServerName string

@description('Specify the SKU name for the SQL DB. For the DTU purchasing model the SKU name is Basic, Standard, or Premium. For the vCore purchasing model the SKU name includes the tier code (GP for GeneralPurpose, GP_S for Serverless, BC for BusinessCritical, or HS for Hyperscale) and the hardware family code (e.g. GP_Gen5).')
param sqlDbSkuName string

@description('Specify the backup storage redundancy for the SQL DB')
@allowed([ 'Geo', 'GeoZone', 'Local', 'Zone' ])
param sqlDbBackupStorageRedundancy string

@description('Specify the Min vCores for the SQL DB')
param sqlDbMinCapacity string

@description('Specify the the number of high-availability secondary replicas for the Hyperscale SQL DB')
param sqlDbHighAvailabilityReplicaCount int = 0

@description('Specify the Data Max Size in GB for the SQL DB')
param sqlDbMaxSizeGb string

@description('Specify the SQL DB will be zone-redundant')
param isZoneRedundant bool = false

@description('Specify the collation for the SQL DB')
param sqlDbCollation string = 'SQL_Latin1_General_CP1_CI_AS'

@description('Specify the resource id of the log analytics workspace that will be used for diagnostic purposes')
param lawsResourceId string

@description('Specify the differential backup interval (Hours) for the SQL DB. Can be 12 Hours or 24 Hours')
@allowed([ 12, 24 ])
param sqlDbDiffBackupIntervalInHours int = 12

@description('Specify the number of days for short-term backup retention.')
@minValue(1)
@maxValue(35)
param sqlDbRetentionDays int = 7

@description('Specify the monthly long-term retention (months)')
param sqlDbLtrMonthlyRetentionInMonths int = 0

@description('Enabled or Disable the read scale-out')
@allowed([ 'Enabled', 'Disabled' ])
param readScale string = 'Disabled'

@description('Specify the resource id of the maintenance Configuration that defines the period when the maintenance updates will occur')
param maintenanceConfigurationId string

@description('Specfy the tags')
param tags object = {}

var sqlDbMaxSizeBytes = json(sqlDbMaxSizeGb) * 1073741824

resource sqlServer 'Microsoft.Sql/servers@2021-11-01' existing = {
  name: sqlServerName
}

resource sqlDb 'Microsoft.Sql/servers/databases@2021-11-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: sqlDbSkuName
  }
  parent: sqlServer
  properties: {
    readScale: readScale
    autoPauseDelay: -1
    maxSizeBytes: sqlDbMaxSizeBytes
    zoneRedundant: isZoneRedundant
    collation: sqlDbCollation
    requestedBackupStorageRedundancy: sqlDbBackupStorageRedundancy
    minCapacity: json(sqlDbMinCapacity)
    highAvailabilityReplicaCount: (sqlDbHighAvailabilityReplicaCount == 0 ? null : sqlDbHighAvailabilityReplicaCount)
    createMode: 'Default'
    maintenanceConfigurationId: maintenanceConfigurationId
  }
}

resource sqlDbLtrPolicy 'Microsoft.Sql/servers/databases/backupLongTermRetentionPolicies@2021-11-01' = if (sqlDbLtrMonthlyRetentionInMonths > 0) {
  name: 'default'
  parent: sqlDb
  properties: {
    monthlyRetention: 'P${sqlDbLtrMonthlyRetentionInMonths}W'
  }
}

resource symbolicname 'Microsoft.Sql/servers/databases/backupShortTermRetentionPolicies@2021-11-01' = {
  name: 'default'
  parent: sqlDb
  properties: {
    diffBackupIntervalInHours: sqlDbDiffBackupIntervalInHours
    retentionDays: sqlDbRetentionDays
  }
}

resource sqlDbDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${sqlDb.name}-dgs'
  scope: sqlDb
  properties: {
    workspaceId: lawsResourceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
      {
        categoryGroup: 'audit'
        enabled: true
      }
    ]
  }
}
