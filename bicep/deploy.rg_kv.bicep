targetScope = 'subscription'
param subscriptionId string
param tenantId string?

param location string
param environmentType string
param environmentTypeLowerCase string
param resourceGroups array
param keyVaults array
param aksCluster1ClientID string
param aksCluster1ObjectID string
param aksCluster2ObjectID string
param aksCluster2ClientID string
param azurelocalsolutioniac_clientid string
param azurelocalsolutioniac_objectid string

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
  roleAssignments: [
    {
      principalId: azurelocalsolutioniac_objectid
      roleDefinitionIdOrName: 'Key Vault Administrator'
      principalType: 'ServicePrincipal'
    }
    {
      principalId: aksCluster1ObjectID
      roleDefinitionIdOrName: 'Key Vault Administrator'
      principalType: 'ServicePrincipal'
    }
    {
      principalId: aksCluster2ObjectID
      roleDefinitionIdOrName: 'Key Vault Administrator'
      principalType: 'ServicePrincipal'
    }
  ]
  accessPolicies: [
    {
      tenantId: tenantId
      objectId: azurelocalsolutioniac_objectid
      permissions: {
        secrets: [
          'get'
          'list'
          'set'
          'delete'
          'recover'
          'backup'
          'restore'
        ]
        keys: [
          'get'
          'list'
          'create'
          'delete'
          'import'
          'update'
          'backup'
          'restore'
          'recover'
          'purge'
          'sign'
          'verify'
          'wrapKey'
          'unwrapKey'
          'encrypt'
          'decrypt'
        ]
        certificates: [
          'get'
          'list'
          'delete'
          'create'
          'import'
          'update'
          'managecontacts'
          'getissuers'
          'listissuers'
          'setissuers'
          'deleteissuers'
          'manageissuers'
          'recover'
          'backup'
          'restore'
        ]
      }
    }
    {
      tenantId: tenantId
      objectId: azurelocalsolutioniac_objectid
      permissions: {
        secrets: [
          'get'
          'list'
          'set'
          'delete'
          'recover'
          'backup'
          'restore'
        ]
        keys: [
          'get'
          'list'
          'create'
          'delete'
          'import'
          'update'
          'backup'
          'restore'
          'recover'
          'purge'
          'sign'
          'verify'
          'wrapKey'
          'unwrapKey'
          'encrypt'
          'decrypt'
        ]
        certificates: [
          'get'
          'list'
          'delete'
          'create'
          'import'
          'update'
          'managecontacts'
          'getissuers'
          'listissuers'
          'setissuers'
          'deleteissuers'
          'manageissuers'
          'recover'
          'backup'
          'restore'
        ]
      }
    }
    {
      tenantId: tenantId
      objectId: aksCluster1ObjectID
      permissions: {
        secrets: [
          'get'
          'list'
          'set'
          'delete'
          'recover'
          'backup'
          'restore'
        ]
        keys: [
          'get'
          'list'
          'create'
          'delete'
          'import'
          'update'
          'backup'
          'restore'
          'recover'
          'purge'
          'sign'
          'verify'
          'wrapKey'
          'unwrapKey'
          'encrypt'
          'decrypt'
        ]
        certificates: [
          'get'
          'list'
          'delete'
          'create'
          'import'
          'update'
          'managecontacts'
          'getissuers'
          'listissuers'
          'setissuers'
          'deleteissuers'
          'manageissuers'
          'recover'
          'backup'
          'restore'
        ]
      }
    }
    {
      tenantId: tenantId
      objectId: aksCluster2ObjectID
      permissions: {
        secrets: [
          'get'
          'list'
          'set'
          'delete'
          'recover'
          'backup'
          'restore'
        ]
        keys: [
          'get'
          'list'
          'create'
          'delete'
          'import'
          'update'
          'backup'
          'restore'
          'recover'
          'purge'
          'sign'
          'verify'
          'wrapKey'
          'unwrapKey'
          'encrypt'
          'decrypt'
        ]
        certificates: [
          'get'
          'list'
          'delete'
          'create'
          'import'
          'update'
          'managecontacts'
          'getissuers'
          'listissuers'
          'setissuers'
          'deleteissuers'
          'manageissuers'
          'recover'
          'backup'
          'restore'
        ]
      }
    }
  ]
}]

module KeyVault '../avm/res/key-vault/vault/main.bicep' = [for (keyVault, i) in keyVaultConfigs: {
  name: '${uniqueString(deployment().name, keyVault.name)}-kv'
  scope: az.resourceGroup(resourceGroupConfigs[i].name)
  params: {
    name: keyVault.name
    sku: keyVault.sku
    accessPolicies: keyVault.accessPolicies
    roleAssignments: keyVault.roleAssignments
  }
}]

output resourceGroupNames array = [for rg in resourceGroupConfigs: rg.name]
output resourceGroupLocations array = [for rg in resourceGroupConfigs: rg.location]
output resourceGroupTags array = [for rg in resourceGroupConfigs: rg.tags]
