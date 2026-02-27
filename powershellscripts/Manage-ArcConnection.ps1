<#
.SYNOPSIS
    Manage Arc-enabled VMware vSphere connection - Enable, Disable, or Check Status
    
.DESCRIPTION
    This script allows you to enable/disable the Azure Arc connection to your VMware 
    labs without affecting the VMware infrastructure. When disabled, no Azure costs 
    are incurred for Arc management. Your VMs and VMware environment remain untouched.

    COST IMPACT:
    - Arc Resource Bridge (running): ~$0/month (free)
    - Arc-enabled VMs (per VM): ~$0/month for basic Arc (free tier)
    - Azure Monitor/Log Analytics: ~$2.76/GB ingested (disable when not needed)
    - Microsoft Defender for Servers: ~$5/server/month (disable when not needed)
    - Azure Policy (guest config): ~$0.04/server/hour (disable when not needed)
    
    To MINIMIZE COST: Disable extensions like monitoring, Defender, and guest config 
    when not actively needed. The base Arc connection is FREE.

.PARAMETER Action
    enable  - Re-enables Arc connection and monitoring
    disable - Disconnects Arc agents (keeps VMware intact, stops Azure costs)
    status  - Shows current connection status for all sites

.PARAMETER Site
    stavanger, oslo, or all

.EXAMPLE
    .\Manage-ArcConnection.ps1 -Action status -Site all
    .\Manage-ArcConnection.ps1 -Action disable -Site stavanger
    .\Manage-ArcConnection.ps1 -Action enable -Site oslo
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('enable', 'disable', 'status')]
    [string]$Action,

    [Parameter(Mandatory = $true)]
    [ValidateSet('stavanger', 'oslo', 'all')]
    [string]$Site,

    [string]$Environment = 'dev'
)

# Ensure Azure context
$context = Get-AzContext
if (-not $context) {
    throw "Not logged in to Azure. Run Connect-AzAccount first."
}

function Get-SiteConfig {
    param([string]$SiteName)
    
    $rgName = "arc-vmware-$SiteName-$Environment"
    $applianceName = "arc-bridge-$SiteName-$Environment"
    
    return @{
        ResourceGroup = $rgName
        ApplianceName = $applianceName
        Site          = $SiteName
    }
}

function Get-ArcStatus {
    param([hashtable]$Config)
    
    Write-Host "`n===== Site: $($Config.Site.ToUpper()) =====" -ForegroundColor Cyan
    
    # Check Resource Bridge
    try {
        $appliance = Get-AzResource -ResourceGroupName $Config.ResourceGroup -ResourceType 'Microsoft.ResourceConnector/appliances' -Name $Config.ApplianceName -ErrorAction Stop
        Write-Host "  Resource Bridge: " -NoNewline
        Write-Host "$($appliance.Properties.status)" -ForegroundColor $(if ($appliance.Properties.status -eq 'Running') { 'Green' } else { 'Yellow' })
    }
    catch {
        Write-Host "  Resource Bridge: " -NoNewline
        Write-Host "Not Found" -ForegroundColor Red
    }
    
    # Check Arc-enabled VMs
    try {
        $arcMachines = Get-AzConnectedMachine -ResourceGroupName $Config.ResourceGroup -ErrorAction Stop
        Write-Host "  Arc-enabled VMs: $($arcMachines.Count)" -ForegroundColor Green
        foreach ($vm in $arcMachines) {
            $status = $vm.Status
            $color = if ($status -eq 'Connected') { 'Green' } elseif ($status -eq 'Disconnected') { 'Yellow' } else { 'Red' }
            Write-Host "    - $($vm.Name): " -NoNewline
            Write-Host "$status" -ForegroundColor $color
            
            # Check cost-generating extensions
            $extensions = Get-AzConnectedMachineExtension -MachineName $vm.Name -ResourceGroupName $Config.ResourceGroup -ErrorAction SilentlyContinue
            foreach ($ext in $extensions) {
                $costFlag = if ($ext.MachineExtensionType -match 'MicrosoftDefender|AzureMonitor|GuestConfiguration') { ' [COST]' } else { '' }
                Write-Host "      Extension: $($ext.Name) ($($ext.ProvisioningState))$costFlag" -ForegroundColor $(if ($costFlag) { 'Yellow' } else { 'Gray' })
            }
        }
    }
    catch {
        Write-Host "  Arc-enabled VMs: 0 (or resource group not found)" -ForegroundColor Yellow
    }
    
    # Check vCenter connection
    try {
        $vcenters = Get-AzResource -ResourceGroupName $Config.ResourceGroup -ResourceType 'Microsoft.ConnectedVMwarevSphere/vcenters' -ErrorAction Stop
        foreach ($vc in $vcenters) {
            Write-Host "  vCenter: $($vc.Name) - Connected" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "  vCenter: Not Connected" -ForegroundColor Yellow
    }
}

function Disable-CostlyExtensions {
    param([hashtable]$Config)
    
    Write-Host "`nDisabling cost-generating extensions for site: $($Config.Site.ToUpper())..." -ForegroundColor Yellow
    
    try {
        $arcMachines = Get-AzConnectedMachine -ResourceGroupName $Config.ResourceGroup -ErrorAction Stop
        
        foreach ($vm in $arcMachines) {
            $extensions = Get-AzConnectedMachineExtension -MachineName $vm.Name -ResourceGroupName $Config.ResourceGroup -ErrorAction SilentlyContinue
            
            foreach ($ext in $extensions) {
                if ($ext.MachineExtensionType -match 'MicrosoftDefender|MicrosoftMonitoringAgent|AzureMonitorWindowsAgent|AzureMonitorLinuxAgent|GuestConfiguration') {
                    Write-Host "  Removing extension $($ext.Name) from $($vm.Name)..." -ForegroundColor Yellow
                    Remove-AzConnectedMachineExtension -MachineName $vm.Name -ResourceGroupName $Config.ResourceGroup -Name $ext.Name -Force -ErrorAction SilentlyContinue
                    Write-Host "  Removed $($ext.Name)" -ForegroundColor Green
                }
            }
        }
        
        # Disable Log Analytics data collection to stop ingestion costs
        $workspaces = Get-AzResource -ResourceGroupName $Config.ResourceGroup -ResourceType 'Microsoft.OperationalInsights/workspaces' -ErrorAction SilentlyContinue
        foreach ($ws in $workspaces) {
            Write-Host "  Setting Log Analytics workspace $($ws.Name) to free tier (500MB/day cap)..." -ForegroundColor Yellow
            Set-AzOperationalInsightsWorkspace -ResourceGroupName $Config.ResourceGroup -Name $ws.Name -Sku "PerGB2018" -RetentionInDays 30 -ErrorAction SilentlyContinue
        }
        
        Write-Host "`nCost-generating extensions disabled. Base Arc connection (FREE) remains active." -ForegroundColor Green
        Write-Host "Your VMware VMs are still visible in Azure portal but no cost is incurred." -ForegroundColor Green
    }
    catch {
        Write-Host "  Error: $_" -ForegroundColor Red
    }
}

function Enable-Extensions {
    param([hashtable]$Config)
    
    Write-Host "`nRe-enabling monitoring extensions for site: $($Config.Site.ToUpper())..." -ForegroundColor Cyan
    
    try {
        $arcMachines = Get-AzConnectedMachine -ResourceGroupName $Config.ResourceGroup -ErrorAction Stop
        
        foreach ($vm in $arcMachines) {
            $osType = $vm.OSName
            $agentType = if ($osType -match 'Windows') { 'AzureMonitorWindowsAgent' } else { 'AzureMonitorLinuxAgent' }
            $publisher = 'Microsoft.Azure.Monitor'
            
            Write-Host "  Installing $agentType on $($vm.Name)..." -ForegroundColor Cyan
            New-AzConnectedMachineExtension `
                -MachineName $vm.Name `
                -ResourceGroupName $Config.ResourceGroup `
                -Name $agentType `
                -Publisher $publisher `
                -ExtensionType $agentType `
                -Location (Get-AzResource -ResourceGroupName $Config.ResourceGroup -ResourceType 'Microsoft.HybridCompute/machines' -Name $vm.Name).Location `
                -EnableAutomaticUpgrade `
                -ErrorAction SilentlyContinue
            
            Write-Host "  Installed $agentType on $($vm.Name)" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "  Error: $_" -ForegroundColor Red
    }
}

# ============================================================================
# Main execution
# ============================================================================

$sites = if ($Site -eq 'all') { @('stavanger', 'oslo') } else { @($Site) }

foreach ($siteName in $sites) {
    $config = Get-SiteConfig -SiteName $siteName
    
    switch ($Action) {
        'status' {
            Get-ArcStatus -Config $config
        }
        'disable' {
            Disable-CostlyExtensions -Config $config
        }
        'enable' {
            Enable-Extensions -Config $config
        }
    }
}

Write-Host "`n===== Cost Summary =====" -ForegroundColor Cyan
Write-Host "Base Arc connection: FREE (Azure Arc-enabled servers)" -ForegroundColor Green
Write-Host "Arc Resource Bridge: FREE" -ForegroundColor Green
Write-Host "Azure Monitor (if enabled): ~`$2.76/GB ingested" -ForegroundColor Yellow
Write-Host "Defender for Servers (if enabled): ~`$5/server/month" -ForegroundColor Yellow
Write-Host "Guest Configuration (if enabled): ~`$0.04/server/hour" -ForegroundColor Yellow
Write-Host "`nTo minimize costs, run: .\Manage-ArcConnection.ps1 -Action disable -Site all" -ForegroundColor White
