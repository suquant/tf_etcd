resource "null_resource" "etcd" {
  count = "${var.count}"
  depends_on = ["null_resource.install"]

  connection {
    host  = "${element(var.connections, count.index)}"
    user  = "root"
    agent = true
  }

  # Unjoin
  provisioner "remote-exec" {
    when    = "destroy"
    inline  = [
      "etcdctl member remove `etcdctl member list | grep \"$(hostname -s)\" | cut -f1 -d':'` || true",
      "systemctl stop etcd.service || true",
      "mv /var/lib/etcd /var/lib/etcd.`date '+%Y%m%d%H%M%S'`"
    ]
  }

  # Join
  provisioner "remote-exec" {
    inline = <<EOF
${element(data.template_file.join.*.rendered, count.index)}
EOF
  }

  provisioner "file" {
    content     = "${element(data.template_file.etcd_service.*.rendered, count.index)}"
    destination = "/etc/systemd/system/etcd.service"
  }

  provisioner "remote-exec" {
    inline = [
      "systemctl is-enabled etcd.service || systemctl enable etcd.service",
      "systemctl daemon-reload",
      "systemctl restart etcd.service"
    ]
  }
}

data "template_file" "etcd_service" {
  count    = "${var.count}"
  template = "${file("${path.module}/templates/etcd.service")}"

  vars {
    hostname              = "${element(var.hostnames, count.index)}"
    intial_cluster        = "${join(",", concat(split(",", var.join_peers), formatlist("%s=http://%s:%s", var.hostnames, var.private_ips, var.peer_port)))}"
    listen_client_urls    = "http://${element(var.private_ips, count.index)}:${var.client_port}"
    advertise_client_urls = "http://${element(var.private_ips, count.index)}:${var.client_port}"
    listen_peer_urls      = "http://${element(var.private_ips, count.index)}:${var.peer_port}"
    after                 = "${join(" ", var.systemd_after)}"
    initial_cluster_state = "${var.join_peers == "" ? "new" : "existing"}"
  }
}

data "template_file" "join" {
  count    = "${var.count}"
  template = "${file("${path.module}/templates/join.sh")}"

  vars {
    join_clients  = "${var.join_clients}"
    hostname      = "${element(var.hostnames, count.index)}"
    urls          = "http://${element(var.private_ips, count.index)}:${var.peer_port}"
  }
}

data "null_data_source" "endpoints" {
  depends_on = ["null_resource.etcd"]

  inputs = {
    client = "${join(",", formatlist("http://%s:%s", var.private_ips, var.client_port))}"
    peer   = "${join(",", formatlist("%s=http://%s:%s", var.hostnames, var.private_ips, var.peer_port))}"
  }
}
