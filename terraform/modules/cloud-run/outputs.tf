output "service_url" {
    type = string
    value = google_cloud_run_service.main.url
}