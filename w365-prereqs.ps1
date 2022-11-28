#Connect to your Tenant
Connect-AzAccount
Connect-AzureAD

#Parameters
$RGName = "rg-w365-automation" #ResourceGroup Name
$Region = "West Europe" #Region for Azure Resources
$MiName = "mi-w365-automation" #Managed Identity name
$AutomationAccount = "aa-w365-automation" #Automation Account name
$subscriptionID = "33eh30a9-8a73-****-*****-********" #Subscription ID
$SCRepo = "https://github.com/j0eyv/W365-Reboot.git" #Github Repo used for Source Control (Code to run)
$ScheduleTimeZone = "Europe/Amsterdam" #Timezone used for scheduled activity
$RebootTime = "23:59:00" #Time used for scheduled activity
$VariableName = "AUTOMATION_SC_USER_ASSIGNED_IDENTITY_ID" #DO NOT MODIFY!

#Create ResourceGroup
New-AzResourceGroup -Name $RGName -Location $Region

#Create AutomationAccount
New-AzAutomationAccount -Name $AutomationAccount -Location $Region -ResourceGroupName $RGName

#Import Required PowerShell Modules.
#Microsoft.Graph.Authentication
$moduleName = "Microsoft.Graph.Authentication"
$moduleVersion = "1.17.0"
New-AzAutomationModule -AutomationAccountName $AutomationAccount -ResourceGroupName $RGName -Name $moduleName -ContentLinkUri "https://www.powershellgallery.com/api/v2/package/$moduleName/$moduleVersion"

#Query Microsoft.Graph.Authentication state. Continue if PrivisioningState is "Succeeded"
While ((Get-AzAutomationModule -AutomationAccountName $AutomationAccount -ResourceGroupName $RGName -Name $moduleName).ProvisioningState -ne "Succeeded")
{
    write-host (get-date) "Required module is installing.. Waiting untill completed."
    Start-Sleep -s 30
    }

Start-Sleep -s 5

if ($ModuleState.ProvisioningState -eq "Succeeded") 
{
    Write-Host "Required module is installed. Continue."
exit 99
}

#Microsoft.Graph.DeviceManagement
$moduleName2 = "Microsoft.Graph.DeviceManagement"
$moduleVersion2 = "1.17.0"
New-AzAutomationModule -AutomationAccountName $AutomationAccount -ResourceGroupName $RGName -Name $moduleName2 -ContentLinkUri "https://www.powershellgallery.com/api/v2/package/$moduleName2/$moduleVersion2"

#Microsoft.Graph.DeviceManagement.Actions
$moduleName3 = "Microsoft.Graph.DeviceManagement.Actions"
$moduleVersion3 = "1.17.0"
New-AzAutomationModule -AutomationAccountName $AutomationAccount -ResourceGroupName $RGName -Name $moduleName3 -ContentLinkUri "https://www.powershellgallery.com/api/v2/package/$moduleName3/$moduleVersion3"

#Microsoft.Graph.DeviceManagement.Actions
$moduleName4 = "Microsoft.Graph.DeviceManagement.Administration"
$moduleVersion4 = "1.17.0"
New-AzAutomationModule -AutomationAccountName $AutomationAccount -ResourceGroupName $RGName -Name $moduleName4 -ContentLinkUri "https://www.powershellgallery.com/api/v2/package/$moduleName4/$moduleVersion4"

#Create User Assigned Managed Identity
New-AzUserAssignedIdentity -ResourceGroupName $RGName -Name $MiName

#Add Managed Identity to Resource
Set-AzAutomationAccount -ResourceGroupName $RGName -Name $automationAccount -AssignUserIdentity "/subscriptions/$subscriptionID/resourcegroups/$RGName/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$MiName" -AssignSystemIdentity

#Create Managed Identity ClientID variable
$VariableContent = Get-AzUserAssignedIdentity -Name $MiName -ResourceGroupName $RGName
New-AzAutomationVariable -AutomationAccountName $AutomationAccount -Name $VariableName -Value $VariableContent.ClientID -ResourceGroupName $RGName -encrypted $false

#Assign contributor permissions to the Managed Identity
$RoleAssignment = Get-AzADServicePrincipal -DisplayName $MiName
New-AzRoleAssignment -ObjectId $RoleAssignment.id -RoleDefinitionName "Contributor" -ResourceGroupName $RGName -WarningAction:SilentlyContinue

#Configure SourceControl (Github Repo)
#Note: Manual Source Control Sync is required from the Azure Portal or modify code in the source (Github). This initiates a sync also.
$SecString = ConvertTo-SecureString "***************************" -AsPlainText -Force
New-AzAutomationSourceControl -Name SCGitHub -RepoUrl $SCRepo -SourceType GitHub -FolderPath "/Runbook" -Branch main -ResourceGroupName $RGName -AutomationAccountName $AutomationAccount -AccessToken $SecString -EnableAutoSync

#Import Recurring Schedule
#Note: This schedule is created on the Automation Account niveau. All runbooks within the Automation Account make use of this.
$StartTime = Get-Date "$RebootTime"
$EndTime = $StartTime.AddYears(5)
New-AzAutomationSchedule -AutomationAccountName "$AutomationAccount" -Name "DailyReboot" -StartTime $StartTime -ExpiryTime $EndTime -DayInterval 1 -ResourceGroupName "$RGName" -TimeZone "$ScheduleTimeZone"

#Add "Graph PowerShell" Enterprise APP.
New-AzureADApplication -DisplayName "Microsoft Graph PowerShell"