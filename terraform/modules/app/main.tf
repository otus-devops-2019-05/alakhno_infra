resource "google_compute_instance" "app" {
  name         = "reddit-app-${var.env}"
  machine_type = "g1-small"
  zone         = "${var.zone}"
  tags         = ["reddit-app-${var.env}"]

  boot_disk {
    initialize_params {
      image = "${var.app_disk_image}"
    }
  }

  network_interface {
    network = "default"

    access_config {
      nat_ip = "${google_compute_address.app_ip.address}"
    }
  }

  metadata {
    ssh-keys = "appuser:${file(var.public_key_path)}"
  }

  connection {
    type  = "ssh"
    user  = "appuser"
    agent = false

    private_key = "${file(var.private_key_path)}"
  }

  provisioner "file" {
    source      = "${path.module}/files/puma.service"
    destination = "/tmp/puma.service"
  }

  provisioner "file" {
    source      = "${path.module}/files/deploy.sh"
    destination = "/tmp/deploy.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "echo Environment='DATABASE_URL=${var.database_url}' >> /tmp/puma.service",
      "${var.app_deploy ? "sh /tmp/deploy.sh" : "echo 'App deploy disabled'"}",
    ]
  }
}

resource "google_compute_address" "app_ip" {
  name = "reddit-app-ip-${var.env}"
}

resource "google_compute_firewall" "firewall_puma" {
  name    = "allow-puma-${var.env}"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["9292"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["reddit-app-${var.env}"]
}
