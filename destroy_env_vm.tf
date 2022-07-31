data "template_file" "destroy_vm_static" {
  count = (var.vcenter_network_mgmt_dhcp == false ? 1 : 0)
  template = file("templates/network_destroy_vm.template")
  vars = {
    ip4_main = "${split(",", replace(var.vcenter_network_mgmt_ip4_addresses, " ", ""))[2]}/${split("/", var.vcenter_network_mgmt_network_cidr)[1]}"
    gw4 = var.vcenter_network_mgmt_gateway4
    dns = var.vcenter_network_mgmt_network_dns
  }
}

data "template_file" "destroy_env_vm_userdata_static" {
  count = (var.vcenter_network_mgmt_dhcp == false ? 1 : 0)
  depends_on = [local_file.private_key]
  template = file("${path.module}/userdata/destroy_env_vm_static.userdata")
  vars = {
    pubkey        = chomp(tls_private_key.ssh.public_key_openssh)
    avi_sdk_version = var.avi_version
    hostname = "${var.destroy_env_vm.name}${random_string.id.result}"
    ansible_version = var.ansible.version
    vsphere_username  = var.vsphere_username
    vsphere_password = var.vsphere_password
    vsphere_server = var.vsphere_server
    username = var.destroy_env_vm.username
    private_key = "${var.ssh_key.private_key_basename}-${random_string.id.result}.pem"
    network_config  = base64encode(data.template_file.destroy_vm_static[0].rendered)
    password      = var.static_password == null ? random_string.password.result : var.static_password
    net_plan_file = var.destroy_env_vm.net_plan_file
  }
}

data "template_file" "destroy_env_vm_userdata_dhcp" {
  count = (var.vcenter_network_mgmt_dhcp == true ? 1 : 0)
  depends_on = [local_file.private_key]
  template = file("${path.module}/userdata/destroy_env_vm_dhcp.userdata")
  vars = {
    pubkey        = chomp(tls_private_key.ssh.public_key_openssh)
    hostname = "${var.destroy_env_vm.name}${random_string.id.result}"
    avi_sdk_version = var.avi_version
    ansible_version = var.ansible.version
    vsphere_username  = var.vsphere_username
    vsphere_password = var.vsphere_password
    vsphere_server = var.vsphere_server
    username = var.destroy_env_vm.username
    private_key = "${var.ssh_key.private_key_basename}-${random_string.id.result}.pem"
    password      = var.static_password == null ? random_string.password.result : var.static_password
  }
}

resource "vsphere_virtual_machine" "destroy_env_vm" {
  count = 1
  name             = "${var.destroy_env_vm.name}${random_string.id.result}"
  datastore_id     = data.vsphere_datastore.datastore.id
  resource_pool_id = data.vsphere_resource_pool.pool.id
  folder           = vsphere_folder.folder.path
  network_interface {
    network_id = data.vsphere_network.network_mgmt.id
  }

  num_cpus = var.destroy_env_vm.cpu
  memory = var.destroy_env_vm.memory
  guest_id = "ubuntu64Guest"

  disk {
    size             = var.destroy_env_vm.disk
    label            = "${var.destroy_env_vm.name}.vmdk"
    thin_provisioned = true
  }

  cdrom {
    client_device = true
  }

  clone {
    template_uuid = vsphere_content_library_item.file_ubuntu_focal.id
  }

  vapp {
    properties = {
      hostname    = "${var.destroy_env_vm.name}${random_string.id.result}"
      public-keys = chomp(tls_private_key.ssh.public_key_openssh)
      user-data   = var.vcenter_network_mgmt_dhcp == true ? base64encode(data.template_file.destroy_env_vm_userdata_dhcp[0].rendered) : base64encode(data.template_file.destroy_env_vm_userdata_static[0].rendered)
    }
  }

  connection {
    host        = var.vcenter_network_mgmt_dhcp == true ? self.default_ip_address : split(",", replace(var.vcenter_network_mgmt_ip4_addresses, " ", ""))[2]
    type        = "ssh"
    agent       = false
    user        = var.destroy_env_vm.username
    private_key = tls_private_key.ssh.private_key_pem
  }

  provisioner "remote-exec" {
    inline      = [
      "while true ; do sleep 5 ; if [ -s \"/tmp/cloudInitFailed.log\" ] ; then exit 255 ; fi; if [ -s \"/tmp/cloudInitDone.log\" ] ; then exit ; fi ; done"
    ]
  }

  provisioner "file" {
    source      = "~/.ssh/${var.ssh_key.private_key_basename}-${random_string.id.result}.pem"
    destination = "/home/${var.destroy_env_vm.username}/.ssh/${var.ssh_key.private_key_basename}-${random_string.id.result}.pem"
  }

  provisioner "file" {
    source      = "bash/destroyAvi.sh"
    destination = "/home/${var.destroy_env_vm.username}/destroyAvi.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 600 ~/.ssh/${var.ssh_key.private_key_basename}-${random_string.id.result}.pem"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "chmod u+x ~/destroyAvi.sh"
    ]
  }
}

resource "null_resource" "clear_ssh_key_locally_destroy_env_vm" {
  count = 1
  provisioner "local-exec" {
    command = var.vcenter_network_mgmt_dhcp == true ? "ssh-keygen -f \"/home/ubuntu/.ssh/known_hosts\" -R \"${vsphere_virtual_machine.destroy_env_vm[count.index].default_ip_address}\" || true" : "ssh-keygen -f \"/home/ubuntu/.ssh/known_hosts\" -R \"${split(",", replace(var.vcenter_network_mgmt_ip4_addresses, " ", ""))[2]}\" || true"
  }
}