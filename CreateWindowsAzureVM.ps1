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
  # Add DomainNameLabel to create an fqdn
  $pip = New-AzureRmPublicIpAddress -DomainNameLabel $name -ResourceGroupName $resGroup -Location $loc -Name "coatelab$(Get-Random)" -AllocationMethod Dynamic -IdleTimeoutInMinutes 4
  #$pip=New-AzurePublicIpAddress -Name $nicName -ResourceGroupName $rgName -DomainNameLabel $domName -Location $locName -AllocationMethod Dynamic
  #DomainNameLabel must be lowercase
  
  # Create an inbound network security group rule for port 22, 80 and 3389 so we can ssh, Web Browse and RDP to this machine
  $nsgRuleSSH = New-AzureRmNetworkSecurityRuleConfig -Name myNetworkSecurityGroupRuleSSH -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22 -Access Allow
  $nsgRuleWeb = New-AzureRmNetworkSecurityRuleConfig -Name myNetworkSecurityGroupRuleWeb -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 80 -Access Allow
  $nsgRuleRdp = New-AzureRmNetworkSecurityRuleConfig -Name myNetworkSecurityGroupRuleRdp -Protocol Tcp -Direction Inbound -Priority 101 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389 -Access Allow
  $nsgRuleWinRm = New-AzureRmNetworkSecurityRuleConfig -Name myNetworkSecurityGroupRuleWinRm -Protocol Tcp -Direction Inbound -Priority 102 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 5985 -Access Allow

  # Create a network security group (appears in the portal after this command)
  $nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $resGroup -Location $loc -Name psLabNSG -SecurityRules $nsgRuleSSH,$nsgRuleWeb,$nsgRuleRdp,$nsgRuleWinRm
  
  # Create a virtual network card and associate it with the public IP address and NSG (appears in the portal after this command)
  $nic = New-AzureRmNetworkInterface -Name psLabNIC -ResourceGroupName $resGroup -Location $loc -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id
  
  # Debug: No net security group
  # $nic = New-AzureRmNetworkInterface -Name psLabNIC -ResourceGroupName $resGroup -Location $loc -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id
  
  $WindowSku = "2008-R2-SP1"
  # 2016-Datacenter
  # 2012-R2-Datacenter
  # 2012-Datacenter
  # 2008-R2-SP1

  # Create a virtual machine configuration -Windows
  # Renames and sets password for built-in admin account to $clientcred
  $vmConfig = New-AzureRmVMConfig -VMName $name -VMSize Standard_A1 | 
    Set-AzureRmVMOperatingSystem -Windows -ComputerName $name -Credential $clientcred | 
    Set-AzureRmVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus $WindowSku -Version latest | 
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
$resourceGroup = "ps2008r2ResourceGroup"

# Create login credentials for your VM
$securePassword = ConvertTo-SecureString 'H0rnyBunny' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("coateds", $securePassword)

New-MyAzureVM "westus" "pslab2008r2vm" $resourceGroup $cred


# Run this to delete the whole kabooble (and the kit too)
# Remove-AzureRmResourceGroup -Name $resourceGroup

# BootStrap a Windows VM
# knife bootstrap windows winrm '192.168.0.206' -r 'role[my-basic-role]' -x administrator -P 'xxxxxxxx' -N 'Server3x'
# Must open port 5985??
# Must run winrm quickconfig
# knife bootstrap windows winrm '13.64.148.123' -r 'role[my-basic-role]' -x coateds -P 'H0rnyBunny' -N 'node1-windows' --json-attributes '{"cloud": {"Public_ip": "pslabvm"}}'

# On ChefDK workstation
# PS C:\chef> gem install knife-windows

# knife bootstrap windows winrm 'pslabvm.westus.cloudapp.azure.com' -r 'role[my-basic-role]' -x .\coateds -P 'H0rnyBunny' -N 'node1-windows' --json-attributes '{"cloud": {"Public_ip": "pslabvm"}}'

# Current bootstrap command
# 1) The Azure FQDN, add DNS entry
# 2) Configure Windows FW on target server
#      This works with one caveat, the command from the ChefDK workstation does not always return
#      netsh advfirewall firewall set rule name="Windows Remote Management (HTTP-In)" profile=public protocol=tcp localport=5985 remoteip=localsubnet new remoteip=any

# knife bootstrap windows winrm 'pslabwinvm.westus.cloudapp.azure.com' -r 'role[my-basic-role]' -x .\coateds -P 'H0rnyBunny' -N 'node2-windows'


# This does not help???
# set winrm/config/winrs '@{MaxMemoryPerShellMB="300"}'
# winrm set winrm/config '@{MaxTimeoutms="1800000"}'

# Get-AzureRmDnsRecordSet -ZoneName "westus.cloudapp.azure.com" -ResourceGroupName $resourceGroup

# (get-AzureRmPublicIpAddress -ResourceGroupName psWinResourceGroup -Name coatelab875374664).DnsSettings