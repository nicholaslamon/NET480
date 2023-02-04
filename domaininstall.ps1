##############################################
#### Windows PowerShell script for AD DS Deployment ####
##############################################

$DomainName = Read-Host -Prompt 'Input a domain name: '

Install-WindowsFeature -name AD-Domain-Services -IncludeManagementTools
Install-ADDSForest `
-CreateDnsDelegation:$false `
-DatabasePath "C:\Windows\NTDS" `
-DomainMode "WinThreshold" `
-DomainName "[local]" `
-DomainNetbiosName "[480]" `
-ForestMode "WinThreshold" `
-InstallDns:$true `
-LogPath "C:\Windows\NTDS" `
-NoRebootOnCompletion:$false `
-SysvolPath "C:\Windows\SYSVOL" `
-Force:$true

############### End of Script ####################
