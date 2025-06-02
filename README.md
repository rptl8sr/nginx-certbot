# Automated Nginx with HTTPS and Let's Encrypt

This project provides a simple and automated way to set up an Nginx web server with HTTPS, utilizing Let's Encrypt for SSL certificates. The entire process, including initial setup and certificate renewal, is handled through Docker containers and orchestrated with a single `make init` command.

## Features

- **Automated HTTPS with Let's Encrypt:** Easily obtain and renew SSL certificates.
- **Single Command Setup:** Initialize the entire environment with `make init`.
- **Dockerized Environment:** All services run in isolated Docker containers.
- **`docker-compose` Integration:** Streamlined management of the Nginx service.
- **Automatic Certificate Renewal:** Let's Encrypt certificates are automatically renewed.

## Prerequisites

- Docker installed on your system.
- Docker Compose installed on your system.

## Project Structure

The project is organized as follows:

- `Makefile`: Contains the commands for building, initializing, and managing the project.
- `docker-compose.yml`: Defines the Docker services (Nginx and Certbot).
- `dumb.env`: Example of environment variables used for configuring the project.
- `nginx.conf.template`: The main Nginx configuration file template.
- `http.conf.template`: Template for the HTTP server block (used during initial certificate issuance).
- `https.conf.template`: Template for the HTTPS server block (used after certificates are obtained).
- `http.html.template`: Template for a simple HTML file displayed on the HTTP server.
- `https.html.template`: Template for a simple HTML file displayed on the HTTPS server.

## Configuration

The project is configured using environment variables defined in the `dumb.env` file. You should copy `dumb.env` to `.env` and modify the values as needed.

Here's a breakdown of the key environment variables:

- `NGINX_HTTP_PORT`: The port Nginx will listen on for HTTP traffic (default: 80).
- `NGINX_HTTPS_PORT`: The port Nginx will listen on for HTTPS traffic (default: 443).
- `DOMAIN_NAME`: Your domain name (e.g., `example.com`). **This is required for Let's Encrypt.**
- `EMAIL`: Your email address, used by Let's Encrypt for important notifications (e.g., `admin@example.com`). **This is required for Let's Encrypt.**
- `NGINX_CONTAINER`: The name of the Nginx Docker container.
- `CERTBOT_CONTAINER`: The name of the Certbot Docker container.
- `NGINX_IMAGE`: The Docker image to use for Nginx (e.g., `nginx:latest`). Consider using a versioned image for stability.
- `CERTBOT_IMAGE`: The Docker image to use for Certbot (e.g., `certbot/certbot:latest`). Consider using a versioned image for stability.
- `LETSENCRYPT_FOLDER`: The folder where Let's Encrypt certificates will be stored (default: `./letsencrypt`).
- `HTML_FOLDER`: The folder where your HTML files will be served from (default: `./html`).
- `NGINX_DEFAULT_CONFIG`: The name of the main Nginx configuration file template.
- `NGINX_DEFAULT_TEMPLATE`: The name of the default Nginx server block template.
- `NGINX_HTTP_TEMPLATE`: The name of the Nginx HTTP server block template used before certification.
- `NGINX_HTTPS_TEMPLATE`: The name of the Nginx HTTPS server block template used after certification.
- `HTML_DEFAULT_TEMPLATE`: The path to the default HTML file for the web server.
- `HTML_HTTP_TEMPLATE`: The name of the HTML template for the HTTP server block.
- `HTML_HTTPS_TEMPLATE`: The name of the HTML template for the HTTPS server block.
- `REMOTE_HOST`: The remote server connection name stored in your SSH config (used for remote deployment, if applicable).
- `REMOTE_PATH`: The remote path for Nginx and Certbot files (used for remote deployment, if applicable).
