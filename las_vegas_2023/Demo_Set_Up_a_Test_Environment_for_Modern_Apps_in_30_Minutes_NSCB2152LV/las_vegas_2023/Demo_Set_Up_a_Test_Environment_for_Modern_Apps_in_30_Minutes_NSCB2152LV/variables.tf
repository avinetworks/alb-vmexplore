#
#Variables that can be changed
#
variable "vsphere_username" {}
variable "vsphere_password" {
}

variable "docker_registry_username" {
}
variable "docker_registry_password" {
}
variable "docker_registry_email" {
}

variable "static_password" {
  default = null
}

variable "vsphere_server" {
  default = "sof2-01-vc08.oc.vmware.com"
}

variable "vcenter_dc" {
  default = "sof2-01-vc08"
}

variable "vcenter_cluster" {
  default = "sof2-01-vc08c01"
}

variable "vcenter_datastore" {
  default = "sof2-01-vc08c01-vsan"
}

variable "vcenter_folder" {
  default = "ako_k8s_remo"
}

variable "vcenter_network_mgmt_name" {
  default = "vxw-dvs-34-virtualwire-3-sid-1080002-sof2-01-vc08-avi-mgmt"
}

variable "vcenter_network_mgmt_network_cidr" {
  default = "10.41.134.0/22"
}

variable "vcenter_network_mgmt_dhcp" {
  default = true
}

variable "vcenter_network_mgmt_ip4_addresses" {
  default = ""
  description = "used only if vcenter_network_mgmt_dhcp is false"
}

variable "vcenter_network_mgmt_ipam_pool" {
  default = ""
  description = "used only if vcenter_network_mgmt_dhcp is false"
}

variable "vcenter_network_mgmt_gateway4" {
  default = "10.206.112.1"
  description = "used only if vcenter_network_mgmt_dhcp is false"
}

variable "vcenter_network_mgmt_network_dns" {
  default = "10.23.108.1, 10.23.108.2"
}

variable "ntp_servers_ips" {
  default = "10.206.8.130, 10.206.8.131"
}

variable "vcenter_network_vip_name" {
    default = "vxw-dvs-34-virtualwire-118-sid-1080117-sof2-01-vc08-avi-dev114"
}

variable "vcenter_network_vip_cidr" {
  default = "172.16.1.0/24"
}

variable "vcenter_network_vip_ip4_address" {
  default = "172.16.1.200"
  description = "IP address of the client VM in the VIP network"
}

variable "vcenter_network_vip_ipam_pool" {
  default = "172.16.1.100 - 172.16.1.199"
}

variable "vcenter_network_k8s_name" {
  default = "vxw-dvs-34-virtualwire-117-sid-1080116-sof2-01-vc08-avi-dev113"
}

variable "vcenter_network_k8s_cidr" {
  default = "10.1.1.0/24"
}

variable "vcenter_network_k8s_ip4_addresses" {
  default = "10.1.1.200, 10.1.1.201, 10.1.1.202"
}

variable "vcenter_network_k8s_ipam_pool" {
  default = "10.1.1.100 - 10.1.1.199"
}

variable "avi_version" {
  default = "22.1.4"
}

variable "sdk_version" {
  default = "22.1.4"
}

variable "avi_domain" {
  default = "avi.com"
}
variable "loglevel" {
  default = "WARN"
  description = "INFO|DEBUG|WARN|ERROR "
}

variable "clustername" {
  default = "cluster1"
}
variable "K8s_version" {
  default = "1.26.6-00"
  #default = "1.25.11-00"
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

variable "avi_controller_url" {
  default = "http://10.79.186.238/builds/22.1.4/ci-build-22.1.4-9196/controller.ova"
}

#variable "avi_controller_url" {
#  default = "https://downloads.avipulse.vmware.com/SoftwaresDownloads/Version-21.1.4-2p3/controller-21.1.4-2p3-9009.ova?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIA4DJUANHFYQ4W2ODS%2F20220818%2Feu-west-1%2Fs3%2Faws4_request&X-Amz-Date=20220818T163650Z&X-Amz-Expires=21600&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEKH%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEaCXVzLWVhc3QtMSJHMEUCIGz6OJ%2FvhrFbAQV7uAq02PNUomNbgcqPoSuNw65J5a2fAiEAjRJLx%2FOUkcy9REd4tL9Ql7d%2Fx1hO0Bm0dK3XVAq%2BapcqpgIIGhADGgw4MzE3MjIxMjE2NzUiDBErTJr8sjA5iT02ZSqDAlh%2FY%2Fn91I6hBQj2JqcAJSOIunbAzlODu2Ee3D%2BoQ0jBfOtPnFgG1e4%2FcCxCBvu5QwFU%2BFdlA%2F96I6I1fB96LpwP1rjr5lgwELDofF4yNGQgTtitWviyJPvhzzmnbIPGRGlP0x2beG1Wauw%2B4D8vbXx5d5E8xAE4Pt%2Fh0ee7HwyZ5yO%2FPIW2hMCRrpiCvzrFg03giPjggzKDAteLs3%2Fcoig3%2FAlD4TyRvo1bK%2FhOoY0dossffVl6jul7loRb35yZcRexHsYoLncsCOPnq0%2By%2FggyA4kd6rpjRUbcHTiSGDoWxECGpQcn%2FnncidVaPzDtRtYeeLYno3rApE0jgeHvgAnr%2FOAwodX5lwY6nQHqjVngTlz6Y8%2F00%2B4jsCh%2Fiscz4gDFPDOved66OqaCClop6Rk9Da1Zxp%2FgwjALi7ka7s8Bk62wKxVvS07Gv4ozymltxg2Tb0EIYzl%2BHBq7%2BZQ63W7kT31a6AUloTnaQBhYPrf7cdV9hABdHi1GSJ6gAIPAIoexxE4o2AcPH6uAlkmNd4cTBXcFBX9vIWce2aW%2BeoG5UEeoOH%2FibCzy&X-Amz-Signature=08e8baf2164dabd72e69cf667ff6693c6bb05ccaec24e77c4a347f05fd261c36&X-Amz-SignedHeaders=host"
#}

variable "ako_helm_url" {
  default = "https://projects.registry.vmware.com/chartrepo/ako"
}

variable "ako_deploy" {
  default = false
}

variable "ako_version" {
  default = "1.10.1"
}

variable "ako_service_type" {
  default = "NodePortLocal"
}

variable "shardVSSize" {
  default = "SMALL"
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
    cpu = 4
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
variable "ubuntuuser" {
 description = "second username for the client with password no ssh key"
 default = "remo"
}
variable "ubuntuuserpass" {
 description = "second username pass for the client with password no ssh key"
 default = "avi123"
}
