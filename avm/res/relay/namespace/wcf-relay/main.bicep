metadata name = 'Relay Namespace WCF Relays'
metadata description = 'This module deploys a Relay Namespace WCF Relay.'

@description('Conditional. The name of the parent Relay Namespace for the WCF Relay. Required if the template is used in a standalone deployment.')
@minLength(6)
@maxLength(50)
param namespaceName string

@description('Required. Name of the WCF Relay.')
@minLength(6)
@maxLength(50)
param name string

@allowed([
  'Http'
  'NetTcp'
])
@description('Required. Type of WCF Relay.')
param relayType string

@description('Optional. A value indicating if this relay requires client authorization.')
param requiresClientAuthorization bool = true

@description('Optional. A value indicating if this relay requires transport security.')
param requiresTransportSecurity bool = true

@description('Optional. User-defined string data for the WCF Relay.')
param userMetadata string?

@description('Optional. Authorization Rules for the WCF Relay.')
param authorizationRules array = [
  {
    name: 'RootManageSharedAccessKey'
    rights: [
      'Listen'
      'Manage'
      'Send'
    ]
  }
  {
    name: 'defaultListener'
    rights: [
      'Listen'
    ]
  }
  {
    name: 'defaultSender'
    rights: [
      'Send'
    ]
  }
]

import { lockType } from 'br/public:avm/utl/types/avm-common-types:0.5.1'
@description('Optional. The lock settings of the service.')
param lock lockType?

import { roleAssignmentType } from 'br/public:avm/utl/types/avm-common-types:0.5.1'
@description('Optional. Array of role assignments to create.')
param roleAssignments roleAssignmentType[]?

var builtInRoleNames = {
  'Azure Relay Listener': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    '26e0b698-aa6d-4085-9386-aadae190014d'
  )
  'Azure Relay Owner': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    '2787bf04-f1f5-4bfe-8383-c8a24483ee38'
  )
  'Azure Relay Sender': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    '26baccc8-eea7-41f1-98f4-1762cc7f685d'
  )
  Contributor: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
  Owner: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8e3af657-a8ff-443c-a75c-2fe8c4bcb635')
  Reader: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')
  'Role Based Access Control Administrator': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    'f58310d9-a9f6-439a-9e8d-f62e7b41a168'
  )
  'User Access Administrator': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    '18d7d88d-d35e-4fb5-a5c3-7773c20a72d9'
  )
}

var formattedRoleAssignments = [
  for (roleAssignment, index) in (roleAssignments ?? []): union(roleAssignment, {
    roleDefinitionId: builtInRoleNames[?roleAssignment.roleDefinitionIdOrName] ?? (contains(
        roleAssignment.roleDefinitionIdOrName,
        '/providers/Microsoft.Authorization/roleDefinitions/'
      )
      ? roleAssignment.roleDefinitionIdOrName
      : subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleAssignment.roleDefinitionIdOrName))
  })
]

resource namespace 'Microsoft.Relay/namespaces@2021-11-01' existing = {
  name: namespaceName
}

resource wcfRelay 'Microsoft.Relay/namespaces/wcfRelays@2021-11-01' = {
  name: name
  parent: namespace
  properties: {
    relayType: relayType
    requiresClientAuthorization: requiresClientAuthorization
    requiresTransportSecurity: requiresTransportSecurity
    userMetadata: userMetadata
  }
}

module wcfRelay_authorizationRules 'authorization-rule/main.bicep' = [
  for (authorizationRule, index) in authorizationRules: {
    name: '${deployment().name}-AuthorizationRule-${index}'
    params: {
      namespaceName: namespaceName
      wcfRelayName: wcfRelay.name
      name: authorizationRule.name
      rights: authorizationRule.?rights
    }
  }
]

resource wcfRelay_lock 'Microsoft.Authorization/locks@2020-05-01' = if (!empty(lock ?? {}) && lock.?kind != 'None') {
  name: lock.?name ?? 'lock-${name}'
  properties: {
    level: lock.?kind ?? ''
    notes: lock.?kind == 'CanNotDelete'
      ? 'Cannot delete resource or child resources.'
      : 'Cannot delete or modify the resource or child resources.'
  }
  scope: wcfRelay
}

resource wcfRelay_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (roleAssignment, index) in (formattedRoleAssignments ?? []): {
    name: roleAssignment.?name ?? guid(wcfRelay.id, roleAssignment.principalId, roleAssignment.roleDefinitionId)
    properties: {
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalId: roleAssignment.principalId
      description: roleAssignment.?description
      principalType: roleAssignment.?principalType
      condition: roleAssignment.?condition
      conditionVersion: !empty(roleAssignment.?condition) ? (roleAssignment.?conditionVersion ?? '2.0') : null // Must only be set if condtion is set
      delegatedManagedIdentityResourceId: roleAssignment.?delegatedManagedIdentityResourceId
    }
    scope: wcfRelay
  }
]

@description('The name of the deployed wcf relay.')
output name string = wcfRelay.name

@description('The resource ID of the deployed wcf relay.')
output resourceId string = wcfRelay.id

@description('The resource group of the deployed wcf relay.')
output resourceGroupName string = resourceGroup().name
