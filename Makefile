build-app:
# 	docker compose up app-dev --build
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