# Blog (Static Nginx + Docker)

A minimal, containerized static blog. Content lives in `www/`, served by Nginx, orchestrated with Docker Compose, and managed via `Makefile` or the `blog.sh` helper.

## What’s inside

- Static HTML in `www/` (example post: `linux-a-comprehensive-introduction/`)
- Nginx with hardening: security headers, rate limiting, gzip, and asset caching
- Dockerfile for a reproducible image and `docker-compose.yml` for local/dev runs
- Makefile targets for common tasks (+ a `blog.sh` script with similar commands)
- Nginx configs in `nginx/` (`nginx.conf`, `blog.conf`)

```
.
├── Dockerfile
├── docker-compose.yml
├── Makefile
├── blog.sh
├── nginx/
│   ├── nginx.conf
│   └── blog.conf
└── www/
      ├── index.html
      └── linux-a-comprehensive-introduction/
            └── index.html
```

## Quick start

- Start
   ```bash
   make up
   # visit http://localhost
   ```

- Logs
   ```bash
   make logs
   ```

- Stop
   ```bash
   make down
   ```

Alternative (helper script):
```bash
./blog.sh start    # stop | restart | logs | test | status
```

## Add a new post

1) Create a folder under `www/` with your slug and an `index.html` inside, e.g. `www/my-post/index.html`.
2) Link it from `www/index.html`.

## Configuration notes

- Edit `nginx/blog.conf` to set `server_name`, headers, cache rules, or to add locations.
- SSL: `docker-compose.yml` mounts `./ssl` to `/etc/nginx/ssl` if you add certs. Update `blog.conf` and enable the HTTPS server block accordingly.
- Logs: container logs are streamed via `make logs`; Nginx writes to `/var/log/nginx` (bind-mounted to `./logs` if present).

## Development tips

- Foreground/dev mode with live logs
   ```bash
   make dev
   ```

- Validate Nginx config
   ```bash
   make test
   ```

## License

MIT
