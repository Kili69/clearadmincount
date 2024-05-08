# clearadmincount

### clearadmincount.ps1 is a powershell script to reset the admincount attribute on non privielged users
This powershell script changes the admincount attribut to 0 to any non privileged account and enables the ACL inheritance on the user object

### Details
This script searches for active directory user where admincount attribute is set to 1 and the user is not member of
- Administrators
- Domain Admins
- Enterprise Admins
- Group Policy Creator Owner
- Account Operators
- Server Operators
- Backup Operators

on any user object where the attribute is changed, the security inheritance will be enabled and explicit ACE entry onthis object will be removed.

### Usage
```powershell
PS C:\Kili69\clearadmincount.ps1


