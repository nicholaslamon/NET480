## TO DO:
## Add commenting for each section
## Increase error handling?


Function 480Banner(){

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

function 480Connect($conf){
    $conn = $global:DefaultVIServer

    #Are we already connected?
    if($conn){
        $msg = 'Already connected to: {0}' -f $conn
        Write-Host -ForegroundColor Green $msg
        Start-Sleep -Seconds 4

    }else {
        
        
        try {
            
            $conn = Connect-VIserver -Server $conf.vcenter_server
            #if this failts let Connect-VIServer handle the exception
            
            Write-Host "Connecting..."
            Start-Sleep -Seconds 2
            Write-Host "Connected!"
            Start-Sleep -Seconds 4
    
        } catch {

            Write-Host "Connection failed, please try again."
            Start-Sleep -Seconds 4

        }
    }
    
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
        $toclone = Get-VM -Name (Read-Host -Prompt "Enter a VM you wish to clone: ") -ErrorAction Stop

        try{

            Write-Host  ""
            $toclone | Get-Snapshot | Select-Object Name -ExpandProperty Name
            Write-Host  ""
            $toclone_snap = Get-Snapshot -VM $toclone -Name (Read-Host -Prompt "Enter the name of the snapshot you wish to use: ")

            $msg = "Defualt datastore is {0}, is that okay? (y or n)" -f $conf.datastore
            try {
                Write-Host  ""
                $datastore = Read-Host -Prompt $msg

                If ($datastore = "y"){
                    $datastore = $conf.datastore
                 } else {
                    Write-Host  ""
                    $datastore = Read-Host -Prompt "Enter the datastore you wish to use: " 

                 }

                try {
                        
                    Write-Host  ""
                    $clonename = Read-Host -Prompt "What to you wish to name your new vm? "
                
                        try{

                            $linkedname = "{0}.linked" -f $clonename
                            $linkedvm = New-VM -LinkedClone -Name $linkedname -VM $toclone -ReferenceSnapshot $toclone_snap -VMHost $conf.esxi_host -Datastore $datastore

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

                        } catch {

                            Write-Host "Linking failed, please try again."
                            Break
                        }

                } catch {

                    Write-Host "Invalid name of VM selected, please try again."
                    Write-Host "Likely a VM with this name already exists. Please select"
                    Write-Host "a different name and try again."
                    Break
                }

            } catch {

                Write-Host "Invalid datastore selected, please try again."
                Break
        }

        } catch {

            Write-Host = "Invalid Snapshot name selected, please try again."
            Break
        }

    }
    catch {

        Write-Host "Invalid VM selected, please try again."
        Break
    }

    MENU(conf$)

}


Function New-Network($conf){

    # Creates a new V Switch
    $switch = New-VirtualSwitch -VMHost $conf.esxi_host -Name(Read-Host "What do you want to name the new Virtual Switch: ") -Confirm:$false
    
    # Creates a new V Port Group
    $vport = New-VirtualPortGroup -VirtualSwitch $switch -Confirm:$false

}