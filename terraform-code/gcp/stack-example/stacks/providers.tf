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
    random = {
    source    = "hashicorp/random"
    version   = "~>3.6.3"
    }
   }
  }

provider "google" {
  project = "terraform" 
  #"prj-__project__-environment__-cef"
  region  = "__region__"
}

provider "google-beta" {
  project = "terraform" 
  #"prj-__project__-environment__-cef"
  region  = "__region__"
  #zone = var.zone
}
  
