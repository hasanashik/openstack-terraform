variable "openstack_auth_url" {
  type    = string
  default = "OPENSTACK_LOGIN_ENDPOINT"
}

variable "openstack_project" {
  type    = string
  default = "zaman-project"
}

variable "openstack_user" {
  type    = string
  default = "zaman"
}

variable "openstack_user_password" {
  type    = string
  default = "PASSWORD"
}

variable "openstack_region" {
  type    = string
  default = "RegionOne"
}


// compute instance
variable "web_server_name" {
  type    = string
  default = "web-server"
}
variable "web_server_image_id" {
  type    = string
  default = "3f17af1e-2679-4a72-8ec9-623e9d725f8a"
}
variable "web_server_flavor_id" {
  type    = string
  default = "3543fe8c-b2fb-45ad-9f41-8917fbea55b5"
}
variable "user_key_name" {
  type    = string
  default = "terraform_testing"
}

// security group
variable "administrator_ip" {
  type    = string
  default = "0.0.0.0/0"
}
