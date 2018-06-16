variable "count" {}

variable "connections" {
  type = "list"
}

variable "private_ips" {
  type = "list"
}

variable "hostnames" {
  type = "list"
}

variable "systemd_after" {
  type = "list"
  default = []
}

variable "etcd_version" {
  default = "v3.2.20"
}

variable "client_port" {
  default = "2379"
}

variable "peer_port" {
  default = "2380"
}