# PHP ECS Application

This repository contains a minimal PHP application served via Nginx, designed to run in AWS ECS Fargate with an Application Load Balancer (ALB) and HTTPS support. The infrastructure is provisioned via Terraform modules and supports **dev** and **prod** environments.

---

## Features

- PHP-FPM application with `/health` and `/api` endpoints
- Nginx reverse proxy
- Rate-limiting and structured logging
- Dockerized for local development and production
- AWS ECS Fargate deployment
- ALB with HTTP → HTTPS redirect
- ACM TLS certificate for HTTPS
- CloudWatch logging
- Terraform modules for ECR, ECS, ALB, ACM
- Environment separation: `dev` and `prod`

---

## Directory Structure

```bash
.
├── app/
│   ├── Dockerfile
│   ├── composer.json
│   ├── composer.lock
│   ├── Dockerfile
│   ├── public/
│   │   └── index.php
│   └── src/
├── nginx/
│   ├── Dockerfile
│   └── nginx.conf
│   └── nginx.dev.conf
├── infra-bootstrap/
│   ├── main.tf
│   ├── providers.tf
│   ├── variables.tf
│   ├── outputs.tf
├── infra/
│   ├── modules/
│   │   ├── alb/
│   │   ├── ecs/
│   │   ├── ecr/
│   │   └── acm/
│   ├── environments/
│   │   ├── shared/
│   │   │   └── main.tf
│   │   │   └── providers.tf
│   │   │   └── variables.tf
│   │   │   └── outputs.tf
│   │   ├── dev/
│   │   │   └── main.tf
│   │   │   └── providers.tf
│   │   │   └── variables.tf
│   │   │   └── outputs.tf
│   │   └── prod/
│   │       └── main.tf
│   │   │   └── providers.tf
│   │   │   └── variables.tf
│   │   │   └── outputs.tf
├── .github/
│   └── workflows/
│       └── deploy.yml
├── docker-compose.yml
├── docker-compose.dev.yml
└── README.md
└── Makefile
```

## Makefile Commands

The Makefile provides shortcuts for building, running, and pushing Docker images.

| Command            | Description                                                           |
| ------------------ | --------------------------------------------------------------------- |
| `make build`       | Build both PHP app and Nginx Docker images locally                    |
| `make build-app`   | Build only the PHP app Docker image                                   |
| `make build-nginx` | Build only the Nginx Docker image                                     |
| `make dev`         | Run the application stack locally using `docker-compose.dev.yml`      |
| `make down-dev`    | Stop the local dev stack                                              |
| `make run`         | Run the full stack using `docker-compose.yml` (production simulation) |
| `make down-run`    | Stop the production simulation stack                                  |
| `make push`        | Push the built images to AWS ECR                                      |

## Example usage:

```bash
# Build images locally
make build

# Run dev stack
make dev

# Stop dev stack
make down-dev

# Push images to ECR
make push
```

## Local Development

Requirements:

- Docker
- Docker Compose
- Make (optional, for shortcuts)

### 1. Build Docker images

```bash
make build
```

This will build:

- `php-ecs-app` for the PHP application

- `php-ecs-nginx` for Nginx reverse proxy

### 2. Running locally

To run the application locally use the following commands

```bash
make dev
```

This uses docker-compose.dev.yml to start the application stack.

```bash
App: http://localhost:8080/api
Health: http://localhost:8080/health
```

To stop:

```bash
make down-dev
```

## Deploy to AWS via Terraform

Requirements:

- Terraform >= 1.5
- AWS CLI configured with sufficient permissions

### 1. Initialize Terraform

To run terraform, first create the bootstrap resources

- `dynamodb` for locking tf runs
- `s3 bucket` for remote state

```bash
cd infra-bootstrap

terraform init
terraform apply
```

The backend configuration is already set up for S3 to store Terraform state.

### 2. Create shared resources

Next create the shared resources. You will need, `s3_bucket_name` and `dynamodb_table_name` from the bootstrap step.

Update your `infra/environments/shared/providers.tf` file and change `dynamodb_table` and `bucket` as neccessary.

```bash
cd infra/environments/shared

terraform init
terraform apply
```

This provisions:

- ECR repositories for PHP and Nginx
- ALB with HTTPS listener and HTTP → HTTPS redirect
- ACM certificate
- ALB Security group

#### Outputs

After apply, Terraform will output:

- `alb_name`: Name of the ALB that was created
- `alb_security_group_id`: Security group Id that was created
- `repository_urls`: URLs to push Docker images

### 3. Setup ECS envrironment

Once all the required rrsources have been created, lets now setup our ECS environment.

Navigate to `infra/environments/dev` and update `providers.tf` as before. Next create a terraform.tfvars file and update it with the contents you copied from the setup phase. Here is how it should look like.

```bash
zone_name         = "ROUTE53_ZONE_NAME"
domain_name       = "YOUR_APP_DOMAIN"
nginx_image_url   = "NGINX_IMAGE_URL"
php_app_image_url = "PHP_IMAGE_URL"
alb_name          ="<alb_name>"
api_key           = "somethingverysecretandsecure"
```

You can get `zone_name` from one of your configured Route53 hosting zones. For simlicity, `domain_name` is a subdomain that will be created in your hosted zone.

Now you are ready to apply the changes.

```bash
cd infra/environments/dev
terraform init
terraform apply
```

This provisions:

- ECS cluster and Fargate tasks
- ALB Listener rule with target group
- Security groups and IAM roles

#### Outputs

After apply, your application will be ready. You can access it from the generated `public_url`

-`public_url`: Public endpoint of the application

### Deploying Multiple Environments

Terraform environment folders:

```bash
infra/environments/
├── dev/
└── prod/
```

Each environment has its own `main.tf` and variables

You can deploy prod after testing dev:

```bash
cd infra/environments/prod
terraform init
terraform apply
```

Same ECR repositories, ALB, and ACM can be shared or duplicated per environment depending on design.

### GitHub Actions CI/CD

The workflow file is at `.github/workflows/deploy.yml`.

This workflow, automatically builds and pushes Docker images to ECR on main or develop branches and triggers ECS deployment using

```bash
aws ecs update-service --cluster <cluster-name> --service <service-name> --force-new-deployment
```

> Make sure AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY are set as GitHub secrets.

## Testing the Application

Once your stack is running, you can test the endpoints using `curl`.

### 1. Health Endpoint

The `/health` endpoint is used for health checks and also supports API key authentication.

```bash
# Replace <public_url> with the url we got from running terraform
curl https://<public_url>/health
```

Example Response:

```json
{
  "status": "OK",
  "timestamp": 1700000000
}
```

### 1. API Endpoint

The `/api` endpoint is used for testing purposes and also supports API key authentication. It is also rate limited.

```bash
# Replace <public_url> with the url we got from running terraform
# Replace <API_KEY> with your API key provided when running the php app
curl -H "x-api-key: <API_KEY>" https://<public_url>/health
```

Example Response:

```json
{
  "message": "Welcome to the API",
  "data": {
    "id": 1,
    "name": "Sample Data"
  }
}
```
