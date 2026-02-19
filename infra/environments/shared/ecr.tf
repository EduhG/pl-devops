module "ecr" {
  source = "../../modules/ecr"

  repositories = {
    "php-ecs-app" = {
      image_tag_mutability = "MUTABLE"
    }

    "php-ecs-nginx" = {
      image_tag_mutability = "IMMUTABLE"
    }
  }
}
