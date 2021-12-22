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

# This is requried by Find-Module, by doing it beforehand we remove some warning messages
Write-Host "Installing PowerShell modules d365fo.tools and AzureRM" 
#Check Modules installed
$NuGet = Get-PackageProvider -Name nuget -ErrorAction SilentlyContinue
$AzureRMCompute = Get-InstalledModule -Name AzureRM.Compute -ErrorAction SilentlyContinue
$DfoTools = Get-InstalledModule -Name d365fo.tools -ErrorAction SilentlyContinue

if([string]::IsNullOrEmpty($NuGet))
{
    Install-PackageProvider nuget -Scope CurrentUser -Force -Confirm:$false
}
if([string]::IsNullOrEmpty($AzureRMCompute))
{
    Install-Module -Name 'AzureRM.Compute' -AllowClobber -Scope CurrentUser -Force -Confirm:$False -SkipPublisherCheck
    Import-Module -Name 'AzureRM.Compute'
}
if([string]::IsNullOrEmpty($DfoTools))
{
    Install-Module -Name d365fo.tools -AllowClobber -Scope CurrentUser -Force -Confirm:$false
}


Set-PSRepository -Name PSGallery -InstallationPolicy Trusted


$AzureRMAccount = Add-AzureRmAccount -Credential $psCred -ServicePrincipal -TenantId $AzureTenantId 

if ($AzureRMAccount) { 
    #Do Logic
    Write-Output "== Logged in == $AzureTenantId "

    Write-Host "Getting Azure VM State $AzureVMName"
    $VMStats = (Get-AzureRmVM -Name "$AzureVMName" -ResourceGroupName "$AzureVMResourceGroup" -Status -Verbose).Statuses
    $PowerState = ($VMStats | Where Code -Like 'PowerState/*')[0].Code.Split("/")[1]
    Write-Host "....state is" $PowerState
    return $PowerState
}
