terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 7.5.0"
    }
  }
}

provider "google" {
  project = "__project_id__"
  region  = "__region__"
}

provider "google-beta" {
  project = "__project_id__"
  region  = "__region__"
}
