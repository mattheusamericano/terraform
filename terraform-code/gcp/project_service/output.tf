output "enabled_apis" {
    description         = "Lista das APIs que foram habilitadas neste projeto"
    value               = [for s in google_project_service.project : s.service]
}