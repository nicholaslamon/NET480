Import-Module '480-utils' -Force

# Call the Banner Function
480Banner
$conf = Get-480Config -config_path "480.json" 
# 480Connect -server $conf.vcenter_server

# Write-Host "Selecting your VM"
# Select-VM -folder "BASE-VM"

MENU($conf)