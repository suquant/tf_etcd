resource "null_resource" "primary" {
  depends_on = ["null_resource.install"]

  connection {
    host  = "${var.connections[0]}"
    user  = "root"
    agent = true
  }

  provisioner "file" {
    content     = "${data.template_file.primary_etcd_service.rendered}"
    destination = "/etc/systemd/system/etcd.service"
  }

  provisioner "remote-exec" {
    inline = [
      "systemctl is-enabled etcd.service || systemctl enable etcd.service",
      "systemctl daemon-reload",
      "systemctl start etcd.service"
    ]
  }
}

data "template_file" "primary_etcd_service" {
  template = "${file("${path.module}/templates/etcd.service")}"

  vars {
    hostname              = "${element(var.hostnames, count.index)}"
    intial_cluster        = "${format("%s=http://%s:%s", var.hostnames[0], var.private_ips[0], var.peer_port)}"
    listen_client_urls    = "http://${var.private_ips[0]}:${var.client_port}"
    advertise_client_urls = "http://${var.private_ips[0]}:${var.client_port}"
    listen_peer_urls      = "http://${var.private_ips[0]}:${var.peer_port}"
    after                 = "${join(" ", var.systemd_after)}"
    initial_cluster_state = "new"
  }
}