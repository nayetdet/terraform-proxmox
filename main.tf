terraform {
  required_version = ">= 1.5.0"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~>0.78"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_insecure
}

locals {
  vm_nodes = toset([for vm in values(var.vms) : vm.vm_node])
}

resource "proxmox_download_file" "ubuntu_noble_cloud_image" {
  for_each = local.vm_nodes

  content_type   = "import"
  datastore_id   = "local"
  file_name      = "noble-server-cloudimg-amd64.qcow2"
  node_name      = each.value
  url            = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
  overwrite      = false
  upload_timeout = 3600
}

resource "proxmox_virtual_environment_vm" "vm" {
  for_each = var.vms

  name      = each.key
  node_name = each.value.vm_node
  vm_id     = each.value.vm_id

  cpu {
    cores = each.value.resources.cpu_cores
  }

  memory {
    dedicated = each.value.resources.memory
  }

  disk {
    datastore_id = "local-lvm"
    import_from  = proxmox_download_file.ubuntu_noble_cloud_image[each.value.vm_node].id
    interface    = "scsi0"
    size         = each.value.resources.disk
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
      username = each.value.username
      password = each.value.password
      keys     = [file(pathexpand("~/.ssh/id_ed25519.pub"))]
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
