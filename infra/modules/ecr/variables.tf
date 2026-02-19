variable "repositories" {
  description = "Map of ECR repositories and their configuration"
  type = map(object({
    image_tag_mutability = string
    scan_on_push         = optional(bool, true)
  }))
}
