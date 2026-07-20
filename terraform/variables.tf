variable "proxmox_endpoint" {
  description = "Proxmox API endpoint, for example https://pve.example.com:8006/"
  type        = string
}

variable "proxmox_api_token" {
  description = "Proxmox API token in the form user@realm!tokenid=secret"
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Skip TLS verification for the Proxmox API endpoint"
  type        = bool
  default     = false
}

variable "vm_image_filename" {
  description = "Filename used to store the VM image in Proxmox"
  type        = string
  default     = "ubuntu-26.04-server-cloudimg-amd64.qcow2"
}

variable "vm_image_url" {
  description = "URL of the VM image"
  type        = string
  default     = "https://cloud-images.ubuntu.com/releases/resolute/release/ubuntu-26.04-server-cloudimg-amd64.img"
}

variable "container_image_filename" {
  description = "Filename used to store the container image in Proxmox"
  type        = string
  default     = "ubuntu-26.04-server-cloudimg-amd64-root.tar.xz"
}

variable "container_image_url" {
  description = "URL of the container image"
  type        = string
  default     = "https://cloud-images.ubuntu.com/releases/server/server/26.04/release/ubuntu-26.04-server-cloudimg-amd64-root.tar.xz"
}

variable "instances" {
  description = "Map of VM and LXC definitions keyed by instance name"
  type = map(object({
    id   = number
    node = string
    type = string
    user = object({
      username = string
      password = string
    })
    resources = object({
      cores   = number
      ram_mb  = number
      disk_gb = number
    })
    networking = object({
      ipv4    = string
      gateway = string
    })
  }))
  validation {
    condition = alltrue([
      for instance in values(var.instances) : contains(["vm", "container"], instance.type)
    ])
    error_message = "instances.type must be one of: vm, container."
  }
}
