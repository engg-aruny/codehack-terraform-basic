# Create a resource group
resource "azurerm_resource_group" "myresourcegroup" {
  name     = "my-resource-group"
  location = "eastus"
}

# Create a virtual network
resource "azurerm_virtual_network" "mynetwork" {
  name                = "my-virtual-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.myresourcegroup.location
  resource_group_name = azurerm_resource_group.myresourcegroup.name
}

# Create a subnet
resource "azurerm_subnet" "mysubnet" {
  name                 = "my-subnet"
  address_prefixes     = ["10.0.1.0/24"]
  virtual_network_name = azurerm_virtual_network.mynetwork.name
  resource_group_name  = azurerm_resource_group.myresourcegroup.name
}

# Create a public IP address
resource "azurerm_public_ip" "mypublicip" {
  name                = "my-public-ip"
  location            = azurerm_resource_group.myresourcegroup.location
  resource_group_name = azurerm_resource_group.myresourcegroup.name
  allocation_method   = "Static"
}

# Create a network interface
resource "azurerm_network_interface" "mynic" {
  name                = "my-network-interface"
  location            = azurerm_resource_group.myresourcegroup.location
  resource_group_name = azurerm_resource_group.myresourcegroup.name

  ip_configuration {
    name                          = "my-ip-configuration"
    subnet_id                     = azurerm_subnet.mysubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.mypublicip.id
  }
}

# Create a virtual machine
resource "azurerm_virtual_machine" "myvm" {
  name                  = "my-virtual-machine"
  location              = azurerm_resource_group.myresourcegroup.location
  resource_group_name   = azurerm_resource_group.myresourcegroup.name
  network_interface_ids = ["${azurerm_network_interface.mynic.id}"]
  vm_size               = "Standard_B2s"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "my-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "myvm"
    admin_username = "admin_01"
    admin_password = "myvmToRock@123"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}
