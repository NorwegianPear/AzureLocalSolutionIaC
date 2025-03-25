using 'main.bicep'

param sshRSAPublicKey = ''

param tenantId = '973a580f-021f-4dc0-88de-48b060e43df1'

param windowsAdminUsername = 'arcdemo'

param windowsAdminPassword = 'arcdemo123!123!'

param logAnalyticsWorkspaceName = 'arcdemo'

param flavor = 'ITPro'

param deployBastion = false

param vmAutologon = true

param resourceTags = {} // Add tags as needed
