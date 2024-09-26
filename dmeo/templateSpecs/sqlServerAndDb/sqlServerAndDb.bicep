targetScope = 'subscription'

metadata displayName = 'Azure Sql Server and Database'
metadata version = '1.0.0'
metadata releaseNotes = 'Initial release'
metadata description = 'Template for deploying azure sql server and database in Azure Landing Zone'

@description('Specify the number of the respective Change')
param changeId string

@description('Specify the name of the resourceGroup where sql server and database will be deployed')
param resourceGroupName string

@description('Specify the sql server params')
param sqlServerParams object

@description('Specify the sql database params')
param sqlDatabaseParams object

module sqlServer '../sqlServer/sqlServer.bicep' = {
  name: 'deploy-sqlServer-${sqlServerParams.name}'
  params: {
    changeId: changeId
    name: sqlServerParams.name
    resourceGroupName: resourceGroupName
    sqlAadAdministratorGroupName: sqlServerParams.sqlAadAdministratorGroupName
    sqlAadAdministratorGroupObjectId: sqlServerParams.sqlAadAdministratorGroupObjectId
    subnetResourceId: sqlServerParams.subnetResourceId
    tdeKeyVaultKeyName: sqlServerParams.tdeKeyVaultKeyName
    tdeKeyVaultResourceId: sqlServerParams.tdeKeyVaultResourceId
  }
  scope: subscription()
}

module sqlDb '../sqlDb/sqlDb.bicep' = {
  name: 'deploy-sqlDatabase-${sqlDatabaseParams.name}'
  params: {
    changeId: changeId
    name: sqlDatabaseParams.name
    sqlServerResourceId: sqlServer.outputs.resId
    isZoneRedundant: sqlDatabaseParams.?isZoneRedundant
    sqlDbBackupStorageRedundancy: sqlDatabaseParams.?sqlDbBackupStorageRedundancy
    sqlDbCollation: sqlDatabaseParams.?sqlDbCollation
    sqlDbLtrMonthlyRetentionInMonths: sqlDatabaseParams.?sqlDbLtrMonthlyRetentionInMonths
    sqlDbMaxSizeGb: sqlDatabaseParams.?sqlDbMaxSizeGb
    sqlDbMinCapacity: sqlDatabaseParams.?sqlDbMinCapacity
    sqlDbReadScale: sqlDatabaseParams.?sqlDbReadScale
    sqlDbSkuName: sqlDatabaseParams.?sqlDbSkuName
  }
  scope: subscription()
}
