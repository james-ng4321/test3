Param
(   
    [string] $VMResourceGroupName,
    [string] $VMName
)
# function Write-Log {
#     param (
#         [string] $Prompt
#     )
#     $Timestamp = $("[" + (Get-Date -Format "MM/dd/yyyy HH:mm:ss") + "]   ")
#     Write-Output $($Timestamp + $Prompt)
# }
# $funcDef = ${function:Write-Log}.ToString()

#Import Module
Import-Module Az.Storage
Import-Module Az.Accounts
Import-Module Az.Compute

# Define ID for Automation Account
$identityID = "3a415520-7ffa-403e-a0d6-6b60a4c72a2e"

# $VMResourceGroupName = "PSSREV-UAT-RG"
# $VMName = "PSSREV-UAT-JUMP-VM-01"

Connect-AzAccount -Identity -AccountId $identityID
Select-AzSubscription 986c1b92-2f1e-4968-b8c7-048a8a708fa4

Start-AzVM -ResourceGroupName $VMResourceGroupName -Name $VMName