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

variable "vms" {
  description = "Map of VM definitions keyed by VM name"
  type = map(object({
    vm_id    = number
    vm_node  = string
    username = string
    password = string
    resources = object({
      cpu_cores = number
      memory    = number
      disk      = number
    })
    networking = object({
      ipv4    = string
      gateway = string
    })
  }))
}
