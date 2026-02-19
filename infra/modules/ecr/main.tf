resource "aws_ecr_repository" "repo" {
  for_each = var.repositories

  name                 = each.key
  image_tag_mutability = each.value.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = each.value.scan_on_push
  }
}

resource "aws_ecr_lifecycle_policy" "policy" {
  for_each = aws_ecr_repository.repo

  repository = each.value.name
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep a maximum of 15 tagged images"
        action = {
          type = "expire"
        }
        selection = {
          tagStatus      = "tagged"
          tagPatternList = [".*"]
          countType      = "imageCountMoreThan"
          countNumber    = 15
        }
      },
      {
        rulePriority = 2
        description  = "Remove all untagged images"
        action = {
          type = "expire"
        }
        selection = {
          tagStatus   = "untagged"
          countType   = "imageCountMoreThan"
          countNumber = 1
        }
      }
    ]
  })
}
