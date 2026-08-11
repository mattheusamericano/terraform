terraform {
  backend "gcs" {
    bucket = "__state-bucket__"
    prefix = "__backend-prefix__"
  }
}
