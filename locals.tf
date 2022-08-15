locals {
  ako_service_type = var.K8s_cni_name == "antrea" ? var.ako_service_type : "ClusterIP"
  default_flannel_pod_network_cidr = "10.244.0.0/16"
}