resource "null_resource" "primary" {
  depends_on = ["null_resource.install"]

  connection {
    host  = "${var.connections[0]}"
    user  = "root"
    agent = true
  }

  provisioner "file" {
    content     = "${data.template_file.etcd_service.0.rendered}"
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