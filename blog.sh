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
    docker compose up -d
    
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
    docker compose down
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
    docker compose logs -f nginx
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
    echo "  update     Clone repo and replace current directory with repo's blog contents"
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

# New: update from repo (clone -> docker compose down -> replace PWD with cloned blog contents)
update_from_repo() {
    local orig_dir tmpdir blog_src uuid
    orig_dir="$(pwd)"
    # Use a UUID for the update path under /root
    if command -v uuidgen >/dev/null 2>&1; then
        uuid="$(uuidgen)"
    elif [ -r /proc/sys/kernel/random/uuid ]; then
        uuid="$(cat /proc/sys/kernel/random/uuid)"
    else
        uuid="$(date +%s)-$$"
    fi
    tmpdir="/root/blog-update-${uuid}"
    mkdir -p "$tmpdir"
    print_status "Cloning into temporary directory: $tmpdir"

    pushd "$tmpdir" >/dev/null
    clone_repo

    # Find the 'blog' directory inside the cloned repo
    blog_src="$(find "$tmpdir" -maxdepth 2 -type d -name 'blog' | head -n1)"
    if [ -z "$blog_src" ]; then
        print_error "Could not find a 'blog' directory in the cloned repository."
        popd >/dev/null
        rm -rf "$tmpdir"
        return 1
    fi

    # Stop services
    print_status "Stopping services with docker compose down..."
    (cd "$orig_dir" && docker compose down)

    # Replace current directory contents (including dotfiles)
    print_warning "Replacing all contents of $orig_dir with cloned 'blog' directory."
    (
        set -e
        cd "$orig_dir"
        shopt -s dotglob nullglob
        rm -rf -- *
    )

    # Copy new contents and cleanup
    cp -a "$blog_src"/. "$orig_dir"/
    popd >/dev/null
    rm -rf "$tmpdir"

    print_success "Update complete. Directory replaced with contents from the cloned 'blog' directory."
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
    update)
        update_from_repo
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
