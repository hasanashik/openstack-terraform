terraform {
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
    }
  }
}

provider "openstack" {
  auth_url    = var.openstack_auth_url
  insecure    = true
  password    = var.openstack_user_password
  region      = var.openstack_region
  tenant_name = var.openstack_project // project name
  user_name   = var.openstack_user

}


