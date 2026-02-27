// ============================================================================
// vCenter Connection for Arc-enabled VMware vSphere
// Connects your on-prem vCenter Server to Azure via the Resource Bridge
// ============================================================================

@description('Name for the vCenter resource in Azure')
param vCenterName string

@description('Azure region for the resource metadata')
param location string

@description('FQDN or IP address of the vCenter Server')
param vCenterFqdn string

@description('Port for vCenter connection (default: 443)')
param port int = 443

@description('Resource ID of the Custom Location')
param customLocationId string

@description('vCenter admin username')
param vCenterUsername string

@description('vCenter admin password')
@secure()
param vCenterPassword string

@description('Tags for cost tracking')
param tags object = {}

resource vCenter 'Microsoft.ConnectedVMwarevSphere/vcenters@2023-12-01' = {
  name: vCenterName
  location: location
  tags: tags
  extendedLocation: {
    type: 'CustomLocation'
    name: customLocationId
  }
  properties: {
    fqdn: vCenterFqdn
    port: port
    credentials: {
      username: vCenterUsername
      password: vCenterPassword
    }
  }
}

@description('Resource ID of the vCenter')
output vCenterId string = vCenter.id

@description('Connection status')
output vCenterName string = vCenter.name
