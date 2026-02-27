// ============================================================================
// Arc Resource Bridge (Appliance) for VMware vSphere
// Deploys Microsoft.ResourceConnector/appliances
// This is the bridge between your on-prem VMware and Azure management plane
// ============================================================================

@description('Name of the Arc Resource Bridge appliance')
param applianceName string

@description('Azure region for the resource metadata')
param location string

@description('Resource group name')
param resourceGroupName string = resourceGroup().name

@description('The infrastructure type - VMware for vSphere environments')
@allowed(['VMWare'])
param infrastructure string = 'VMWare'

@description('The distro - matches the Resource Bridge OS')
@allowed(['AKSEdge'])
param distro string = 'AKSEdge'

@description('Public key for the appliance identity')
param publicKey string = ''

@description('Tags for cost tracking and management')
param tags object = {}

resource resourceBridge 'Microsoft.ResourceConnector/appliances@2022-10-27' = {
  name: applianceName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    distro: distro
    infrastructure: infrastructure
    publicKey: publicKey
  }
}

@description('Resource ID of the Arc Resource Bridge')
output applianceId string = resourceBridge.id

@description('Name of the Arc Resource Bridge')
output applianceName string = resourceBridge.name

@description('Identity principal ID for RBAC assignments')
output identityPrincipalId string = resourceBridge.identity.principalId
