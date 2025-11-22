############################################################
# WEB TIER - Virtual Machine Scale Set
# Purpose: Nginx web servers that serve the frontend
############################################################

# 1. Public IP for the Load Balancer (so users can access)
resource "azurerm_public_ip" "web_lb_ip" {
  name                = "web-lb-public-ip"
  location            = "canadacentral"
  resource_group_name = "project1-RG"
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    tier = "web"
  }
}

# 2. Load Balancer for Web Tier
resource "azurerm_lb" "web_lb" {
  name                = "web-tier-lb"
  location            = "canadacentral"
  resource_group_name = "project1-RG"
  sku                 = "Standard"

  # Connect the public IP to the load balancer
  frontend_ip_configuration {
    name                 = "web-lb-frontend"
    public_ip_address_id = azurerm_public_ip.web_lb_ip.id
  }

  tags = {
    tier = "web"
  }
}
# 2a. NAT Pool for SSH access to VMs
resource "azurerm_lb_nat_pool" "ssh_nat_pool" {
  resource_group_name            = "project1-RG"
  loadbalancer_id                = azurerm_lb.web_lb.id
  name                           = "SSH-Keys"
  protocol                       = "Tcp"
  frontend_port_start            = 50000
  frontend_port_end              = 50099
  backend_port                   = 22
  frontend_ip_configuration_name = "web-lb-frontend"
}

# 3. Backend Pool - Where VMs register themselves
resource "azurerm_lb_backend_address_pool" "web_backend" {
  name            = "web-backend-pool"
  loadbalancer_id = azurerm_lb.web_lb.id
}

# 4. Health Probe - Check if VMs are alive
resource "azurerm_lb_probe" "web_health" {
  name                = "web-health-probe"
  loadbalancer_id     = azurerm_lb.web_lb.id
  protocol            = "Tcp"
  port                = 80
  interval_in_seconds = 5
  number_of_probes    = 2
}

# 5. Load Balancing Rule - How traffic is distributed
resource "azurerm_lb_rule" "web_http" {
  name                           = "web-http-rule"
  loadbalancer_id                = azurerm_lb.web_lb.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "web-lb-frontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.web_backend.id]
  probe_id                       = azurerm_lb_probe.web_health.id
  disable_outbound_snat          = false
  #enable_tcp_reset               = true
}

############################################################
# 6. Virtual Machine Scale Set - The actual VMs!
############################################################
resource "azurerm_linux_virtual_machine_scale_set" "web_vmss" {
  name                = "web-tier-vmss"
  resource_group_name = "project1-RG"
  location            = "canadacentral"
  sku                 = "Standard_B1s"
  instances           = 1
  admin_username      = "azureuser"

  # Spread VMs across availability zones for high availability
  zones = ["1", "2", "3"]

  # Use our generated SSH key for authentication
  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.vm_ssh_key.public_key_openssh
  }

  # Disable password authentication (SSH keys only = more secure)
  disable_password_authentication = true

  # OS Disk configuration
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS" # Standard locally-redundant storage
  }

  # Ubuntu 20.04 LTS image
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  # ADD THIS: Install Nginx automatically when VM starts
  custom_data = base64encode(file("${path.module}/scripts/web-tier-init.sh"))

  network_interface {
    name    = "web-vmss-nic"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.web_subnet.id

      load_balancer_backend_address_pool_ids = [
        azurerm_lb_backend_address_pool.web_backend.id
      ]

      load_balancer_inbound_nat_rules_ids = [azurerm_lb_nat_pool.ssh_nat_pool.id]
    }
    network_security_group_id = azurerm_network_security_group.web_nsg.id
  }

  tags = {
    tier        = "web"
    environment = "dev"
  }

  depends_on = [
    tls_private_key.vm_ssh_key,
    azurerm_lb_backend_address_pool.web_backend
  ]
}

############################################################
# Outputs - Important information
############################################################
output "web_lb_public_ip" {
  value       = azurerm_public_ip.web_lb_ip.ip_address
  description = "Public IP address of Web Tier Load Balancer"
}

output "web_vmss_id" {
  value       = azurerm_linux_virtual_machine_scale_set.web_vmss.id
  description = "ID of Web Tier VMSS"
}
output "private_key" {
  value     = tls_private_key.vm_ssh_key.private_key_pem
  sensitive = true
}