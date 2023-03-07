## TO DO:
## Add commenting for each section
## Create hashtable for Get-IP function


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
    [5] Create a New V Network
    [6] Get System Information
    [7] Set Network Adapter
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
                '5' {
                    Clear-Host
                    New-Network($conf)
                }
                '6' {
                    Clear-Host
                    Get-IP($conf)
                }
                '7' {
                    Clear-Host
                    Set-Network($conf)
                }
                Default {Write-Host "Please select an option 1-7"}

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
    MENU($conf)
}

Function Cloner($conf){

    try {
        Write-Host ""
        Get-VM -Location $conf.vm_cfolder | Select-Object Name -ExpandProperty Name
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

    MENU($conf)

}


Function New-Network($conf){


    try {
        # Creates a new V Switch
        $vswitch = New-VirtualSwitch -VMHost $conf.esxi_host -Name (Read-Host "What do you want to name the new Virtual Switch: ")
            
        
        Write-Host "Creating..."
        $msg = "Created Virtual Switch {0}!" -f $vswitch.Name
        Write-Host $msg

    
        try {
            # Creates a new V Port Group
            $vport = New-VirtualPortGroup -VirtualSwitch $vswitch  -Name(Read-Host "What do you wish to name the Virtual Port Group: ")

            Write-Host "Creating..."
            $msg2 = "Created Virtual Port Group {0}!" -f $vport.Name
            Write-Host $msg2

        } catch {

            Write-Host "Virtual Port Group creation failed, please try again." -ForegroundColor DarkRed
            Start-Sleep -Seconds 4

        }

        } catch {

            Write-Host "Virtual Switch creation failed, please try again." -ForegroundColor DarkRed
            Start-Sleep -Seconds 4
        }
        MENU($conf)
    }

Function Get-IP($conf){

    Write-Host "What host would you like to get information on?"
    Get-VM -Location $conf.vm_folder | Select-Object Name -ExpandProperty Name
    Write-Host ""
    $vm = Read-Host "Enter hostname from list above: "

    $ip = (Get-VM -Name $vm).Guest.IPAddress[0]

    $mac = (Get-NetworkAdapter -VM $vm | Select-Object MacAddress).MacAddress[0]
    
    $msg = "$ip hostname=$vm mac=$mac"
    Write-Host $msg
}

Function PowerSwitch($conf){

    Write-Host "What host would you like to change the power state on?"
    Write-Host ""
    Get-VM -Location $conf.vm_folder | Select-Object Name -ExpandProperty Name
    Write-Host ""

    $vm = Read-Host "Enter hostname from the list above: "
    Write-Host "Power State: "
    Get-VM -Name $vm | Select-Object PowerState -ExpandProperty PowerState
    $power = Read-Host "Would you like to turn that vm on or off? "

    If($power -eq "on"){
        
        Start-VM -VM $vm
        Write-Host "$vm is now on!"
        Start-Sleep -Seconds 4

    } elseif($power -eq "off"){
        Stop-VM -VM $vm -Confirm:$false
        Write-Host "$vm is now off!"
        Start-Sleep -Seconds 4
    } else {

        Write-Host "Please select either on or off."
        PowerSwitch($conf)
    }
    MENU($conf)
}

Function Set-Network ($conf){


    try {
        Write-Host "What VM would you like to change the network adapter on?"
        Write-Host ""
        Get-VM -Location $conf.vm_folder | Select-Object Name -ExpandProperty Name
        Write-Host ""

        $vm = Read-Host "Select a VM from the list above: "
        Write-Host ""

        Get-VirtualNetwork
        Write-Host ""
        $network = Read-Host "Select a network from the list above: "
        Write-Host ""


        Get-NetworkAdapter -VM $vm | Select-Object Name -ExpandProperty Name
        Write-Host ""
        $netad = Read-Host "Select what network adapter you would like to change: "
        Write-Host ""

        Write-Host "Configuring."
        Write-Host "Configuring.."
        Get-VM $vm | Get-NetworkAdapter -Name $netad| Set-NetworkAdapter -NetworkName $network -Confirm:$false
    } catch {

        Write-Host "Critical error occurred, seek script creator for solution."
        Start-Sleep -Seconds 4
        Write-Host "Actually, nvm, you just stupid..."
        Start-Sleep -Seconds 1
       }

    MENU($conf)
}