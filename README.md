# Azure VM Creation with PowerShell and Chef

This repository contains PowerShell scripts for building Ubuntu and Windows Azure VMs. Then there is a command for each to bootstrap these VMs into a Chef server/organization.

Prerequisites for running the VM creation script
`install-module AzureRM`  --  PS module for managing Azure RM

 Log in to azure
 (This command does not seem to work inside a script... Maybe it needs a sleep command??)
`Add-AzureRmAccount`

## Ubuntu Server 16.04 latest
opens ports 22, 80 and 3389, the Chef role installs a web server, xRDP and a GUI. Test the installation with ssh, RDP and a browser.

The script's function will return the public IP address of the new VM, which could be used to run the bootstrap command

## Bootstrap the Ubuntu Server
`knife bootstrap '40.78.103.239' --ssh-user 'coateds' --ssh-password 'xxxxxxxxxx' --sudo --node-name node1-ubuntu --run-list 'role[ubuntuweb]' --json-attributes '{"cloud": {"Public_ip": "pslabvm"}}'`

When bootstrapping a test node like this, be sure to delete the old node from hosted chef

The bootstrap command must be run from the ChefDK special PS window. The current dir of that window must contain a .chef dir that points to the correct hosted chef organization.