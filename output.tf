output "private_ips" {
  value = ["${var.private_ips}"]

  depends_on = ["null_resource.etcd"]
}

output "hostnames" {
  value = ["${var.hostnames}"]

  depends_on = ["null_resource.etcd"]
}

output "systemd_after" {
  value = ["${var.systemd_after}"]

  depends_on = ["null_resource.etcd"]
}

output "etcd_version" {
  value = "${var.etcd_version}"

  depends_on = ["null_resource.etcd"]
}

output "client_endpoints" {
  value = "${join(",", formatlist("http://%s:%s", var.private_ips, var.client_port))}"

  depends_on = ["null_resource.etcd"]
}

output "peer_endpoints" {
  value = "${join(",", formatlist("%s=http://%s:%s", var.hostnames, var.private_ips, var.peer_port))}"

  depends_on = ["null_resource.etcd"]
}