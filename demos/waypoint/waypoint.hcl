project = "deployer"

# Labels can be specified for organizational purposes.
labels = { "event" = "HashiTalks" }

pipeline "full-up" {
  step "my-build" {
    use "build" {}
  }

  step "my-deploy" {
    use "deploy" {}
  }

  step "my-release" {
    use "release" {
      prune        = true
      prune_retain = 4
    }
  }
}

app "web" {
  labels = {
    env = "dev"
  }

  config {
    env = {
      HELLO = "Hello from HashiTalks 2023!"
    }
  }

  build {
    use "docker" {
    }
    registry {
      #  use "docker" {
      #    image = "test-app"
      #    tag   = "latest"
      #    local = true
      #  }
      use "aws-ecr" {
        region     = var.region
        repository = "waypoint"
        tag        = "latest"
      }
    }
  }

  deploy {
    #use "docker" {
    #}
    #hook {
    #  when = "before"
    #  command = ["kind", "load", "docker-image", "waypoint.local/web:latest"]
    #}
    use "kubernetes" {
      probe_path   = "/"
      replicas     = 1
      service_port = var.port
    }
  }

  release {
    use "kubernetes" {
      #node_port     = 30000
      load_balancer = true
      port          = 80
    }
  }

  url {
    auto_hostname = true
  }
}

variable "region" {
  type = string
  #default = "eu-west-1"
  env = ["REGION"]
}

variable "port" {
  type    = number
  default = 3000
}
