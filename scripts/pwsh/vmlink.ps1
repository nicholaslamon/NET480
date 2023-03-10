$vcenter="vcenter.nick.local"
Connect-VIServer -Server $vcenter


$vm=Get-VM -Name(Read-Host -Prompt "Enter VM You wish to link: ")
$snapshot=Get-Snapshot -VM $vm -Name(Read-host -Prompt "Enter the name of the snapshot for the chosen VM: ")
$vmhost=Get-VMHost -Name "192.168.7.16"
$ds=Get-Datastore -Name datastore2-super6
$linkedname="{0}.linked" -f $vm.name
$linkedvm=New-VM -LinkedClone -Name $linkedname -VM $vm -ReferenceSnapshot $snapshot -VMHost $vmhost -Datastore $ds
$linkedvm | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName 480-wan
