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
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_insecure
}

locals {
  vm_nodes = toset([for vm in values(var.vms) : vm.metadata.vm_node])
  ansible_inventory = {
    all = {
      hosts = {
        for name, vm in var.vms : name => {
          ansible_host = split("/", vm.networking.ipv4)[0]
          ansible_user = vm.user.username
        }
      }
    }
  }
}

resource "local_file" "ansible_inventory" {
  filename        = "${path.root}/../ansible/inventory.yml"
  content         = yamlencode(local.ansible_inventory)
  file_permission = "0644"
}

resource "proxmox_download_file" "vm_image" {
  for_each = local.vm_nodes

  content_type   = "import"
  datastore_id   = "local"
  file_name      = "ubuntu-26.04-server-cloudimg-amd64.qcow2"
  node_name      = each.value
  url            = "https://cloud-images.ubuntu.com/releases/resolute/release/ubuntu-26.04-server-cloudimg-amd64.img"
  overwrite      = false
  upload_timeout = 3600
}

resource "proxmox_virtual_environment_vm" "vm" {
  for_each = var.vms

  name      = each.key
  node_name = each.value.metadata.vm_node
  vm_id     = each.value.metadata.vm_id

  cpu {
    cores = each.value.resources.cores
  }

  memory {
    dedicated = each.value.resources.ram_mb
  }

  disk {
    datastore_id = "local-lvm"
    import_from  = proxmox_download_file.vm_image[each.value.metadata.vm_node].id
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
      keys     = fileexists(pathexpand("~/.ssh/id_ed25519.pub")) ? [file(pathexpand("~/.ssh/id_ed25519.pub"))] : []
    }
  }

  network_device {
    bridge = "vmbr0"
  }

  boot_order = ["scsi0"]

  serial_device {
    device = "socket"
  }
}
