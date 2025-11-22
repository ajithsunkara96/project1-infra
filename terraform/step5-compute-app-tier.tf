############################################################
# APP TIER - Virtual Machine Scale Set
# Purpose: Node.js API servers that handle business logic
############################################################

# 1. Load Balancer for App Tier (Internal only)
resource "azurerm_lb" "app_lb" {
  name                = "app-tier-lb"
  location            = "canadacentral"
  resource_group_name = "project1-RG"
  sku                 = "Standard"

  # Internal load balancer (no public IP)
  frontend_ip_configuration {
    name                          = "app-lb-frontend"
    subnet_id                     = azurerm_subnet.app_subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    tier = "app"
  }
}

# 2. Backend Pool
resource "azurerm_lb_backend_address_pool" "app_backend" {
  name            = "app-backend-pool"
  loadbalancer_id = azurerm_lb.app_lb.id
}

# 3. Health Probe
resource "azurerm_lb_probe" "app_health" {
  name                = "app-health-probe"
  loadbalancer_id     = azurerm_lb.app_lb.id
  protocol            = "Http"
  port                = 3000
  request_path        = "/health"
  interval_in_seconds = 5
  number_of_probes    = 2
}

# 4. Load Balancing Rule
resource "azurerm_lb_rule" "app_api" {
  name                           = "app-api-rule"
  loadbalancer_id                = azurerm_lb.app_lb.id
  protocol                       = "Tcp"
  frontend_port                  = 3000
  backend_port                   = 3000
  frontend_ip_configuration_name = "app-lb-frontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.app_backend.id]
  probe_id                       = azurerm_lb_probe.app_health.id
  load_distribution              = "Default"
}

############################################################
# 5. Virtual Machine Scale Set - App Tier
############################################################
resource "azurerm_linux_virtual_machine_scale_set" "app_vmss" {
  name                = "app-tier-vmss"
  resource_group_name = "project1-RG"
  location            = "canadacentral"
  sku                 = "Standard_B1s"
  instances           = 1
  admin_username      = "azureuser"

  zones = ["1", "2", "3"]

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.vm_ssh_key.public_key_openssh
  }

  disable_password_authentication = true

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  # Install Node.js and API server automatically
  custom_data = base64encode(file("${path.module}/scripts/app-tier-init.sh"))

  network_interface {
    name    = "app-vmss-nic"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.app_subnet.id

      load_balancer_backend_address_pool_ids = [
        azurerm_lb_backend_address_pool.app_backend.id
      ]
    }

    network_security_group_id = azurerm_network_security_group.app_nsg.id
  }

  tags = {
    tier        = "app"
    environment = "dev"
  }

  depends_on = [
    tls_private_key.vm_ssh_key,
    azurerm_lb_backend_address_pool.app_backend
  ]
}

############################################################
# Outputs
############################################################
output "app_lb_private_ip" {
  value       = azurerm_lb.app_lb.frontend_ip_configuration[0].private_ip_address
  description = "Internal IP address of App Tier Load Balancer"
}

output "app_vmss_id" {
  value       = azurerm_linux_virtual_machine_scale_set.app_vmss.id
  description = "ID of App Tier VMSS"
}