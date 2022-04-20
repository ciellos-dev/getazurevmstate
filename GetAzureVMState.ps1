    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$AzureVMName,
        [string]$AzureTenantId,
        [string]$AzureVMResourceGroup,
        [string]$AzureClientId,
        [string]$AzureClientSecret)

$azurePassword = ConvertTo-SecureString $AzureClientSecret -AsPlainText -Force
$psCred = New-Object System.Management.Automation.PSCredential($AzureClientId , $azurePassword)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "Check az cli installation..."
if(-not(Test-Path -Path "C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin\"))
{
    Write-Host "az cli installing.."
    $ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi
    Write-Host "az cli installed.."
}

Set-Alias -Name az -Value "C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin\az.cmd"
$AzureRMAccount = az login --service-principal -u $AzureClientId -p $AzureClientSecret --tenant $AzureTenantId


if ($AzureRMAccount) { 
    #Do Logic
    Write-Host "== Logged in == $AzureTenantId "

    Write-Host "Getting Azure VM State $AzureVMName"
    $PowerState = (az vm list -d --query "[?name=='$($AzureVMName)'].powerState").Trim().Trim("[").Trim("]").Trim('"').Trim("VM ")
    Write-Host "....state is" $PowerState
    return $PowerState
}
