using 'main.bicep'

param sshRSAPublicKey = ''

param tenantId = readEnvironmentVariable('AZURE_TENANT_ID', '')

param windowsAdminUsername = 'arcdemo'

param windowsAdminPassword = readEnvironmentVariable('ARCBOX_ADMIN_PASSWORD', '')

param logAnalyticsWorkspaceName = 'arcdemo'

param flavor = 'ITPro'

param deployBastion = false

param vmAutologon = true

param resourceTags = {} // Add tags as needed
