// ============================================================================
// Main deployment for Arc-enabled VMware vSphere - Per Site
// Orchestrates: Resource Bridge → Custom Location → vCenter Connection
// ============================================================================

targetScope = 'subscription'

@description('Site name identifier (e.g., stavanger, oslo)')
param siteName string

@description('Azure region for resource metadata')
@allowed(['norwayeast', 'norwaywest'])
param location string = 'norwayeast'

@description('Environment type')
@allowed(['dev', 'qa', 'prod'])
param environmentType string = 'dev'

@description('FQDN or IP of the vCenter Server at this site')
param vCenterFqdn string

@description('Port for vCenter connection')
param vCenterPort int = 443

@description('vCenter admin username')
param vCenterUsername string

@description('vCenter admin password')
@secure()
param vCenterPassword string

@description('Tags for cost tracking and management')
param tags object = {}

// ============================================================================
// Variables
// ============================================================================
var resourceGroupName = 'arc-vmware-${siteName}-${environmentType}'
var applianceName = 'arc-bridge-${siteName}-${environmentType}'
var customLocationName = 'cl-${siteName}-${environmentType}'
var vCenterResourceName = 'vcenter-${siteName}-${environmentType}'

var defaultTags = union(tags, {
  Site: siteName
  Environment: environmentType
  Project: 'AzureLocalSolutionIaC'
  ManagedBy: 'Bicep'
  CostCenter: 'ArcVMware'
})

// ============================================================================
// Resource Group
// ============================================================================
resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: defaultTags
}

// ============================================================================
// Arc Resource Bridge
// ============================================================================
module resourceBridge 'resource-bridge.bicep' = {
  name: 'deploy-resource-bridge-${siteName}'
  scope: rg
  params: {
    applianceName: applianceName
    location: location
    tags: defaultTags
  }
}

// ============================================================================
// Custom Location
// ============================================================================
module customLocation 'custom-location.bicep' = {
  name: 'deploy-custom-location-${siteName}'
  scope: rg
  params: {
    customLocationName: customLocationName
    location: location
    applianceId: resourceBridge.outputs.applianceId
    tags: defaultTags
  }
}

// ============================================================================
// vCenter Connection
// ============================================================================
module vCenterConnection 'vcenter-connection.bicep' = {
  name: 'deploy-vcenter-${siteName}'
  scope: rg
  params: {
    vCenterName: vCenterResourceName
    location: location
    vCenterFqdn: vCenterFqdn
    port: vCenterPort
    customLocationId: customLocation.outputs.customLocationId
    vCenterUsername: vCenterUsername
    vCenterPassword: vCenterPassword
    tags: defaultTags
  }
}

// ============================================================================
// Outputs
// ============================================================================
output resourceGroupName string = rg.name
output applianceId string = resourceBridge.outputs.applianceId
output customLocationId string = customLocation.outputs.customLocationId
output vCenterId string = vCenterConnection.outputs.vCenterId
