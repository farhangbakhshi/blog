#!/bin/bash

# Blog deployment and management script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Source configuration
CONFIG_FILE="/root/config.env"
if [ -f "$CONFIG_FILE" ]; then
    # shellcheck source=/root/config.env
    . "$CONFIG_FILE"
    print_status "Loaded configuration from $CONFIG_FILE"
else
    print_warning "Config file not found at $CONFIG_FILE; REPO_ADDRESS-dependent features may not work."
fi

# Function to start the blog
start_blog() {
    print_status "Starting the blog..."
    docker-compose up -d
    
    # Wait a moment for the container to start
    sleep 3
    
    # Check if the blog is running
    if curl -s -o /dev/null -w "%{http_code}" http://localhost | grep -q "200"; then
        print_success "Blog is running successfully at http://localhost"
    else
        print_warning "Blog started but may not be fully ready yet. Check logs with: $0 logs"
    fi
}

# Function to stop the blog
stop_blog() {
    print_status "Stopping the blog..."
    docker-compose down
    print_success "Blog stopped"
}

# Function to restart the blog
restart_blog() {
    print_status "Restarting the blog..."
    stop_blog
    start_blog
}

# Function to show logs
show_logs() {
    print_status "Showing nginx logs (Ctrl+C to exit)..."
    docker-compose logs -f nginx
}

# Function to test nginx configuration
test_config() {
    print_status "Testing nginx configuration..."
    if docker run --rm -v "$(pwd)/nginx:/etc/nginx:ro" nginx:alpine nginx -t; then
        print_success "Nginx configuration is valid"
    else
        print_error "Nginx configuration has errors"
        exit 1
    fi
}

# Function to show status
show_status() {
    print_status "Checking blog status..."
    
    if docker ps | grep -q "blog_nginx"; then
        print_success "Blog container is running"
        
        if curl -s -o /dev/null -w "%{http_code}" http://localhost | grep -q "200"; then
            print_success "Blog is accessible at http://localhost"
        else
            print_warning "Container is running but blog is not accessible"
        fi
    else
        print_error "Blog container is not running"
    fi
}

# Function to show help
show_help() {
    echo "Blog Management Script"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  start      Start the blog"
    echo "  stop       Stop the blog"
    echo "  restart    Restart the blog"
    echo "  logs       Show nginx logs"
    echo "  test       Test nginx configuration"
    echo "  status     Show blog status"
    echo "  new-post   Create a new blog post"
    echo "  help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start"
    echo "  $0 new-post"
    echo "  $0 logs"
}

# New: clone a repository using $REPO_ADDRESS from config.env
clone_repo() {
    local repo="${REPO_ADDRESS}"

    if [ -z "$repo" ]; then
        print_error "REPO_ADDRESS is not set. Ensure $CONFIG_FILE exists and defines REPO_ADDRESS."
        return 1
    fi

    if ! command -v git >/dev/null 2>&1; then
        print_error "git is not installed or not in PATH."
        return 1
    fi

    print_status "Cloning repository: $repo"
    git clone "$repo"
    print_success "Repository cloned."
}

# Main script logic
case "$1" in
    start)
        start_blog
        ;;
    stop)
        stop_blog
        ;;
    restart)
        restart_blog
        ;;
    logs)
        show_logs
        ;;
    test)
        test_config
        ;;
    status)
        show_status
        ;;
    new-post)
        create_post
        ;;
    help|--help|-h)
        show_help
        ;;
    "")
        print_error "No command specified"
        show_help
        exit 1
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
