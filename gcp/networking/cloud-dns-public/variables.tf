# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# These variables are expected to be passed in by the operator.
# ---------------------------------------------------------------------------------------------------------------------

variable "project" {
  description = "The project ID where all resources will be launched."
  type        = string
}

variable "domain" {
  description = "Zone domain, must end with a period."
  type        = string
}

variable "name" {
  description = "Zone name, must be unique within the project."
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "recordsets" {
  description = "List of DNS record objects to manage, in the standard terraform dns structure."
  type        = list(object({
                  name = string
                  type = string
                  ttl  = number
                  records = list(string)
                }))
  default     = []

#  default = [
#    {
#      name    = "localhost"
#      type    = "A"
#      ttl     = 300
#      records = [
#        "127.0.0.1",
#      ]
#    },
#  ]
}

variable "labels" {
  description = "A set of key/value label pairs to assign to this ManagedZone"
  type        = map
  default     = {}
}

variable "description" {
  description = "zone description (shown in console)"
  type        = string
  default     = "Public DNS managed by Terraform"
}

# ---------------------------------------------------------------------------------------------------------------------
# TERRAGRUNT PARAMETERS
# These variables are supplied by Terragrunt.
# ---------------------------------------------------------------------------------------------------------------------

