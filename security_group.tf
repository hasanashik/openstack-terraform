resource "openstack_networking_secgroup_v2" "allow_ssh_http" {
  name        = "allow_ssh_http"
  description = "Allow SSH and HTTP traffic."
}

resource "openstack_networking_secgroup_rule_v2" "allow_ssh" {
  security_group_id = openstack_networking_secgroup_v2.allow_ssh_http.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = var.administrator_ip
}

resource "openstack_networking_secgroup_rule_v2" "allow_http" {
  security_group_id = openstack_networking_secgroup_v2.allow_ssh_http.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = var.administrator_ip
}

# Ingress ICMP (allow ping to the VM)
resource "openstack_networking_secgroup_rule_v2" "allow_icmp_ingress" {
  security_group_id = openstack_networking_secgroup_v2.allow_ssh_http.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
}

# Egress ICMP (allow ping from the VM to outside)
resource "openstack_networking_secgroup_rule_v2" "allow_icmp_egress" {
  security_group_id = openstack_networking_secgroup_v2.allow_ssh_http.id
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
}
