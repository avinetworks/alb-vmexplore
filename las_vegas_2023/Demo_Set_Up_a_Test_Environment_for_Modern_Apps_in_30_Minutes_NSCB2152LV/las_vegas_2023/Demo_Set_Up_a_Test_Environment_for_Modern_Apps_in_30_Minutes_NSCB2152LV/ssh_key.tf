
resource "tls_private_key" "ssh" {
  algorithm = var.ssh_key.algorithm
  rsa_bits  = var.ssh_key.rsa_bits
}

resource "local_file" "private_key" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = pathexpand("~/.ssh/${var.ssh_key.private_key_basename}-${random_string.id.result}.pem")
  file_permission = var.ssh_key.file_permission
}