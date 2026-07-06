# Terraform Proxmox

Provisiona VMs no Proxmox via Terraform usando a provider `bpg/proxmox`.

## O que ele faz

- Conecta no endpoint da API do Proxmox com token.
- Cria uma ou mais VMs a partir de uma definição em `var.vms`.
- Configura CPU, memória, disco, rede, usuário e senha inicial.

## Estrutura

- `main.tf`: configuração do provider e recursos de criação das VMs.
- `variables.tf`: variáveis de entrada.
- `shell.nix`: ambiente com `terraform`.

## Requisitos

- Acesso ao Proxmox com token de API
- Chave pública SSH disponível no caminho esperado pelo Terraform

## Como usar

1. Entre no ambiente, se usar Nix:

```bash
nix-shell
```

2. Crie um arquivo `terraform.tfvars` com seus dados:

```hcl
proxmox_endpoint  = "https://pve.example.com:8006/"
proxmox_api_token = "user@pam!tokenid=secret"
proxmox_insecure  = false

vms = {
  "vm-01" = {
    vm_id    = 101
    vm_node  = "pve01"
    username = "ubuntu"
    password = "changeme"
    resources = {
      cpu_cores = 2
      memory    = 2048
      disk      = 20
    }
    networking = {
      ipv4    = "192.168.1.101/24"
      gateway = "192.168.1.1"
    }
  }
}
```

3. Inicialize o Terraform:

```bash
terraform init
```

4. Revise o plano:

```bash
terraform plan
```

5. Aplique:

```bash
terraform apply
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

- `vm_id`: ID numérico da VM no Proxmox
- `vm_node`: nó do Proxmox onde a VM será criada
- `username`: usuário inicial da VM
- `password`: senha inicial da VM
- `resources.cpu_cores`: quantidade de vCPUs
- `resources.memory`: memória em MB
- `resources.disk`: tamanho do disco conforme esperado pelo provider
- `networking.ipv4`: IP com prefixo, por exemplo `192.168.1.101/24`
- `networking.gateway`: gateway padrão
