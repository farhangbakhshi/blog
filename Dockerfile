FROM nginx:latest

# Install additional packages for health checks
RUN apt-get update && apt-get install -y curl && apt-get clean && rm -rf /var/lib/apt/lists/*

# Remove default nginx configuration
RUN rm -f /etc/nginx/nginx.conf /etc/nginx/conf.d/default.conf

# Create necessary directories
RUN mkdir -p /var/www/blog /var/log/nginx

# Copy SSL certificates
COPY /root/blog/certificate.crt /ssl/certificate.crt
COPY /root/blog/private.key /ssl/private.key

# Copy nginx configuration files
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/blog.conf /etc/nginx/conf.d/blog.conf

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
