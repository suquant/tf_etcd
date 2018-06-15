resource "null_resource" "install" {
  count = "${var.count}"

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
}