# This script executes the Windows 365 Cloud PC Reboot process.
# This script is part of a Azure Automation runbook with a recurring schedule.

#Connect MgGraph
Connect-MgGraph `
    -ClientId "940063b6-80ab-****-****-************" `
    -TenantId "e077bfdf-65f9-****-****-*************" `
    -CertificateThumbprint "2a64bf*************************"


#Import required modules
Import-Module Microsoft.Graph.DeviceManagement.Actions
Import-Module Microsoft.Graph.DeviceManagement.Administration

#Switch to Beta Profile. Cloud PC API is only here available
Select-MgProfile -Name "Beta"

#Get all Cloud PC's
$AllCloudPC = Get-MgDeviceManagementVirtualEndpointCloudPC | Where-Object {($_.DisplayName -Like '*Joey*')}

#Restart all Cloud PC's
foreach ($CloudPC in $AllCloudPC.Id)
{
    Restart-MgDeviceManagementVirtualEndpointCloudPc -CloudPcId $CloudPC
    Write-Host "Cloud PC Restarted"
}