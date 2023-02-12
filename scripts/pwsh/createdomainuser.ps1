$User = Read-Host -Prompt 'Enter the username: '
$Group = Read-Host -Prompt 'Enter the group you want the user to be added to: '

New-ADUser -Name $User -AccountPassword(Read-Host -AsSecureString AccountPassword)
Add-ADGroupMember -Identity "$Group" -Members $User `
