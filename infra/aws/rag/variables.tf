variable "region" { type = string }
variable "account_id" { type = string }
variable "name" {
  type    = string
  default = "mini-ai-energy-docs"
}
variable "gateway_role_name" {
  type        = string
  default     = "mini-ai-litellm-bedrock"
  description = "Existing web-identity role used by the LiteLLM gateway (Lab 3)"
}
