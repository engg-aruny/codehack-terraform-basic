### What is Terraform?
**Terraform is an open-source** infrastructure as code (IaC) tool that allows users to define and manage their cloud infrastructure in a declarative way. This means that users can write code that describes their desired infrastructure state, and Terraform will handle the provisioning and management of the actual resources in the cloud provider.

We talk about Terraform theory in detail in our previous article [Part1 - Terraform on Microsoft Azure](https://www.arunyadav.in/codehacks/blogs/post/44/part1-terraform-on-microsoft-azure)

### Terraform to create/provision a virtual machine (VM) in Azure

![Terraform Workflow](https://www.dropbox.com/s/1eo8xtvihwsgach/Cover_Image.jpg?raw=1 "Terraform Workflow")

1. **Azure subscription**: If you don't have an Azure subscription, create a [free account](https://azure.microsoft.com/free/?ref=microsoft.com&utm_source=microsoft.com&utm_medium=docs&utm_campaign=visualstudio)
2. **Installing Terraform** [Terraform Download - For Windows](https://learn.microsoft.com/en-us/azure/developer/terraform/get-started-windows-powershell?tabs=bash#4-install-terraform-for-windows)

> From the downloaded zip file you need to extract the executable to your directory e.g. `c:\terraform` and then make sure to update your global path.

3. **Install Azure CLI on Windows** [Install or update](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-windows?tabs=azure-cli#install-or-update)

The Azure Command-Line Interface (CLI) is a cross-platform command-line tool that can be installed locally on Windows computers. You can use the Azure CLI for Windows to connect to Azure and execute administrative commands on Azure resources.

> Make sure to **restart your command prompt** after setting global path and azure cli

4. **Create a `main.tf`**
This is the main Terraform configuration file where you define the resources and their configurations that you want to create or manage in your cloud infrastructure.

```bash
# Provider block for Azure
provider "azurerm" {
  features {}
}

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

```

5. **Using Azure CLI**

_Prepare your working directory for other commands_

```bash
terraform init -upgrade
```

Output:

![terraform init -upgrade](https://www.dropbox.com/s/kbpw5nr93rwrio9/create-terraform-%20terraform-init_output.jpg?raw=1 "terraform init -upgrade")

_Show changes required by the current configuration, and create an execution plan and output to `*.tfplan`_

```bash
terraform plan -out main.tfplan
```
Output:

![terraform plan ](https://www.dropbox.com/s/lustbogbqf5cln2/create-terraform-%20terraform-plan-output.png?raw=1 "terraform plan")

_Create or update infrastructure_

```bash
terraform apply main.tfplan
```
Output:

![terraform apply](https://www.dropbox.com/s/8tgnzacz8r3xgpu/create-terraform-%20terraform-plan-apply-output.png?raw=1 "terraform apply")


### Validating Deployment/Virtual Machine
Output-
![Provisioned Virtual Machine](https://www.dropbox.com/s/sqxkd7fhzdqo5j9/virtual_machine_azure.png?raw=1 "Provisioned Virtual Machine")

### **Clean up resources** 

When you no longer need the resources created via Terraform, do the following steps:

_Destroy previously-created infrastructure and output to `*.destroy.tfplan`_

```bash
terraform plan -destroy -out main.destroy.tfplan
```

```bash
terraform apply main.destroy.tfplan
```
Output:

![Terraform Destroy](https://www.dropbox.com/s/86n2q8d5pakyljn/terraform-plan-distroy-output.png?raw=1 "Terraform Destroy")


### Using Input and Output variable

**Input variable** Let you customize the terraform module so that can use reused for multiple configurations if required. Let's see how we can declare input variables.

`variables.tf`

```bash
# Define input variables
variable "resource_group_name" {
  type    = string
  default = "my-resource-group"
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "virtual_network_name" {
  type    = string
  default = "my-virtual-network"
}

```
Example of using a variable in `main.tf` (note: we are using `var` here)

```bash
# Create a resource group
resource "azurerm_resource_group" "myresourcegroup" {
  name     = var.resource_group_name
  location = var.location
}

# Create a virtual network
resource "azurerm_virtual_network" "mynetwork" {
  name                = var.virtual_network_name
  address_space       = var.address_space
  location            = azurerm_resource_group.myresourcegroup.location
  resource_group_name = azurerm_resource_group.myresourcegroup.name
}
```

**Output value** Output values make information about your infrastructure available on the command line, and can expose information for other Terraform configurations to use. Output values are similar to return values in programming languages.

`outputs.tf` 

```bash
output "resource_group_name" {
value = azurerm_resource_group.myresourcegroup.name
}

output "virtual_network_name" {
value = azurerm_virtual_network.mynetwork.name
}

output "subnet_name" {
value = azurerm_subnet.mysubnet.name
}

```

Example of using an output value

```bash
terraform output resource_group_name
```

### Summary
Provided step-by-step instructions on how to perform this transformation also discussion was focused on transforming a Terraform file to use input and output variables. 
