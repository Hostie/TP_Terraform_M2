terraform {
required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.51.1"
    }
  }
}

provider "openstack" {
  user_name   = "admin"
  tenant_name = "admin"
  password    = "xMvLAtOwFyGnwVoT3V96mRZsxaMyxNE8HVQ4G8CJ"
  auth_url    = "http://9.11.93.4:5000"
}

variable "network_name" {
  type        = string
  description = "TP_Network"
  default     = "my-network"
}

variable "instances" {
  description = "List of EC2 instances configurations"
  type        = map(object({
    instance_image = string
  }))
}

variable "security_group_name" {
  type        = string
  description = "Nom du groupe de sécurité"
  default     = "sc-tp"
}

variable "subnet_cidr" {
  type        = string
  description = "CIDR du sous-réseau"
  default     = "10.0.0.0/24"
}

variable "key_pair_name" {
  type        = string
  description = "la key pair"
  default     = "key-tp"
}
variable "floating_ip_pool" {
  type        = string
  description = "Nom du pool d'IP flottantes"
  default     = "public1"
}
resource "openstack_networking_network_v2" "network" {
  name = var.network_name
}

resource "openstack_networking_subnet_v2" "subnet" {
  name       = "${var.network_name}-subnet"
  network_id = openstack_networking_network_v2.network.id
  cidr       = var.subnet_cidr
}

resource "openstack_networking_floatingip_v2" "floating_ip" {
  pool = var.floating_ip_pool
}

resource "openstack_networking_secgroup_v2" "security_group" {
  name        = var.security_group_name
  description = "Sécu TP"
}

resource "openstack_networking_secgroup_rule_v2" "security_group_rule_ssh" {
  security_group_id = openstack_networking_secgroup_v2.security_group.id
  direction         = "ingress"
  protocol          = "tcp"
  ethertype         = "IPv4"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "openstack_networking_secgroup_rule_v2" "security_group_rule_http" {
  security_group_id = openstack_networking_secgroup_v2.security_group.id
  direction         = "ingress"
  protocol          = "tcp"
  ethertype         = "IPv4"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "openstack_compute_flavor_v2" "flavor" {
  name     = "template-tp"
  ram      = 2048
  vcpus    = 1
  disk     = 20
}

resource "openstack_networking_router_v2" "router" {
  name = "router-tp"
  admin_state_up = true
  external_network_id = "9cd4fa81-8616-4a2d-af0f-a910890b7e52"
}

resource "openstack_networking_router_interface_v2" "router_interface" {
  router_id   = openstack_networking_router_v2.router.id
  subnet_id   = openstack_networking_subnet_v2.subnet.id
}

resource "openstack_images_image_v2" "ubuntu" {
  name             = "UbuntuOS"
  container_format = "bare"
  image_source_url = "https://cloud-images.ubuntu.com/jammy/20230602/jammy-server-cloudimg-amd64.img"
  disk_format      = "qcow2"
  min_disk_gb      = 3
  min_ram_mb       = 1024
}

resource "openstack_compute_keypair_v2" "keypair" {
  name = var.key_pair_name
}

resource "openstack_compute_instance_v2" "instances" {
  for_each        = var.instances
  name            = each.key
  image_name      = openstack_images_image_v2.ubuntu.name
  flavor_id       = openstack_compute_flavor_v2.flavor.id
  key_pair        = openstack_compute_keypair_v2.keypair.name
  security_groups = [openstack_networking_secgroup_v2.security_group.name]

  network {
    name = openstack_networking_network_v2.network.name
  }
}

#resource "openstack_compute_floatingip_associate_v2" "floating_ip" {
#  floating_ip = openstack_networking_floatingip_v2.floating_ip.address
#  instance_id = openstack_compute_instance_v2.instances.id
#}

