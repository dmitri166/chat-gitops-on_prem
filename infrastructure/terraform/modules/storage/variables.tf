
variable "envs" {
	description = "List of env namespaces to create"
	type        = list(string)
	default     = ["dev", "staging", "prod"]
}

variable "pvc_size" {
	description = "PVC size for chat logs"
	type        = string
	default     = "1Gi"
}

