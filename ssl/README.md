# SSL Certificates

This directory contains SSL certificates for HTTPS configuration.

## Current Setup

The current certificates are **self-signed** and generated for development/testing purposes only.

- `certificate.crt` - Self-signed SSL certificate
- `private.key` - Private key (keep this secure!)

## For Production Use

Replace these files with proper SSL certificates from a Certificate Authority (CA) such as:

- **Let's Encrypt** (free, automated)
- **Cloudflare** (if using Cloudflare)
- **Commercial CA** (DigiCert, GlobalSign, etc.)

## Using Let's Encrypt with Certbot

To get free SSL certificates from Let's Encrypt:

```bash
# Install certbot
sudo apt install certbot

# Get certificates (replace farhang.blog with your domain)
sudo certbot certonly --standalone -d farhang.blog

# Certificates will be in /etc/letsencrypt/live/farhang.blog/
# Copy them to this directory:
sudo cp /etc/letsencrypt/live/farhang.blog/fullchain.pem ./certificate.crt
sudo cp /etc/letsencrypt/live/farhang.blog/privkey.pem ./private.key
```

## Security Note

- Keep the `private.key` file secure and never commit it to version control
- Set proper file permissions: `chmod 600 private.key`
- Renew certificates before they expire (Let's Encrypt certificates expire every 90 days)

## Current Configuration

The nginx configuration is set to:
- Redirect all HTTP (port 80) traffic to HTTPS (port 443)
- Use modern TLS protocols (TLSv1.2 and TLSv1.3)
- Include security headers like HSTS
- Use strong cipher suites
