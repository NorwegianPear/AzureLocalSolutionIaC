param location string
param aksKeyVaultName string
param avdKeyVaultName string
param aksResourceGroupName string
param avdResourceGroupName string

resource aksKeyVault 'Microsoft.KeyVault/vaults@2021-04-01-preview' = {
  name: aksKeyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: []
  }
}

resource avdKeyVault 'Microsoft.KeyVault/vaults@2021-04-01-preview' = {
  name: avdKeyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: []
  }
}
