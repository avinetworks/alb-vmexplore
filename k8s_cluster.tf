
data "template_file" "values" {
  count = 1
  depends_on = [null_resource.ansible_avi, null_resource.K8s_sanity_check]
  template = file("templates/values.yml.${var.ako_version}.template")
  vars = {
    disableStaticRouteSync = "false"
    clusterName  = "cluster1"
    cniPlugin    = var.K8s_cni_name
    subnetIP     = split("/", var.vcenter_network_vip_cidr)[0]
    subnetPrefix = split("/", var.vcenter_network_vip_cidr)[1]
    networkName = var.vcenter_network_vip_name
    serviceType = local.ako_service_type
    shardVSSize = "SMALL"
    serviceEngineGroupName = "Default-Group"
    controllerVersion = var.avi_version
    cloudName = "dc1_vCenter"
    controllerHost = var.vcenter_network_mgmt_dhcp == true ? vsphere_virtual_machine.controller_dhcp[0].default_ip_address : split(",", replace(var.vcenter_network_mgmt_ip4_addresses, " ", ""))[0]
  }
}

data "template_file" "ingress" {
  count = 1
  template = file("templates/ingress.yml.template")
  vars = {
    domain = var.avi_domain
    clusterName  = "cluster1"
  }
}

data "template_file" "secure_ingress" {
  count = 1
  template = file("templates/secure-ingress.yml.template")
  vars = {
    domain = var.avi_domain
    clusterName  = "cluster1"
  }
}

data "template_file" "avi_crd_hostrule_waf" {
  count = 1
  template = file("templates/avi_crd_hostrule_waf.yml.template")
  vars = {
    default_waf_policy = "System-WAF-Policy"
    domain = var.avi_domain
    clusterName  = "cluster1"
  }
}

data "template_file" "avi_crd_hostrule_tls_cert" {
  count = 1
  template = file("templates/avi_crd_hostrule_tls_cert.yml.template")
  vars = {
    domain = var.avi_domain
    clusterName  = "cluster1"
  }
}

resource "null_resource" "ako_prerequisites" {
  count = 1
  connection {
    host = var.vcenter_network_mgmt_dhcp == true ? vsphere_virtual_machine.master.default_ip_address : split(",", replace(var.vcenter_network_mgmt_ip4_addresses, " ", ""))[3]
    type = "ssh"
    agent = false
    user = "ubuntu"
    private_key = tls_private_key.ssh.private_key_pem
  }

  provisioner "file" {
    content = data.template_file.values[count.index].rendered
    destination = "values.yml"
  }

  provisioner "file" {
    source = "templates/deployment.yml"
    destination = "deployment.yml"
  }

  provisioner "file" {
    source = "templates/service_clusterIP.yml"
    destination = "service_clusterIP.yml"
  }

  provisioner "file" {
    source = "templates/service_loadBalancer.yml"
    destination = "service_loadBalancer.yml"
  }

  provisioner "file" {
    content = data.template_file.ingress[count.index].rendered
    destination = "ingress.yml"
  }

  provisioner "file" {
    content = data.template_file.secure_ingress[count.index].rendered
    destination = "secure_ingress.yml"
  }

  provisioner "file" {
    content = data.template_file.avi_crd_hostrule_waf[count.index].rendered
    destination = "avi_crd_hostrule_waf.yml"
  }

  provisioner "file" {
    content = data.template_file.avi_crd_hostrule_tls_cert[count.index].rendered
    destination = "avi_crd_hostrule_tls_cert.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "echo \"export avi_password='${random_string.password.result}'\" | sudo tee -a /home/ubuntu/.profile",
      "helm repo add ako ${var.ako_helm_url}",
      "kubectl create secret docker-registry docker --docker-server=docker.io --docker-username=${var.docker_registry_username} --docker-password=${var.docker_registry_password} --docker-email=${var.docker_registry_email}",
      "kubectl patch serviceaccount default -p \"{\\\"imagePullSecrets\\\": [{\\\"name\\\": \\\"docker\\\"}]}\"",
      "kubectl create ns avi-system",
      "kubectl create secret docker-registry docker --docker-server=docker.io --docker-username=${var.docker_registry_username} --docker-password=${var.docker_registry_password} --docker-email=${var.docker_registry_email} -n avi-system",
      "kubectl patch serviceaccount default -p \"{\\\"imagePullSecrets\\\": [{\\\"name\\\": \\\"docker\\\"}]}\" -n avi-system",
      "openssl req -newkey rsa:4096 -x509 -sha256 -days 3650 -nodes -out ssl.crt -keyout ssl.key -subj \"/C=US/ST=CA/L=Palo Alto/O=VMWARE/OU=IT/CN=ingress.${var.avi_domain}\"",
      "kubectl create secret tls cert01 --key=ssl.key --cert=ssl.crt",
    ]
  }
}

resource "null_resource" "ako_deploy" {
  depends_on = [null_resource.ako_prerequisites]
  count = (var.ako_deploy == true ? 1 : 0)
  connection {
    host = var.vcenter_network_mgmt_dhcp == true ? vsphere_virtual_machine.master.default_ip_address : split(",", replace(var.vcenter_network_mgmt_ip4_addresses, " ", ""))[3]
    type = "ssh"
    agent = false
    user = "ubuntu"
    private_key = tls_private_key.ssh.private_key_pem
  }

  provisioner "remote-exec" {
    inline = [
      "helm --debug install ako/ako --generate-name --version ${var.ako_version} -f values.yml --namespace=avi-system --set avicredentials.username=admin --set avicredentials.password=${random_string.password.result}"
    ]
  }
}