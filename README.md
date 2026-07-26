# Terraform Proxmox

Provisioning and configuration of Proxmox VMs and LXC containers with Terraform and Ansible.

## What it does

- Connects to the Proxmox API endpoint using `root@pam`.
- Creates VMs and LXC containers from a single definition in `var.instances`.
- Uses `type = "vm"` or `type = "container"` to select the instance type.
- Configures CPU, memory, disks, networking, users, and initial passwords.
- Generates the Ansible inventory at `ansible/inventory.ini`, with `vm` and `container` groups.

## Structure

- `terraform/main.tf`: provider configuration and instance creation resources.
- `terraform/variables.tf`: input variables.
- `terraform/terraform.tfvars`: example local Terraform values.
- `shell.nix`: environment containing `terraform`.
- `ansible/inventory.ini`: inventory generated automatically by Terraform and used by Ansible.

## Requirements

- Access to Proxmox with a username and password, preferably `root@pam`.
- An optional SSH public key at `~/.ssh/id_ed25519.pub`.

## Usage

1. Enter the environment if you use Nix:

```bash
nix-shell
```

2. Enter the Terraform directory:

```bash
cd terraform
```

3. Create a `terraform.tfvars` file with your values:

```hcl
proxmox_endpoint = "https://pve.example.com:8006/"
proxmox_insecure = false

instances = {
  "vm-01" = {
    id   = 101
    node = "pve01"
    type = "vm"
    user = {
      username = "ubuntu"
      password = "changeme"
    }
    resources = {
      architecture = "x86_64"
      cpu_type     = "x86-64-v2"
      cores        = 2
      ram_mb       = 2048
      disk_gb      = 20
    }
    networking = {
      ipv4    = "192.168.1.101/24"
      gateway = "192.168.1.1"
    }
  }
  "lxc-01" = {
    id   = 201
    node = "pve01"
    type = "container"
    user = {
      username = "root"
      password = "changeme"
    }
    resources = {
      cores   = 1
      ram_mb  = 512
      disk_gb = 8
    }
    networking = {
      ipv4    = "192.168.1.201/24"
      gateway = "192.168.1.1"
    }
  }
}
```

4. Initialize Terraform:

```bash
terraform init
```

5. Review the plan:

```bash
terraform plan
```

6. Apply the configuration:

```bash
terraform apply
```

This also generates `ansible/inventory.ini` with the provisioned hosts.

7. Run Ansible from the `ansible/` directory:

```bash
cd ansible
ansible-playbook playbook.yml
```

To run only specific roles, use the corresponding tags:

```bash
ansible-playbook playbook.yml --tags "docker,ssh"
```

The available tags are `docker`, `firewall`, `shell`, `ssh`, and `tools`. To run all roles, omit `--tags`; to skip a specific role, use `--skip-tags`.

## Variables

### `proxmox_endpoint`

Proxmox API endpoint, for example `https://pve.example.com:8006/`.

### `proxmox_username`

Username used for the Proxmox API. The default is `root@pam`.

### `proxmox_password`

API user password. It is recommended to provide it through the `TF_VAR_proxmox_password` environment variable.

### `proxmox_insecure`

Whether TLS certificate verification should be skipped. The default is `false`.

### Images

- `vm_image_filename`: VM image filename on Proxmox.
- `vm_image_url`: VM image URL.
- `container_image_filename`: container image filename on Proxmox.
- `container_image_url`: container image URL.
- `container_os_type`: operating system type used by Proxmox to configure the container.

All four variables default to Ubuntu 26.04 and can be overridden in `terraform.tfvars`.

### `instances`

Single map of instances, indexed by name. Each entry expects:

- `id`: numeric ID of the VM or container on Proxmox.
- `node`: Proxmox node where the instance will be created.
- `type`: `vm` or `container`.
- `user.username`: initial VM user.
- `user.password`: initial VM password.
- `resources.architecture`: VM CPU architecture, such as `x86_64` or `aarch64` (default: `x86_64`).
- `resources.cpu_type`: CPU model exposed to the VM (default: `x86-64-v2`).
- `resources.cores`: number of vCPUs.
- `resources.ram_mb`: memory in MB.
- `resources.disk_gb`: disk size in GB.
- `networking.ipv4`: IP address with prefix, such as `192.168.1.101/24`.
- `networking.gateway`: default gateway.

`container` instances are created as privileged containers. The template used by the containers is the official Ubuntu 26.04 image for LXD/LXC.
