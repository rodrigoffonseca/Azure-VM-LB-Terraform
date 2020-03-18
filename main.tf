# Configure the Microsoft Azure Provider.
provider "azurerm" {
    version = "=2.0.0"
    subscription_id = "cce01445-8719-4563-b5b7-37b26250b020"
    client_id       = "e779ba7b-619d-4617-a964-66d743f02887"
    client_secret   = "2f053691-cce4-435c-84ee-917e30b84aa8"
    tenant_id       = "72f988bf-86f1-41af-91ab-2d7cd011db47"
    #service principal information to login 
    features {}
}

# Create a resource group
resource "azurerm_resource_group" "rg" {
    name     = "${var.prefix}TFRG-${local.environment}"
    location = var.location
    tags     = var.tags
} 

# Create virtual network
resource "azurerm_virtual_network" "vnet" {
    name                = "${var.prefix}TFVnet-${local.environment}"
    address_space       = ["10.0.0.0/16"]
    location            = var.location
    resource_group_name = azurerm_resource_group.rg.name
    tags                = var.tags
}

# Create subnet
resource "azurerm_subnet" "subnet" {
    name                 = "${var.prefix}TFSubnet"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefix       = "10.0.1.0/24"
    service_endpoints         = ["Microsoft.Storage","Microsoft.Sql"]
}

# Create public IP
resource "azurerm_public_ip" "publicip" {
    name                         = "${var.prefix}TFPublicIP-${local.environment}"
    location                     = var.location
    resource_group_name          = azurerm_resource_group.rg.name
    allocation_method            = "Static"
    tags                         = var.tags
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "nsg" {
    name                = "${var.prefix}TFNSG-${local.environment}"
    location            = var.location
    resource_group_name = azurerm_resource_group.rg.name
    tags                = var.tags

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    security_rule {
        name                       = "HTTP"
        priority                   = 1010
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}

# Create a Linux virtual machine
resource "azurerm_virtual_machine" "vm" {
    name                  = "${var.prefix}TFVM${count.index}-${local.environment}"
    location              = var.location
    resource_group_name   = azurerm_resource_group.rg.name
    network_interface_ids = ["${element(azurerm_network_interface.nic.*.id, count.index)}"]
    vm_size               = local.size
    tags                  = var.tags
    availability_set_id = azurerm_availability_set.avset.id
    count = 3

    storage_os_disk {
        name              = "${var.prefix}OsDisk${count.index}"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = lookup(var.sku, var.location)
        version   = "latest"
    }

    os_profile {
        computer_name  = "${var.prefix}TFVM${count.index}-${local.environment}"
        admin_username = var.adminname
        admin_password = var.adminpwd
    }

    os_profile_linux_config {
        disable_password_authentication = false
    }
    
}

# Create network interface
resource "azurerm_network_interface" "nic" {
    name                      = "${var.prefix}NIC${count.index}-${local.environment}"
    location                  = var.location
    resource_group_name       = azurerm_resource_group.rg.name
    tags                      = var.tags
    count = 3

    ip_configuration {
        name                          = "IPConfig1"
        subnet_id                     = azurerm_subnet.subnet.id
        private_ip_address_allocation = "dynamic"
        #public_ip_address_id          = "${azurerm_public_ip.publicip.id}"
    }
}
# create nat rule association
resource "azurerm_network_interface_nat_rule_association" "natrule" {
    network_interface_id = element(azurerm_network_interface.nic.*.id, count.index)
    ip_configuration_name = "IPConfig1"
    nat_rule_id           = element(azurerm_lb_nat_rule.tcp.*.id, count.index)
    count = 3
}
# create load balancer backend pool association with VM NICs
resource "azurerm_network_interface_backend_address_pool_association" "backendassociation" {
  network_interface_id    = element(azurerm_network_interface.nic.*.id, count.index)
  ip_configuration_name   = "IPConfig1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id
  count = 3
}
# create availability set
resource "azurerm_availability_set" "avset" {
    name = "vmavset-${local.environment}"
    platform_fault_domain_count = "3"
    platform_update_domain_count = "5" 
    resource_group_name = azurerm_resource_group.rg.name
    location = var.location
    managed = "true"
}


#create load balance

resource "azurerm_lb" "lb" {

  resource_group_name = azurerm_resource_group.rg.name

  name                = "LB${var.prefix}-${local.environment}"

  location            = var.location



  frontend_ip_configuration {

    name                 = "LoadBalancerFrontEnd"

    public_ip_address_id = azurerm_public_ip.publicip.id

  }

}

resource "azurerm_lb_backend_address_pool" "backend_pool" {

  resource_group_name = azurerm_resource_group.rg.name

  loadbalancer_id     = azurerm_lb.lb.id

  name                = "BackendPool1"

}


resource "azurerm_lb_nat_rule" "tcp" {

  resource_group_name            = azurerm_resource_group.rg.name

  loadbalancer_id                = azurerm_lb.lb.id

  name                           = "RDP-VM-${count.index}"

  protocol                       = "tcp"

  frontend_port                  = "5000${count.index + 1}"

  backend_port                   = 3389

  frontend_ip_configuration_name = "LoadBalancerFrontEnd"

  count = 3

}

resource "azurerm_lb_rule" "lb_rule" {

  resource_group_name            = azurerm_resource_group.rg.name

  loadbalancer_id                = azurerm_lb.lb.id

  name                           = "LBRule"

  protocol                       = "tcp"

  frontend_port                  = 80

  backend_port                   = 80

  frontend_ip_configuration_name = "LoadBalancerFrontEnd"

  enable_floating_ip             = false

  backend_address_pool_id        = azurerm_lb_backend_address_pool.backend_pool.id

  idle_timeout_in_minutes        = 5

  probe_id                       = azurerm_lb_probe.lb_probe.id

  depends_on                     = [azurerm_lb_probe.lb_probe]

}

resource "azurerm_lb_probe" "lb_probe" {

  resource_group_name = azurerm_resource_group.rg.name

  loadbalancer_id     = azurerm_lb.lb.id

  name                = "tcpProbe"

  protocol            = "tcp"

  port                = 80

  interval_in_seconds = 5

  number_of_probes    = 2

}

#Custom script to install apache on all VMS
resource "azurerm_virtual_machine_extension" "ApacheInstall" {
  name                 = "hostname"
  virtual_machine_id   = element(azurerm_virtual_machine.vm.*.id, count.index)
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"
  count = 3

settings = <<SETTINGS
    {
    "fileUris": ["${var.scripturl}"],
    "commandToExecute": "sh apache-install.sh"
    }
SETTINGS

  tags = {
    environment = "Production"
  }
}

#get public IP address data
data "azurerm_public_ip" "test" {
  name                = azurerm_public_ip.publicip.name
  resource_group_name = azurerm_resource_group.rg.name
}

#Terraform backend config for Remote State in Azure Storage Account
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-foca-storage"
    storage_account_name = "safocainfra"
    container_name       = "terraformstate"
    key                  = "terraform.tfstate"
  }
}

# Locals

locals {
  environment = lookup(var.workspace_to_environment_map, terraform.workspace, "dev")
  size = "${local.environment == "dev" ? lookup(var.workspace_to_size_map, terraform.workspace, "Standard_B2s") : var.environment_to_size_map[local.environment]}"
}


#output variables for Public IP Address and VM SKU
output "ip" {
  value = "${data.azurerm_public_ip.test.ip_address}"
}
