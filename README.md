# Terraform Proxmox

Provisiona VMs no Proxmox via Terraform usando a provider `bpg/proxmox`.

## O que ele faz

- Conecta no endpoint da API do Proxmox com token.
- Cria uma ou mais VMs a partir de uma definição em `terraform/variables.tf` via `var.vms`.
- Configura CPU, memória, disco, rede, usuário e senha inicial.
- Gera o inventory do Ansible em `ansible/inventory.yml`.

## Estrutura

- `terraform/main.tf`: configuração do provider e recursos de criação das VMs.
- `terraform/variables.tf`: variáveis de entrada.
- `terraform/terraform.tfvars`: exemplo de valores locais para o Terraform.
- `shell.nix`: ambiente com `terraform`.
- `ansible/inventory.yml`: inventory gerado automaticamente pelo Terraform e usado pelo Ansible.

## Requisitos

- Acesso ao Proxmox com token de API
- Chave pública SSH opcional em `~/.ssh/id_ed25519.pub`

## Como usar

1. Entre no ambiente, se usar Nix:

```bash
nix-shell
```

2. Entre na pasta do Terraform:

```bash
cd terraform
```

3. Crie um arquivo `terraform.tfvars` com seus dados:

```hcl
proxmox_endpoint  = "https://pve.example.com:8006/"
proxmox_api_token = "user@pam!tokenid=secret"
proxmox_insecure  = false

vms = {
  "vm-01" = {
    metadata = {
      vm_id   = 101
      vm_node = "pve01"
    }
    user = {
      username = "ubuntu"
      password = "changeme"
    }
    resources = {
      cores   = 2
      ram_mb  = 2048
      disk_gb = 20
    }
    networking = {
      ipv4    = "192.168.1.101/24"
      gateway = "192.168.1.1"
    }
  }
}
```

4. Inicialize o Terraform:

```bash
terraform init
```

5. Revise o plano:

```bash
terraform plan
```

6. Aplique:

```bash
terraform apply
```

Isso também gera `ansible/inventory.yml` com os hosts provisionados.

7. Rode o Ansible a partir da pasta `ansible/`:

```bash
cd ansible
ansible-playbook playbook.yml
```

## Variáveis

### `proxmox_endpoint`

Endpoint da API do Proxmox, por exemplo `https://pve.example.com:8006/`.

### `proxmox_api_token`

Token no formato `user@realm!tokenid=secret`.

### `proxmox_insecure`

Define se a verificação TLS deve ser ignorada. O padrão é `false`.

### `vms`

Mapa de VMs, indexado pelo nome da VM. Cada entrada espera:

- `metadata.vm_id`: ID numérico da VM no Proxmox
- `metadata.vm_node`: nó do Proxmox onde a VM será criada
- `user.username`: usuário inicial da VM
- `user.password`: senha inicial da VM
- `resources.cores`: quantidade de vCPUs
- `resources.ram_mb`: memória em MB
- `resources.disk_gb`: tamanho do disco em GB
- `networking.ipv4`: IP com prefixo, por exemplo `192.168.1.101/24`
- `networking.gateway`: gateway padrão
