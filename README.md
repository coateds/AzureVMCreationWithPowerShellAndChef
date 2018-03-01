# Azure VM Creation with PowerShell and Chef

This repository contains PowerShell scripts for building Ubuntu and Windows Azure VMs. Then there is a command for each to bootstrap these VMs into a Chef server/organization.

Prerequisites for running the VM creation script
`install-module AzureRM`  --  PS module for managing Azure RM

Log in to azure
(This command does not seem to work inside a script... Maybe it needs a sleep command??)
`Add-AzureRmAccount`

```diff
-Alternate is use Get-AzurePublishSettingsFile for automation
-save the file in c:\chef (or whatever chef root dir you are working from)
```

There is a Chef Gem that also needs to be installed on the ChefDK workstation for Windows WinRM
`gem install knife-windows`

## Ubuntu Server 16.04 latest
opens ports 22, 80 and 3389, the Chef role installs a web server, xRDP and a GUI. Test the installation with ssh, RDP and a browser.

The script's function will return the public IP address of the new VM, which could be used to run the bootstrap command

## Bootstrap the Ubuntu Server
`knife bootstrap '40.78.103.239' --ssh-user 'coateds' --ssh-password 'xxxxxxxxxx' --sudo --node-name node1-ubuntu --run-list 'role[ubuntuweb]' --json-attributes '{"cloud": {"Public_ip": "pslabvm"}}'`

When bootstrapping a test node like this, be sure to delete the old node from hosted chef

The bootstrap command must be run from the ChefDK special PS window. The current dir of that window must contain a .chef dir that points to the correct hosted chef organization.

## Windows 2016 Latest
opens ports 80, 3389 and 5985 (22 not 5985 if working inside my workplace)

The script's function will return the public IP address of the new VM, but the bootstrap command requires a public FQDN be set in Azure for the NIC of the VM. Creating the FQDN in the Az Portal is simple. Just configure the DNS Name for the VM.

But can this be done in the script? The following command will retrieve the current DNS Settings for a Public IP Address. (Name is that assigned to the PIP when the VM is built, the number is random)
`(get-AzureRmPublicIpAddress -ResourceGroupName psWinResourceGroup -Name coatelab875374664).DnsSettings`

Yes, this can be done in the script by modifying the command to create a Public IP to include a "DomainNameLabel"

The bootstrap command also requires that the client VM's firewall be opened for port 5985. More specifically, the existing rule allows connection from local subnet, it has to be adjusted to allow from any subnet.

```powershell
netsh advfirewall firewall set rule name="Windows Remote Management (HTTP-In)" profile=public protocol=tcp localport=5985 remoteip=localsubnet new remoteip=any
# This command changes remoteip from localsubnet to any
```

Source: https://blogs.technet.microsoft.com/christwe/2012/06/20/what-port-does-powershell-remoting-use/


Recap on a Windows VM
1. The FQDN requirement is easily fulfilled in the PS script
2. The firewall on the Windows Server must be opened in 1 of 3 ways
  * `netsh advfirewall firewall set rule name="Windows Remote Management (HTTP-In)" profile=public protocol=tcp localport=5985 remoteip=localsubnet new remoteip=any`
  * `Set-Item WSMan:\localhost\Service\EnableCompatibilityHttpListener -Value true`  In this case '-p 80' must be added to the bootstrap command
  * `Set-Item wsman:\localhost\listener\listener*\port –value <Port>`  For my workplace port = 22 and '-p 22' must be added to the bootstrap command
  * Source: https://blogs.technet.microsoft.com/christwe/2012/06/20/what-port-does-powershell-remoting-use/

## Azure Chef Extension
For use with Azure, there is an alternative to bootstrapping a node.

Start research here:
https://github.com/chef-partners/azure-chef-extension
https://docs.microsoft.com/en-us/azure/virtual-machines/windows/extensions-features
https://docs.microsoft.com/en-us/azure/virtual-machines/windows/chef-automation