$global:scriptPath = $myinvocation.mycommand.definition

function Restart-AsAdmin {
    $pwshCommand = "powershell"
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        $pwshCommand = "pwsh"
    }

    try {
        Write-Host "This script requires administrator permissions to install the Azure Connected Machine Agent. Attempting to restart script with elevated permissions..."
        $arguments = "-NoExit -Command `"& '$scriptPath'`""
        Start-Process $pwshCommand -Verb runAs -ArgumentList $arguments
        exit 0
    } catch {
        throw "Failed to elevate permissions. Please run this script as Administrator."
    }
}

try {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        if ([System.Environment]::UserInteractive) {
            Restart-AsAdmin
        } else {
            throw "This script requires administrator permissions to install the Azure Connected Machine Agent. Please run this script as Administrator."
        }
}

    $env:SUBSCRIPTION_ID = "ecfca6b3-6f73-421f-8d02-7f31ed0978bc";
    $env:RESOURCE_GROUP = "aks-kubernetes-arc-rg-dev";
    $env:TENANT_ID = "973a580f-021f-4dc0-88de-48b060e43df1";
    $env:LOCATION = "norwayeast";
    $env:AUTH_TYPE = "token";
    $env:CORRELATION_ID = "059e8b09-3a2f-43b8-9ad3-a7d3d8e7b9b6";
    $env:CLOUD = "AzureCloud";
    

    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072;

    # Download the installation package
    Invoke-WebRequest -UseBasicParsing -Uri "https://gbl.his.arc.azure.com/azcmagent-windows" -TimeoutSec 30 -OutFile "$env:TEMP\install_windows_azcmagent.ps1";

    # Install the hybrid agent
    & "$env:TEMP\install_windows_azcmagent.ps1";
    if ($LASTEXITCODE -ne 0) { exit 1; }

    # Run connect command
    & "$env:ProgramW6432\AzureConnectedMachineAgent\azcmagent.exe" connect --resource-group "$env:RESOURCE_GROUP" --tenant-id "$env:TENANT_ID" --location "$env:LOCATION" --subscription-id "$env:SUBSCRIPTION_ID" --cloud "$env:CLOUD" --correlation-id "$env:CORRELATION_ID";
}
catch {
    $logBody = @{subscriptionId="$env:SUBSCRIPTION_ID";resourceGroup="$env:RESOURCE_GROUP";tenantId="$env:TENANT_ID";location="$env:LOCATION";correlationId="$env:CORRELATION_ID";authType="$env:AUTH_TYPE";operation="onboarding";messageType=$_.FullyQualifiedErrorId;message="$_";};
    Invoke-WebRequest -UseBasicParsing -Uri "https://gbl.his.arc.azure.com/log" -Method "PUT" -Body ($logBody | ConvertTo-Json) | out-null;
    Write-Host  -ForegroundColor red $_.Exception;
}
