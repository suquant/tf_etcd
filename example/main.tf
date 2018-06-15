variable "token" {}
variable "hosts" {
  default = 2
}
variable "extra_hosts" {
  default = 1
}

provider "hcloud" {
  token = "${var.token}"
}

module "provider" {
  source = "git::https://github.com/suquant/tf_hcloud.git?ref=v1.0.0"

  count = "${var.hosts}"
  token = "${var.token}"
}

module "etcd" {
  source = ".."

  count       = "${var.hosts}"
  connections = "${module.provider.public_ips}"

  hostnames   = "${module.provider.hostnames}"
  private_ips = "${module.provider.private_ips}"
}

module "provider_extra" {
  source = "git::https://github.com/suquant/tf_hcloud.git?ref=v1.0.0"

  count = "${var.extra_hosts}"
  token = "${var.token}"
  name  = "extra"

  # Reuse ssh keys
  ssh_keys  = []
  ssh_names = ["${module.provider.ssh_names}"]
}

module "etcd_extra" {
  source = ".."

  count         = "${var.extra_hosts}"
  connections   = "${module.provider_extra.public_ips}"

  hostnames     = "${module.provider_extra.hostnames}"
  private_ips   = "${module.provider_extra.private_ips}"

  join_clients  = "${module.etcd.client_endpoints}"
  join_peers    = "${module.etcd.peer_endpoints}"
}
