locals {
  # These are defaults for each provisionined VM
  # They will apply to every VM unless overwritten for specific VM below
  vm_defaults = {
    name_prefix           = "k-"               # Prefix for all machine names / host names in cluster
    name                  = "default"          # Virtual machine name and host name
    ip                    = null               # IP address, use DHCP if null
    datacenter            = "Datacenter"       # Datacenter to provision VM in
    cluster               = "Cluster"          # Cluster to provision VM on
    datastore             = "SSD1"             # Datastore to provision VM on
    folder                = "Kubernetes"       # VM Floder to provision VM in
    template              = "ubuntu-2004-base" # VM template path to provision VM from
    network               = "VMInt"            # Network to put VM on
    netmask               = 24                 # Netmask, if using DHCP can be null
    gateway               = "192.168.90.1"     # Default gateway on the network, if using DHCP can be null
    dns_server_list       = ["192.168.88.1"]   # DNS servers to use, if using DHCP can be null
    domain                = "internal"         # Domain of the VM
    dns_suffix_list       = null               # List of search suffixes for DNS
    disk_size             = 64                 # Size (GB) of the disk, can only be greater or equal to the VM tempalte size
    additional_disk_sizes = []                 # Array of sizes (GB) of additional disks to provision
    vcpu                  = 2                  # Number of CPUs
    memory                = 4096               # Memory in Mb
  }

  # Each of node groups are defined here
  vm_list = [
    {
      # Specify this for ansible inventory generation. This will be ansible group name
      ansible_group = "master"
      # This is a prefix for vm name and hostname, the actual names will be master1, master2, master3, etc
      name = "master"
      # This is a prefix for etcd node name, specify this for ansible inventory generation
      etcd = "etcd"
      # specify individual values for each machine in the group
      # This works with all properies but ansible_group and count, by appending '_array' to the property name
      ip_array = ["192.168.90.90", "192.168.90.91", "192.168.90.92"]
      # More customizations for the group
      memory = 4096
      count  = 3
    },
    {
      ip_array      = ["192.168.90.93", "192.168.90.94", "192.168.90.95"]
      ansible_group = "node"
      name          = "node"
      memory        = 8192
      count         = 3
    },
    {
      ip_array              = ["192.168.90.96", "192.168.90.97", "192.168.90.98"]
      ansible_group         = "storage"
      name                  = "storage"
      additional_disk_sizes = [50]
      memory                = 4096
      count                 = 3
    },
  ]
}

# Call the module
module "nodes" {
  source      = "github.com/AndrewSav/terraform_vsphere_vm_cluster"
  vm_defaults = local.vm_defaults
  vm_list     = local.vm_list
  # You can specify your own inventory tempalte if you like
  #inventory_template_path = "c:\inventory.tpl"
}

# Write out inventory to a local file
# But you can write it to whereever you want, e.g. Consul, or skip this step alltogether if you do not need inventory
resource "local_file" "inventory" {
  content  = module.nodes.inventory
  filename = "${path.module}/ansible_hosts.ini"
}
