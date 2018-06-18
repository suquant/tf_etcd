variable "token" {}
variable "hosts" {
  default = 4
}
variable "etcds" {
  default = 4
}

provider "hcloud" {
  token = "${var.token}"
}

module "provider" {
  source = "git::https://github.com/suquant/tf_hcloud.git?ref=v1.0.0"

  count = "${var.hosts}"
  token = "${var.token}"

  server_type = "cx21"
}

module "etcd" {
  source = ".."

  count       = "${var.etcds}"
  connections = "${module.provider.public_ips}"

  hostnames   = "${module.provider.hostnames}"
  private_ips = "${module.provider.private_ips}"
}
