#
# Variables that can be changed
#
variable "vsphere_username" {}
variable "vsphere_password" {
}

variable "docker_registry_username" {
  //  sensitive = true
}
variable "docker_registry_password" {
}
variable "docker_registry_email" {
}

variable "static_password" {
  default = null
}

variable "vsphere_server" {
  default = "wdc-06-vc12.oc.vmware.com"
}

variable "vcenter_dc" {
  default = "wdc-06-vc12"
}

variable "vcenter_cluster" {
  default = "wdc-06-vc12c01"
}

variable "vcenter_datastore" {
  default = "wdc-06-vc12c01-vsan"
}

variable "vcenter_folder" {
  default = "tf_ako_k8s_demo"
}

variable "vcenter_network_mgmt_name" {
  default = "vxw-dvs-34-virtualwire-3-sid-6120002-wdc-06-vc12-avi-mgmt"
}

variable "vcenter_network_mgmt_network_cidr" {
  default = "10.206.112.0/22"
}

variable "vcenter_network_mgmt_dhcp" {
  default = false
}

variable "vcenter_network_mgmt_ip4_addresses" {
  default = "10.206.112.70, 10.206.112.71, 10.206.112.72, 10.206.112.73, 10.206.112.74, 10.206.112.75"
  description = "used only if vcenter_network_mgmt_dhcp is false"
}

variable "vcenter_network_mgmt_ipam_pool" {
  default = "10.206.112.55 - 10.206.112.57"
  description = "used only if vcenter_network_mgmt_dhcp is false"
}

variable "vcenter_network_mgmt_gateway4" {
  default = "10.206.112.1"
  description = "used only if vcenter_network_mgmt_dhcp is false"
}

variable "vcenter_network_mgmt_network_dns" {
  default = "10.206.8.130, 10.206.8.131"
}

variable "ntp_servers_ips" {
  default = "10.206.8.130, 10.206.8.131"
}

variable "vcenter_network_vip_name" {
    default = "vxw-dvs-34-virtualwire-120-sid-6120119-wdc-06-vc12-avi-dev116"
}

variable "vcenter_network_vip_cidr" {
  default = "10.1.100.0/24"
}

variable "vcenter_network_vip_ip4_address" {
  default = "10.1.100.200"
  description = "IP address of the client VM in the VIP network"
}

variable "vcenter_network_vip_ipam_pool" {
  default = "10.1.100.100 - 10.1.100.199"
}

variable "vcenter_network_k8s_name" {
  default = "vxw-dvs-34-virtualwire-116-sid-6120115-wdc-06-vc12-avi-dev112"
}

variable "vcenter_network_k8s_cidr" {
  default = "100.100.100.0/24"
}

variable "vcenter_network_k8s_ip4_addresses" {
  default = "100.100.100.200, 100.100.100.201, 100.100.100.202"
}

variable "vcenter_network_k8s_ipam_pool" {
  default = "100.100.100.100 - 100.100.100.199"
}

variable "avi_version" {
  default = "21.1.4"
}

variable "avi_domain" {
  default = "avi.com"
}

variable "K8s_version" {
  default = "1.21.3-00"
}

variable "K8s_cni_name" {
  default = "antrea"
}

variable "K8s_pod_cidr" {
  default = "192.168.0.0/16"
}

variable "Docker_version" {
  default = "5:20.10.7~3-0~ubuntu-focal"
}

variable "avi_controller_url" {}

variable "ako_helm_url" {
  default = "https://projects.registry.vmware.com/chartrepo/ako"
}

variable "ako_deploy" {
  default = false
}

variable "ako_version" {
  default = "1.7.1"
}

variable "ako_service_type" {
  default = "NodePortLocal"
}

# Other Variables

variable "content_library" {
  default = {
    basename = "content_library_tf_"
    source_url_ubuntu_focal = "https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.ova"
  }
}

variable "controller" {
  default = {
    cpu = 8
    name = "ako-avi-controller"
    memory = 24768
    disk = 128
    wait_for_guest_net_timeout = 4
  }
}

variable "ssh_key" {
  type = map
  default = {
    algorithm            = "RSA"
    rsa_bits             = "4096"
    private_key_basename = "ssh_private_key"
    file_permission      = "0600"
  }
}

variable "destroy_env_vm" {
  type = map
  default = {
    name = "destroy-env-vm-"
    cpu = 2
    memory = 4096
    disk = 20
    template_name = "ubuntu-focal-20.04-cloudimg-template"
    username = "ubuntu"
    net_plan_file = "/etc/netplan/50-cloud-init.yaml"
  }
}

variable "client" {
  type = map
  default = {
    basename = "demo-client-"
    cpu = 2
    memory = 4096
    disk = 20
    username = "ubuntu"
    net_plan_file = "/etc/netplan/50-cloud-init.yaml"
  }
}

variable "ansible" {
  type = map
  default = {
    version = "2.10.7"
  }
}

variable "master" {
  type = map
  default = {
    basename = "master-tf-"
    username = "ubuntu"
    cpu = 2
    memory = 8192
    disk = 20
    net_plan_file = "/etc/netplan/50-cloud-init.yaml"
  }
}

variable "workers" {
  type = map
  default = {
    basename = "worker-tf"
    username = "ubuntu"
    cpu = 2
    memory = 4096
    disk = 20
    net_plan_file = "/etc/netplan/50-cloud-init.yaml"
  }
}
