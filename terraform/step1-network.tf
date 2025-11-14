# 1️⃣ Virtual Network
resource "azurerm_virtual_network" "project1_vnet" {
  name                = "project1-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = "canadacentral"
  resource_group_name = "project1-RG"
}

# 2️⃣ Subnets
resource "azurerm_subnet" "web_subnet" {
  name                 = "web-subnet"
  resource_group_name  = "project1-RG"
  virtual_network_name = azurerm_virtual_network.project1_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "app_subnet" {
  name                 = "app-subnet"
  resource_group_name  = "project1-RG"
  virtual_network_name = azurerm_virtual_network.project1_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "db_subnet" {
  name                 = "db-subnet"
  resource_group_name  = "project1-RG"
  virtual_network_name = azurerm_virtual_network.project1_vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

# 3️⃣ Network Security Groups
resource "azurerm_network_security_group" "web_nsg" {
  name                = "web-nsg"
  location            = "canadacentral"
  resource_group_name = "project1-RG"

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "app_nsg" {
  name                = "app-nsg"
  location            = "canadacentral"
  resource_group_name = "project1-RG"

  security_rule {
    name                       = "AllowAppFromWeb"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = azurerm_subnet.web_subnet.address_prefixes[0]
    source_port_range =         "*"
    destination_port_range     = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "db_nsg" {
  name                = "db-nsg"
  location            = "canadacentral"
  resource_group_name = "project1-RG"

  security_rule {
    name                       = "AllowDbFromApp"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = azurerm_subnet.app_subnet.address_prefixes[0]
    source_port_range =        "*"
    destination_port_range     = "*"
    destination_address_prefix = "*"
  }
}

# 4️⃣ Associate NSGs with subnets
resource "azurerm_subnet_network_security_group_association" "web_assoc" {
  subnet_id                 = azurerm_subnet.web_subnet.id
  network_security_group_id = azurerm_network_security_group.web_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "app_assoc" {
  subnet_id                 = azurerm_subnet.app_subnet.id
  network_security_group_id = azurerm_network_security_group.app_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "db_assoc" {
  subnet_id                 = azurerm_subnet.db_subnet.id
  network_security_group_id = azurerm_network_security_group.db_nsg.id
}

# 5️⃣ Outputs
output "vnet_id" {
  value = azurerm_virtual_network.project1_vnet.id
}

output "web_subnet_id" {
  value = azurerm_subnet.web_subnet.id
}

output "app_subnet_id" {
  value = azurerm_subnet.app_subnet.id
}

output "db_subnet_id" {
  value = azurerm_subnet.db_subnet.id
}