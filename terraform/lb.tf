resource "google_compute_instance_group" "app-group" {
  name        = "reddit-app-group"
  description = "Reddit App instance group"

  zone = "${var.zone}"

  named_port {
    name = "http"
    port = "9292"
  }

  instances = [
    "${google_compute_instance.app.self_link}",
  ]
}

resource "google_compute_health_check" "app-health-check" {
  name        = "reddit-app-health-check"
  description = "Reddit App health check"

  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2

  http_health_check {
    port = 9292
  }
}

resource "google_compute_backend_service" "app-backend-service" {
  name        = "reddit-app-backend-service"
  description = "Reddit App backend service"

  port_name = "http"
  protocol  = "HTTP"

  backend {
    group = "${google_compute_instance_group.app-group.self_link}"
  }

  health_checks = [
    "${google_compute_health_check.app-health-check.self_link}",
  ]
}

resource "google_compute_url_map" "app-url-map" {
  name        = "reddit-app-url-map"
  description = "Reddit App url map"

  default_service = "${google_compute_backend_service.app-backend-service.self_link}"
}

resource "google_compute_target_http_proxy" "app-target-proxy" {
  name        = "reddit-app-target-proxy"
  description = "Reddit App target proxy"

  url_map = "${google_compute_url_map.app-url-map.self_link}"
}

resource "google_compute_global_forwarding_rule" "app-global-forwarding-rule" {
  name        = "reddit-app-global-forwarding-rule"
  description = "Reddit App global forwarding rule"

  target     = "${google_compute_target_http_proxy.app-target-proxy.self_link}"
  port_range = "80"
}
