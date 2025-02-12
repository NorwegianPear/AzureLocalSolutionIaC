targetScope = 'subscription'

@description('Set basetime to UTC')
param baseTime string = utcNow('u')

@description('set basetime to Norway(UTC+1) in string format')
param NorwayBaseTimeString string = dateTimeAdd(baseTime, 'PT1H')

@description('Converts timeformat baseTime from string to int and adds 1 hour to set NorwayBaseTime ')
param NorwayBaseTime int = dateTimeToEpoch(dateTimeAdd(baseTime, 'PT1H'))

@description('Converts timeformat NorwayBaseTime from string to int and adds 1 Year to NorwayBaseTime')
param NorwayBaseTimeAdd1Year int = dateTimeToEpoch(dateTimeAdd(NorwayBaseTimeString, 'P1Y'))

@description('Adds 29 days to NorwayBaseTimeAdd1Year')
param NorwayBaseTimeAdd29Days int = dateTimeToEpoch(dateTimeAdd(NorwayBaseTimeString, 'P29D'))


@allowed([
  'PROD'
  'QA'
  'DEV'
  'TEST'
])
param environmentType string

@allowed([
  'prod'
  'qa'
  'dev'
  'test'
])
param environmentTypeLowerCase string

param subscriptionPrefix string = split(subscription().displayName, '-')[0]
param locationShortName object = {
  westeurope: 'WE'
  northeurope: 'NE'
  norwayeast: 'NOE'
  norwaywest: 'NOW'
  southcentralus: 'SCUS'
  northcentralus: 'NCUS'
  brazilsouth: 'BS'
}
param location string 
param tags object?
param aksClusters array
param storageAccounts array

param resourceGroupName string

var aksClusterconfigs = [for (aksClusters, i) in aksClusters: union({
  name: '${subscriptionPrefix}${aksClusters.name}-${environmentType}'
  location: location
  kubernetesVersion: aksClusters.kubernetesVersion
  dnsPrefix: aksClusters.dnsPrefix
  primaryAgentPoolProfiles: aksClusters.primaryAgentPoolProfiles
  tags: tags
  agentPools: aksClusters.agentPools
  aksServicePrincipalProfile: aksClusters.aksServicePrincipalProfile

}, aksClusters)]

var storageAccountsconfigs = [for (storageAccount, i) in storageAccounts: union({
  name: '${subscriptionPrefix}${storageAccount.name}-${environmentType}'
  location: location
  skuName: 'Standard_LRS'
  kind: 'StorageV2'
  tags: tags

}, storageAccount)]


module aksCluster '../avm/res/container-service/managed-cluster/main.bicep' = [for (aksCluster, i) in aksClusterconfigs: {
  name: '${uniqueString(deployment().name, aksCluster.name)}-aks'
  scope: resourceGroup('${resourceGroupName}-${environmentTypeLowerCase}')
  
  params: {
    name: aksCluster.name
    location: location
    kubernetesVersion: aksCluster.kubernetesVersion
    dnsPrefix: aksCluster.dnsPrefix
    primaryAgentPoolProfiles: aksCluster.primaryAgentPoolProfiles
    tags: tags
    agentPools: aksCluster.agentPools
    aksServicePrincipalProfile: aksCluster.aksServicePrincipalProfile
    
  }
}]

module storageAccount '../avm/res/storage/storage-account/main.bicep' = [for (storageAccount, i) in storageAccountsconfigs: {
  name: '${uniqueString(deployment().name, storageAccount.name)}-storage'
  scope: resourceGroup('${resourceGroupName}-${environmentTypeLowerCase}')
  
  params: {
    name: storageAccount.name
    location: storageAccount.location
    skuName: storageAccount.skuName
    kind: storageAccount.kind
    tags: storageAccount.tags
}
}
]


param avd object
module avdResource '../avm/res/desktop-virtualization/host-pool/main.bicep' = {
  name: '${uniqueString(deployment().name, avd.properties.friendlyName)}-avd'
  scope: resourceGroup('${resourceGroupName}-${environmentTypeLowerCase}')
  
  params: {
    name: avd.properties.friendlyName
    location: location
    tags: tags
    friendlyName: avd.properties.friendlyName
    description: avd.properties.description
    hostPoolType: avd.properties.hostPoolType
    personalDesktopAssignmentType: avd.properties.personalDesktopAssignmentType
    loadBalancerType: avd.properties.loadBalancerType
    preferredAppGroupType: avd.properties.preferredAppGroupType
  }
}

param arcEnabledServers array

var arcEnabledServersConfigs = [for (arcEnabledServer, i) in arcEnabledServers: {
  name: arcEnabledServer.name
    location: arcEnabledServer.location
    tags: arcEnabledServer.tags
    osType: arcEnabledServer.osType
    vmSize: arcEnabledServer.vmSize
    adminUsername: arcEnabledServer.adminUsername
    adminPassword: arcEnabledServer.adminPassword
    imageReference: arcEnabledServer.imageReference
    nicConfigurations: arcEnabledServer.nicConfigurations
    osDisk: arcEnabledServer.osDisk
    zone: arcEnabledServer.zone
}]

module arcEnabledServer '../avm/res/compute/virtual-machine/main.bicep' = [for (arcEnabledServer, i) in arcEnabledServersConfigs: {
  name: '${uniqueString(deployment().name, arcEnabledServer.name)}-arc'
  scope: resourceGroup('${resourceGroupName}-${environmentTypeLowerCase}')
  
  params: {
    name: arcEnabledServer.name
    location: arcEnabledServer.location
    tags: arcEnabledServer.tags
    osType: arcEnabledServer.osType
    vmSize: arcEnabledServer.vmSize
    adminUsername: arcEnabledServer.adminUsername
    adminPassword: arcEnabledServer.adminPassword
    imageReference: arcEnabledServer.imageReference
    nicConfigurations: arcEnabledServer.nicConfigurations
    osDisk: arcEnabledServer.osDisk
    zone: arcEnabledServer.zone
  }
}]
