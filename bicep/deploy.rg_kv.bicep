targetScope = 'subscription'
param subscriptionId string?
param tenantId string?

param location string
param environmentType string
param environmentTypeLowerCase string
param resourceGroups array
param keyVaults array

var resourceGroupConfigs = [for (resourceGroup, i) in resourceGroups: {
  name: '${resourceGroup.name}-${environmentTypeLowerCase}'
  location: location
  tags: resourceGroup.tags
}]

module resourceGroup '../avm/res/resources/resource-group/main.bicep' = [for (resourceGroup, i) in resourceGroupConfigs: {
  name: '${uniqueString(deployment().name, '${resourceGroup.name}-${environmentTypeLowerCase}')}-rg'
  scope: subscription(subscriptionId)
  params: {
    lock: {
      name: null
      kind: 'None'
    }
    location: resourceGroup.location
    tags: resourceGroup.tags
    name: resourceGroup.name
  }
}]

var keyVaultConfigs = [for (keyVault, i) in keyVaults: {
  name: '${keyVault.name}-${environmentTypeLowerCase}'
  location: location
  tags: keyVault.tags
  sku: keyVault.sku
  resourceGroupName: keyVault.resourceGroupName
}]

module KeyVault '../avm/res/key-vault/vault/main.bicep' = [for (keyVault, i) in keyVaultConfigs: {
  name: '${uniqueString(deployment().name, keyVault.name)}-kv'
  scope: az.resourceGroup(resourceGroupConfigs[i].name)
  params: {
    name: keyVault.name
    sku: keyVault.sku
    accessPolicies: []
  }
}]

output resourceGroupNames array = [for rg in resourceGroupConfigs: rg.name]
output resourceGroupLocations array = [for rg in resourceGroupConfigs: rg.location]
output resourceGroupTags array = [for rg in resourceGroupConfigs: rg.tags]
