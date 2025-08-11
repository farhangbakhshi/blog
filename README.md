# Farhang's Blog

A modern, fast, and secure blog built with static HTML, TailwindCSS, and IBM Plex Serif font, served by nginx in a Docker container.

## Features

- ⚡ **Ultra Fast**: Static HTML served by nginx
- 🌙 **Dark Mode**: Automatic dark/light mode based on system preference
- 📱 **Responsive**: Mobile-first design with TailwindCSS
- 🎨 **Beautiful Typography**: IBM Plex Serif font for excellent readability
- 🔒 **Secure**: Security headers and rate limiting
- 🐳 **Dockerized**: Self-contained deployment with single Dockerfile
- 📊 **Optimized**: Gzip compression and asset caching

## Quick Deployment

### One-Click Deploy

This project is designed for deployment services like **Railway**, **Render**, **Vercel**, **Netlify**, or **Fly.io** that can deploy directly from GitHub.

**Deploy URL**: Just connect your GitHub repository to any Docker-compatible hosting service.

### Local Development

```bash
# Clone the repository
git clone https://github.com/yourusername/farhangs-blog.git
cd farhangs-blog

# Build and run with Docker
docker build -t farhangs-blog .
docker run -p 3000:80 farhangs-blog

# Visit http://localhost:3000
```

```
blog_new/
├── nginx/                 # Nginx configuration files
│   ├── nginx.conf        # Main nginx configuration
│   └── blog.conf         # Site-specific configuration
├── www/                  # Website content
│   ├── index.html        # Homepage
│   ├── styles.css        # Main stylesheet
│   └── linux-a-comprehensive-introduction/
│       ├── index.html    # Blog post page
│       └── post.css      # Post-specific styles
├── logs/                 # Nginx log files
├── ssl/                  # SSL certificates (when configured)
├── docker-compose.yml    # Docker Compose configuration
├── Dockerfile           # Custom nginx Docker image
├── Makefile            # Build and management commands
└── README.md           # This file
```

## Features

- ⚡ **Fast**: Static site served by nginx
- 🔒 **Secure**: Security headers and rate limiting configured
- 📱 **Responsive**: Mobile-friendly design
- 🐳 **Dockerized**: Easy deployment with Docker
- 📊 **Logging**: Comprehensive access and error logging
- 🔧 **Configurable**: Easy to customize and extend

## Quick Start

### Using Docker Compose (Recommended)

1. **Start the blog:**
   ```bash
   make up
   ```

2. **View the blog:**
   Open http://localhost in your browser

3. **Stop the blog:**
   ```bash
   make down
   ```

### Manual Docker Setup

1. **Build the image:**
   ```bash
   docker build -t blog-nginx .
   ```

2. **Run the container:**
   ```bash
   docker run -d -p 80:80 --name blog blog-nginx
   ```

### Traditional nginx Setup

1. **Copy configuration files:**
   ```bash
   sudo cp nginx/nginx.conf /etc/nginx/
   sudo cp nginx/blog.conf /etc/nginx/sites-available/
   sudo ln -s /etc/nginx/sites-available/blog.conf /etc/nginx/sites-enabled/
   ```

2. **Copy website content:**
   ```bash
   sudo cp -r www/* /var/www/blog/
   ```

3. **Test and reload nginx:**
   ```bash
   sudo nginx -t
   sudo systemctl reload nginx
   ```

## Available Commands

| Command | Description |
|---------|-------------|
| `make up` | Start the blog |
| `make down` | Stop the blog |
| `make logs` | View nginx logs |
| `make restart` | Restart the blog |
| `make clean` | Clean up containers |
| `make test` | Test nginx configuration |
| `make dev` | Start in development mode |
| `make status` | Check if blog is running |
| `make backup` | Create a backup |

## Configuration

### Adding New Blog Posts

1. Create a new directory in `www/` for your post
2. Add an `index.html` file with your content
3. Update the homepage (`www/index.html`) to link to your new post
4. Optionally create post-specific CSS files

### SSL Configuration

1. Place your SSL certificates in the `ssl/` directory
2. Uncomment the HTTPS server block in `nginx/blog.conf`
3. Update the certificate paths
4. Restart the blog: `make restart`

### Custom Domain

1. Update the `server_name` directive in `nginx/blog.conf`
2. Configure your DNS to point to your server
3. Restart nginx: `make restart`

## Security Features

- Rate limiting to prevent abuse
- Security headers (HSTS, CSP, etc.)
- Hidden file protection
- Backup file access denial
- SSL/TLS configuration ready

## Monitoring and Logs

Logs are stored in the `logs/` directory:

- `access.log` - Access logs
- `error.log` - Error logs
- `blog_access.log` - Blog-specific access logs
- `blog_error.log` - Blog-specific error logs

View live logs:
```bash
make logs
```

## Performance Optimization

The nginx configuration includes:

- Gzip compression
- Static asset caching
- Efficient worker configuration
- Keep-alive connections

## Development

For development with live reloading:

```bash
make dev
```

This will show logs in real-time and restart automatically when you make changes.

## Backup and Restore

Create a backup:
```bash
make backup
```

This creates a compressed archive with all content and configuration files.

## Troubleshooting

### Blog not accessible
1. Check if the container is running: `docker ps`
2. Check logs: `make logs`
3. Test nginx configuration: `make test`

### Port conflicts
If port 80 is already in use, modify the `docker-compose.yml` file to use a different port:
```yaml
ports:
  - "8080:80"  # Use port 8080 instead
```

### Permission issues
Ensure proper ownership of files:
```bash
sudo chown -R $USER:$USER .
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is open source and available under the MIT License.

## Support

For issues and questions:
- Check the logs: `make logs`
- Test configuration: `make test`
- Review nginx documentation
- Check Docker Compose logs
