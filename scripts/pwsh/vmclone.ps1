$vcenter="vcenter.nick.local"
Connect-VIServer -Server $vcenter

# Show and Select VMs
Write-Host ""
Write-Host "----- VMs -----"
Get-VM | Select-Object Name -ExpandProperty Name
Write-Host "---------------"
Write-Host ""
$vm=Get-VM -Name(Read-Host -Prompt "Enter VM You wish to clone: ")

cls

# Show and Select Snapshots
Write-Host ""
Write-Host "----- Snapshots -----"
$vm | Get-Snapshot | Select-Object Name -ExpandProperty Name
Write-Host "----- ---------------"
Write-Host ""
$snapshot=Get-Snapshot -VM $vm -Name(Read-host -Prompt "Enter the name of the snapshot for the chosen VM: ")


cls

$vmhost=Get-VMHost -Name "192.168.7.16"

# Show and Select Datastores
Write-Host ""
Write-Host "----- Datastores -----"
Get-Datastore | Select-Object Name -ExpandProperty Name
Write-Host "----------------------"
Write-Host ""
$ds=Get-Datastore -Name(Read-Host -Prompt "Enter the name of the datastore you would like to use: ")

cls

Write-Host "----- Linking -----"
$linkedname="{0}.linked" -f $vm.name
$linkedvm=New-VM -LinkedClone -Name $linkedname -VM $vm -ReferenceSnapshot $snapshot -VMHost $vmhost -Datastore $ds

cls

Write-Host "----- Creating New VM -----"
$newvm = New-VM -Name "$vm.new" -VM $linkedvm -VMHost $vmhost -Datastore $ds
$newvm | new-snapshot -Name "Base"

cls

Write-Host "----- Cleaning Up -----"
$linkedvm | Remove-VM -Force

cls 

Write-Host "Finished successfully. New VM created named $newvm and new snapshot named Base."
