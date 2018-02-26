# Modified from the documentation sample at https://docs.microsoft.com/en-us/azure/virtual-machines/scripts/virtual-machines-linux-powershell-sample-create-vm

# Log in to azure
# This command does not seem to work inside a script... Maybe it needs a sleep command??
#Add-AzureRmAccount

Function New-MyAzureVM ($loc, $name, $resGroup, $clientcred)
  {
  # Create the resource group (appears in the portal after this command)
  New-AzureRmResourceGroup -Name $resGroup -Location $loc

  # Create a subnet configuration
  $subnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name psLabSubnet -AddressPrefix 10.0.0.0/24

  # Create a virtual network (appears in the portal after this command)
  $vnet = New-AzureRmVirtualNetwork -ResourceGroupName $resGroup -Location $loc -Name psLabVNet -AddressPrefix 10.0.0.0/16 -Subnet $subnetConfig

  # Create a public IP address and specify a DNS name (appears in the portal after this command)
  $pip = New-AzureRmPublicIpAddress -ResourceGroupName $resGroup -Location $loc -Name "coatelab$(Get-Random)" -AllocationMethod Dynamic -IdleTimeoutInMinutes 4
  
  # Create an inbound network security group rule for port 22, 80 and 3389 so we can ssh, Web Browse and RDP to this machine
  $nsgRuleSSH = New-AzureRmNetworkSecurityRuleConfig -Name myNetworkSecurityGroupRuleSSH -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22 -Access Allow
  $nsgRuleWeb = New-AzureRmNetworkSecurityRuleConfig -Name myNetworkSecurityGroupRuleWeb -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 80 -Access Allow
  $nsgRuleRdp = New-AzureRmNetworkSecurityRuleConfig -Name myNetworkSecurityGroupRuleRdp -Protocol Tcp -Direction Inbound -Priority 101 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389 -Access Allow

  # Create a network security group (appears in the portal after this command)
  $nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $resGroup -Location $loc -Name psLabNSG -SecurityRules $nsgRuleSSH,$nsgRuleWeb,$nsgRuleRdp
  
  # Create a virtual network card and associate it with the public IP address and NSG (appears in the portal after this command)
  # $nic = New-AzureRmNetworkInterface -Name psLabNIC -ResourceGroupName $resGroup -Location $loc -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id
  
  # Debug: No net security group
  $nic = New-AzureRmNetworkInterface -Name psLabNIC -ResourceGroupName $resGroup -Location $loc -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id
  
  # Create a virtual machine configuration -Linux
  # $vmConfig = New-AzureRmVMConfig -VMName $name -VMSize Standard_A1 | 
  #   Set-AzureRmVMOperatingSystem -Linux -ComputerName $name -Credential $clientcred | 
  #   Set-AzureRmVMSourceImage -PublisherName Canonical -Offer UbuntuServer -Skus 16.04-LTS -Version latest | 
  #   Set-AzureRmVMOSDisk -Name psLabOSDisk -DiskSizeInGB 128 -CreateOption FromImage -Caching ReadWrite -StorageAccountType StandardLRS | 
  #   Add-AzureRmVMNetworkInterface -Id $nic.Id

  # Create a virtual machine configuration -Windows
  # Renames and sets password for built-in admin account to $clientcred
  $vmConfig = New-AzureRmVMConfig -VMName $name -VMSize Standard_A1 | 
    Set-AzureRmVMOperatingSystem -Windows -ComputerName $name -Credential $clientcred | 
    Set-AzureRmVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2016-Datacenter -Version latest | 
    Set-AzureRmVMOSDisk -Name psLabOSDisk -DiskSizeInGB 128 -CreateOption FromImage -Caching ReadWrite -StorageAccountType StandardLRS | 
    Add-AzureRmVMNetworkInterface -Id $nic.Id

  # image_urn: MicrosoftWindowsServer:WindowsServer:2012-R2-Datacenter:latest
  
  # "offer": "WindowsServer",
  # "publisher": "MicrosoftWindowsServer",
  # "sku": "2016-Datacenter",
  # "urn": "MicrosoftWindowsServer:WindowsServer:2016-Datacenter:latest",
  # "urnAlias": "Win2016Datacenter",
  # "version": "latest"
  
  # Create the virtual machine
  # and the OSDisk
  # and the Storage Account
  New-AzureRmVM -ResourceGroupName $resGroup -Location $loc -VM $vmConfig

  # Get the PublicIP
  # install-module -name wftools  (one time install of module)
  (Get-AzureRmVmPublicIP -ResourceGroupName $resGroup | where {$_.VMName -eq $name}).PublicIP
  }

# Variables for common values
# Set a variable to be your resource group's name
# $location = "westus"
# $vmName = "psLabVM"
$resourceGroup = "psResourceGroup"

# Create login credentials for your VM
$securePassword = ConvertTo-SecureString 'H0rnyBunny' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("coateds", $securePassword)

New-MyAzureVM "westus" "psLabVM" $resourceGroup $cred


# These commands cannot be run inside the PE ISE. Go to ChefDK PS window
# Test Connection:  ssh coateds@138.91.246.158
# Get-AzureRmVM -ResourceGroupName $resourceGroup -status -Name $vmName
# lsb_release -a to get Ubuntu version


# Run this to delete the whole kabooble (and the kit too)
# Remove-AzureRmResourceGroup -Name $resourceGroup

# This command cannot be run inside the PE ISE. Go to ChefDK PS window
# knife bootstrap [public ip] --ssh-user [user] --ssh-password [password] --sudo --node-name node1-ubuntu --run-list 'recipe[ubuntu-installation-recipes::server-info-web]' --json-attributes '{"cloud": {"Public_ip": "[public ip]"}}'
# knife bootstrap '104.42.70.234' --ssh-user 'coateds' --ssh-password 'H0rnyBunny' --sudo --node-name node1-ubuntu --run-list 'recipe[ubuntu-installation-recipes::server-info-web]' --json-attributes '{"cloud": {"Public_ip": "pslabvm"}}'

# knife bootstrap '104.42.70.92' --ssh-user 'coateds' --ssh-password 'H0rnyBunny' --sudo --node-name node1-ubuntu --run-list 'role[ubuntuweb]' --json-attributes '{"cloud": {"Public_ip": "pslabvm"}}'

# BootStrap a Windows VM
# knife bootstrap windows winrm '192.168.0.206' -r 'role[my-basic-role]' -x administrator -P 'xxxxxxxx' -N 'Server3x'
# Must open port 5985??
# Must run winrm quickconfig
# knife bootstrap windows winrm '13.64.148.123' -r 'role[my-basic-role]' -x coateds -P 'H0rnyBunny' -N 'node1-windows' --json-attributes '{"cloud": {"Public_ip": "pslabvm"}}'

# PS C:\chef> gem install knife-windows
# Fetching: knife-windows-1.9.0.gem (100%)
# WARNING:  You don't have c:\users\administrator.coatelab\appdata\local\chefdk\gem\ruby\2.4.0\bin in your PATH,
#           gem executables will not run.
# Successfully installed knife-windows-1.9.0
# Parsing documentation for knife-windows-1.9.0
# Installing ri documentation for knife-windows-1.9.0
# Done installing documentation for knife-windows after 1 seconds

# Detritus
# Get your resource group's name
#Get-AzureRmResourceGroup