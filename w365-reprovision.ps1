# This script executes the Windows 365 Cloud PC Reboot process.
# This script is part of a Azure Automation runbook with a recurring schedule.

#Connect to your Tenant
Connect-MgGraph -Scopes "CloudPC.ReadWrite.All"

#Import required modules
Import-Module Microsoft.Graph.DeviceManagement.Actions
Import-Module Microsoft.Graph.DeviceManagement.Administration

#Switch to Beta Profile. Cloud PC API is only here available
Select-MgProfile -Name "Beta"

#Get all Cloud PC's
$AllCloudPC = Get-MgDeviceManagementVirtualEndpointCloudPC | Where-Object {($_.DisplayName -Like '*')}

#Reprovision All Cloud PC's - Predefined for automation purposes
foreach ($CloudPC in $AllCloudPC.Id)
{
    Invoke-MgReprovisionDeviceManagementVirtualEndpointCloudPc -CloudPcId $CloudPC
}