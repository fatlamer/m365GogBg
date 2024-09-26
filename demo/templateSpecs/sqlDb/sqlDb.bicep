targetScope = 'subscription'

metadata displayName = 'Azure Sql Database'
metadata version = '1.0.0'
metadata releaseNotes = 'Initial release'
metadata description = 'Template for deploying azure sql database in Azure Landing Zone'

@description('Specify the number of the respective Change')
param changeId string

@description('Specify the name of the SQL DB')
param name string

@description('Specify the resource id of the SQL server for the SQL DB')
param sqlServerResourceId string

@description('Specify the SKU name for the SQL DB. For the DTU purchasing model the SKU name is Basic, Standard, or Premium. For the vCore purchasing model the SKU name includes the tier code (GP for GeneralPurpose, GP_S for Serverless, BC for BusinessCritical, or HS for Hyperscale) and the hardware family code (e.g. GP_Gen5).')
param sqlDbSkuName string

@description('Specify the monthly long-term retention (months)')
param sqlDbLtrMonthlyRetentionInMonths int = 0

@description('Specify the backup storage redundancy for the SQL DB')
@allowed(['Geo', 'GeoZone', 'Local', 'Zone'])
param sqlDbBackupStorageRedundancy string = 'Local'

@description('Specify the Min vCores for the SQL DB')
param sqlDbMinCapacity string = '1'

@description('Specify the the number of high-availability secondary replicas for the SQL DB')
param sqlDbHighAvailabilityReplicaCount int = 0

@description('Enabled or Disable the read scale-out')
@allowed(['Enabled', 'Disabled'])
param sqlDbReadScale string = 'Disabled'

@description('Specify the Data Max Size in GB for the SQL DB')
param sqlDbMaxSizeGb string = '1'

@description('Specify if the SQL DB will be zone-redundant')
param isZoneRedundant bool = false

@description('Specify the collation for the SQL DB')
param sqlDbCollation string = 'Latin1_General_100_CI_AS_KS_WS'

@description('Specify the name of the maintenance Configuration that defines the period when the maintenance updates will occur')
param maintenanceConfigurationName string = 'SQL_Default'

@description('Specify the environment name')
@allowed(['demo'])
param environmentType string = 'demo'

var environmentConfig = loadJsonContent('../../config/environment.jsonc')
var hubRgName = environmentConfig[environmentType].azure.hubRgName
var sqlServerName = split(sqlServerResourceId, '/')[8]
var sqlServerResourceGroupName = split(sqlServerResourceId, '/')[4]

resource sqlServer 'Microsoft.Sql/servers@2021-11-01' existing = {
  name: sqlServerName
  scope: resourceGroup(sqlServerResourceGroupName)
}

resource sqlMaintenanceConfiguration 'Microsoft.Maintenance/publicMaintenanceConfigurations@2021-05-01' existing = {
  name: maintenanceConfigurationName
}

resource hubLaws 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: environmentConfig[environmentType].azure.hubLawsName
  scope: resourceGroup(hubRgName)
}

module sqlDB '../../bicepModules/sqlDb/sqlDb.bicep' = {
  scope: resourceGroup(sqlServerResourceGroupName)
  name: 'deploy-sqlDb'
  params: {
    tags: { changeId: changeId }
    name: name
    sqlDbBackupStorageRedundancy: sqlDbBackupStorageRedundancy
    sqlDbHighAvailabilityReplicaCount: sqlDbHighAvailabilityReplicaCount
    sqlDbMinCapacity: sqlDbMinCapacity
    sqlDbSkuName: sqlDbSkuName
    sqlDbCollation: sqlDbCollation
    isZoneRedundant: isZoneRedundant
    sqlServerName: sqlServer.name
    sqlDbMaxSizeGb: sqlDbMaxSizeGb
    location: environmentConfig[environmentType].azure.location
    sqlDbLtrMonthlyRetentionInMonths: sqlDbLtrMonthlyRetentionInMonths
    lawsResourceId: hubLaws.id
    readScale: sqlDbReadScale
    maintenanceConfigurationId: sqlMaintenanceConfiguration.id
  }
}
