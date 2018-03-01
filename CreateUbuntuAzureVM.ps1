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
  # DomainNameLabel must be lowercase
  $pip = New-AzureRmPublicIpAddress -DomainNameLabel $name -ResourceGroupName $resGroup -Location $loc -Name "coatelab$(Get-Random)" -AllocationMethod Dynamic -IdleTimeoutInMinutes 4

  # Create an inbound network security group rule for port 22, 80 and 3389 so we can ssh, Web Browse and RDP to this machine
  $nsgRuleSSH = New-AzureRmNetworkSecurityRuleConfig -Name myNetworkSecurityGroupRuleSSH -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22 -Access Allow
  $nsgRuleWeb = New-AzureRmNetworkSecurityRuleConfig -Name myNetworkSecurityGroupRuleWeb -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 80 -Access Allow
  $nsgRuleRdp = New-AzureRmNetworkSecurityRuleConfig -Name myNetworkSecurityGroupRuleRdp -Protocol Tcp -Direction Inbound -Priority 101 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389 -Access Allow

  # Create a network security group (appears in the portal after this command)
  $nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $resGroup -Location $loc -Name psLabNSG -SecurityRules $nsgRuleSSH,$nsgRuleWeb,$nsgRuleRdp

  # Create a virtual network card and associate it with the public IP address and NSG (appears in the portal after this command)
  $nic = New-AzureRmNetworkInterface -Name psLabNIC -ResourceGroupName $resGroup -Location $loc -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id

  # Create a virtual machine configuration -Linux
  $vmConfig = New-AzureRmVMConfig -VMName $name -VMSize Standard_A1 |
    Set-AzureRmVMOperatingSystem -Linux -ComputerName $name -Credential $clientcred |
    Set-AzureRmVMSourceImage -PublisherName Canonical -Offer UbuntuServer -Skus 16.04-LTS -Version latest |
    Set-AzureRmVMOSDisk -Name psLabOSDisk -DiskSizeInGB 128 -CreateOption FromImage -Caching ReadWrite -StorageAccountType StandardLRS |
    Add-AzureRmVMNetworkInterface -Id $nic.Id

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
$resourceGroup = "psUbuntuResourceGroup"

# Create login credentials for your VM
$securePassword = ConvertTo-SecureString 'H0rnyBunny' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("coateds", $securePassword)

New-MyAzureVM "westus" "pslabubuntuvm" $resourceGroup $cred

# These commands cannot be run inside the PE ISE. Go to ChefDK PS window
# Test Connection:  ssh coateds@138.91.246.158
# Get-AzureRmVM -ResourceGroupName $resourceGroup -status -Name $vmName
# lsb_release -a to get Ubuntu version


# Run this to delete the whole kabooble (and the kit too)
# Remove-AzureRmResourceGroup -Name $resourceGroup

# This command cannot be run inside the PE ISE. Go to ChefDK PS window
# knife bootstrap [public ip] --ssh-user [user] --ssh-password [password] --sudo --node-name node1-ubuntu --run-list 'recipe[ubuntu-installation-recipes::server-info-web]' --json-attributes '{"cloud": {"Public_ip": "[public ip]"}}'
# knife bootstrap '104.42.70.234' --ssh-user 'coateds' --ssh-password 'H0rnyBunny' --sudo --node-name node1-ubuntu --run-list 'recipe[ubuntu-installation-recipes::server-info-web]' --json-attributes '{"cloud": {"Public_ip": "pslabvm"}}'

# knife bootstrap '40.78.103.239' --ssh-user 'coateds' --ssh-password 'H0rnyBunny' --sudo --node-name node1-ubuntu --run-list 'role[ubuntuweb]' --json-attributes '{"cloud": {"Public_ip": "pslabvm"}}'

# Detritus
# Get your resource group's name
#Get-AzureRmResourceGroup