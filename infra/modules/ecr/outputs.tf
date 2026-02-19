output "repository_urls" {
  value = {
    for repo_name, repo in aws_ecr_repository.repo :
    repo_name => repo.repository_url
  }
}
