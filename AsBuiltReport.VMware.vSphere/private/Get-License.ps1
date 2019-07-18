function Get-License
{
    <#
.SYNOPSIS
Function to retrieve vSphere product licensing information.
.DESCRIPTION
Function to retrieve vSphere product licensing information.
.NOTES
Version:        0.1.2
Author:         Tim Carman
Twitter:        @tpcarman
Github:         tpcarman
.PARAMETER VMHost
A vSphere ESXi Host object
.PARAMETER vCenter
A vSphere vCenter Server object
.PARAMETER Licenses
All vSphere product licenses
.INPUTS
System.Management.Automation.PSObject.
.OUTPUTS
System.Management.Automation.PSObject.
.EXAMPLE
PS> Get-License -VMHost ESXi01
.EXAMPLE
PS> Get-License -vCenter VCSA
.EXAMPLE
PS> Get-License -Licenses
#>
    [CmdletBinding()][OutputType('System.Management.Automation.PSObject')]

    Param
    (
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [ValidateNotNullOrEmpty()]
        [PSObject]$vCenter, 
        [PSObject]$VMHost,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [Switch]$Licenses
    ) 

    $LicenseObject = @()
    $ServiceInstance = Get-View ServiceInstance -Server $vCenter
    $LicenseManager = Get-View $ServiceInstance.Content.LicenseManager -Server $vCenter
    $LicenseManagerAssign = Get-View $LicenseManager.LicenseAssignmentManager -Server $vCenter
    if ($VMHost)
    {
        $VMHostId = $VMHost.Extensiondata.Config.Host.Value
        $VMHostAssignedLicense = $LicenseManagerAssign.QueryAssignedLicenses($VMHostId)    
        $VMHostLicense = $VMHostAssignedLicense.AssignedLicense
        if ($VMHostLicense.LicenseKey -and $Options.ShowLicenseKeys)
        {
            $VMHostLicenseKey = $VMHostLicense.LicenseKey
        }
        else
        {
            $VMHostLicenseKey = "*****-*****-*****" + $VMHostLicense.LicenseKey.Substring(17)
        }
        $LicenseObject = [PSCustomObject]@{                               
            Product    = $VMHostLicense.Name 
            LicenseKey = $VMHostLicenseKey                   
        }
    }
    if ($vCenter)
    {
        $vCenterAssignedLicense = $LicenseManagerAssign.GetType().GetMethod("QueryAssignedLicenses").Invoke($LicenseManagerAssign, @($_.MoRef.Value)) | Where-Object { $_.EntityID -eq $vCenter.InstanceUuid }
        $vCenterLicense = $vCenterAssignedLicense.AssignedLicense
        if ($vCenterLicense.LicenseKey -and $Options.ShowLicenseKeys)
        { 
            $vCenterLicenseKey = $vCenterLicense.LicenseKey
        }
        else
        {
            $vCenterLicenseKey = "*****-*****-*****" + $vCenterLicense.LicenseKey.Substring(17)
        }
        $LicenseObject = [PSCustomObject]@{                               
            Product    = $vCenterLicense.Name
            LicenseKey = $vCenterLicenseKey                    
        }
    }
    if ($Licenses)
    {
        foreach ($License in $LicenseManager.Licenses)
        {
            if ($Options.ShowLicenseKeys)
            {
                $LicenseKey = $License.LicenseKey
            }
            else
            {
                $LicenseKey = "*****-*****-*****" + $License.LicenseKey.Substring(17)
            }
            $Object = [PSCustomObject]@{                               
                'Product'    = $License.Name
                'LicenseKey' = $LicenseKey
                'Total'      = $License.Total
                'Used'       = $License.Used                     
            }
            $LicenseObject += $Object
        }
    }
    Write-Output $LicenseObject
}