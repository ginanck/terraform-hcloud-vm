<!-- BEGIN_TF_DOCS -->
# Hetzner Cloud VM Terraform Module

This module creates and manages Hetzner Cloud servers and related infrastructure using the hcloud provider.

## Features

- Full server lifecycle management
- Multi-server deployment via `for_each`
- SSH key management
- Private network and subnet support
- Firewall rules with inbound/outbound support
- Block volume management with automount
- Placement groups for high availability
- Reverse DNS configuration
- Cloud-init / user data support
- Public IPv4/IPv6 toggle
- Flexible per-server overrides
- Configurable via Terragrunt

## Usage

### Basic Example (Single Server)

```hcl
module "hcloud_vm" {
  source = "git::https://github.com/ginanck/terraform-hcloud-vm.git?ref=master"

  hcloud_token = var.hcloud_token

  ssh_keys = {
    my-key = "ssh-ed25519 AAAA... user@host"
  }

  servers = {
    web-server = {
      name        = "web-01"
      server_type = "cx22"
      image       = "ubuntu-24.04"
      location    = "nbg1"
      ssh_keys    = ["my-key"]
      labels      = { env = "production", role = "web" }
    }
  }
}
```

### Multi-Server with Network and Firewall

```hcl
module "hcloud_vm" {
  source = "git::https://github.com/ginanck/terraform-hcloud-vm.git?ref=master"

  hcloud_token = var.hcloud_token

  ssh_keys = {
    deploy-key = "ssh-ed25519 AAAA... deploy@ci"
  }

  firewalls = {
    web-fw = {
      rules = [
        {
          direction  = "in"
          protocol   = "tcp"
          port       = "22"
          source_ips = ["0.0.0.0/0", "::/0"]
        },
        {
          direction  = "in"
          protocol   = "tcp"
          port       = "80"
          source_ips = ["0.0.0.0/0", "::/0"]
        },
        {
          direction  = "in"
          protocol   = "tcp"
          port       = "443"
          source_ips = ["0.0.0.0/0", "::/0"]
        }
      ]
    }
  }

  networks = {
    internal = {
      ip_range = "10.0.0.0/16"
    }
  }

  subnets = {
    internal-subnet = {
      network_key  = "internal"
      ip_range     = "10.0.1.0/24"
      network_zone = "eu-central"
    }
  }

  servers = {
    app-01 = {
      name         = "app-01"
      server_type  = "cx32"
      image        = "ubuntu-24.04"
      location     = "fsn1"
      ssh_keys     = ["deploy-key"]
      firewall_keys = ["web-fw"]
      network_keys = ["internal"]
      private_ip   = "10.0.1.10"
      backups      = true
    }
    app-02 = {
      name         = "app-02"
      server_type  = "cx32"
      image        = "ubuntu-24.04"
      location     = "fsn1"
      ssh_keys     = ["deploy-key"]
      firewall_keys = ["web-fw"]
      network_keys = ["internal"]
      private_ip   = "10.0.1.11"
      backups      = true
    }
  }
}
```

### Placement Groups

```hcl
module "hcloud_vm" {
  source = "git::https://github.com/ginanck/terraform-hcloud-vm.git?ref=master"

  hcloud_token = var.hcloud_token

  ssh_keys = {
    deploy-key = "ssh-ed25519 AAAA... deploy@ci"
  }

  placement_groups = {
    web-spread = {
      type = "spread"
    }
  }

  servers = {
    web-01 = {
      name                = "web-01"
      ssh_keys            = ["deploy-key"]
      placement_group_key = "web-spread"
    }
    web-02 = {
      name                = "web-02"
      ssh_keys            = ["deploy-key"]
      placement_group_key = "web-spread"
    }
  }
}
```

### Reverse DNS

```hcl
module "hcloud_vm" {
  source = "git::https://github.com/ginanck/terraform-hcloud-vm.git?ref=master"

  hcloud_token = var.hcloud_token

  ssh_keys = {
    deploy-key = "ssh-ed25519 AAAA... deploy@ci"
  }

  servers = {
    mail-server = {
      name     = "mail-01"
      ssh_keys = ["deploy-key"]
      rdns     = "mail.example.com"
    }
  }
}
```

### Cloud-Init / User Data

```hcl
module "hcloud_vm" {
  source = "git::https://github.com/ginanck/terraform-hcloud-vm.git?ref=master"

  hcloud_token = var.hcloud_token

  ssh_keys = {
    deploy-key = "ssh-ed25519 AAAA... deploy@ci"
  }

  servers = {
    app-server = {
      name      = "app-01"
      ssh_keys  = ["deploy-key"]
      user_data = <<-EOT
        #cloud-config
        packages:
          - nginx
          - curl
        runcmd:
          - systemctl enable nginx
          - systemctl start nginx
      EOT
    }
  }
}
```

### Public Network Toggle

```hcl
module "hcloud_vm" {
  source = "git::https://github.com/ginanck/terraform-hcloud-vm.git?ref=master"

  hcloud_token = var.hcloud_token

  ssh_keys = {
    deploy-key = "ssh-ed25519 AAAA... deploy@ci"
  }

  networks = {
    internal = {
      ip_range = "10.0.0.0/16"
    }
  }

  subnets = {
    internal-subnet = {
      network_key  = "internal"
      ip_range     = "10.0.1.0/24"
      network_zone = "eu-central"
    }
  }

  servers = {
    private-server = {
      name              = "private-01"
      ssh_keys          = ["deploy-key"]
      public_ipv4_enabled = false
      public_ipv6_enabled = false
      network_keys      = ["internal"]
      private_ip        = "10.0.1.10"
    }
  }
}
```

### Delete and Rebuild Protection

```hcl
module "hcloud_vm" {
  source = "git::https://github.com/ginanck/terraform-hcloud-vm.git?ref=master"

  hcloud_token = var.hcloud_token

  ssh_keys = {
    deploy-key = "ssh-ed25519 AAAA... deploy@ci"
  }

  servers = {
    critical-server = {
      name               = "critical-01"
      ssh_keys           = ["deploy-key"]
      delete_protection  = true
      rebuild_protection = true
    }
  }
}
```

### Multiple Volumes per Server

```hcl
module "hcloud_vm" {
  source = "git::https://github.com/ginanck/terraform-hcloud-vm.git?ref=master"

  hcloud_token = var.hcloud_token

  ssh_keys = {
    admin = "ssh-ed25519 AAAA... admin@host"
  }

  servers = {
    db-server = {
      name        = "db-01"
      server_type = "cx42"
      image       = "debian-12"
      ssh_keys    = ["admin"]
    }
  }

  volumes = {
    db-data = {
      size       = 100
      server_key = "db-server"
      format     = "xfs"
      automount  = true
    }
    db-logs = {
      size       = 50
      server_key = "db-server"
      format     = "ext4"
      automount  = true
      labels     = { purpose = "logs" }
    }
  }
}
```

### Terragrunt Example

```hcl
terraform {
  source = "git::https://github.com/ginanck/terraform-hcloud-vm.git?ref=master"
}

inputs = {
  hcloud_token = get_env("HCLOUD_TOKEN")

  ssh_keys = {
    admin = "ssh-ed25519 AAAA... admin@host"
  }

  placement_groups = {
    db-spread = {}
  }

  servers = {
    db-server = {
      name                = "db-01"
      server_type         = "cx42"
      image               = "debian-12"
      location            = "nbg1"
      ssh_keys            = ["admin"]
      labels              = { env = "production", role = "database" }
      placement_group_key = "db-spread"
      delete_protection   = true
      rebuild_protection  = true
      rdns                = "db-01.example.com"
      user_data           = <<-EOT
        #cloud-config
        packages:
          - postgresql
      EOT
    }
  }

  volumes = {
    db-data = {
      size       = 100
      server_key = "db-server"
      format     = "xfs"
      automount  = true
    }
    db-logs = {
      size       = 50
      server_key = "db-server"
      format     = "ext4"
      automount  = true
      labels     = { purpose = "logs" }
    }
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_hcloud"></a> [hcloud](#requirement\_hcloud) | 1.50.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_hcloud"></a> [hcloud](#provider\_hcloud) | 1.50.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [hcloud_firewall.firewall](https://registry.terraform.io/providers/hetznercloud/hcloud/1.50.0/docs/resources/firewall) | resource |
| [hcloud_network.network](https://registry.terraform.io/providers/hetznercloud/hcloud/1.50.0/docs/resources/network) | resource |
| [hcloud_network_subnet.subnet](https://registry.terraform.io/providers/hetznercloud/hcloud/1.50.0/docs/resources/network_subnet) | resource |
| [hcloud_placement_group.placement_group](https://registry.terraform.io/providers/hetznercloud/hcloud/1.50.0/docs/resources/placement_group) | resource |
| [hcloud_rdns.rdns](https://registry.terraform.io/providers/hetznercloud/hcloud/1.50.0/docs/resources/rdns) | resource |
| [hcloud_server.server](https://registry.terraform.io/providers/hetznercloud/hcloud/1.50.0/docs/resources/server) | resource |
| [hcloud_ssh_key.ssh_key](https://registry.terraform.io/providers/hetznercloud/hcloud/1.50.0/docs/resources/ssh_key) | resource |
| [hcloud_volume.volume](https://registry.terraform.io/providers/hetznercloud/hcloud/1.50.0/docs/resources/volume) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allow_deprecated_images"></a> [allow\_deprecated\_images](#input\_allow\_deprecated\_images) | Allow use of deprecated images | `bool` | `false` | no |
| <a name="input_backups"></a> [backups](#input\_backups) | Enable automatic backups | `bool` | `false` | no |
| <a name="input_delete_protection"></a> [delete\_protection](#input\_delete\_protection) | Enable delete protection (prevents accidental deletion) | `bool` | `false` | no |
| <a name="input_firewall_keys"></a> [firewall\_keys](#input\_firewall\_keys) | Default list of firewall keys to attach to servers | `list(string)` | `[]` | no |
| <a name="input_firewalls"></a> [firewalls](#input\_firewalls) | Map of firewall configurations to create. Each key is the firewall name. | `any` | `{}` | no |
| <a name="input_hcloud_token"></a> [hcloud\_token](#input\_hcloud\_token) | Hetzner Cloud API token | `string` | n/a | yes |
| <a name="input_image"></a> [image](#input\_image) | OS image name or ID (e.g., ubuntu-24.04, debian-12, rocky-9, alma-9) | `string` | `"ubuntu-24.04"` | no |
| <a name="input_keep_disk"></a> [keep\_disk](#input\_keep\_disk) | Keep disk when scaling down server type | `bool` | `false` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Map of labels to apply to resources | `map(string)` | `{}` | no |
| <a name="input_location"></a> [location](#input\_location) | Server location (e.g., nbg1, fsn1, hel1, ash, hil) | `string` | `"nbg1"` | no |
| <a name="input_network_keys"></a> [network\_keys](#input\_network\_keys) | Default list of network keys to attach servers to | `list(string)` | `[]` | no |
| <a name="input_network_zone"></a> [network\_zone](#input\_network\_zone) | Default network zone for subnets (eu-central, us-east, us-west, ap-southeast) | `string` | `"eu-central"` | no |
| <a name="input_networks"></a> [networks](#input\_networks) | Map of network configurations to create. Each key is the network name. | `any` | `{}` | no |
| <a name="input_placement_group_key"></a> [placement\_group\_key](#input\_placement\_group\_key) | Default placement group key to assign to servers | `string` | `null` | no |
| <a name="input_placement_groups"></a> [placement\_groups](#input\_placement\_groups) | Map of placement group configurations to create. Each key is the placement group name. | `any` | `{}` | no |
| <a name="input_public_ipv4_enabled"></a> [public\_ipv4\_enabled](#input\_public\_ipv4\_enabled) | Enable public IPv4 for servers | `bool` | `true` | no |
| <a name="input_public_ipv6_enabled"></a> [public\_ipv6\_enabled](#input\_public\_ipv6\_enabled) | Enable public IPv6 for servers | `bool` | `true` | no |
| <a name="input_rdns"></a> [rdns](#input\_rdns) | Default reverse DNS pointer for server IPv4 address | `string` | `null` | no |
| <a name="input_rebuild_protection"></a> [rebuild\_protection](#input\_rebuild\_protection) | Enable rebuild protection (prevents accidental rebuild) | `bool` | `false` | no |
| <a name="input_server_ssh_keys"></a> [server\_ssh\_keys](#input\_server\_ssh\_keys) | List of SSH key names or IDs to attach to servers (references keys created by ssh\_keys variable or existing keys) | `list(string)` | `[]` | no |
| <a name="input_server_type"></a> [server\_type](#input\_server\_type) | Server type (e.g., cx22, cx32, cx42, cpx11, cpx21, cax11) | `string` | `"cx22"` | no |
| <a name="input_servers"></a> [servers](#input\_servers) | Map of server configurations. Each key is a unique identifier for the server. | `any` | `{}` | no |
| <a name="input_ssh_keys"></a> [ssh\_keys](#input\_ssh\_keys) | Map of SSH key names to public key content to create. Keys are the name, values are the public key string. | `map(string)` | `{}` | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | Map of subnet configurations to create. | `any` | `{}` | no |
| <a name="input_user_data"></a> [user\_data](#input\_user\_data) | Cloud-init user data script or configuration | `string` | `null` | no |
| <a name="input_volume_automount"></a> [volume\_automount](#input\_volume\_automount) | Default automount setting for volumes | `bool` | `false` | no |
| <a name="input_volume_format"></a> [volume\_format](#input\_volume\_format) | Default filesystem format for volumes (ext4, xfs) | `string` | `"ext4"` | no |
| <a name="input_volumes"></a> [volumes](#input\_volumes) | Map of volume configurations to create and attach to servers. | `any` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_firewall_ids"></a> [firewall\_ids](#output\_firewall\_ids) | Map of firewall names to their IDs |
| <a name="output_network_ids"></a> [network\_ids](#output\_network\_ids) | Map of network names to their IDs |
| <a name="output_placement_group_ids"></a> [placement\_group\_ids](#output\_placement\_group\_ids) | Map of placement group names to their IDs |
| <a name="output_server_ids"></a> [server\_ids](#output\_server\_ids) | Map of server keys to their IDs |
| <a name="output_server_ipv4_addresses"></a> [server\_ipv4\_addresses](#output\_server\_ipv4\_addresses) | Map of server keys to their public IPv4 addresses |
| <a name="output_server_ipv6_addresses"></a> [server\_ipv6\_addresses](#output\_server\_ipv6\_addresses) | Map of server keys to their public IPv6 addresses |
| <a name="output_server_status"></a> [server\_status](#output\_server\_status) | Map of server keys to their status |
| <a name="output_ssh_key_ids"></a> [ssh\_key\_ids](#output\_ssh\_key\_ids) | Map of SSH key names to their IDs |
| <a name="output_subnet_ids"></a> [subnet\_ids](#output\_subnet\_ids) | Map of subnet keys to their IDs |
| <a name="output_volume_ids"></a> [volume\_ids](#output\_volume\_ids) | Map of volume names to their IDs |
| <a name="output_volume_linux_devices"></a> [volume\_linux\_devices](#output\_volume\_linux\_devices) | Map of volume names to their Linux device paths |
<!-- END_TF_DOCS -->
