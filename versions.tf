terraform {
  required_version = ">= 1.3"

  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = ">= 1.14"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.7"
    }
  }
}
