targetScope = 'subscription'

param location string
param environmentType string
param environmentTypeLowerCase string
param resourceGroupName string
param tags object

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${resourceGroupName}-${environmentTypeLowerCase}'
  location: location
  tags: tags
}

output resourceGroupName string = resourceGroup.name
output resourceGroupLocation string = resourceGroup.location
output resourceGroupTags object = resourceGroup.tags
