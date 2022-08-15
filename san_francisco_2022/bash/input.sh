#!/bin/bash
type terraform >/dev/null 2>&1 || { echo >&2 "terraform is not installed - please visit: https://learn.hashicorp.com/tutorials/terraform/install-cli to install it - Aborting." ; exit 255; }
type jq >/dev/null 2>&1 || { echo >&2 "jq is not installed - please install it - Aborting." ; exit 255; }
run_cmd() {
  retry=10
  pause=20
  attempt=0
  while [ $attempt -ne $retry ]; do
    if eval "$@"; then
      break
    else
      echo "$1 FAILED"
    fi
    ((attempt++))
    sleep $pause
    if [ $attempt -eq $retry ]; then
      echo "$1 FAILED after $retry retries" | tee /tmp/cloudInitFailed.log
      exit 255
    fi
    done
}
#
assign_var_from_json_file () {
  rm -f .var
  echo "Select $1..."
  if [[ $(jq length $2) -eq 1 ]] ; then
    echo "defaulting to $(jq -r -c .[0] $2)"
    var=$(jq -r -c .[0] $2)
  else
    count=1
    IFS=$'\n'
    for item in $(jq -c -r .[] $2)
    do
      echo "$count: $item"
      count=$((count+1))
    done
    re='^[0-9]+$' ; yournumber=""
    until [[ $yournumber =~ $re ]] ; do echo -n "$1 number: " ; read -r yournumber ; done
    yournumber=$((yournumber-1))
    var=$(jq -r -c .[$yournumber] $2)
  fi
  echo $var | tee .var >/dev/null
  sleep 2
  clear
}
#
assign_var_boolean () {
  unset var
  until [[ $var == "y" ]] || [[ $var == "n" ]] ; do echo -n "$1 y/n?: " ; read -r var ; done
  if [[ $var == "y" ]] ; then
    contents="$(jq '."'$2'" = true' $3)"
  fi
  if [[ $var == "n" ]] ; then
    contents="$(jq '."'$2'" = false' $3)"
  fi
  echo $contents | tee $3 >/dev/null
  sleep 2
  clear
}
#
rm -f booleans.json ; echo "{}" | tee booleans.json >/dev/null
unset vsphere_server ; until [ ! -z "$vsphere_server" ] ; do echo -n "vsphere server FQDN: " ; read -r vsphere_server ; done
unset vsphere_username ; until [ ! -z "$vsphere_username" ] ; do echo -n "vsphere username: " ; read -r vsphere_username ; done
unset vsphere_password ; until [ ! -z "$vsphere_password" ] ; do echo -n "vsphere password: " ; read -s vsphere_password ; echo ; done
run_cmd 'curl https://raw.githubusercontent.com/tacobayle/bash/master/vcenter/get_vcenter.sh -o get_vcenter.sh --silent ; test $(ls -l get_vcenter.sh | awk '"'"'{print $5}'"'"') -gt 0'
/bin/bash get_vcenter.sh $vsphere_server $vsphere_username $vsphere_password
clear
# dc
unset TF_VAR_vcenter_dc ; assign_var_from_json_file "vCenter dc" "datacenters.json" ; TF_VAR_vcenter_dc=$(cat .var)
# cluster
unset TF_VAR_vcenter_cluster ; assign_var_from_json_file "vCenter cluster" "clusters.json" ; TF_VAR_vcenter_cluster=$(cat .var)
# datastore
unset TF_VAR_vcenter_datastore ; assign_var_from_json_file "vCenter datastore" "datastores.json" ; TF_VAR_vcenter_datastore=$(cat .var)
# management network
unset TF_VAR_vcenter_network_mgmt_name ; assign_var_from_json_file "vCenter management network" "networks.json" ; TF_VAR_vcenter_network_mgmt_name=$(cat .var)
# management network dhcp
assign_var_boolean "dhcp for management network" "dhcp" "booleans.json"
if [[  $(jq -r .dhcp booleans.json) == false ]] ; then
  unset TF_VAR_vcenter_network_mgmt_ip4_addresses ; until [ ! -z "$TF_VAR_vcenter_network_mgmt_ip4_addresses" ] ; do echo -n "enter 6 free IPs separated by commas to use in the management network (like: 10.206.112.70, 10.206.112.71, 10.206.112.72, 10.206.112.73, 10.206.112.74, 10.206.112.75): " ; read -r TF_VAR_vcenter_network_mgmt_ip4_addresses ; done
  unset TF_VAR_vcenter_network_mgmt_ipam_pool ; until [ ! -z "$TF_VAR_vcenter_network_mgmt_ipam_pool" ] ; do echo -n "enter a range of at least two IPs for management network separated by hyphen (like: 10.206.112.55 - 10.206.112.57): " ; read -r TF_VAR_vcenter_network_mgmt_ipam_pool ; done
  unset TF_VAR_vcenter_network_mgmt_gateway4 ; until [ ! -z "$TF_VAR_vcenter_network_mgmt_gateway4" ] ; do echo -n "enter IP of the default gateway (like: 10.206.112.1): " ; read -r TF_VAR_vcenter_network_mgmt_gateway4 ; done
fi
unset TF_VAR_vcenter_network_mgmt_network_cidr ; until [ ! -z "$TF_VAR_vcenter_network_mgmt_network_cidr" ] ; do echo -n "enter management network address cidr (like: 10.206.112.0/22): " ;  read -r TF_VAR_vcenter_network_mgmt_network_cidr ; done
unset TF_VAR_vcenter_network_mgmt_network_dns ; echo -n "enter DNS IPs separated by commas (like: 10.206.8.130, 10.206.8.131) - type enter to ignore: " ; read -r TF_VAR_vcenter_network_mgmt_network_dns
unset TF_VAR_ntp_servers_ips ; echo -n "enter NTP IPs separated by commas (like: 10.206.8.130, 10.206.8.131) - type enter to ignore: " ; read -r TF_VAR_ntp_servers_ips
clear
# vip network
unset TF_VAR_vcenter_network_vip_name ; assign_var_from_json_file "vCenter vCenter vip network" "networks.json" ; TF_VAR_vcenter_network_vip_name=$(cat .var)
# vip network details
unset TF_VAR_vcenter_network_vip_cidr ; until [ ! -z "$TF_VAR_vcenter_network_vip_cidr" ] ; do echo -n "enter vip network address cidr (like: 10.206.112.0/22): " ; read -r TF_VAR_vcenter_network_vip_cidr ; done
unset TF_VAR_vcenter_network_vip_ip4_address ; until [ ! -z "$TF_VAR_vcenter_network_vip_ip4_address" ] ; do echo -n "enter a free IPs to use in the vip network (like: 10.1.100.200): " ; read -r TF_VAR_vcenter_network_vip_ip4_address ; done
unset TF_VAR_vcenter_network_vip_ipam_pool ; until [ ! -z "$TF_VAR_vcenter_network_vip_ipam_pool" ] ; do echo -n "enter a range of IPs for vip network separated by hyphen (like: 10.1.100.100 - 10.1.100.199): " ; read -r TF_VAR_vcenter_network_vip_ipam_pool ; done
clear
# k8s network
unset TF_VAR_vcenter_network_k8s_name ; assign_var_from_json_file "vCenter vCenter k8s network" "networks.json" ; TF_VAR_vcenter_network_k8s_name=$(cat .var)
# k8s network details
unset TF_VAR_vcenter_network_k8s_cidr ; until [ ! -z "$TF_VAR_vcenter_network_k8s_cidr" ] ; do echo -n "enter K8s network address cidr (like: 10.206.112.0/22): " ; read -r TF_VAR_vcenter_network_k8s_cidr ; done
unset TF_VAR_vcenter_network_k8s_ip4_addresses ; until [ ! -z "$TF_VAR_vcenter_network_k8s_ip4_addresses" ] ; do echo -n "enter 3 free IPs separated by commas to use in the k8s network (like: 100.100.100.200, 100.100.100.201, 100.100.100.202): " ; read -r TF_VAR_vcenter_network_k8s_ip4_addresses ; done
unset TF_VAR_vcenter_network_k8s_ipam_pool ; until [ ! -z "$TF_VAR_vcenter_network_k8s_ipam_pool" ] ; do echo -n "enter a range of IPs for vip network separated by hyphen (like: 100.100.100.100 - 100.100.100.199): " ; read -r TF_VAR_vcenter_network_k8s_ipam_pool ; done
clear
# domain
unset TF_VAR_avi_domain ; until [ ! -z "$TF_VAR_avi_domain" ] ; do echo -n "enter a domain name (like: avi.com): " ; read -r TF_VAR_avi_domain ; done
# CNI
unset TF_VAR_K8s_cni_name ; assign_var_from_json_file "CNI" "cnis.json" ; TF_VAR_K8s_cni_name=$(cat .var)
# svc type
if [[ $TF_VAR_K8s_cni_name == "antrea" ]] ; then
  unset TF_VAR_ako_service_type ; assign_var_from_json_file "AKO service type" "svc_types.json" ; TF_VAR_ako_service_type=$(cat .var)
fi
if [[ $TF_VAR_K8s_cni_name == "calico" ]] || [[ TF_VAR_K8s_cni_name == "flannel" ]] ; then
    TF_VAR_ako_service_type="ClusterIP"
fi
# Avi version
unset TF_VAR_avi_version ; assign_var_from_json_file "Avi version" "avi_versions.json" ; TF_VAR_avi_version=$(cat .var)
# Ako version
unset TF_VAR_ako_version
rm -f .var
echo "Select AKO version..."
if [[ $(jq -c -r '.["'$TF_VAR_avi_version'"]' ako_versions.json | jq length) -eq 1 ]] ; then
  echo "defaulting to $(jq -c -r '.["'$TF_VAR_avi_version'"]' ako_versions.json | jq -c -r .[0])"
  TF_VAR_ako_version=$(jq -c -r '.["'$TF_VAR_avi_version'"]' ako_versions.json | jq -c -r .[0])
else
  count=1
  IFS=$'\n'
  for item in $(jq -c -r '.["'$TF_VAR_avi_version'"]' ako_versions.json)
    do
      echo "$count: $item"
      count=$((count+1))
    done
  re='^[0-9]+$' ; yournumber=""
  until [[ $yournumber =~ $re ]] ; do echo -n "AKO version number: " ; read -r yournumber ; done
  yournumber=$((yournumber-1))
  TF_VAR_ako_version=$(jq -c -r '.["'$TF_VAR_avi_version'"]' ako_versions.json | jq -c -r .[$yournumber])
fi
# AKO deploy
assign_var_boolean "deploy AKO" "ako_deploy" "booleans.json"
# avi url
unset TF_VAR_avi_controller_url ; until [ ! -z "$TF_VAR_avi_controller_url" ] ; do echo -n "Avi download URL: " ; read -r TF_VAR_avi_controller_url ; done
# docker account
unset TF_VAR_docker_registry_username ; echo -n "enter docker username - type enter to ignore: " ; read -r TF_VAR_docker_registry_username
unset TF_VAR_docker_registry_password ; echo -n "enter docker password - type enter to ignore: " ; read -s TF_VAR_docker_registry_password
echo
unset TF_VAR_docker_registry_email ; echo -n "enter docker email - type enter to ignore: " ; read -r TF_VAR_docker_registry_email
#
#terraform init
#terraform apply -auto-approve -var-file=booleans.json