data "vsphere_datacenter" "dc" {
  name = var.vcenter_dc
}

data "vsphere_compute_cluster" "compute_cluster" {
  name          = var.vcenter_cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "datastore" {
  name = var.vcenter_datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_resource_pool" "pool" {
  name          = "${var.vcenter_cluster}/Resources"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network_mgmt" {
  name = var.vcenter_network_mgmt_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network_vip" {
  name = var.vcenter_network_vip_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network_k8s" {
  name = var.vcenter_network_k8s_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_folder" "folder" {
  path          = "${var.vcenter_folder}-${random_string.id.result}"
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.dc.id
}
