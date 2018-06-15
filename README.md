# Etcd service module for terraform

## Key features

* Add/remove extra nodes without restart whole cluster

## Interfaces

### Input variables

* count - count of connections
* connections - public ips where applied
* private_ips - private ips
* hostnames - hostnames
* systemd_after - service file injection "After" (default: [])
* etcd_version - etcd version (default: v3.2.20)
* client_port - client port (default: 2379)
* peer_port - peer port (default: 2380)
* join_clients - join to existing cluster, client urls (default: "")
* join_peers - join to existing cluster, peer urls (default: "")

### Output variables

* public_ips - public ips of instances/servers
* private_ips
* hostnames
* systemd_after
* etcd_version
* client_port
* peer_port
* client_endpoints - client enpoints (http://<private_ip1>:<client_port>,http://<private_ip2>:<client_port>,...)
* peer_endpoints - peer enpoints (<private_hostname1>=http://<private_ip1>:<peer_port>,<private_hostname2>=http://<private_ip2>:<peer_port>,...)


## Example

```
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
  source = "git::https://github.com/suquant/tf_etcd.git?ref=v1.0.0"

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
  source = "git::https://github.com/suquant/tf_etcd.git?ref=v1.0.0"

  count         = "${var.extra_hosts}"
  connections   = "${module.provider_extra.public_ips}"

  hostnames     = "${module.provider_extra.hostnames}"
  private_ips   = "${module.provider_extra.private_ips}"

  join_clients  = "${module.etcd.client_endpoints}"
  join_peers    = "${module.etcd.peer_endpoints}"
}
```