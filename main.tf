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

variable "after_unit" {
  type = "list"
  default = []
}

variable "etcd_version" {
  default = "v3.2.24"
}

variable "client_port" {
  default = "2379"
}

variable "peer_port" {
  default = "2380"
}


resource "null_resource" "etcd" {
  count = "${var.count}"

  triggers {
    count = "${var.count}"
  }

  connection {
    host  = "${element(var.connections, count.index)}"
    user  = "root"
    agent = true
  }

  provisioner "remote-exec" {
    inline = [
      "curl -L https://storage.googleapis.com/etcd/${var.etcd_version}/etcd-${var.etcd_version}-linux-amd64.tar.gz -o /tmp/etcd-${var.etcd_version}-linux-amd64.tar.gz",
      "tar xzvf /tmp/etcd-${var.etcd_version}-linux-amd64.tar.gz -C /usr/bin --strip-components=1 etcd-${var.etcd_version}-linux-amd64/etcd etcd-${var.etcd_version}-linux-amd64/etcdctl",
      "rm /tmp/etcd-${var.etcd_version}-linux-amd64.tar.gz"
    ]
  }

  provisioner "file" {
    content     = "${element(data.template_file.etcd_service.*.rendered, count.index)}"
    destination = "/etc/systemd/system/etcd3.service"
  }

  provisioner "remote-exec" {
    inline = [
      "systemctl is-enabled etcd3.service || systemctl enable etcd3.service",
      "systemctl daemon-reload",
      "systemctl restart etcd3.service"
    ]
  }

}

data "template_file" "etcd_service" {
  count    = "${var.count}"
  template = "${file("${path.module}/templates/etcd3.service")}"

  vars {
    hostname      = "${element(var.hostnames, count.index)}"
    listen_ip     = "${element(var.private_ips, count.index)}"
    client_port   = "${var.client_port}"
    peer_port     = "${var.peer_port}"
    peer_members  = "${join(",", formatlist("%s=http://%s:%s", var.hostnames, var.private_ips, var.peer_port))}"
    after_unit    = "${join(" ", var.after_unit)}"
  }
}


output "public_ips" {
  value = ["${var.connections}"]

  depends_on = ["null_resource.etcd"]
}

output "private_ips" {
  value = ["${var.private_ips}"]

  depends_on = ["null_resource.etcd"]
}

output "hostnames" {
  value = ["${var.hostnames}"]

  depends_on = ["null_resource.etcd"]
}

output "after_unit" {
  value = ["${var.after_unit}"]

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