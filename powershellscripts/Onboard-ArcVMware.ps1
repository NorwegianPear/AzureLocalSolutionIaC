<#
.SYNOPSIS
    Onboard a VMware vSphere lab to Azure Arc via Resource Bridge
    
.DESCRIPTION
    Run this script on a machine at the site that has:
    1. Network access to the vCenter Server
    2. Azure CLI installed with arcappliance + connectedvmware extensions
    3. Credentials to both Azure and vCenter
    
    This script sets up the Arc Resource Bridge VM on your VMware infrastructure,
    connects it to Azure, and enables you to see all VMware VMs in the Azure portal.
    
    YOUR VMWARE ENVIRONMENT IS NOT MODIFIED. Only a small bridge VM is added.

.PARAMETER SiteName
    Site identifier (stavanger or oslo)

.PARAMETER VCenterFqdn
    FQDN or IP of the vCenter Server

.PARAMETER VCenterUsername
    vCenter admin username (e.g., administrator@vsphere.local)

.PARAMETER Environment
    Environment type (dev, qa, prod)

.EXAMPLE
    .\Onboard-ArcVMware.ps1 -SiteName stavanger -VCenterFqdn "vcenter.stavanger.local" -VCenterUsername "administrator@vsphere.local"
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('stavanger', 'oslo')]
    [string]$SiteName,

    [Parameter(Mandatory = $true)]
    [string]$VCenterFqdn,

    [Parameter(Mandatory = $true)]
    [string]$VCenterUsername,

    [Parameter(Mandatory = $false)]
    [string]$Environment = 'dev',

    [Parameter(Mandatory = $false)]
    [string]$Location = 'norwayeast'
)

# Variables
$resourceGroupName = "arc-vmware-$SiteName-$Environment"
$applianceName = "arc-bridge-$SiteName-$Environment"
$customLocationName = "cl-$SiteName-$Environment"
$vCenterResourceName = "vcenter-$SiteName-$Environment"
$configFolder = "$env:TEMP\arc-vmware-$SiteName"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " Arc-enabled VMware vSphere Onboarding" -ForegroundColor Cyan
Write-Host " Site: $($SiteName.ToUpper())" -ForegroundColor Cyan 
Write-Host " vCenter: $VCenterFqdn" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# Prerequisites check
# ============================================================================
Write-Host "Checking prerequisites..." -ForegroundColor Yellow

# Check Azure CLI
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    throw "Azure CLI is not installed. Install from: https://aka.ms/installazurecli"
}

# Install/update extensions
Write-Host "Installing Azure CLI extensions..."
az extension add --name arcappliance --upgrade --yes 2>$null
az extension add --name connectedvmware --upgrade --yes 2>$null
az extension add --name customlocation --upgrade --yes 2>$null

# Check Azure login
$account = az account show -o json 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "Not logged in to Azure. Logging in..."
    az login --use-device-code
}

Write-Host "Azure subscription: $($account.name) ($($account.id))" -ForegroundColor Green

# ============================================================================
# Step 1: Create configuration for Arc Resource Bridge
# ============================================================================
Write-Host "`nStep 1: Creating Arc Resource Bridge configuration..." -ForegroundColor Cyan

if (-not (Test-Path $configFolder)) {
    New-Item -ItemType Directory -Path $configFolder -Force | Out-Null
}

# Generate appliance configuration
az arcappliance createconfig vmware `
    --resource-group $resourceGroupName `
    --name $applianceName `
    --location $Location `
    --address $VCenterFqdn `
    --username $VCenterUsername `
    --out-dir $configFolder

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to create configuration. Please check your vCenter credentials." -ForegroundColor Red
    exit 1
}

# ============================================================================
# Step 2: Validate the configuration
# ============================================================================
Write-Host "`nStep 2: Validating configuration..." -ForegroundColor Cyan

az arcappliance validate vmware `
    --config-file "$configFolder\$applianceName-appliance.yaml"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Validation failed. Check network connectivity and vCenter access." -ForegroundColor Red
    exit 1
}

Write-Host "Validation passed!" -ForegroundColor Green

# ============================================================================
# Step 3: Prepare VMware infrastructure
# ============================================================================
Write-Host "`nStep 3: Preparing VMware infrastructure (creates bridge VM template)..." -ForegroundColor Cyan

az arcappliance prepare vmware `
    --config-file "$configFolder\$applianceName-appliance.yaml"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Preparation failed." -ForegroundColor Red
    exit 1
}

Write-Host "Infrastructure prepared!" -ForegroundColor Green

# ============================================================================
# Step 4: Deploy Arc Resource Bridge VM
# ============================================================================
Write-Host "`nStep 4: Deploying Arc Resource Bridge VM on VMware..." -ForegroundColor Cyan
Write-Host "This deploys a small Kubernetes VM (~4 vCPU, 16GB RAM) on your vCenter." -ForegroundColor Yellow
Write-Host "Your existing VMs are NOT affected." -ForegroundColor Yellow

az arcappliance deploy vmware `
    --config-file "$configFolder\$applianceName-appliance.yaml"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Deployment failed." -ForegroundColor Red
    exit 1
}

Write-Host "Bridge VM deployed!" -ForegroundColor Green

# ============================================================================
# Step 5: Create Arc Resource Bridge in Azure
# ============================================================================
Write-Host "`nStep 5: Connecting Resource Bridge to Azure..." -ForegroundColor Cyan

az arcappliance create vmware `
    --config-file "$configFolder\$applianceName-appliance.yaml" `
    --kubeconfig "$configFolder\kubeconfig"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Azure connection failed." -ForegroundColor Red
    exit 1
}

Write-Host "Resource Bridge connected to Azure!" -ForegroundColor Green

# ============================================================================
# Step 6: Create Custom Location + connect vCenter
# ============================================================================
Write-Host "`nStep 6: Creating Custom Location and connecting vCenter..." -ForegroundColor Cyan

# Get appliance ID
$applianceId = az arcappliance show --resource-group $resourceGroupName --name $applianceName --query id -o tsv

# Get the cluster extension ID for VMware
$extensionId = az k8s-extension show `
    --resource-group $resourceGroupName `
    --cluster-name $applianceName `
    --cluster-type appliances `
    --name vmware `
    --query id -o tsv

# Create custom location
az customlocation create `
    --resource-group $resourceGroupName `
    --name $customLocationName `
    --location $Location `
    --host-resource-id $applianceId `
    --namespace "vmware-system" `
    --cluster-extension-ids $extensionId

# Connect vCenter
$customLocationId = az customlocation show `
    --resource-group $resourceGroupName `
    --name $customLocationName `
    --query id -o tsv

az connectedvmware vcenter connect `
    --resource-group $resourceGroupName `
    --name $vCenterResourceName `
    --location $Location `
    --custom-location $customLocationId `
    --fqdn $VCenterFqdn `
    --username $VCenterUsername `
    --port 443

Write-Host "`n============================================" -ForegroundColor Green
Write-Host " ONBOARDING COMPLETE!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Your VMware vCenter at $VCenterFqdn is now connected to Azure." -ForegroundColor Green
Write-Host "All VMware VMs will appear in the Azure portal under:" -ForegroundColor Green
Write-Host "  Resource Group: $resourceGroupName" -ForegroundColor White
Write-Host "  Custom Location: $customLocationName" -ForegroundColor White
Write-Host ""
Write-Host "COST: Base Arc connection is FREE. Monitor/Defender extensions are not" -ForegroundColor Yellow
Write-Host "installed by default. Enable only what you need." -ForegroundColor Yellow
Write-Host ""
Write-Host "To check status:  .\Manage-ArcConnection.ps1 -Action status -Site $SiteName" -ForegroundColor White
Write-Host "To disable costs: .\Manage-ArcConnection.ps1 -Action disable -Site $SiteName" -ForegroundColor White
Write-Host "To teardown:      Run the deploy_arc_vmware workflow with action=teardown" -ForegroundColor White
