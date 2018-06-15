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
  value = "${data.null_data_source.endpoints.outputs["client"]}"
}

output "peer_endpoints" {
  value = "${data.null_data_source.endpoints.outputs["peer"]}"
}