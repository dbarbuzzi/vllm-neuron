variable "REPOSITORY" {
  default = "quay.io/vllm/automation-vllm"
}

variable "RELEASE_IMAGE" {
  default = false
}

# GITHUB_* variables are set as env vars in github actions
variable "GITHUB_SHA" {}
variable "GITHUB_REPOSITORY" {}
variable "GITHUB_RUN_ID" {}

variable "VLLM_VERSION" {}

variable "PYTHON_VERSION" {
  default = "3.12"
}

target "docker-metadata-action" {} // populated by gha docker/metadata-action

target "_common" {
  context = "."

  args = {
    BASE_UBI_IMAGE_TAG = "9.6-1760340943"
    PYTHON_VERSION = "3.12"
  }

  inherits = ["docker-metadata-action"]

  platforms = [
    "linux/amd64",
  ]
  labels = {
    "org.opencontainers.image.source" = "https://github.com/${GITHUB_REPOSITORY}"
    "vcs-ref" = "${GITHUB_SHA}"
    "vcs-type" = "git"
  }
}

group "default" {
  targets = [ "neuron" ]
}

target "neuron" {
  inherits = [ "_common" ]
  dockerfile = "Dockerfile.ubi"

  args = {
    PYTHON_VERSION = "${PYTHON_VERSION}"
  }

  tags = [
    "${REPOSITORY}:${replace(VLLM_VERSION, "+", "_")}", # vllm_version might contain local version specifiers (+) which are not valid tags
    "${REPOSITORY}:neuron-${GITHUB_SHA}",
    "${REPOSITORY}:neuron-${GITHUB_RUN_ID}",
    RELEASE_IMAGE ? "quay.io/vllm/vllm-neuron:${replace(VLLM_VERSION, "+", "_")}" : ""
  ]
}
