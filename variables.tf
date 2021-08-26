variable "vm_defaults" {}
variable "vm_list" {}
variable "inventory_template_path" { default = null }
# specify false if the folder(s) already exists
variable "create_vm_folder" { default = true }
