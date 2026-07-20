terraform {
  required_version = ">= 1.5.0"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5.0"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.111.1"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox_endpoint
  username = var.proxmox_username
  password = var.proxmox_password
  insecure = var.proxmox_insecure
}

locals {
  vm_instances        = { for name, instance in var.instances : name => instance if instance.type == "vm" }
  container_instances = { for name, instance in var.instances : name => instance if instance.type != "vm" }
  ssh_keys            = fileexists(pathexpand("~/.ssh/id_ed25519.pub")) ? [file(pathexpand("~/.ssh/id_ed25519.pub"))] : []
}

resource "local_file" "ansible_inventory" {
  filename        = "${path.root}/../ansible/inventory.ini"
  content         = templatefile("${path.module}/inventory.ini.tftpl", { vms = local.vm_instances, containers = local.container_instances })
  file_permission = "0644"
}

resource "proxmox_download_file" "vm_image" {
  for_each = toset([for vm in values(local.vm_instances) : vm.node])

  content_type   = "import"
  datastore_id   = "local"
  file_name      = var.vm_image_filename
  node_name      = each.value
  url            = var.vm_image_url
  upload_timeout = 3600
}

resource "proxmox_download_file" "container_image" {
  for_each = toset([for container in values(local.container_instances) : container.node])

  content_type   = "vztmpl"
  datastore_id   = "local"
  file_name      = var.container_image_filename
  node_name      = each.value
  url            = var.container_image_url
  upload_timeout = 3600
}

resource "proxmox_virtual_environment_vm" "vm" {
  for_each = local.vm_instances

  name      = each.key
  node_name = each.value.node
  vm_id     = each.value.id

  cpu {
    cores = each.value.resources.cores
  }

  memory {
    dedicated = each.value.resources.ram_mb
  }

  disk {
    datastore_id = "local-lvm"
    import_from  = proxmox_download_file.vm_image[each.value.node].id
    interface    = "scsi0"
    size         = each.value.resources.disk_gb
  }

  initialization {
    datastore_id = "local-lvm"

    ip_config {
      ipv4 {
        address = each.value.networking.ipv4
        gateway = each.value.networking.gateway
      }
    }

    user_account {
      username = each.value.user.username
      password = each.value.user.password
      keys     = local.ssh_keys
    }
  }

  network_device {
    bridge = "vmbr0"
  }
}

resource "proxmox_virtual_environment_container" "container" {
  for_each = local.container_instances

  node_name     = each.value.node
  vm_id         = each.value.id

  features {
    nesting = true
  }

  cpu {
    cores = each.value.resources.cores
  }

  memory {
    dedicated = each.value.resources.ram_mb
  }

  disk {
    datastore_id = "local-lvm"
    size         = each.value.resources.disk_gb
  }

  operating_system {
    template_file_id = proxmox_download_file.container_image[each.value.node].id
    type             = var.container_os_type
  }

  initialization {
    hostname = each.key

    ip_config {
      ipv4 {
        address = each.value.networking.ipv4
        gateway = each.value.networking.gateway
      }
    }

    user_account {
      password = each.value.user.password
      keys     = local.ssh_keys
    }
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }
}
