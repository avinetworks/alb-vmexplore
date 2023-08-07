data "template_file" "network_workers_static" {
  count = (var.vcenter_network_mgmt_dhcp == false ? 2 : 0)
  template = file("templates/network_workers_static.template")
  vars = {
    ip4_main = "${split(",", replace(var.vcenter_network_mgmt_ip4_addresses, " ", ""))[4 + count.index]}/${split("/", var.vcenter_network_mgmt_network_cidr)[1]}"
    gw4 = var.vcenter_network_mgmt_gateway4
    dns = var.vcenter_network_mgmt_network_dns
    ip4_second = "${split(",", replace(var.vcenter_network_k8s_ip4_addresses, " ", ""))[1 + count.index]}/${split("/", var.vcenter_network_k8s_cidr)[1]}"
  }
}

data "template_file" "network_workers_dhcp_static" {
  count = (var.vcenter_network_mgmt_dhcp == true ? 2 : 0)
  template = file("templates/network_workers_dhcp_static.template")
  vars = {
    ip4_second = "${split(",", replace(var.vcenter_network_k8s_ip4_addresses, " ", ""))[1 + count.index]}/${split("/", var.vcenter_network_k8s_cidr)[1]}"
  }
}

data "template_file" "workers_userdata" {
  template = var.vcenter_network_mgmt_dhcp == true ? file("${path.module}/userdata/workers_dhcp.userdata") : file("${path.module}/userdata/workers_static.userdata")
  count            = 2
  vars = {
    password      = var.static_password == null ? random_string.password.result : var.static_password
    net_plan_file = var.workers.net_plan_file
    hostname = "${var.workers.basename}-${count.index}-${random_string.id.result}"
    network_config  = var.vcenter_network_mgmt_dhcp == true ? base64encode(data.template_file.network_workers_dhcp_static[count.index].rendered) : base64encode(data.template_file.network_workers_static[count.index].rendered)
  }
}

resource "vsphere_virtual_machine" "workers" {
  count = 2
  name             = "${var.workers.basename}-${count.index}-${random_string.id.result}"
  datastore_id     = data.vsphere_datastore.datastore.id
  resource_pool_id = data.vsphere_resource_pool.pool.id
  folder           = vsphere_folder.folder.path

  network_interface {
    network_id = data.vsphere_network.network_mgmt.id
  }

  num_cpus = var.workers.cpu
  memory = var.workers.memory
  guest_id = "ubuntu64Guest"

  disk {
    size             = var.workers.disk
    label            = "workers.lab_vmdk"
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
      hostname    = "${var.workers.basename}-${random_string.id.result}-${count.index}"
      public-keys = chomp(tls_private_key.ssh.public_key_openssh)
      user-data   = base64encode(data.template_file.workers_userdata[count.index].rendered)
    }
  }

  connection {
    host        = var.vcenter_network_mgmt_dhcp == true ? self.default_ip_address : split(",", replace(var.vcenter_network_mgmt_ip4_addresses, " ", ""))[4 + count.index]
    type        = "ssh"
    agent       = false
    user        = var.workers.username
    private_key = tls_private_key.ssh.private_key_pem
  }

  provisioner "remote-exec" {
    inline      = [
      "while true ; do sleep 5 ; if [ -s \"/tmp/cloudInitFailed.log\" ] ; then exit 255 ; fi; if [ -s \"/tmp/cloudInitDone.log\" ] ; then exit ; fi ; done"
    ]
  }
}

resource "null_resource" "add_nic_to_workers" {
  depends_on = [vsphere_virtual_machine.workers]
  count = 2
  provisioner "local-exec" {
    command = <<-EOT
      export GOVC_USERNAME=${var.vsphere_username}
      export GOVC_PASSWORD=${var.vsphere_password}
      export GOVC_DATACENTER=${var.vcenter_dc}
      export GOVC_URL=${var.vsphere_server}
      export GOVC_CLUSTER=${var.vcenter_cluster}
      export GOVC_INSECURE=true
      /usr/local/bin/govc vm.network.add -vm "${var.workers.basename}-${count.index}-${random_string.id.result}" -net "${var.vcenter_network_k8s_name}"
    EOT
  }
}

resource "null_resource" "clear_ssh_key_locally_workers" {
  count = 2
  provisioner "local-exec" {
    command = var.vcenter_network_mgmt_dhcp == true ? "ssh-keygen -f \"/home/ubuntu/.ssh/known_hosts\" -R \"${vsphere_virtual_machine.workers[count.index].default_ip_address}\" || true" : "ssh-keygen -f \"/home/ubuntu/.ssh/known_hosts\" -R \"${split(",", replace(var.vcenter_network_mgmt_ip4_addresses, " ", ""))[4 + count.index]}\" || true"
  }
}

data "template_file" "k8s_bootstrap_workers" {
  template = file("${path.module}/templates/k8s_bootstrap_workers.template")
  count = 2
  vars = {
    ip_k8s = split(",", replace(var.vcenter_network_k8s_ip4_addresses, " ", ""))[0]
    net_plan_file = var.master.net_plan_file
    K8s_version = var.K8s_version
    Docker_version = var.Docker_version
    docker_registry_username = var.docker_registry_username
    docker_registry_password = var.docker_registry_password
    cni_name = var.K8s_cni_name
    ako_service_type = local.ako_service_type
    dhcp = var.vcenter_network_mgmt_dhcp
    ip_k8s = split(",", replace(var.vcenter_network_k8s_ip4_addresses, " ", ""))[1 + count.index]
  }
}

resource "null_resource" "k8s_bootstrap_workers" {
  count = 2
  depends_on = [null_resource.add_nic_to_workers]

  connection {
    host = var.vcenter_network_mgmt_dhcp == true ? vsphere_virtual_machine.workers[count.index].default_ip_address : split(",", replace(var.vcenter_network_mgmt_ip4_addresses, " ", ""))[4 + count.index]
    type = "ssh"
    agent = false
    user = "ubuntu"
    private_key = tls_private_key.ssh.private_key_pem
  }

  provisioner "file" {
    content = data.template_file.k8s_bootstrap_workers[count.index].rendered
    destination = "k8s_bootstrap_workers.sh"
  }

  provisioner "remote-exec" {
    inline = ["sudo /bin/bash k8s_bootstrap_workers.sh"]
  }

}

resource "null_resource" "copy_join_command_to_workers" {
  count            = 2
  depends_on = [null_resource.copy_join_command_to_tf, null_resource.k8s_bootstrap_workers]
  provisioner "local-exec" {
    command = var.vcenter_network_mgmt_dhcp == true ? "scp -i ~/.ssh/${var.ssh_key.private_key_basename}-${random_string.id.result}.pem -o StrictHostKeyChecking=no join-command ubuntu@${vsphere_virtual_machine.workers[count.index].default_ip_address}:/home/ubuntu/join-command" : "scp -i ~/.ssh/${var.ssh_key.private_key_basename}-${random_string.id.result}.pem -o StrictHostKeyChecking=no join-command ubuntu@${split(",", replace(var.vcenter_network_mgmt_ip4_addresses, " ", ""))[4 + count.index]}:/home/ubuntu/join-command"
  }
}

resource "null_resource" "join_cluster" {
  depends_on = [null_resource.copy_join_command_to_workers]
  count            = 2
  connection {
    host        = var.vcenter_network_mgmt_dhcp == true ? vsphere_virtual_machine.workers[count.index].default_ip_address : split(",", replace(var.vcenter_network_mgmt_ip4_addresses, " ", ""))[4 + count.index]
    type        = "ssh"
    agent       = false
    user        = var.workers.username
    private_key = tls_private_key.ssh.private_key_pem
  }

  provisioner "remote-exec" {
    inline      = [
      "sudo /bin/bash /home/ubuntu/join-command"
    ]
  }
}