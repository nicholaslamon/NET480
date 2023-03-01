function 480Banner(){

    $banner = @"

 _        _______ _________               ___     _____    _______ 
| \    /||  ____ \\__   __/              /   |   / ___ \  /  __   \
|  \  | || |    \/   | |                / /| |  | |___| | | |  /  |
|   \ | || |__       | |      _____    / /_| |_  \     /  | | /   |
| |\ \| ||  __|      | |     |_____|  |____   _| / ___ \  | |/ /| |
| | \   || |         | |                   | |  | /   \ | |   / | |
| |  \  || |____/\   | |                   | |  | \___/ | |  /__| |
|/    \_||_______/   |_|                   |_|   \_____/  \_______/
                                                                     
by Nick Lamon    
"@
Write-Host $banner
Write-Host ""
}


Function MENU($conf){

    Clear-Host
    480Banner
    Write-Host "
    Please Select an Option:
    [1] Exit
    [2] Cloner
    [3] Connection Test
    [4] Power a VM On/Off
    "
    $selection = Read-Host "Enter an option from above: "

            switch($selection){
                '1' {
                    Clear-Host
                    Break
                }
                '2' {
                    Clear-Host
                    Cloner($conf)
                }
                '3' {
                    Clear-Host
                    480Connect($conf)
                }
                '4' {
                    Clear-Host
                    PowerSwitch($conf)
                }
                Default {Write-Host "Please select an option 1-4"}

            }
}

function 480Connect([string] $server){
    $conn = $global:DefaultVIServer

    #Are we already connected?
    if($conn){
        $msg = 'Already connected to: {0}' -f $conn
        Write-Host -ForegroundColor Green $msg
    }else {
        $conn = Connect-VIserver -Server $server
        #if this failts let Connect-VIServer handle the exception
    }

    Start-Sleep -Seconds 4
    MENU($conf)
}

function Get-480Config([string] $config_path){
    $conf = $null
    if(Test-Path $config_path) {
        $conf = (Get-Content -Raw -Path $config_path | ConvertFrom-Json)
        $msg = 'Using configuration file at {0}' -f $config_path
        Write-Host -ForegroundColor Green $msg
    } else {
        Write-Host -ForegroundColor Yellow "No configuration done"
    }
    return $conf
}


Function Select-VM([string] $folder){

    $selected_vm=$null
    try {
        $vms = Get-VM -Location $folder
        $index = 1
        foreach ($vm in $vms){
            Write-Host [$index] $vm.Name
            $index+=1
        }

        $pick_index = Read-Host "Which index number [x] do you wish to pick?"
        $selected_vm = $vms[$pick_index -1]
        Write-Host "You selected " $selected_vm.Name
        return $selected_vm
    }
    catch {
        Write-Host "Invalid Folder: $folder" -ForegroundColor Red
    }

}

Function Cloner($conf){
        

    try {
        Write-Host ""
        Get-VM -Location $conf.vm_folder | Select-Object Name -ExpandProperty Name
        Write-Host  ""
        $toclone = Get-VM -Name (Read-Host -Prompt "Enter a VM you wish to clone: ")

    }
    catch {

        Write-Host "Invalid VM selected, please try again."
        Break
    }
    
    try{

        Write-Host  ""
        $toclone | Get-Snapshot | Select-Object Name -ExpandProperty Name
        Write-Host  ""
        $toclone_snap = Get-Snapshot -VM $toclone -Name (Read-Host -Prompt "Enter the name of the snapshot you wish to use: ")

    } catch {

        Write-Host = "Invalid Snapshot name selected, please try again."
        Break
    }

        $msg = "Defualt datastore is {0}, is that okay? (y or n)" -f $conf.datastore
    try {
        Write-Host  ""
        $datastore = Read-Host -Prompt $msg

        If ($datastore = 'y'){
            $datastore = $conf.datastore
        } else {
            Write-Host  ""
            $datastore = Read-Host -Prompt "Enter the datastore you wish to use: " 

        }
    } catch {

        Write-Host "Invalid datastore selected, please try again."
        Break
    }

    try {
        Write-Host  ""
        $clonename = Read-Host -Prompt "What to you wish to name your new vm? "
    } catch {

        Write-Host "Invalid name of VM selected, please try again."
        Write-Host "Likely a VM with this name already exists. Please select"
        Write-Host "a different name and try again."
        Break
    }

    try{

        $linkedname = "{0}.linked" -f $clonename
        $linkedvm = New-VM -LinkedClone -Name $linkedname -VM $toclone -ReferenceSnapshot $toclone_snap -VMHost $conf.esxi_host -Datastore $datastore

    } catch {

        Write-Host "Linking failed, please try again."
        Break
    }

    try{ 
        $newvm = New-VM -Name $clonename -VM $linkedvm -VMHost $conf.esxi_host -Datastore $datastore
        $newvm | New-Snapshot -Name "Base" 

        $linkedvm | Remove-VM -DeletePermanently -Confirm:$false
        Write-Host ""
        Write-Host "Clone created at $datastore named $clonename." -ForegroundColor Green
        
        Start-Sleep -Seconds 4
    
    } catch { 

        Write-Host "Critical error occurred during last phase, please try again."
        Write-Host "Likely due to an issue with the names of the VM or linked clone."
        Break
    }
    MENU($conf)
}

Function PowerSwitch($conf){

    Write-Host "Selecting your VM." -ForegroundColor DarkMagenta

    $selected_vm = $null
    $vms = Get-VM
    $index = 1

    foreach ($vm in $vms){

        Write-Host [$index] $vm.Name
        $index+=1

    }

    $pick_index = Read-Host "Which index number do you wish to select? "

    try {

        $selected_vm = $vms[$pick_index -1]
        Write-Host "You selected " $selected_vm.name -ForegroundColor Cyan

    } catch {

        $msg = "Invalid format, please select 1-{0}" -f $index-1
        Write-Host -ForegroundColor DarkRed $msg
    }

    $OnOrOff = Read-Host "Would you like to turn that VM on or off? "

        if($OnOrOff -like 'on'){ 
            Start-VM -VM $selected_vm -Confirm:$false -RunAsync
            Write-Host "VM {0} is being turned on." -f $selected_vm.Name
            Start-Sleep -Seconds 4

        }

        elseif ($OnOrOff -like 'off'){ 
            Stop-VM -VM $selected_vm -Confirm:$false 
            Write-Host "VM {0} is being turned off." -f $selected_vm.Name
            Start-Sleep -Seconds 4

        }

    MENU($conf)
}