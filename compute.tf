
# Create a network
resource "openstack_networking_network_v2" "zaman_net_2" {
  name           = "zaman-net-2"
  admin_state_up = true
}

# Create a subnet
resource "openstack_networking_subnet_v2" "zaman_net_2_subnet_1" {
  name        = "zaman-net-2-subnet-1"
  network_id  = openstack_networking_network_v2.zaman_net_2.id
  cidr        = "172.16.170.0/24"
  ip_version  = 4
  enable_dhcp = true
}

# Create a router with external gateway
resource "openstack_networking_router_v2" "zaman_router" {
  name                = "zaman-router"
  admin_state_up      = true
  external_network_id = "78ac56f0-08f1-4257-9f7c-16d3d5369084"
}

# Attach subnet to the router
resource "openstack_networking_router_interface_v2" "zaman_router_interface" {
  router_id = openstack_networking_router_v2.zaman_router.id
  subnet_id = openstack_networking_subnet_v2.zaman_net_2_subnet_1.id
}



# ------------------------------
# Allocate a floating IP from external network
# ------------------------------
resource "openstack_networking_floatingip_v2" "web_fip" {
  pool = "kkr-stg01-fip-net-01"
}

# ------------------------------
# VM
# ------------------------------
resource "openstack_compute_instance_v2" "web-server" {
  name            = var.web_server_name
  image_id        = var.web_server_image_id
  flavor_id       = var.web_server_flavor_id
  key_pair        = var.user_key_name
  security_groups = ["${openstack_networking_secgroup_v2.allow_ssh_http.name}"]

  network {
    uuid = openstack_networking_network_v2.zaman_net_2.id
  }
}

# ------------------------------
# Lookup the VM's port
# ------------------------------
data "openstack_networking_port_v2" "web_server_port" {
  device_id  = openstack_compute_instance_v2.web-server.id
  depends_on = [openstack_compute_instance_v2.web-server]
}

# ------------------------------
# Associate floating IP to VM port
# ------------------------------
resource "openstack_networking_floatingip_associate_v2" "web_fip_assoc" {
  floating_ip = openstack_networking_floatingip_v2.web_fip.address
  port_id     = data.openstack_networking_port_v2.web_server_port.id

  depends_on = [
    data.openstack_networking_port_v2.web_server_port
  ]
}

# ------------------------------
# Ansible Provisioner
# ------------------------------
resource "null_resource" "ansible_provision" {
  depends_on = [openstack_networking_floatingip_associate_v2.web_fip_assoc]

  provisioner "local-exec" {
    command = "sleep 45 && ansible-playbook -u ubuntu -i '${openstack_networking_floatingip_v2.web_fip.address},' -e 'ansible_python_interpreter=/usr/bin/python3' --private-key=/home/nokialab/terraform/terraform_testing.pem apache.yml"
  }
}
