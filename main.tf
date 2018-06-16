resource "null_resource" "etcd" {
  count = "${var.count - 1}"
  depends_on = ["null_resource.install", "null_resource.primary"]

  connection {
    host  = "${element(var.connections, count.index + 1)}"
    user  = "root"
    agent = true
  }

  # Unjoin
  provisioner "remote-exec" {
    when    = "destroy"
    inline  = [
      "etcdctl member remove `etcdctl member list | grep \"$(hostname -s)\" | cut -f1 -d':'`",
      "systemctl stop etcd.service",
      "mv /var/lib/etcd /var/lib/etcd.`date '+%Y%m%d%H%M%S'`"
    ]
    on_failure = "continue"
  }

  # Join
  provisioner "remote-exec" {
    inline = [
      "etcdctl -C \"${format("http://%s:%s", var.private_ips[0], var.client_port)}\" member add \"${element(var.hostnames, count.index + 1)}\" \"${format("http://%s:%s", element(var.private_ips, count.index + 1), var.peer_port)}\""
    ]
  }

  provisioner "file" {
    content     = "${element(data.template_file.etcd_service.*.rendered, count.index + 1)}"
    destination = "/etc/systemd/system/etcd.service"
  }

  provisioner "remote-exec" {
    inline = [
      "systemctl is-enabled etcd.service || systemctl enable etcd.service",
      "systemctl daemon-reload",
      "systemctl start etcd.service"
    ]
    on_failure = "continue"
  }
}

data "template_file" "etcd_service" {
  count    = "${var.count}"
  template = "${file("${path.module}/templates/etcd.service")}"

  vars {
    hostname              = "${element(var.hostnames, count.index)}"
    intial_cluster        = "${join(",", formatlist("%s=http://%s:%s", slice(var.hostnames, 0, count.index + 1), slice(var.private_ips, 0, count.index + 1), var.peer_port))}"
    listen_client_urls    = "http://${element(var.private_ips, count.index)}:${var.client_port}"
    advertise_client_urls = "http://${element(var.private_ips, count.index)}:${var.client_port}"
    listen_peer_urls      = "http://${element(var.private_ips, count.index)}:${var.peer_port}"
    after                 = "${join(" ", var.systemd_after)}"
    initial_cluster_state = "existing"
  }
}