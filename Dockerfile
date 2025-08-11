FROM nginx:alpine

# Install additional packages for health checks
RUN apk add --no-cache curl

# Remove default nginx configuration
RUN rm -f /etc/nginx/nginx.conf /etc/nginx/conf.d/default.conf

# Create necessary directories
RUN mkdir -p /var/www/blog /var/log/nginx

# Create nginx.conf
RUN cat > /etc/nginx/nginx.conf << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;

    gzip on;
    gzip_vary on;
    gzip_min_length 1000;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;

    limit_req_zone $binary_remote_addr zone=blog:10m rate=10r/m;

    include /etc/nginx/conf.d/*.conf;
}
EOF

# Create blog.conf
RUN cat > /etc/nginx/conf.d/blog.conf << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name localhost;
    
    root /var/www/blog;
    index index.html index.htm;

    access_log /var/log/nginx/blog_access.log;
    error_log /var/log/nginx/blog_error.log;

    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' https: 'unsafe-inline' fonts.googleapis.com cdn.tailwindcss.com" always;

    limit_req zone=blog burst=20 nodelay;

    location / {
        try_files $uri $uri/ $uri.html =404;
        
        location ~* \.(css|js|jpg|jpeg|png|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1M;
            add_header Cache-Control "public, immutable";
        }
    }

    location /linux-a-comprehensive-introduction {
        try_files $uri $uri/ /linux-a-comprehensive-introduction/index.html =404;
    }

    location ~ /\. {
        deny all;
    }

    location ~* \.(bak|config|sql|fla|psd|ini|log|sh|inc|swp|dist)$ {
        deny all;
    }
}
EOF

# Copy website content
COPY www /var/www/blog

# Set proper permissions
RUN chown -R nginx:nginx /var/www/blog /var/log/nginx

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# Expose port 80 (many deployment services handle port mapping automatically)
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
