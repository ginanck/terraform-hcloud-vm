# SSH keys

resource "hcloud_ssh_key" "ssh_key" {
  for_each = var.ssh_keys

  name       = each.key
  public_key = each.value
  labels     = var.labels
}

# Placement groups

resource "hcloud_placement_group" "placement_group" {
  for_each = var.placement_groups

  name   = each.key
  type   = lookup(each.value, "type", "spread")
  labels = lookup(each.value, "labels", var.labels)
}

# Firewalls

resource "hcloud_firewall" "firewall" {
  for_each = var.firewalls

  name   = each.key
  labels = lookup(each.value, "labels", var.labels)

  dynamic "rule" {
    for_each = lookup(each.value, "rules", [])
    content {
      direction       = rule.value.direction
      protocol        = rule.value.protocol
      port            = lookup(rule.value, "port", null)
      source_ips      = lookup(rule.value, "source_ips", [])
      destination_ips = lookup(rule.value, "destination_ips", [])
      description     = lookup(rule.value, "description", null)
    }
  }
}

# Networks

resource "hcloud_network" "network" {
  for_each = var.networks

  name     = each.key
  ip_range = each.value.ip_range
  labels   = lookup(each.value, "labels", var.labels)

  delete_protection = lookup(each.value, "delete_protection", false)
}

resource "hcloud_network_subnet" "subnet" {
  for_each = var.subnets

  network_id   = hcloud_network.network[each.value.network_key].id
  type         = lookup(each.value, "type", "cloud")
  ip_range     = each.value.ip_range
  network_zone = lookup(each.value, "network_zone", var.network_zone)
}

# Servers

resource "hcloud_server" "server" {
  for_each = var.servers

  # Basic settings
  name        = each.value.name
  server_type = lookup(each.value, "server_type", var.server_type)
  image       = lookup(each.value, "image", var.image)
  location    = lookup(each.value, "location", var.location)
  labels      = lookup(each.value, "labels", var.labels)

  # Server behavior settings
  backups                 = lookup(each.value, "backups", var.backups)
  delete_protection       = lookup(each.value, "delete_protection", var.delete_protection)
  rebuild_protection      = lookup(each.value, "rebuild_protection", var.rebuild_protection)
  keep_disk               = lookup(each.value, "keep_disk", var.keep_disk)
  allow_deprecated_images = lookup(each.value, "allow_deprecated_images", var.allow_deprecated_images)

  # SSH keys
  ssh_keys = lookup(each.value, "ssh_keys", var.server_ssh_keys)

  # Placement group
  placement_group_id = lookup(each.value, "placement_group_key", null) != null ? hcloud_placement_group.placement_group[each.value.placement_group_key].id : (
    var.placement_group_key != null ? hcloud_placement_group.placement_group[var.placement_group_key].id : null
  )

  # Firewall IDs
  firewall_ids = [
    for fw_key in lookup(each.value, "firewall_keys", var.firewall_keys) :
    hcloud_firewall.firewall[fw_key].id
  ]

  # User data (cloud-init)
  user_data = lookup(each.value, "user_data", var.user_data)

  # Public network configuration
  public_net {
    ipv4_enabled = lookup(each.value, "public_ipv4_enabled", var.public_ipv4_enabled)
    ipv6_enabled = lookup(each.value, "public_ipv6_enabled", var.public_ipv6_enabled)
  }

  # Network attachment
  dynamic "network" {
    for_each = lookup(each.value, "network_keys", var.network_keys)
    content {
      network_id = hcloud_network.network[network.value].id
      ip         = lookup(each.value, "private_ip", null)
      alias_ips  = lookup(each.value, "alias_ips", [])
    }
  }

  depends_on = [
    hcloud_ssh_key.ssh_key,
    hcloud_network_subnet.subnet,
  ]

  lifecycle {
    ignore_changes = [
      ssh_keys,
      user_data,
    ]
  }
}

# Volumes

resource "hcloud_volume" "volume" {
  for_each = var.volumes

  name              = each.key
  size              = each.value.size
  server_id         = hcloud_server.server[each.value.server_key].id
  location          = lookup(each.value, "location", null)
  automount         = lookup(each.value, "automount", var.volume_automount)
  format            = lookup(each.value, "format", var.volume_format)
  delete_protection = lookup(each.value, "delete_protection", false)
  labels            = lookup(each.value, "labels", var.labels)
}

# Reverse DNS

resource "hcloud_rdns" "rdns" {
  for_each = {
    for k, v in var.servers : k => v
    if lookup(v, "rdns", var.rdns) != null
  }

  server_id  = hcloud_server.server[each.key].id
  ip_address = hcloud_server.server[each.key].ipv4_address
  dns_ptr    = lookup(each.value, "rdns", var.rdns)
}
