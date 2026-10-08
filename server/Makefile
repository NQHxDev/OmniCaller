.PHONY: help build up down logs restart clean dev prod test migrate

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## Build Docker images
	docker-compose build

up: ## Start all services
	docker-compose up -d

down: ## Stop all services
	docker-compose down

logs: ## Show logs from all services
	docker-compose logs -f

logs-server: ## Show logs from server only
	docker-compose logs -f server

logs-cloudflared: ## Show logs from cloudflared only
	docker-compose logs -f cloudflared

restart: ## Restart all services
	docker-compose restart

restart-server: ## Restart server only
	docker-compose restart server

clean: ## Stop and remove all containers, volumes, and images
	docker-compose down -v --rmi all

dev: ## Start services in development mode
	docker-compose up

prod: build up ## Build and start in production mode

ps: ## Show running containers
	docker-compose ps

shell-server: ## Open shell in server container
	docker exec -it omni-caller-server /bin/bash

shell-postgres: ## Open PostgreSQL shell
	docker exec -it omni-caller-postgres psql -U postgres -d omnicaller

migrate: ## Run database migrations (if applicable)
	docker exec -it omni-caller-server /app/omnicaller_server migrate

health: ## Check health of all services
	@echo "Checking service health..."
	@docker ps --filter "name=omni-caller" --format "table {{.Names}}\t{{.Status}}"

tunnel-info: ## Show Cloudflare tunnel information
	docker exec omni-caller-cloudflared cloudflared tunnel info || echo "Tunnel info not available with token-based auth"

rebuild-server: ## Rebuild and restart server only
	docker-compose up -d --build server

env-setup: ## Copy .env.example to .env
	cp .env.example .env
	@echo ".env file created. Please edit it with your configuration."

backup-db: ## Backup PostgreSQL database
	docker exec omni-caller-postgres pg_dump -U postgres omnicaller > backup_$$(date +%Y%m%d_%H%M%S).sql
	@echo "Database backed up successfully"

restore-db: ## Restore PostgreSQL database (usage: make restore-db FILE=backup.sql)
	@if [ -z "$(FILE)" ]; then echo "Usage: make restore-db FILE=backup.sql"; exit 1; fi
	docker exec -i omni-caller-postgres psql -U postgres omnicaller < $(FILE)
	@echo "Database restored successfully"
