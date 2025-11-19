############################################################
# SSH Key Pair Generation for VM Access
############################################################

# 1. Generate a new RSA key pair (4096 bits = very secure)
resource "tls_private_key" "vm_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 2. Create a folder to store the keys
resource "local_file" "ssh_key_directory" {
  content  = ""
  filename = "${path.module}/ssh-keys/.gitkeep"
}

# 3. Save the PRIVATE key to a file (keep this secure)
resource "local_file" "private_key" {
  content         = tls_private_key.vm_ssh_key.private_key_pem
  filename        = "${path.module}/ssh-keys/project1-vm-key.pem"
  file_permission = "0600"

  depends_on = [local_file.ssh_key_directory]
}

# 4. Save the PUBLIC key to a file (safe to share)
resource "local_file" "public_key" {
  content         = tls_private_key.vm_ssh_key.public_key_openssh
  filename        = "${path.module}/ssh-keys/project1-vm-key.pub"
  file_permission = "0644" # Anyone can read, but not modify

  depends_on = [local_file.ssh_key_directory]
}

############################################################
# Outputs - Show the public key and SSH command
############################################################
output "ssh_private_key_path" {
  value       = local_file.private_key.filename
  description = "Path to SSH private key file"
}

output "ssh_public_key" {
  value       = tls_private_key.vm_ssh_key.public_key_openssh
  description = "SSH public key for VMs"
  sensitive   = false
}