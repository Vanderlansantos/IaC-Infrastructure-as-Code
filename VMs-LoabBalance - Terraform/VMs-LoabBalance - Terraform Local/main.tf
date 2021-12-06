provider "azurerm" {
    # The "feature" block is required for AzureRM provider 2.x.
    # If you're using version 1.x, the "features" block is not allowed.
    version = ">=2.68.0"
    features {}
}

terraform {
  backend "local" {}
}
data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "resource_group" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "example" {
  name                = "virtualNetworkDev"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]

}
resource "azurerm_network_security_group" "nsg-azure1" {
  name                = "nsg-frontend"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

    security_rule {
    name                       = "RDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }
  security_rule {
    name                       = "HTTP"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"

  }

}
resource "azurerm_network_security_group" "nsg-azure2" {
  name                = "nsg-backend"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
}
resource "azurerm_subnet" "subnet1" {
  name                 = "frontend"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.0.0/24"]
}
resource "azurerm_subnet" "subnet2" {
  name                 = "backend"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
  depends_on           = [azurerm_subnet.subnet1]
}
## Associando NSG a SubNet de fronend
resource "azurerm_subnet_network_security_group_association" "nsg1" {
  subnet_id                 = azurerm_subnet.subnet1.id
  network_security_group_id = azurerm_network_security_group.nsg-azure1.id
  depends_on = [azurerm_subnet.subnet1]
}
## Associando NSG a SubNet de backend
resource "azurerm_subnet_network_security_group_association" "nsg2" {
  subnet_id                 = azurerm_subnet.subnet2.id
  network_security_group_id = azurerm_network_security_group.nsg-azure2.id
  depends_on                = [azurerm_subnet_network_security_group_association.nsg1,azurerm_subnet.subnet2]
}

resource "azurerm_public_ip" "ippublic" {
  name                    = "ip-public"
  location                = azurerm_resource_group.resource_group.location
  resource_group_name     = azurerm_resource_group.resource_group.name
  allocation_method       = "Dynamic"
  idle_timeout_in_minutes = 30
}
## IpPublico para o LoadBalance
resource "azurerm_public_ip" "ipload" {
  name                    = "Ip-public-lb"
  location                = azurerm_resource_group.resource_group.location
  resource_group_name     = azurerm_resource_group.resource_group.name
  allocation_method       = "Dynamic"
  idle_timeout_in_minutes = 30
}
resource "azurerm_dns_zone" "example" {
  name                = "testeterraform.com"
  resource_group_name = azurerm_resource_group.resource_group.name
}
resource "azurerm_dns_a_record" "example" {
  name                = "test"
  zone_name           = azurerm_dns_zone.example.name
  resource_group_name = azurerm_resource_group.resource_group.name
  ttl                 = 300
  target_resource_id  = azurerm_public_ip.ipload.id
}
resource "azurerm_network_interface" "nic" {
  name                = "nic-web"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "public"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ippublic.id
  }
}
resource "azurerm_network_interface" "nic1" {
  name                = "nic-bancodedados"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet2.id
    private_ip_address_allocation = "Dynamic"
  }
  depends_on          = [azurerm_network_interface.nic]
}
## Associação da placa de rede ao NSG de frontend
resource "azurerm_network_interface_security_group_association" "interface1" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg-azure1.id
}
## Associação da placa de rede ao NSG de backend
resource "azurerm_network_interface_security_group_association" "interface2" {
  network_interface_id      = azurerm_network_interface.nic1.id
  network_security_group_id = azurerm_network_security_group.nsg-azure2.id
}
## VM interna
resource "azurerm_windows_virtual_machine" "vm1" {
  name                = "vm-bancodedados"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  size                = "Standard_D2s_v3"
  admin_username      = "adminteste"
  admin_password      = "teste@123"
  network_interface_ids = [azurerm_network_interface.nic1.id]
  
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
  depends_on = [azurerm_network_interface.nic1]
}

## VM da aplicação
resource "azurerm_windows_virtual_machine" "vm" {
  name                = "vm-web"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  size                = "Standard_D2s_v3"
  admin_username      = "adminteste"
  admin_password      = "teste@123"
  network_interface_ids = [azurerm_network_interface.nic.id]
  
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
  depends_on = [azurerm_network_interface.nic]
}
## LoadBalance publico, para VM de aplicação
resource "azurerm_lb" "lb" {
  name                = "LoadBalancer"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.ipload.id
  }
}
## LoadBalance interno, para VM interna
resource "azurerm_lb" "lb1" {
  name                = "LoadBalancer-backend"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  frontend_ip_configuration {
    name                 = "BackEnd"
    subnet_id            = azurerm_subnet.subnet1.id
  }
}
## Obter o pool de endereço pro loadbalance publico
resource "azurerm_lb_backend_address_pool" "pool" {
   loadbalancer_id     = azurerm_lb.lb.id
   name                = "BackEndAddressPool"
}

## Obter o pool de endereço pro loadbalance interno
resource "azurerm_lb_backend_address_pool" "backpool" {
   loadbalancer_id     = azurerm_lb.lb1.id
   name                = "BackEndAddressPool1"
}
## Regra LoadBalance publico
 resource "azurerm_lb_probe" "probe" {
  resource_group_name = azurerm_resource_group.resource_group.name
  loadbalancer_id     = azurerm_lb.lb.id
  name                = "classiclb"
  port                = 80
  interval_in_seconds = 10
  number_of_probes    = 3
  protocol            = "Http"
  request_path        = "/" 
}
## Regra  LoadBalance publico
resource "azurerm_lb_rule" "example" {
  resource_group_name            = azurerm_resource_group.resource_group.name
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "classiclb"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.pool.id
  probe_id                       = azurerm_lb_probe.probe.id
}
## Associnar a VM ao pool de endereco para o Loadbalance - vm da aplicação
resource "azurerm_network_interface_backend_address_pool_association" "example" {
  network_interface_id    = azurerm_network_interface.nic.id
  ip_configuration_name   = "public"
  backend_address_pool_id = azurerm_lb_backend_address_pool.pool.id
}
## Associnar a VM ao pool de endereco para o Loadbalance - vm interna
resource "azurerm_network_interface_backend_address_pool_association" "example1" {
  network_interface_id    = azurerm_network_interface.nic1.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backpool.id
}