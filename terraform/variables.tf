variable "proxmox_endpoint" {
  description = "Proxmox API endpoint, for example https://pve.example.com:8006/"
  type        = string
}

variable "proxmox_username" {
  description = "Proxmox API username, for example root@pam"
  type        = string
  default     = "root@pam"
}

variable "proxmox_password" {
  description = "Proxmox API password"
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

variable "container_os_type" {
  description = "Operating system type used by Proxmox to configure the container"
  type        = string
  default     = "ubuntu"
}

variable "vms" {
  description = "Map of VM definitions keyed by VM name"
  type = map(object({
    id   = number
    node = string
    user = object({
      username = string
      password = string
    })
    resources = object({
      architecture = optional(string, "x86_64")
      cpu_type     = optional(string, "x86-64-v2")
      cores        = number
      ram_mb       = number
      disk_gb      = number
    })
    networking = object({
      ipv4    = string
      gateway = string
    })
  }))
  default = {}
}

variable "containers" {
  description = "Map of LXC container definitions keyed by container name"
  type = map(object({
    id   = number
    node = string
    user = object({
      password = string
    })
    resources = object({
      architecture = optional(string, "x86_64")
      cpu_type     = optional(string, "x86-64-v2")
      cores        = number
      ram_mb       = number
      disk_gb      = number
    })
    features = optional(object({
      fuse    = optional(bool)
      keyctl  = optional(bool, false)
      mknod   = optional(bool)
      nesting = optional(bool, true)
      mount   = optional(list(string))
    }), {})
    devices = optional(list(object({
      path       = string
      deny_write = optional(bool)
      gid        = optional(number)
      mode       = optional(string)
      uid        = optional(number)
    })), [])
    networking = object({
      ipv4    = string
      gateway = string
    })
  }))
  default = {}
}
