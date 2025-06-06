targetScope = 'subscription'

param subscriptionId string
param tenantId string?
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

param resourceGroupName string?

@secure()
param aksCluster1ClientID string?

@secure()
param aksCluster1ClientSecret string?

@secure()
param aksCluster2ClientID string?

@secure()
param aksCluster2ClientSecret string?

var aksClusterconfigs = [for (aksCluster, i) in aksClusters: union({
  name: '${subscriptionPrefix}${aksCluster.name}-${environmentType}'
  location: location
  kubernetesVersion: aksCluster.kubernetesVersion
  dnsPrefix: aksCluster.dnsPrefix
  primaryAgentPoolProfiles: aksCluster.primaryAgentPoolProfiles
  tags: tags
  agentPools: aksCluster.agentPools
  aksServicePrincipalProfile: {
    clientId: i == 0 ? aksCluster1ClientID : aksCluster2ClientID
    secret: i == 0 ? aksCluster1ClientSecret : aksCluster2ClientSecret
  }
}, aksCluster)]

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
    //arcEnabledServices: aksCluster.arcEnabledServices
    //kubernetesApplications: aksCluster.kubernetesApplications
  }
}]

module enablearc '../avm/res/container-service/managed-cluster/main.bicep' = [for (aksCluster, i) in aksClusterconfigs: {
  name: '${uniqueString(deployment().name, aksCluster.name)}-arc'
  scope: resourceGroup('${resourceGroupName}-${environmentTypeLowerCase}')
  
  params: {
    name: aksCluster.name
    location: location
    tags: tags
    kubernetesVersion: aksCluster.kubernetesVersion
    dnsPrefix: aksCluster.dnsPrefix
    agentPools: aksCluster.agentPools
    primaryAgentPoolProfiles: aksCluster.primaryAgentPoolProfiles
  }
}]


var storageAccountsconfigs = [for (storageAccount, i) in storageAccounts: union({
  name: '${subscriptionPrefix}${storageAccount.name}-${environmentType}'
  location: location
  skuName: 'Standard_LRS'
  kind: 'StorageV2'
  tags: tags
}, storageAccount)]

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
}]
