variable "project_name" {
  type        = string
  description = "Short project slug used to prefix resource names."
}

variable "environment" {
  type        = string
  description = "Deployment environment (e.g. stg, prd, global)."

  validation {
    condition     = contains(["global", "stg", "prd"], var.environment)
    error_message = "environment must be one of: global, stg, prd."
  }
}

variable "tags" {
  type        = map(string)
  description = "Extra tags merged onto every resource in this module."
  default     = {}
}
