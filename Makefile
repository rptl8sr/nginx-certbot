# Load environment variables
ifneq (,$(wildcard ./.env))
include .env
export
endif

# Validate required variables
REQUIRED_VARS = DOMAIN_NAME EMAIL NGINX_CONTAINER CERTBOT_CONTAINER NGINX_IMAGE CERTBOT_IMAGE LETSENCRYPT_FOLDER HTML_FOLDER NGINX_DEFAULT_TEMPLATE NGINX_HTTP_TEMPLATE NGINX_HTTPS_TEMPLATE HTML_DEFAULT_TEMPLATE HTML_HTTP_TEMPLATE HTML_HTTPS_TEMPLATE
$(foreach var,$(REQUIRED_VARS),$(if $($(var)),,$(error $(var) is not set in .env file)))

# Docker compose command with explicit env file
COMPOSE := docker compose --env-file .env

# Phony targets
.PHONY: init-http init-staging init-production init start stop restart logs-nginx logs-certbot exec-nginx exec-certbot clear remote-deploy curl-http curl-https

init: init-staging init-production start

init-http:
	# Run nginx in HTTP mode
	@echo "Initializing HTTP config for domain: $(DOMAIN_NAME)"
	@mkdir -p $(LETSENCRYPT_FOLDER) $(HTML_FOLDER)
	@cp $(NGINX_HTTP_TEMPLATE) $(NGINX_DEFAULT_TEMPLATE)
	@cp $(HTML_HTTP_TEMPLATE) $(HTML_DEFAULT_TEMPLATE)
	@$(COMPOSE) down -v > /dev/null 2>&1 || true
	@$(COMPOSE) up -d $(NGINX_CONTAINER)

init-staging: init-http
	# Get staging certificates
	@echo "Running Certbot for staging certificates..."
	@$(COMPOSE) run --rm --entrypoint '' $(CERTBOT_CONTAINER) sh -c " \
		certbot certonly \
			--webroot \
			--webroot-path /var/www/html \
			--email $(EMAIL) \
			--agree-tos \
			--no-eff-email \
			--staging \
			--non-interactive \
			--keep-until-expiring \
			-d $(DOMAIN_NAME) \
	" || (echo "Certbot failed!"; $(COMPOSE) down; exit 1)
	@echo "Staging certificates acquired."

	# Shutdown Nginx
	@$(COMPOSE) down
	@echo "Staging setup complete. Ready for production."

init-production: init-http
	# Get production certificates
	@echo "Running initial Certbot for production certificates..."
	@$(COMPOSE) run --rm --entrypoint '' $(CERTBOT_CONTAINER) sh -c " \
		certbot certonly \
			--webroot \
			--webroot-path /var/www/html \
			--email $(EMAIL) \
			--force-renewal \
			--agree-tos \
			--no-eff-email \
			--non-interactive \
			--keep-until-expiring \
			-d $(DOMAIN_NAME) \
	" || (echo "Certbot failed!"; $(COMPOSE) down; exit 1)
	@echo "Production certificates acquired."

	@echo "Switching to HTTPS configuration..."
	@cp $(NGINX_HTTPS_TEMPLATE) $(NGINX_DEFAULT_TEMPLATE)
	@cp $(HTML_HTTPS_TEMPLATE) $(HTML_DEFAULT_TEMPLATE)

	@$(COMPOSE) down -v 
	@$(COMPOSE) up -d --force-recreate $(NGINX_CONTAINER)

	@echo "Production setup complete. Nginx is now running with HTTPS."
	@sleep 2
	@$(COMPOSE) down
	@echo "Nginx has been stopped after production setup. You can now start it with 'make start'."

start:
	@echo "Starting Nginx with current configuration..."
	@cp $(NGINX_HTTPS_TEMPLATE) $(NGINX_DEFAULT_TEMPLATE)
	@cp $(HTML_HTTPS_TEMPLATE) $(HTML_DEFAULT_TEMPLATE)
	@$(COMPOSE) up -d
	@echo "Nginx & Certbot started successfully."

stop:
	@echo "Stopping Nginx..."
	@$(COMPOSE) down
	@echo "Nginx stopped successfully."

restart: stop start
	@echo "Nginx restarted successfully."

logs-nginx:
	@echo "Fetching Nginx logs..."
	@$(COMPOSE) logs $(NGINX_CONTAINER)
	@echo "Nginx logs fetched."

logs-certbot:
	@echo "Fetching Certbot logs..."
	@$(COMPOSE) logs $(CERTBOT_CONTAINER)
	@echo "Certbot logs fetched."


exec-nginx:
	@echo "Executing shell in Nginx container..."
	@$(COMPOSE) exec -it $(NGINX_CONTAINER) sh

exec-certbot:
	@echo "Executing shell in Certbot container..."
	@$(COMPOSE) exec -it $(CERTBOT_CONTAINER) sh

clear:
	@echo "Clearing Docker volumes and networks..."
	@$(COMPOSE) down -v --remove-orphans > /dev/null 2>&1 || true
	@rm -f $(NGINX_DEFAULT_TEMPLATE) $(HTML_DEFAULT_TEMPLATE)
	@rm -rf $(LETSENCRYPT_FOLDER)
	@rm -rf $(HTML_FOLDER)
	@echo "Docker volumes, templates, certificates and networks have been cleared."

remote-deploy:
	@echo "Deploying files to remote server..."
	scp -p docker-compose.yml *.template .env Makefile $(REMOTE_HOST):$(REMOTE_PATH)
	@echo "Deployment complete."

curl-http:
	@echo "Testing HTTP connection to $(DOMAIN_NAME)..."
	curl -I http://$(DOMAIN_NAME) || (echo "HTTP connection failed!"; exit 1)

curl-https:
	@echo "Testing HTTPS connection to $(DOMAIN_NAME)..."
	curl -I https://$(DOMAIN_NAME) || (echo "HTTPS connection failed!"; exit 1)

# GitHub
REPO_NAME := $(shell basename $(CURDIR))
PROJECT := $(CURDIR)

git-init:
	gh repo create $(USER)/$(REPO_NAME) --public
	git init
	git config user.name "$(USER)"
	git config user.email "$(EMAIL)"
	touch .gitignore README.md
	git add Makefile .gitignore README.md
	git commit -m "Init commit"
	git remote add origin git@github.com:$(USER)/$(REPO_NAME).git
	git remote -v
	git push -u origin master