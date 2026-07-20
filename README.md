# Terraform Proxmox

Provisiona VMs e containers LXC no Proxmox via Terraform usando o provider `bpg/proxmox`.

## O que ele faz

- Conecta no endpoint da API do Proxmox com token.
- Cria VMs e containers LXC a partir de uma definição única em `var.instances`.
- Usa `type = "vm"` ou `type = "container"` para escolher o tipo.
- Configura CPU, memória, disco, rede, usuário e senha inicial.
- Gera o inventory do Ansible em `ansible/inventory.ini`, com os grupos `vm` e `container`.

## Estrutura

- `terraform/main.tf`: configuração do provider e recursos de criação das instâncias.
- `terraform/variables.tf`: variáveis de entrada.
- `terraform/terraform.tfvars`: exemplo de valores locais para o Terraform.
- `shell.nix`: ambiente com `terraform`.
- `ansible/inventory.ini`: inventory gerado automaticamente pelo Terraform e usado pelo Ansible.

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
      cores   = 2
      ram_mb  = 2048
      disk_gb = 20
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

Isso também gera `ansible/inventory.ini` com os hosts provisionados.

7. Rode o Ansible a partir da pasta `ansible/`:

```bash
cd ansible
ansible-playbook playbook.yml
```

Para executar somente algumas roles, use as tags correspondentes:

```bash
ansible-playbook playbook.yml --tags "docker,ssh"
```

As tags disponíveis são `docker`, `firewall`, `shell`, `ssh` e `tools`. Para executar todas as roles, omita `--tags`; para ignorar uma role específica, use `--skip-tags`.

## Variáveis

### `proxmox_endpoint`

Endpoint da API do Proxmox, por exemplo `https://pve.example.com:8006/`.

### `proxmox_api_token`

Token no formato `user@realm!tokenid=secret`.

### `proxmox_insecure`

Define se a verificação TLS deve ser ignorada. O padrão é `false`.

### Imagens

- `vm_image_filename`: nome do arquivo da imagem da VM no Proxmox
- `vm_image_url`: URL da imagem da VM
- `container_image_filename`: nome do arquivo da imagem do container no Proxmox
- `container_image_url`: URL da imagem do container

As quatro variáveis têm defaults para Ubuntu 26.04 e podem ser sobrescritas no `terraform.tfvars`.

### `instances`

Mapa único de instâncias, indexado pelo nome. Cada entrada espera:

- `id`: ID numérico da VM ou container no Proxmox
- `node`: nó do Proxmox onde a instância será criada
- `type`: `vm` ou `container`
- `user.username`: usuário inicial da VM
- `user.password`: senha inicial da VM
- `resources.cores`: quantidade de vCPUs
- `resources.ram_mb`: memória em MB
- `resources.disk_gb`: tamanho do disco em GB
- `networking.ipv4`: IP com prefixo, por exemplo `192.168.1.101/24`
- `networking.gateway`: gateway padrão

Instâncias `container` são criadas como privileged. O template usado pelos containers é a imagem oficial Ubuntu 26.04 para LXD/LXC.
