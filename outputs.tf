# Server outputs

output "server_ids" {
  description = "Map of server keys to their IDs"
  value       = { for k, v in hcloud_server.server : k => v.id }
}

output "server_ipv4_addresses" {
  description = "Map of server keys to their public IPv4 addresses"
  value       = { for k, v in hcloud_server.server : k => v.ipv4_address }
}

output "server_ipv6_addresses" {
  description = "Map of server keys to their public IPv6 addresses"
  value       = { for k, v in hcloud_server.server : k => v.ipv6_address }
}

output "server_status" {
  description = "Map of server keys to their status"
  value       = { for k, v in hcloud_server.server : k => v.status }
}

# SSH key outputs

output "ssh_key_ids" {
  description = "Map of SSH key names to their IDs"
  value       = { for k, v in hcloud_ssh_key.ssh_key : k => v.id }
}

# Network outputs

output "network_ids" {
  description = "Map of network names to their IDs"
  value       = { for k, v in hcloud_network.network : k => v.id }
}

output "subnet_ids" {
  description = "Map of subnet keys to their IDs"
  value       = { for k, v in hcloud_network_subnet.subnet : k => v.id }
}

# Firewall outputs

output "firewall_ids" {
  description = "Map of firewall names to their IDs"
  value       = { for k, v in hcloud_firewall.firewall : k => v.id }
}

# Volume outputs

output "volume_ids" {
  description = "Map of volume names to their IDs"
  value       = { for k, v in hcloud_volume.volume : k => v.id }
}

output "volume_linux_devices" {
  description = "Map of volume names to their Linux device paths"
  value       = { for k, v in hcloud_volume.volume : k => v.linux_device }
}

# Placement group outputs

output "placement_group_ids" {
  description = "Map of placement group names to their IDs"
  value       = { for k, v in hcloud_placement_group.placement_group : k => v.id }
}
