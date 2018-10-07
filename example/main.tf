variable "token" {}
variable "hosts" {
  default = 3
}

provider "hcloud" {
  token = "${var.token}"
}

module "provider" {
  source = "git::https://github.com/suquant/tf_hcloud.git?ref=v1.1.0"

  count = "${var.hosts}"
}

module "etcd" {
  source = ".."

  count       = "${var.hosts}"
  connections = "${module.provider.public_ips}"

  hostnames   = "${module.provider.hostnames}"
  private_ips = "${module.provider.private_ips}"
}
