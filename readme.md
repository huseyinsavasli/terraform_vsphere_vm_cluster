# Provisioning vSphere VMs for a cluster

This is a module to quickly provision a number of VMs for a cluster, especially a Kubernetes cluster. Optionally it can generate an [inventory file](https://github.com/kubernetes-sigs/kubespray/blob/master/docs/ansible.md) for [kubespray](https://github.com/kubernetes-sigs/kubespray)

## Features

* Specify defaults once only
* Provision several groups of nodes for you cluster with different hardware (disk, memory, CPU) for each group
* Use DHCP or static IP addresses for new VMs
* Override individual provisioning properties on group or individual VM basis
* Specify additional disks if required
* Automatically generate a Kubespray inventory
* Customize inventory template file for your needs

A vSphere virtual machine has a lot of parameters, so it was not feasible to support all of them. Following parameters are supported:

```text
name_prefix           = "k-"               # Prefix for all machine names / host names in cluster
name                  = "default"          # Virtual machine name and host name
ip                    = null               # IP address, use DHCP if null
datacenter            = "Datacenter"       # Datacenter to provision VM in
cluster               = "Cluster"          # Cluster to provision VM on
datastore             = "DS01"             # Datastore to provision VM on
folder                = "Kubernetes"       # VM Floder to provision VM in
template              = "ubuntu-2004-base" # VM template path to provision VM from
network               = "VMInt"            # Network to put VM on
netmask               = 24                 # Netmask, if using DHCP can be null
gateway               = "192.168.90.1"     # Default gateway on the network, if using DHCP can be null
dns_server_list       = ["192.168.88.1"]   # DNS servers to use, if using DHCP can be null
domain                = "internal"         # Domain of the VM
dns_suffix_list       = ["mydomain.tld"]   # List of search suffixes for DNS
disk_size             = 64                 # Size (GB) of the disk, can only be greater or equal to the VM tempalte size
additional_disk_sizes = [50,50]            # Array of sizes (GB) of additional disks to provision
vcpu                  = 2                  # Number of CPUs
memory                = 4096               # Memory in Mb
```
## Customizing Ansible template

The default template is given in [templates/ansible_hosts.tpl](templates/ansible_hosts.tpl), The template syntax reference is available in [terraform documentaion](https://www.terraform.io/docs/configuration/expressions.html#string-templates). Kubespray specific considerations are outlined [here](https://github.com/kubernetes-sigs/kubespray/blob/master/docs/ansible.md). Familiarity with [inventory files in Ansible](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html) in general will also help. Once you created your own template specify its filename via `inventory_template_path` module parameter, see [example/main.tf](example/main.tf).

## Usage

You can find an annotated example of usage in [example/main.tf](example/main.tf).

