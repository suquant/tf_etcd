resource "null_resource" "etcd" {
  count = "${var.count - 1}"
  depends_on = ["null_resource.install", "null_resource.primary"]

  connection {
    host  = "${element(var.connections, count.index + 1)}"
    user  = "root"
    agent = true
  }

  provisioner "file" {
    content     = "${element(data.template_file.etcd_service.*.rendered, count.index + 1)}"
    destination = "/etc/systemd/system/etcd.service"
  }

  provisioner "remote-exec" {
    inline = <<EOF
${element(data.template_file.join.*.rendered, count.index + 1)}
EOF
  }

  # Unjoin
  provisioner "remote-exec" {
    when    = "destroy"
    inline  = [
      "attemps=10",
      "echo \"try to remove member \\\"$(hostname -s)\\\" from cluster, index=${count.index + 1} host=${element(var.connections, count.index + 1)}...\"",
      "until [ $attemps -le 0 ] || etcdctl --endpoints \"${format("http://%s:%s", var.private_ips[0], var.client_port)}\" member list | grep \"$(hostname -s)\" | cut -f1 -d':' | xargs -n1 etcdctl --endpoints \"${format("http://%s:%s", var.private_ips[0], var.client_port)}\" member remove; do echo \"waiting till etcd member \\\"$(hostname -s)\\\" will be removed...\"; sleep 5; attemps=$((attemps-1)); done",
      "mv /var/lib/etcd /var/lib/etcd.$(date '+%Y%m%d%H%M%S')",
      "systemctl stop etcd.service"
    ]
    on_failure = "continue"
  }

}

data "template_file" "etcd_service" {
  count    = "${var.count}"
  template = "${file("${path.module}/templates/etcd.service")}"

  vars {
    hostname              = "${element(var.hostnames, count.index)}"
    listen_client_urls    = "http://${element(var.private_ips, count.index)}:${var.client_port}"
    advertise_client_urls = "http://${element(var.private_ips, count.index)}:${var.client_port}"
    listen_peer_urls      = "http://${element(var.private_ips, count.index)}:${var.peer_port}"
    after                 = "${join(" ", var.systemd_after)}"
  }
}

data "template_file" "join" {
  count    = "${var.count}"
  template = "${file("${path.module}/templates/join.sh")}"

  vars {
    primary_client_url  = "${format("http://%s:%s", var.private_ips[0], var.client_port)}"
    sequence_number     = "${count.index}"
    hostname            = "${element(var.hostnames, count.index)}"
    peer_url            = "${format("http://%s:%s", element(var.private_ips, count.index), var.peer_port)}"
  }
}