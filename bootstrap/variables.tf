variable "project" {
  type = string
}

variable "location" {
  type    = string
  default = "westeurope"
}

variable "repo_owner" {
  type        = string
  description = "GitHub org/user that owns the repo"
}

variable "repo_name" {
  type        = string
  description = "GitHub repository name"
}

variable "repo_branch" {
  type    = string
  default = "main"
}

# Override if you want custom names; otherwise generated.
variable "tf_state_rg_name" {
  type    = string
  default = null
}

variable "tf_state_sa_name" {
  type    = string
  default = null
}

variable "tf_state_container" {
  type    = string
  default = "tfstate"
}

variable "tf_state_key" {
  type    = string
  default = "sandpit.terraform.tfstate"
}

# Grant "User Access Administrator" in addition to "Contributor"
variable "grant_user_access_admin" {
  type    = bool
  default = true
}
