# Tests

## passed
### dhcp

- vcenter_network_mgmt_dhcp: true, avi_version: 21.1.3, cni: antrea, ako_service_type: NodePortLocal
- vcenter_network_mgmt_dhcp: true, avi_version: 21.1.3, cni: antrea, ako_service_type: ClusterIP
- vcenter_network_mgmt_dhcp: true, avi_version: 21.1.3, cni: calico, ako_service_type: ClusterIP
- vcenter_network_mgmt_dhcp: true, avi_version: 21.1.3, cni: flannel, ako_service_type: ClusterIP

### static

- vcenter_network_mgmt_dhcp: false, avi_version: 21.1.3, cni: antrea, ako_service_type: ClusterIP
- vcenter_network_mgmt_dhcp: false, avi_version: 21.1.3, cni: calico, ako_service_type: ClusterIP
- vcenter_network_mgmt_dhcp: false, avi_version: 21.1.3, cni: flannel, ako_service_type: ClusterIP
- vcenter_network_mgmt_dhcp: false, avi_version: 21.1.3, cni: antrea, ako_service_type: NodePortLocal


## on-going

### dhcp

### static

- vcenter_network_mgmt_dhcp: false, avi_version: 21.1.4, cni: antrea, ako_service_type: NodePortLocal



## to be done

### dhcp

- vcenter_network_mgmt_dhcp: true, avi_version: 21.1.4, cni: antrea, ako_service_type: NodePortLocal
- vcenter_network_mgmt_dhcp: true, avi_version: 21.1.4, cni: antrea, ako_service_type: ClusterIP
- vcenter_network_mgmt_dhcp: true, avi_version: 21.1.4, cni: calico, ako_service_type: ClusterIP
- vcenter_network_mgmt_dhcp: true, avi_version: 21.1.4, cni: flannel, ako_service_type: ClusterIP

### static

- vcenter_network_mgmt_dhcp: false, avi_version: 21.1.4, cni: antrea, ako_service_type: ClusterIP
- vcenter_network_mgmt_dhcp: false, avi_version: 21.1.4, cni: calico, ako_service_type: ClusterIP
- vcenter_network_mgmt_dhcp: false, avi_version: 21.1.4, cni: flannel, ako_service_type: ClusterIP

