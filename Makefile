build-app:
	docker build --platform=linux/amd64 --tag php-ecs-app ./app

build-nginx:
	docker build --platform=linux/amd64 --tag php-ecs-nginx ./nginx

build: build-app build-nginx

dev:
	docker compose -f docker-compose.dev.yml up

down-dev:
	docker compose -f docker-compose.dev.yml down

run:
	docker compose -f docker-compose.yml up

down-run:
	docker compose -f docker-compose.yml down

push-app: build-app
	docker tag php-ecs-app:latest 572551389279.dkr.ecr.eu-west-3.amazonaws.com/php-ecs-app:latest
	docker push 572551389279.dkr.ecr.eu-west-3.amazonaws.com/php-ecs-app:latest

push-nginx: build-nginx
	docker tag php-ecs-nginx:latest 572551389279.dkr.ecr.eu-west-3.amazonaws.com/php-ecs-nginx:latest
	docker push 572551389279.dkr.ecr.eu-west-3.amazonaws.com/php-ecs-nginx:latest