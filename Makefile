# Makefile for nginx blog management

.PHONY: help build up down logs restart clean test

# Default target
help:
	@echo "Available commands:"
	@echo "  build     - Build the Docker image"
	@echo "  up        - Start the blog with Docker Compose"
	@echo "  down      - Stop the blog"
	@echo "  logs      - Show nginx logs"
	@echo "  restart   - Restart the blog"
	@echo "  clean     - Clean up containers and images"
	@echo "  test      - Test nginx configuration"
	@echo "  dev       - Start in development mode"

# Build the Docker image
build:
	docker-compose build

# Start the blog
up:
	docker-compose up -d
	@echo "Blog is running at http://localhost"

# Stop the blog
down:
	docker-compose down

# Show logs
logs:
	docker-compose logs -f nginx

# Restart the blog
restart: down up

# Clean up
clean:
	docker-compose down -v --remove-orphans
	docker system prune -f

# Test nginx configuration
test:
	docker run --rm -v $(PWD)/nginx:/etc/nginx:ro nginx:alpine nginx -t

# Development mode (with file watching)
dev:
	docker-compose up
	@echo "Development mode - logs will be shown"

# Check if blog is running
status:
	@curl -s -o /dev/null -w "%{http_code}" http://localhost || echo "Blog is not running"

# Create backup
backup:
	@echo "Creating backup..."
	tar -czf blog_backup_$(shell date +%Y%m%d_%H%M%S).tar.gz www nginx logs
	@echo "Backup created"
