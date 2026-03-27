module "vm" {
  source = "../../"

  hcloud_token = var.hcloud_token

  # SSH keys
  ssh_keys = {
    deploy-key = var.ssh_public_key
  }

  server_ssh_keys = ["deploy-key"]

  # Networks
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
      type         = "cloud"
    }
  }

  # Firewalls
  firewalls = {
    web = {
      rules = [
        {
          description = "Allow SSH"
          direction   = "in"
          protocol    = "tcp"
          port        = "22"
          source_ips  = ["0.0.0.0/0", "::/0"]
        },
        {
          description = "Allow HTTP"
          direction   = "in"
          protocol    = "tcp"
          port        = "80"
          source_ips  = ["0.0.0.0/0", "::/0"]
        },
        {
          description = "Allow HTTPS"
          direction   = "in"
          protocol    = "tcp"
          port        = "443"
          source_ips  = ["0.0.0.0/0", "::/0"]
        },
      ]
    }
  }

  # Placement groups
  placement_groups = {
    web-spread = {
      type = "spread"
    }
  }

  # Servers
  servers = {
    web-01 = {
      name                = "web-01"
      server_type         = "cx22"
      image               = "ubuntu-24.04"
      location            = "nbg1"
      backups             = true
      network_keys        = ["internal"]
      firewall_keys       = ["web"]
      placement_group_key = "web-spread"
      private_ip          = "10.0.1.10"
      labels = {
        environment = "staging"
        role        = "web"
      }
    }
    web-02 = {
      name                = "web-02"
      server_type         = "cx22"
      image               = "ubuntu-24.04"
      location            = "nbg1"
      backups             = true
      network_keys        = ["internal"]
      firewall_keys       = ["web"]
      placement_group_key = "web-spread"
      private_ip          = "10.0.1.11"
      labels = {
        environment = "staging"
        role        = "web"
      }
    }
  }

  # Volumes
  volumes = {
    data-vol = {
      size       = 10
      location   = "nbg1"
      server_key = "web-01"
      format     = "ext4"
      automount  = true
    }
  }

  # Default labels
  labels = {
    managed_by = "opentofu"
    project    = "example"
  }
}
