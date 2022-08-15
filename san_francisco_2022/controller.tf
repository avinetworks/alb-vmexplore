resource "vsphere_virtual_machine" "controller_dhcp" {
  count            = (var.vcenter_network_mgmt_dhcp == true ? 1 : 0)
  name             = "${var.controller.name}-${random_string.id.result}"
  datastore_id     = data.vsphere_datastore.datastore.id
  folder           = vsphere_folder.folder.path
  resource_pool_id = data.vsphere_resource_pool.pool.id
  network_interface {
    network_id = data.vsphere_network.network_mgmt.id
  }

  num_cpus = var.controller.cpu
  memory = var.controller.memory
  wait_for_guest_net_timeout = var.controller.wait_for_guest_net_timeout
  guest_id = "guestid-controller-${count.index}"

  disk {
    size             = var.controller.disk
    label            = "controller--${count.index}.lab_vmdk"
    thin_provisioned = true
  }

  clone {
    template_uuid = vsphere_content_library_item.file_avi.id
  }
}

resource "vsphere_virtual_machine" "controller_static" {
  count            = (var.vcenter_network_mgmt_dhcp == false ? 1 : 0)
  name             = "${var.controller.name}-${random_string.id.result}"
  datastore_id     = data.vsphere_datastore.datastore.id
  folder           = vsphere_folder.folder.path
  resource_pool_id = data.vsphere_resource_pool.pool.id
  network_interface {
    network_id = data.vsphere_network.network_mgmt.id
  }

  num_cpus = var.controller.cpu
  memory = var.controller.memory
  wait_for_guest_net_timeout = var.controller.wait_for_guest_net_timeout
  guest_id = "guestid-controller-${count.index}"

  disk {
    size             = var.controller.disk
    label            = "controller--${count.index}.lab_vmdk"
    thin_provisioned = true
  }

  clone {
    template_uuid = vsphere_content_library_item.file_avi.id
  }

  vapp {
    properties = {
      "mgmt-ip"     = split(",", replace(var.vcenter_network_mgmt_ip4_addresses, " ", ""))[0]
      "mgmt-mask"   = cidrnetmask(var.vcenter_network_mgmt_network_cidr)
      "default-gw"  = var.vcenter_network_mgmt_gateway4
    }
  }
}

resource "null_resource" "wait_https_controller" {
  depends_on = [vsphere_virtual_machine.controller_dhcp, vsphere_virtual_machine.controller_static]
  count            = 1

  provisioner "local-exec" {
    command = var.vcenter_network_mgmt_dhcp == true ? "until $(curl --output /dev/null --silent --head -k https://${vsphere_virtual_machine.controller_dhcp[count.index].default_ip_address}); do echo 'Waiting for Avi Controller to be ready'; sleep 10 ; done" : "until $(curl --output /dev/null --silent --head -k https://${vsphere_virtual_machine.controller_static[count.index].default_ip_address}); do echo 'Waiting for Avi Controller to be ready'; sleep 10 ; done"
  }
}