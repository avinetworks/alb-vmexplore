data "template_file" "network_client_static" {
  count = (var.vcenter_network_mgmt_dhcp == false ? 1 : 0)
  template = file("templates/network_client_static.template")
  vars = {
    ip4_main = "${split(",", replace(var.vcenter_network_mgmt_ip4_addresses, " ", ""))[1]}/${split("/", var.vcenter_network_mgmt_network_cidr)[1]}"
    gw4 = var.vcenter_network_mgmt_gateway4
    avi_dns_vs = "${split("-", replace(var.vcenter_network_vip_ipam_pool, " ", ""))[0]}"
    ip4_second = "${split(",", replace(var.vcenter_network_vip_ip4_address, " ", ""))[0]}/${split("/", var.vcenter_network_vip_cidr)[1]}"
  }
}

data "template_file" "network_client_dhcp" {
  count = (var.vcenter_network_mgmt_dhcp == true ? 1 : 0)
  template = file("templates/network_client_dhcp.template")
  vars = {
    avi_dns_vs = "${split("-", replace(var.vcenter_network_vip_ipam_pool, " ", ""))[0]}"
    ip4_second = "${split(",", replace(var.vcenter_network_vip_ip4_address, " ", ""))[0]}/${split("/", var.vcenter_network_vip_cidr)[1]}"
  }
}

data "template_file" "network_client_dhcp_static" {
  count = (var.vcenter_network_mgmt_dhcp == true ? 1 : 0)
  template = file("templates/network_client_dhcp_static.template")
  vars = {
    avi_dns_vs = "${split("-", replace(var.vcenter_network_vip_ipam_pool, " ", ""))[0]}"
    ip4_second = "${split(",", replace(var.vcenter_network_vip_ip4_address, " ", ""))[0]}/${split("/", var.vcenter_network_vip_cidr)[1]}"
  }
}

data "template_file" "client_userdata_dhcp" {
  count = (var.vcenter_network_mgmt_dhcp == true ? 1 : 0)
  template = file("${path.module}/userdata/client_dhcp.userdata")
  vars = {
    password      = var.static_password == null ? random_string.password.result : var.static_password
    net_plan_file = var.client.net_plan_file
    hostname = "${var.client.basename}${random_string.id.result}"
    network_config  = base64encode(data.template_file.network_client_dhcp_static[0].rendered)
    network_config_static  = base64encode(data.template_file.network_client_dhcp_static[0].rendered)
  }
}

data "template_file" "client_userdata_static" {
  count = (var.vcenter_network_mgmt_dhcp == false ? 1 : 0)
  template = file("${path.module}/userdata/client_static.userdata")
  vars = {
    password      = var.static_password == null ? random_string.password.result : var.static_password
    net_plan_file = var.client.net_plan_file
    hostname = "${var.client.basename}${random_string.id.result}"
    network_config  = base64encode(data.template_file.network_client_static[0].rendered)
  }
}

resource "vsphere_virtual_machine" "client_static" {
  count = (var.vcenter_network_mgmt_dhcp == false ? 1 : 0)
  name             = "${var.client.basename}${random_string.id.result}"
  datastore_id     = data.vsphere_datastore.datastore.id
  resource_pool_id = data.vsphere_resource_pool.pool.id
  folder           = vsphere_folder.folder.path

  network_interface {
                      network_id = data.vsphere_network.network_mgmt.id
  }

  num_cpus = var.client.cpu
  memory = var.client.memory
  guest_id = "ubuntu64Guest"

  disk {
    size             = var.client.disk
    label            = "client.lab_vmdk"
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
     hostname    = "${var.client.basename}${random_string.id.result}"
     public-keys = chomp(tls_private_key.ssh.public_key_openssh)
     user-data   = base64encode(data.template_file.client_userdata_static[0].rendered)
   }
 }

  connection {
    host        = split(",", replace(var.vcenter_network_mgmt_ip4_addresses, " ", ""))[1]
    type        = "ssh"
    agent       = false
    user        = var.client.username
    private_key = tls_private_key.ssh.private_key_pem
  }

  provisioner "remote-exec" {
   inline      = [
     "while [ ! -f /tmp/cloudInitDone.log ]; do sleep 1; done"
   ]
  }
}

resource "vsphere_virtual_machine" "client_dhcp" {
  count = (var.vcenter_network_mgmt_dhcp == true ? 1 : 0)
  name             = "${var.client.basename}${random_string.id.result}"
  datastore_id     = data.vsphere_datastore.datastore.id
  resource_pool_id = data.vsphere_resource_pool.pool.id
  folder           = vsphere_folder.folder.path

  network_interface {
    network_id = data.vsphere_network.network_mgmt.id
  }

  num_cpus = var.client.cpu
  memory = var.client.memory
  guest_id = "ubuntu64Guest"

  disk {
    size             = var.client.disk
    label            = "client.lab_vmdk"
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
      hostname    = "${var.client.basename}${random_string.id.result}"
      public-keys = chomp(tls_private_key.ssh.public_key_openssh)
      user-data   = base64encode(data.template_file.client_userdata_dhcp[0].rendered)
    }
  }

  connection {
    host        = self.default_ip_address
    type        = "ssh"
    agent       = false
    user        = var.client.username
    private_key = tls_private_key.ssh.private_key_pem
  }

  provisioner "remote-exec" {
    inline      = [
      "while [ ! -f /tmp/cloudInitDone.log ]; do sleep 1; done"
    ]
  }
}

resource "null_resource" "add_nic_to_client" {
  depends_on = [vsphere_virtual_machine.client_dhcp, vsphere_virtual_machine.client_static]

  provisioner "local-exec" {
    command = <<-EOT
      export GOVC_USERNAME=${var.vsphere_username}
      export GOVC_PASSWORD=${var.vsphere_password}
      export GOVC_DATACENTER=${var.vcenter_dc}
      export GOVC_URL=${var.vsphere_server}
      export GOVC_CLUSTER=${var.vcenter_cluster}
      export GOVC_INSECURE=true
      /usr/local/bin/govc vm.network.add -vm "${var.client.basename}${random_string.id.result}" -net "${var.vcenter_network_vip_name}"
    EOT
  }
}

resource "null_resource" "clear_ssh_key_locally_static_client" {
  count = (var.vcenter_network_mgmt_dhcp == false ? 1 : 0)
  provisioner "local-exec" {
    command = "ssh-keygen -f \"/home/ubuntu/.ssh/known_hosts\" -R \"${split(",", replace(var.vcenter_network_mgmt_ip4_addresses, " ", ""))[1]}\" || true"
  }
}

resource "null_resource" "clear_ssh_key_locally_dhcp_client" {
  count = (var.vcenter_network_mgmt_dhcp == true ? 1 : 0)
  provisioner "local-exec" {
    command = "ssh-keygen -f \"/home/ubuntu/.ssh/known_hosts\" -R \"${vsphere_virtual_machine.client_dhcp[count.index].default_ip_address}\" || true"
  }
}

resource "null_resource" "update_ip_to_client_dhcp" {
  depends_on = [null_resource.add_nic_to_client]
  count = (var.vcenter_network_mgmt_dhcp == true ? 1 : 0)

  connection {
    host        = vsphere_virtual_machine.client_dhcp[0].default_ip_address
    type        = "ssh"
    agent       = false
    user        = var.client.username
    private_key = tls_private_key.ssh.private_key_pem
  }

  provisioner "remote-exec" {
    inline = [
      "if_secondary_name=$(sudo dmesg | grep eth0 | tail -1 | awk -F' ' '{print $5}' | sed 's/://')",
      "sudo sed -i -e \"s/if_name_secondary_to_be_replaced/\"$if_secondary_name\"/g\" /tmp/50-cloud-init.yaml",
      "sudo cp /tmp/50-cloud-init.yaml ${var.client.net_plan_file}",
      "sudo netplan apply"
    ]
  }
}

resource "null_resource" "update_ip_to_client_static" {
  depends_on = [null_resource.add_nic_to_client]
  count = (var.vcenter_network_mgmt_dhcp == false ? 1 : 0)

  connection {
    host        = split(",", replace(var.vcenter_network_mgmt_ip4_addresses, " ", ""))[1]
    type        = "ssh"
    agent       = false
    user        = var.client.username
    private_key = tls_private_key.ssh.private_key_pem
  }

  provisioner "remote-exec" {
    inline = [
      "if_secondary_name=$(sudo dmesg | grep eth0 | tail -1 | awk -F' ' '{print $5}' | sed 's/://')",
      "sudo sed -i -e \"s/if_name_secondary_to_be_replaced/\"$if_secondary_name\"/g\" ${var.client.net_plan_file}",
      "sudo netplan apply"
    ]
  }
}
resource "null_resource" "waftest_client" {
  depends_on = [null_resource.add_nic_to_client]

  connection {
    host        = vsphere_virtual_machine.client_dhcp[0].default_ip_address
    type        = "ssh"
    agent       = false
    user        = "ubuntu"
    private_key = tls_private_key.ssh.private_key_pem
  }
  provisioner "file" {
    source      = "templates/waftest.txt"
    destination = "waftest.txt"
  }
}
