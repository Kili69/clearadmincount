<#
Script Info

Author: Andreas Lucas [MSFT]
Download: https://github.com/Kili69/clearadmincount

Disclaimer:
This sample script is not supported under any Microsoft standard support program or service. 
The sample script is provided AS IS without warranty of any kind. Microsoft further disclaims 
all implied warranties including, without limitation, any implied warranties of merchantability 
or of fitness for a particular purpose. The entire risk arising out of the use or performance of 
the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, 
or anyone else involved in the creation, production, or delivery of the scripts be liable for any 
damages whatsoever (including, without limitation, damages for loss of business profits, business 
interruption, loss of business information, or other pecuniary loss) arising out of the use of or 
inability to use the sample scripts or documentation, even if Microsoft has been advised of the 
possibility of such damages

Version
    0.1.20240508

.Synopsis
    Manage admincount attribute

.DESCRIPTION
    This script change the admincount attribute to 0 if the user is not member of administrators,  
    domain admins, Enterprise Admins, Group Policy creator, Account Operators, Server Operators 
    or Backup Operators.
    Additional to change the admincount attribute, the ACL inheritance will be enabled and the AdminHolder ACE
    entries will be remoed
.OUTPUTS 
    None
#>

$aryUsers = @()
#Get any user with admincount = 1 except the built-in administrator and the krbtgt account

$aryUsers = Get-ADUser -LDAPFilter "(admincount=1)" | Where-Object {($_.SID -notlike "*-500") -and ($_.SID -notlike "*-502")}
#on any user with admincount=1 validate the user is not member of the administrators group
Foreach ($User in $aryUsers){
    $isAdmin = $false
    $MemberOf = Get-ADGroup -LDAPFilter ("(member:1.2.840.113556.1.4.1941:={0})" -f $User.DistinguishedName) -Properties ObjectSID
    #walk throught the groups
    foreach ($group in $Memberof){
        #if the group SID ends with -544 => the user is member of administrators
        switch -wildcard ($Group.ObjectSID) {
            "S-1-5-32-544" {
                #Is Member of administrator
                $isAdmin = $true; 
                Write-Host "$User is member of Administrators. The AdminCount attribute will not changed"
                break
            } 
            "*-512" {
                #Is Member of Domain Admins
                $isAdmin = $true; 
                Write-Host "$User is member of Domain Admins. The AdminCount attribute will not changed"
                break
            }
            "*-519" {
                #Is member of Enterprise Admins
                $isAdmin = $true; 
                Write-Host "$User is member of Enterprise Admins. The AdminCount attribute will not changed"
                break
            }
            "*-520" {
                #Is member of Group Policy creator Owner
                $isAdmin = $true
                Write-Host "$user is member of Group Policy Creator Owner. The AdminCount attribute will not changed"
            } 
            "S-1-5-32-548" {
                #Is member of Account Operators
                $isAdmin = $true; 
                Write-Host "$User is member of Account operators. The AdminCount attribute will not changed"
                break
            }
            "S-1-5-32-549" {
                #Is member of Server Operators
                $isAdmin = $true; 
                Write-Host "$User is member of Server Operators. The AdminCount attribute will not changed"
                break
            }
            "S-1-5-32-551" {
                #Is member of Backup Operators
                $isAdmin = $true; 
                Write-Host "$User is member of Backup Operators. The AdminCount attribute will not changed"
                break
            }
        }
    }
    if (!$isAdmin){
        Write-Host "found user $user who has admincount=1 but the user is not member of a protected group" -ForegroundColor Yellow
        Write-Host "resetting attribute"
        $user.AdminCount = 0
        Set-ADUser -Instance $User
        $acl = Get-Acl -Path "AD:\$($user.DistinguishedName)"
        # Enable inheritance
        $acl.SetAccessRuleProtection($false,$false)
        $aceToRemove = $acl.Access | Where-Object {$_.isInherited -eq $false}
        foreach ($ace in $aceToRemove){ $acl.RemoveAccessRule($ace)} 
        Set-Acl -Path "AD:\$($user.DistinguishedName)" -AclObject $acl
    }
}
