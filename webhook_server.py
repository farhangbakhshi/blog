#!/usr/bin/env python3
"""
GitHub Webhook Server
A Flask application that receives GitHub webhooks and triggers blog updates.
Runs as a daemon with SSL support using Waitress.
"""

import os
import sys
import json
import subprocess
import logging
import signal
from pathlib import Path
from flask import Flask, request, jsonify
from flask_cors import CORS
from waitress import serve
import requests
import ipaddress

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/webhook_server.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)

# Configuration
SSL_CERT_PATH = '/root/certificate.crt'
SSL_KEY_PATH = '/root/private.key'
BLOG_DIR = '/root/blog'
PORT = 5000
HOST = '0.0.0.0'

# GitHub IP ranges (updated as of 2024)
GITHUB_IP_RANGES = [
    '192.30.252.0/22',
    '185.199.108.0/22',
    '140.82.112.0/20',
    '143.55.64.0/20',
    '2a0a:a440::/29',
    '2606:50c0::/32'
]

def is_github_ip(ip_address):
    """Check if the IP address belongs to GitHub's IP ranges."""
    try:
        ip = ipaddress.ip_address(ip_address)
        for ip_range in GITHUB_IP_RANGES:
            if ip in ipaddress.ip_network(ip_range):
                return True
    except ValueError:
        logger.warning(f"Invalid IP address: {ip_address}")
        return False
    return False

def get_real_ip():
    """Extract the real IP address from the request."""
    # Check X-Real-IP header first (set by reverse proxy)
    real_ip = request.headers.get('X-Real-IP')
    if real_ip:
        return real_ip
    
    # Check X-Forwarded-For header
    forwarded_for = request.headers.get('X-Forwarded-For')
    if forwarded_for:
        # X-Forwarded-For can contain multiple IPs, take the first one
        return forwarded_for.split(',')[0].strip()
    
    # Fall back to remote_addr
    return request.remote_addr

def verify_github_source():
    """Verify that the request is coming from GitHub."""
    real_ip = get_real_ip()
    
    if not real_ip:
        logger.warning("Could not determine real IP address")
        return False
    
    logger.info(f"Request from IP: {real_ip}")
    
    if is_github_ip(real_ip):
        logger.info(f"Valid GitHub IP: {real_ip}")
        return True
    
    logger.warning(f"Invalid IP address (not from GitHub): {real_ip}")
    return False

def run_blog_update():
    """Execute the blog update script."""
    try:
        # Change to blog directory and run the update script
        logger.info(f"Changing directory to {BLOG_DIR}")
        os.chdir(BLOG_DIR)
        
        logger.info("Running blog update script")
        result = subprocess.run(
            ['./blog.sh', 'update'],
            cwd=BLOG_DIR,
            capture_output=True,
            text=True,
            timeout=300  # 5 minute timeout
        )
        
        if result.returncode == 0:
            logger.info("Blog update completed successfully")
            logger.info(f"Script output: {result.stdout}")
            return True, result.stdout
        else:
            logger.error(f"Blog update failed with return code {result.returncode}")
            logger.error(f"Script error: {result.stderr}")
            return False, result.stderr
            
    except subprocess.TimeoutExpired:
        logger.error("Blog update script timed out")
        return False, "Script execution timed out"
    except Exception as e:
        logger.error(f"Error running blog update: {str(e)}")
        return False, str(e)

@app.route('/webhook', methods=['POST'])
def github_webhook():
    """Handle GitHub webhook requests."""
    try:
        # Verify the request is from GitHub
        if not verify_github_source():
            logger.warning("Webhook request rejected: not from GitHub IP")
            return jsonify({'error': 'Unauthorized'}), 403
        
        # Get the request data
        if request.is_json:
            payload = request.get_json()
        else:
            payload = request.form.to_dict()
        
        logger.info(f"Received webhook: {payload.get('action', 'unknown')}")
        
        # Log webhook details
        if 'repository' in payload:
            repo_name = payload['repository'].get('name', 'unknown')
            logger.info(f"Repository: {repo_name}")
        
        # Trigger blog update
        success, output = run_blog_update()
        
        if success:
            return jsonify({
                'status': 'success',
                'message': 'Blog updated successfully',
                'output': output
            }), 200
        else:
            return jsonify({
                'status': 'error',
                'message': 'Blog update failed',
                'error': output
            }), 500
            
    except Exception as e:
        logger.error(f"Error processing webhook: {str(e)}")
        return jsonify({
            'status': 'error',
            'message': 'Internal server error',
            'error': str(e)
        }), 500

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint."""
    return jsonify({
        'status': 'healthy',
        'service': 'webhook-server',
        'version': '1.0.0'
    }), 200

def check_ssl_files():
    """Check if SSL certificate files exist."""
    cert_exists = os.path.exists(SSL_CERT_PATH)
    key_exists = os.path.exists(SSL_KEY_PATH)
    
    if not cert_exists:
        logger.error(f"SSL certificate not found: {SSL_CERT_PATH}")
    if not key_exists:
        logger.error(f"SSL private key not found: {SSL_KEY_PATH}")
    
    return cert_exists and key_exists

def check_blog_script():
    """Check if blog script exists and is executable."""
    script_path = os.path.join(BLOG_DIR, 'blog.sh')
    
    if not os.path.exists(script_path):
        logger.error(f"Blog script not found: {script_path}")
        return False
    
    if not os.access(script_path, os.X_OK):
        logger.error(f"Blog script is not executable: {script_path}")
        return False
    
    return True

def daemonize():
    """Daemonize the process."""
    try:
        # First fork
        pid = os.fork()
        if pid > 0:
            # Exit parent process
            sys.exit(0)
    except OSError as e:
        logger.error(f"Fork #1 failed: {e}")
        sys.exit(1)
    
    # Decouple from parent environment
    os.chdir("/")
    os.setsid()
    os.umask(0)
    
    try:
        # Second fork
        pid = os.fork()
        if pid > 0:
            # Exit second parent process
            sys.exit(0)
    except OSError as e:
        logger.error(f"Fork #2 failed: {e}")
        sys.exit(1)
    
    # Redirect standard file descriptors
    sys.stdout.flush()
    sys.stderr.flush()
    
    with open('/dev/null', 'r') as si:
        os.dup2(si.fileno(), sys.stdin.fileno())
    with open('/dev/null', 'w') as so:
        os.dup2(so.fileno(), sys.stdout.fileno())
    with open('/dev/null', 'w') as se:
        os.dup2(se.fileno(), sys.stderr.fileno())

def signal_handler(signum, frame):
    """Handle shutdown signals."""
    logger.info(f"Received signal {signum}, shutting down...")
    sys.exit(0)

def main():
    """Main function to start the webhook server."""
    # Set up signal handlers
    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGINT, signal_handler)
    
    # Check prerequisites
    if not check_ssl_files():
        logger.error("SSL files not found, exiting")
        sys.exit(1)
    
    if not check_blog_script():
        logger.error("Blog script not found or not executable, exiting")
        sys.exit(1)
    
    # Daemonize the process
    if len(sys.argv) > 1 and sys.argv[1] == '--no-daemon':
        logger.info("Running in foreground mode")
    else:
        logger.info("Daemonizing process...")
        daemonize()
    
    logger.info("Starting GitHub Webhook Server")
    logger.info(f"Listening on {HOST}:{PORT}")
    logger.info(f"SSL Certificate: {SSL_CERT_PATH}")
    logger.info(f"SSL Private Key: {SSL_KEY_PATH}")
    logger.info(f"Blog Directory: {BLOG_DIR}")
    
    # Write PID file
    with open('/var/run/webhook_server.pid', 'w') as f:
        f.write(str(os.getpid()))
    
    try:
        # Start the server with SSL
        serve(
            app,
            host=HOST,
            port=PORT,
            url_scheme='https',
            ssl_cert=SSL_CERT_PATH,
            ssl_key=SSL_KEY_PATH,
            threads=4,
            connection_limit=100
        )
    except Exception as e:
        logger.error(f"Failed to start server: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
