locals {
  inventory_template_path = var.inventory_template_path == null ? "${path.module}/templates/ansible_hosts.tpl" : var.inventory_template_path
  merged                  = [for vm in var.vm_list : merge(var.vm_defaults, vm)]
  flattened = flatten([
    for vm in local.merged : [
      for item in range(vm.count) :
      merge(vm, {
        name                  = try("${vm.name_prefix}${vm.name_array[item]}", "${vm.name_prefix}${vm.name}${item + 1}", vm.name_array[item], "${vm.name}${item + 1}")
        etcd                  = try(vm.etcd_array[item], vm.etcd == null ? null : "${vm.etcd}${item + 1}", null)
        ip                    = try(vm.ip_array[item], vm.ip)
        datacenter            = try(vm.datacenter_array[item], vm.datacenter)
        cluster               = try(vm.cluster_array[item], vm.cluster)
        datastore             = try(vm.datastore_array[item], vm.datastore)
        folder                = try(vm.folder_array[item], vm.folder)
        template              = try(vm.template_array[item], vm.template)
        network               = try(vm.network_array[item], vm.network)
        netmask               = try(vm.netmask_array[item], vm.netmask)
        gateway               = try(vm.gateway_array[item], vm.gateway)
        dns_server_list       = try(vm.dns_server_list_array[item], vm.dns_server_list)
        domain                = try(vm.domain_array[item], vm.domain)
        dns_suffix_list       = try(vm.dns_suffix_list_array[item], vm.dns_suffix_list)
        disk_size             = try(vm.disk_size_array[item], vm.disk_size)
        additional_disk_sizes = try(vm.additional_disk_sizes_array[item], vm.additional_disk_sizes)
        vcpu                  = try(vm.vcpu_array[item], vm.vcpu)
        memory                = try(vm.memory_array[item], vm.memory)
      })
    ]
  ])
  vms = { for vm in local.flattened : vm.name => vm }
  folders = var.create_vm_folder ? {
    for folder in distinct([
      for vm in local.flattened : {
        folder     = vm.folder,
        datacenter = vm.datacenter
      }
    ]) : "${folder.datacenter}-${folder.folder}" =>
    {
      folder = folder.folder
      dckey  = coalesce([
        for vm in local.flattened : vm.name 
        if vm.folder == folder.folder && vm.datacenter == folder.datacenter
      ]...) 
    }
  } : {}
}

data "vsphere_datacenter" "datacentre" {
  for_each = local.vms
  name     = each.value.datacenter
}

data "vsphere_datastore" "datastore" {
  for_each      = local.vms
  name          = each.value.datastore
  datacenter_id = data.vsphere_datacenter.datacentre[each.key].id
}

data "vsphere_resource_pool" "pool" {
  for_each      = local.vms
  name          = "${each.value.cluster}/Resources"
  datacenter_id = data.vsphere_datacenter.datacentre[each.key].id
}

data "vsphere_network" "network" {
  for_each      = local.vms
  name          = each.value.network
  datacenter_id = data.vsphere_datacenter.datacentre[each.key].id
}

data "vsphere_virtual_machine" "template" {
  for_each      = local.vms
  name          = each.value.template
  datacenter_id = data.vsphere_datacenter.datacentre[each.key].id
}

resource "vsphere_folder" "folder" {
  for_each      = local.folders
  path          = each.value.folder
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.datacentre[each.value.dckey].id
}

resource "vsphere_virtual_machine" "vm" {

  for_each = local.vms

  name             = each.value.name
  folder           = each.value.folder
  num_cpus         = each.value.vcpu
  memory           = each.value.memory
  datastore_id     = data.vsphere_datastore.datastore[each.key].id
  resource_pool_id = data.vsphere_resource_pool.pool[each.key].id
  guest_id         = data.vsphere_virtual_machine.template[each.key].guest_id
  annotation       = "Built on ${timestamp()}"
  lifecycle {
    ignore_changes = [annotation]
  }

  network_interface {
    network_id = data.vsphere_network.network[each.key].id
  }

  disk {
    label = "disk0"
    size  = each.value.disk_size == null ? data.vsphere_virtual_machine.template[each.key].disks[0].size : each.value.disk_size
  }

  dynamic "disk" {
    for_each = each.value.additional_disk_sizes
    content {
      label       = "disk${disk.key + 1}"
      size        = disk.value
      unit_number = disk.key + 1
    }
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template[each.key].id
    customize {
      linux_options {
        host_name = each.value.name
        domain    = each.value.domain
      }

      network_interface {
        ipv4_address = each.value.ip
        ipv4_netmask = each.value.netmask
      }

      dns_server_list = each.value.dns_server_list
      ipv4_gateway    = each.value.gateway
      dns_suffix_list = each.value.dns_suffix_list
    }
  }
}

output "inventory" {
  value = templatefile(local.inventory_template_path, {
    groups = {
      for group in var.vm_list : group.ansible_group => [
        for vm in vsphere_virtual_machine.vm : {
          name = vm.name
          ip   = vm.default_ip_address
          etcd = local.vms[vm.name].etcd
        } if group.ansible_group == try(local.vms[vm.name].ansible_group, null)
      ]
    }
  })
}
