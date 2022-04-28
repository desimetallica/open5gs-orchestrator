# Define required providers
terraform {
required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.47.0"
    }
  }
}

variable "instance_num" {
    description = "The Number of instances to be created."
    default  = 2
}

# Configure the OpenStack Provider
provider "openstack" {
  user_name   = "admin"
  tenant_name = "admin"
  password    = "rai5g"
  auth_url    = "http://10.54.131.159:5000/v3"
  region      = "RegionOne"
}

# Create a couple of istances
resource "openstack_compute_instance_v2" "test-server" {
  count = var.instance_num
  name = "${format("open5gs-server-%02d", count.index + 1)}" 
  image_id = "f72a5c48-d07b-4238-9a41-540c4845e29f"
  flavor_id = "a04ee621-6924-4f34-9810-189014b7ae1d"
  key_pair = "desi-HP-Z6-G4-Workstation"
  security_groups = ["default"]
  availability_zone = "dl580"
  network {
    name =  "${openstack_networking_network_v2.network_1.name}" 
    port = element(openstack_networking_port_v2.port.*.id, count.index + 1)
  }
}

# configure floating ips
resource "openstack_networking_floatingip_v2" "myip" {
  count = var.instance_num
  pool = "rainet"
}

resource "openstack_compute_floatingip_associate_v2" "myip" {
  count = var.instance_num
  floating_ip = element(openstack_networking_floatingip_v2.myip.*.address, count.index)
  instance_id = element(openstack_compute_instance_v2.test-server.*.id, count.index)
  fixed_ip = element(openstack_compute_instance_v2.test-server.*.network.0.fixed_ip_v4, count.index)

}

# configure network 
resource "openstack_networking_network_v2" "network_1" {
  name           = "open5gs-network"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "subnet_1" {
  name       = "open5gs-subnet"
  network_id = "${openstack_networking_network_v2.network_1.id}"
  cidr       = "192.168.199.0/24"
  ip_version = 4
}

resource "openstack_networking_port_v2" "port" {
  count = var.instance_num
  name = "${format("port-%02d", count.index + 10)}"
  network_id         = "${openstack_networking_network_v2.network_1.id}"
  admin_state_up     = "true"

  fixed_ip {
    subnet_id  = "${openstack_networking_subnet_v2.subnet_1.id}"
    ip_address = "${format("192.168.199.%02d", count.index + 10)}"
  }
}

# configure router
resource "openstack_networking_router_interface_v2" "router_interface_1" {
  router_id = "2a2c48c2-a60d-4c3a-9e11-5d2272bb9a8a"
  subnet_id = "${openstack_networking_subnet_v2.subnet_1.id}"
}

# generate inventory file for Ansible
resource "local_file" "hosts_cfg" {
  content = templatefile("${path.module}/templates/hosts.tpl",
    {
      open5gs = openstack_compute_floatingip_associate_v2.myip.0.floating_ip
      euransim = openstack_compute_floatingip_associate_v2.myip.1.floating_ip
    }
  )
  filename = "../ansible/inventory"
}
