Install-Module -Name AzureAD -Force -AllowClobber

Connect-AzureAD

$app1 = Get-AzureADApplication -Filter "DisplayName eq 'AppRegSPA-coolAksCluster1'"
$password1 = New-AzureADApplicationPasswordCredential -ObjectId $app1.ObjectId -CustomKeyIdentifier "myKey1" -StartDate (Get-Date) -EndDate (Get-Date).AddYears(1)
$clientSecret1 = $password1.SecretText


$app2 = Get-AzureADApplication -Filter "DisplayName eq 'AppRegSPA-coolAksCluster2'"
$password2 = New-AzureADApplicationPasswordCredential -ObjectId $app2.ObjectId -CustomKeyIdentifier "myKey2" -StartDate (Get-Date) -EndDate (Get-Date).AddYears(1)
$clientSecret2 = $password2.SecretText