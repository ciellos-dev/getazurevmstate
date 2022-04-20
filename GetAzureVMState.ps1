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
$NuGet = Get-PackageProvider -Name nuget
$Az = Get-InstalledModule -Name Az
$DfoTools = Get-InstalledModule -Name d365fo.tools #-ErrorAction SilentlyContinue

if([string]::IsNullOrEmpty($NuGet))
{
    Install-PackageProvider nuget -Scope CurrentUser -Verbose -Force -Confirm:$false
}
if([string]::IsNullOrEmpty($Az))
{
    Install-Module -Name Az -AllowClobber -Scope CurrentUser -Verbose -Force -Confirm:$False -SkipPublisherCheck 
}
if([string]::IsNullOrEmpty($DfoTools))
{
    Install-Module -Name d365fo.tools -AllowClobber -Scope CurrentUser -Verbose -Force -Confirm:$false
}

Import-Module Az
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
$AzureRMAccount = Add-AzAccount -Credential $psCred -ServicePrincipal -TenantId $AzureTenantId -Verbose 

if ($AzureRMAccount) { 
    #Do Logic
    Write-Host "== Logged in == $AzureTenantId "

    Write-Host "Getting Azure VM State $AzureVMName"
    $VMStats = (Get-AzVM -Name "$AzureVMName" -ResourceGroupName "$AzureVMResourceGroup" -Status -Verbose).Statuses
    $PowerState = ($VMStats | Where Code -Like 'PowerState/*')[0].Code.Split("/")[1]
    Write-Host "....state is" $PowerState
    return $PowerState
}
