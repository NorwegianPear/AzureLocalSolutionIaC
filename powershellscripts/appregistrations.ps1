# Variables
$subscriptionId = "<Your-Subscription-ID>"
$resourceGroupName = "MyResourceGroup"
$location = "norwaywest"
$aksClusterName = "MyAKSCluster"
$avdHostPoolName = "MyAVDHostPool"
$keyVaultName = "MyKeyVault"

# Login to Azure
Connect-AzAccount
Set-AzContext -SubscriptionId $subscriptionId

# Create Resource Group
New-AzResourceGroup -Name $resourceGroupName -Location $location

# Create Key Vault
New-AzKeyVault -ResourceGroupName $resourceGroupName -VaultName $keyVaultName -Location $location

# Create App Registration and Service Principal
$app = New-AzADApplication -DisplayName "MyApp" -IdentifierUris "http://MyApp"
$sp = New-AzADServicePrincipal -ApplicationId $app.ApplicationId
$spPassword = New-AzADSpCredential -ObjectId $sp.Id -EndDate (Get-Date).AddYears(1)

# Store credentials in Key Vault
$secret = ConvertTo-SecureString -String $spPassword.SecretText -AsPlainText -Force
Set-AzKeyVaultSecret -VaultName $keyVaultName -Name "SP-ClientSecret" -SecretValue $secret
Set-AzKeyVaultSecret -VaultName $keyVaultName -Name "SP-ClientId" -SecretValue (ConvertTo-SecureString -String $sp.ApplicationId -AsPlainText -Force)

# Output Service Principal details
Write-Output "Service Principal ID: $($sp.ApplicationId)"
Write-Output "Service Principal Secret: $($spPassword.SecretText)"