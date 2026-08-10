terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.29.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 7.29.0"
    }
    random = {
    source    = "hashicorp/random"
    version   = "~>3.6.3"
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
  
