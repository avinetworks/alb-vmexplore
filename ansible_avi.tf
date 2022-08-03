resource "null_resource" "ansible_avi" {
  count            = 1
  depends_on = [vsphere_virtual_machine.destroy_env_vm, null_resource.wait_https_controller]
  connection {
    host = var.vcenter_network_mgmt_dhcp == true ? vsphere_virtual_machine.destroy_env_vm[0].default_ip_address : split(",", replace(var.vcenter_network_mgmt_ip4_addresses, " ", ""))[2]
    type = "ssh"
    agent = false
    user = var.destroy_env_vm.username
    private_key = tls_private_key.ssh.private_key_pem
  }

  provisioner "file" {
    source = "ansible/aviConfigure"
    destination = "aviConfigure"
  }

  provisioner "file" {
    source = "ansible/aviAbsent"
    destination = "aviAbsent"
  }

  provisioner "remote-exec" {
    inline = var.vcenter_network_mgmt_dhcp == true ? [
      "cd aviConfigure",
      "ansible-playbook local.yml --extra-vars '{\"avi_version\": ${jsonencode(var.avi_version)}, \"controller_ip\": ${jsonencode(vsphere_virtual_machine.controller_dhcp[0].default_ip_address)}, \"avi_username\": ${jsonencode("admin")}, \"avi_password\": ${jsonencode(random_string.password.result)}, \"ntp_servers_ips\": ${jsonencode((split(",", replace(var.ntp_servers_ips, " ", ""))))}, \"dns_servers_ips\": ${jsonencode(split(",", replace(var.vcenter_network_mgmt_network_dns, " ", "")))}, \"avi_domain\": ${jsonencode(var.avi_domain)}, \"vsphere_username\": ${jsonencode(var.vsphere_username)}, \"vsphere_password\": ${jsonencode(var.vsphere_password)}, \"vsphere_server\": ${jsonencode(var.vsphere_server)}, \"vcenter_dc\": ${jsonencode(var.vcenter_dc)}, \"vcenter_network_mgmt_name\": ${jsonencode(var.vcenter_network_mgmt_name)}, \"vcenter_network_mgmt_network_cidr\": ${jsonencode(var.vcenter_network_mgmt_network_cidr)}, \"vcenter_network_mgmt_dhcp\": ${jsonencode(var.vcenter_network_mgmt_dhcp)}, \"vcenter_network_vip_name\": ${jsonencode(var.vcenter_network_vip_name)}, \"vcenter_network_vip_cidr\": ${jsonencode(var.vcenter_network_vip_cidr)}, \"vcenter_network_vip_ipam_pool\": ${jsonencode(split("-", replace(var.vcenter_network_vip_ipam_pool, " ", "")))}, \"vcenter_network_k8s_name\": ${jsonencode(var.vcenter_network_k8s_name)}, \"vcenter_network_k8s_cidr\": ${jsonencode(var.vcenter_network_k8s_cidr)}, \"vcenter_network_k8s_ipam_pool\": ${jsonencode(split("-", replace(var.vcenter_network_k8s_ipam_pool, " ", "")))}, \"vcenter_folder\": \"${var.vcenter_folder}-${random_string.id.result}\"}'"
    ] : [
      "cd aviConfigure",
      "ansible-playbook local.yml --extra-vars '{\"avi_version\": ${jsonencode(var.avi_version)}, \"controller_ip\": ${jsonencode(split(",", replace(var.vcenter_network_mgmt_ip4_addresses, " ", ""))[0])}, \"avi_username\": ${jsonencode("admin")}, \"avi_password\": ${jsonencode(random_string.password.result)}, \"ntp_servers_ips\": ${jsonencode((split(",", replace(var.ntp_servers_ips, " ", ""))))}, \"dns_servers_ips\": ${jsonencode(split(",", replace(var.vcenter_network_mgmt_network_dns, " ", "")))}, \"avi_domain\": ${jsonencode(var.avi_domain)}, \"vsphere_username\": ${jsonencode(var.vsphere_username)}, \"vsphere_password\": ${jsonencode(var.vsphere_password)}, \"vsphere_server\": ${jsonencode(var.vsphere_server)}, \"vcenter_dc\": ${jsonencode(var.vcenter_dc)}, \"vcenter_network_mgmt_name\": ${jsonencode(var.vcenter_network_mgmt_name)}, \"vcenter_network_mgmt_network_cidr\": ${jsonencode(var.vcenter_network_mgmt_network_cidr)}, \"vcenter_network_mgmt_dhcp\": ${jsonencode(var.vcenter_network_mgmt_dhcp)}, \"vcenter_network_mgmt_ipam_pool\": ${jsonencode(split("-", replace(var.vcenter_network_mgmt_ipam_pool, " ", "")))}, \"vcenter_network_vip_name\": ${jsonencode(var.vcenter_network_vip_name)}, \"vcenter_network_vip_cidr\": ${jsonencode(var.vcenter_network_vip_cidr)}, \"vcenter_network_vip_ipam_pool\": ${jsonencode(split("-", replace(var.vcenter_network_vip_ipam_pool, " ", "")))}, \"vcenter_network_k8s_name\": ${jsonencode(var.vcenter_network_k8s_name)}, \"vcenter_network_k8s_cidr\": ${jsonencode(var.vcenter_network_k8s_cidr)}, \"vcenter_network_k8s_ipam_pool\": ${jsonencode(split("-", replace(var.vcenter_network_k8s_ipam_pool, " ", "")))}, \"vcenter_folder\": \"${var.vcenter_folder}-${random_string.id.result}\"}'"
    ]
  }
}