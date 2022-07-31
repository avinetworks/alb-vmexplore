data "template_file" "network_master_static" {
  count = (var.vcenter_network_mgmt_dhcp == false ? 1 : 0)
  template = file("templates/network_master_static.template")
  vars = {
    ip4_main = "${split(",", replace(var.vcenter_network_mgmt_ip4_addresses, " ", ""))[3]}/${split("/", var.vcenter_network_mgmt_network_cidr)[1]}"
    gw4 = var.vcenter_network_mgmt_gateway4
    dns = var.vcenter_network_mgmt_network_dns
    ip4_second = "${split(",", replace(var.vcenter_network_k8s_ip4_addresses, " ", ""))[0]}/${split("/", var.vcenter_network_k8s_cidr)[1]}"
  }
}

data "template_file" "network_master_dhcp_static" {
  count = (var.vcenter_network_mgmt_dhcp == true ? 1 : 0)
  template = file("templates/network_master_dhcp_static.template")
  vars = {
    ip4_second = "${split(",", replace(var.vcenter_network_k8s_ip4_addresses, " ", ""))[0]}/${split("/", var.vcenter_network_k8s_cidr)[1]}"
  }
}

data "template_file" "master_userdata" {
  template = var.vcenter_network_mgmt_dhcp == true ? file("${path.module}/userdata/master_dhcp.userdata") : file("${path.module}/userdata/master_static.userdata")
  count            = 1
  vars = {
    password      = var.static_password == null ? random_string.password.result : var.static_password
    hostname = "${var.master.basename}${random_string.id.result}"
    network_config  = var.vcenter_network_mgmt_dhcp == true ? base64encode(data.template_file.network_master_dhcp_static[0].rendered) : base64encode(data.template_file.network_master_static[count.index].rendered)
    net_plan_file = var.master.net_plan_file
  }
}

resource "vsphere_virtual_machine" "master" {
  name             = "${var.master.basename}${random_string.id.result}"
  datastore_id     = data.vsphere_datastore.datastore.id
  resource_pool_id = data.vsphere_resource_pool.pool.id
  folder           = vsphere_folder.folder.path

  network_interface {
    network_id = data.vsphere_network.network_mgmt.id
  }

  num_cpus = var.master.cpu
  memory = var.master.memory
  guest_id = "ubuntu64Guest"

  disk {
    size             = var.master.disk
    label            = "master.lab_vmdk"
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
      hostname    = "${var.master.basename}-${random_string.id.result}"
      public-keys = chomp(tls_private_key.ssh.public_key_openssh)
      user-data   = base64encode(data.template_file.master_userdata[0].rendered)
    }
  }

  connection {
    host        = var.vcenter_network_mgmt_dhcp == true ? self.default_ip_address : split(",", replace(var.vcenter_network_mgmt_ip4_addresses, " ", ""))[3]
    type        = "ssh"
    agent       = false
    user        = var.master.username
    private_key = tls_private_key.ssh.private_key_pem
  }

  provisioner "remote-exec" {
    inline      = [
      "while true ; do sleep 5 ; if [ -s \"/tmp/cloudInitFailed.log\" ] ; then exit 255 ; fi; if [ -s \"/tmp/cloudInitDone.log\" ] ; then exit ; fi ; done"
    ]
  }
}

resource "null_resource" "add_nic_to_master" {
  depends_on = [vsphere_virtual_machine.master]

  provisioner "local-exec" {
    command = <<-EOT
      export GOVC_USERNAME=${var.vsphere_username}
      export GOVC_PASSWORD=${var.vsphere_password}
      export GOVC_DATACENTER=${var.vcenter_dc}
      export GOVC_URL=${var.vsphere_server}
      export GOVC_CLUSTER=${var.vcenter_cluster}
      export GOVC_INSECURE=true
      /usr/local/bin/govc vm.network.add -vm "${var.master.basename}${random_string.id.result}" -net "${var.vcenter_network_k8s_name}"
    EOT
  }
}

resource "null_resource" "clear_ssh_key_locally_master" {
  provisioner "local-exec" {
    command = var.vcenter_network_mgmt_dhcp == true ? "ssh-keygen -f \"/home/ubuntu/.ssh/known_hosts\" -R \"${vsphere_virtual_machine.master.default_ip_address}\" || true" : "ssh-keygen -f \"/home/ubuntu/.ssh/known_hosts\" -R \"${split(",", replace(var.vcenter_network_mgmt_ip4_addresses, " ", ""))[3]}\" || true"
  }
}

data "template_file" "k8s_bootstrap_master" {
  template = file("${path.module}/templates/k8s_bootstrap_master.template")
  vars = {
    ip_k8s = split(",", replace(var.vcenter_network_k8s_ip4_addresses, " ", ""))[0]
    net_plan_file = var.master.net_plan_file
    docker_registry_username = var.docker_registry_username
    K8s_pod_cidr = var.K8s_pod_cidr
    K8s_pod_network = split("/", var.K8s_pod_cidr)[0]
    K8s_pod_prefix = split("/", var.K8s_pod_cidr)[1]
    default_flannel_pod_prefix = split("/", local.default_flannel_pod_network_cidr)[1]
    K8s_version = var.K8s_version
    Docker_version = var.Docker_version
    docker_registry_password = var.docker_registry_password
    cni_name = var.K8s_cni_name
    ako_service_type = local.ako_service_type
    default_flannel_pod_network = split("/", local.default_flannel_pod_network_cidr)[0]
    default_flannel_pod_prefix = split("/", local.default_flannel_pod_network_cidr)[1]
    dhcp = var.vcenter_network_mgmt_dhcp
  }
}

resource "null_resource" "k8s_bootstrap_master" {
  depends_on = [null_resource.add_nic_to_master]

  connection {
    host = var.vcenter_network_mgmt_dhcp == true ? vsphere_virtual_machine.master.default_ip_address : split(",", replace(var.vcenter_network_mgmt_ip4_addresses, " ", ""))[3]
    type = "ssh"
    agent = false
    user = "ubuntu"
    private_key = tls_private_key.ssh.private_key_pem
  }
  provisioner "file" {
    content = data.template_file.k8s_bootstrap_master.rendered
    destination = "k8s_bootstrap_master.sh"
  }
  provisioner "file" {
    source      = "templates/waftest.txt"
    destination = "waftest.txt"
  }
  provisioner "remote-exec" {
    inline = ["sudo /bin/bash k8s_bootstrap_master.sh"]
  }
}

resource "null_resource" "copy_join_command_to_tf" {
  depends_on = [null_resource.k8s_bootstrap_master]
  provisioner "local-exec" {
    command = var.vcenter_network_mgmt_dhcp == true ? "scp -i ~/.ssh/${var.ssh_key.private_key_basename}-${random_string.id.result}.pem -o StrictHostKeyChecking=no ubuntu@${vsphere_virtual_machine.master.default_ip_address}:/home/ubuntu/join-command join-command" : "scp -i ~/.ssh/${var.ssh_key.private_key_basename}-${random_string.id.result}.pem -o StrictHostKeyChecking=no ubuntu@${split(",", replace(var.vcenter_network_mgmt_ip4_addresses, " ", ""))[3]}:/home/ubuntu/join-command join-command"
  }
}

data "template_file" "K8s_sanity_check" {
  template = file("templates/K8s_check.sh.template")
  vars = {
    nodes = 3
  }
}

resource "null_resource" "K8s_sanity_check" {
  depends_on = [null_resource.join_cluster]

  connection {
    host = var.vcenter_network_mgmt_dhcp == true ? vsphere_virtual_machine.master.default_ip_address : split(",", replace(var.vcenter_network_mgmt_ip4_addresses, " ", ""))[3]
    type = "ssh"
    agent = false
    user = var.master.username
    private_key = tls_private_key.ssh.private_key_pem
  }

  provisioner "file" {
    content = data.template_file.K8s_sanity_check.rendered
    destination = "K8s_sanity_check.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "/bin/bash K8s_sanity_check.sh",
    ]
  }
}
