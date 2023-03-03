provider "kubernetes" {
  config_path = var.kubernetes_config_path
}

# Namespace for renovate and related resources (volume claims, secrets)
resource "kubernetes_namespace" "renovate" {
  metadata {
    name = "renovate"
  }
}

# Credentials for the GitHub 
resource "kubernetes_secret" "container_registry_credentials" {
  metadata {
    name = "container-registry-credentials"
    namespace = "renovate"
  }

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "${var.container_registry_url}" = {
          auth = "${base64encode("${var.container_registry_username}:${var.container_registry_password}")}"
        }
      }
    })
  }

  type = "kubernetes.io/dockerconfigjson"
}

resource "kubernetes_secret" "renovate-env" {
  metadata {
    name = "renovate-env"
    namespace = "renovate"
  }
  data = {
    NPM_REGISTRY_NPMJS_ORG_TOKEN = var.npm_registry_npmjs_org_token
    RENOVATE_TOKEN = var.renovate_github_token
    GITHUB_COM_TOKEN = var.renovate_github_token
    RENOVATE_GIT_PRIVATE_KEY = var.renovate_private_key
  }
  type = "Opaque"
}

resource "kubernetes_config_map" "renovate-config" {
  metadata {
    name = "renovate-config"
    namespace = "renovate"
  }
  data = {
    "config.json" = "${file("${path.module}/assets/renovate_config.json")}"
  }
}

resource "kubernetes_cron_job_v1" "renovate" {
  metadata {
    name      = "renovate"
    namespace = "renovate"
  }
  timeouts {
      delete = "10m"
  } 

  spec {
    concurrency_policy = "Forbid"
    schedule = "@hourly"
    starting_deadline_seconds = 10
    failed_jobs_history_limit = 2
    successful_jobs_history_limit = 2     
    job_template {
      metadata {}
      spec {
        backoff_limit              = 2
        ttl_seconds_after_finished = 10
        template {
          metadata {}
          spec {
            restart_policy = "Never"
            container {
              image = "renovate/renovate:34.150.0"
              name  = "renovate"
              resources {
                limits = {
                  cpu    = "2"
                  memory = "4096Mi"
                }
                requests = {
                  cpu = "250m"
                  memory = "2048Mi"
                }
              }
              env_from {
                secret_ref {
                  name = "renovate-env"
                }
              }
              env {
                name = "LOG_LEVEL"
                value = "debug"
              }
              env {
                name = "RENOVATE_GIT_AUTHOR"
                value = var.renovate_git_author
              }
              env {
                name = "RENOVATE_AUTODISCOVER"
                value = var.renovate_autodiscover
              }
              env {
                name = "RENOVATE_PLATFORM"
                value = "github"
              }
              volume_mount {
                name = "work-volume"
                mount_path = "/tmp/renovate/"
              }
              volume_mount {
                name = "config-volume"
                mount_path = "/opt/renovate/"
              }
            }
            volume {
              name = "work-volume"
              empty_dir {}
            }
            volume {
              name = "config-volume"
              config_map {
                name = "renovate-config"
              }
            }
            node_selector = {
              "kubernetes.io/os" = "linux"
              "kubernetes.azure.com/mode" = "user"
            }
            image_pull_secrets {
              name = kubernetes_secret.container_registry_credentials.metadata.0.name
            }
          }
        }
      }
    }
  }
}
