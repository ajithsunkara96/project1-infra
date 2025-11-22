# NAT Gateway Public IP
resource "azurerm_public_ip" "nat_gateway_ip" {
  name                = "nat-gateway-ip"
  location            = "canadacentral"
  resource_group_name = "project1-RG"
  allocation_method   = "Static"
  sku                 = "Standard"
}

# NAT Gateway
resource "azurerm_nat_gateway" "app_nat" {
  name                = "app-nat-gateway"
  location            = "canadacentral"
  resource_group_name = "project1-RG"
  sku_name            = "Standard"
}

# Associate Public IP with NAT Gateway
resource "azurerm_nat_gateway_public_ip_association" "nat_ip_assoc" {
  nat_gateway_id       = azurerm_nat_gateway.app_nat.id
  public_ip_address_id = azurerm_public_ip.nat_gateway_ip.id
}

# Associate NAT Gateway with App Subnet
resource "azurerm_subnet_nat_gateway_association" "app_subnet_nat" {
  subnet_id      = azurerm_subnet.app_subnet.id
  nat_gateway_id = azurerm_nat_gateway.app_nat.id
}