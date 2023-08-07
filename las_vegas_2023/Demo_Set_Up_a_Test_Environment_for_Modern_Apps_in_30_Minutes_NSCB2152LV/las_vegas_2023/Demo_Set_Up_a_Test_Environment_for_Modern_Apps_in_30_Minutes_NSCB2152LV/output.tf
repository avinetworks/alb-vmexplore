# Outputs for Terraform

output "Avi_login" {
  value = "admin"
}

output "Avi_password" {
  value = random_string.password.result
}

output "Avi_controller_IP" {
  value = var.vcenter_network_mgmt_dhcp == true ? "https://${vsphere_virtual_machine.controller_dhcp[0].default_ip_address}" : "https://${split(",", replace(var.vcenter_network_mgmt_ip4_addresses, " ", ""))[0]}"
}

output "Ssh_username" {
  value = "ubuntu"
}

output "Ssh_password" {
  value = random_string.password.result
}

output "Destroy_command_all" {
  value = var.vcenter_network_mgmt_dhcp == true ? "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.ssh_key.private_key_basename}-${random_string.id.result}.pem -t ubuntu@${vsphere_virtual_machine.destroy_env_vm[0].default_ip_address} './destroyAvi.sh'; sleep 5 ; terraform destroy -auto-approve" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.ssh_key.private_key_basename}-${random_string.id.result}.pem -t ubuntu@${split(",", replace(var.vcenter_network_mgmt_ip4_addresses, " ", ""))[2]} './destroyAvi.sh'; sleep 5 ; terraform destroy -auto-approve"
  description = "command to destroy the avi config"
}

output "Destroy_command_avi_config_only" {
  value = var.vcenter_network_mgmt_dhcp == true ? "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.ssh_key.private_key_basename}-${random_string.id.result}.pem -t ubuntu@${vsphere_virtual_machine.destroy_env_vm[0].default_ip_address} './destroyAvi.sh'" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.ssh_key.private_key_basename}-${random_string.id.result}.pem -t ubuntu@${split(",", replace(var.vcenter_network_mgmt_ip4_addresses, " ", ""))[2]} './destroyAvi.sh'"
  description = "command to destroy the avi config"
}

output "ako_install_command_to_apply_on_master_node" {
  value = var.ako_deploy == true ? "AKO has been deployed automatically" : "helm --debug install ako/ako --generate-name --version ${var.ako_version} -f values.yml --namespace=avi-system --set avicredentials.username=admin --set avicredentials.password=$avi_password"
}

output "ssh_connect_to_client_VM" {
  value = var.vcenter_network_mgmt_dhcp == true ? "ssh -i ~/.ssh/${var.ssh_key.private_key_basename}-${random_string.id.result}.pem -o StrictHostKeyChecking=no ubuntu@${vsphere_virtual_machine.client_dhcp[0].default_ip_address}" : "ssh -i ~/.ssh/${var.ssh_key.private_key_basename}-${random_string.id.result}.pem -o StrictHostKeyChecking=no ubuntu@${split(",", replace(var.vcenter_network_mgmt_ip4_addresses, " ", ""))[1]}"
}

output "ssh_connect_to_destroy_env_VM" {
  value = var.vcenter_network_mgmt_dhcp == true ? "ssh -i ~/.ssh/${var.ssh_key.private_key_basename}-${random_string.id.result}.pem -o StrictHostKeyChecking=no ubuntu@${vsphere_virtual_machine.destroy_env_vm[0].default_ip_address}" : "ssh -i ~/.ssh/${var.ssh_key.private_key_basename}-${random_string.id.result}.pem -o StrictHostKeyChecking=no ubuntu@${split(",", replace(var.vcenter_network_mgmt_ip4_addresses, " ", ""))[2]}"
}

output "ssh_connect_to_master_VM" {
  value = var.vcenter_network_mgmt_dhcp == true ? "ssh -i ~/.ssh/${var.ssh_key.private_key_basename}-${random_string.id.result}.pem -o StrictHostKeyChecking=no ubuntu@${vsphere_virtual_machine.master.default_ip_address}" : "ssh -i ~/.ssh/${var.ssh_key.private_key_basename}-${random_string.id.result}.pem -o StrictHostKeyChecking=no ubuntu@${split(",", replace(var.vcenter_network_mgmt_ip4_addresses, " ", ""))[3]}"
}

output "ssh_connect_to_worker1_VM" {
  value = var.vcenter_network_mgmt_dhcp == true ? "ssh -i ~/.ssh/${var.ssh_key.private_key_basename}-${random_string.id.result}.pem -o StrictHostKeyChecking=no ubuntu@${vsphere_virtual_machine.workers[0].default_ip_address}" : "ssh -i ~/.ssh/${var.ssh_key.private_key_basename}-${random_string.id.result}.pem -o StrictHostKeyChecking=no ubuntu@${split(",", replace(var.vcenter_network_mgmt_ip4_addresses, " ", ""))[4]}"
}

output "ssh_connect_to_worker2_VM" {
  value = var.vcenter_network_mgmt_dhcp == true ? "ssh -i ~/.ssh/${var.ssh_key.private_key_basename}-${random_string.id.result}.pem -o StrictHostKeyChecking=no ubuntu@${vsphere_virtual_machine.workers[1].default_ip_address}" : "ssh -i ~/.ssh/${var.ssh_key.private_key_basename}-${random_string.id.result}.pem -o StrictHostKeyChecking=no ubuntu@${split(",", replace(var.vcenter_network_mgmt_ip4_addresses, " ", ""))[5]}"
}