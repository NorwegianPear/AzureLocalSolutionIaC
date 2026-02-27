// ============================================================================
// Custom Location for Arc-enabled VMware vSphere
// Links the Arc Resource Bridge to a namespace for VMware resources
// ============================================================================

@description('Name of the custom location')
param customLocationName string

@description('Azure region')
param location string

@description('Resource ID of the Arc Resource Bridge appliance')
param applianceId string

@description('Namespace for the custom location')
param namespace string = 'vmware-system'

@description('Cluster Extension IDs to associate (VMware operator extension)')
param clusterExtensionIds array = []

@description('Tags for cost tracking')
param tags object = {}

resource customLocation 'Microsoft.ExtendedLocation/customLocations@2021-08-31-preview' = {
  name: customLocationName
  location: location
  tags: tags
  properties: {
    hostResourceId: applianceId
    namespace: namespace
    clusterExtensionIds: clusterExtensionIds
    hostType: 'Kubernetes'
  }
}

@description('Resource ID of the custom location')
output customLocationId string = customLocation.id

@description('Name of the custom location')
output customLocationName string = customLocation.name
