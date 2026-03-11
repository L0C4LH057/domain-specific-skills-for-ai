# Containers Reference — Docker & Docker Compose

## Table of Contents
1. [Dockerfile Patterns](#dockerfile-patterns)
2. [Multi-Stage Builds](#multi-stage-builds)
3. [Docker Compose](#docker-compose)
4. [Security Hardening](#security-hardening)
5. [Registry & Image Management](#registry--image-management)

---

## Dockerfile Patterns

### Node.js (Production-Ready)
```dockerfile
# syntax=docker/dockerfile:1
FROM node:20-alpine AS base
WORKDIR /app
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

FROM base AS deps
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

FROM base AS build
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM base AS production
ENV NODE_ENV=production
COPY --from=deps /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
USER appuser
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1
CMD ["node", "dist/server.js"]
```

### Python (FastAPI / Flask)
```dockerfile
FROM python:3.12-slim AS base
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1
WORKDIR /app
RUN adduser --disabled-password --gecos "" appuser

FROM base AS deps
COPY requirements.txt .
RUN pip install --upgrade pip && pip install -r requirements.txt

FROM base AS production
COPY --from=deps /usr/local/lib/python3.12 /usr/local/lib/python3.12
COPY --from=deps /usr/local/bin /usr/local/bin
COPY --chown=appuser:appuser . .
USER appuser
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=5s CMD curl -f http://localhost:8000/health || exit 1
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Go (Minimal scratch image)
```dockerfile
FROM golang:1.22-alpine AS build
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o server ./cmd/server

FROM scratch
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /app/server /server
EXPOSE 8080
ENTRYPOINT ["/server"]
```

### Java (Spring Boot)
```dockerfile
FROM eclipse-temurin:21-jdk-alpine AS build
WORKDIR /app
COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
RUN ./mvnw dependency:resolve
COPY src ./src
RUN ./mvnw package -DskipTests

FROM eclipse-temurin:21-jre-alpine
RUN adduser -D appuser
USER appuser
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
HEALTHCHECK --interval=30s CMD wget -qO- http://localhost:8080/actuator/health || exit 1
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75", "-jar", "app.jar"]
```

---

## Multi-Stage Builds

### Key Rules
- Each `FROM` resets the filesystem — only `COPY --from` transfers artifacts
- Name stages with `AS <name>` to reference them and to enable `--target`
- Order `COPY` from least-to-most-changing to maximize layer cache hits:
  1. System deps (`apt-get`, `apk`)
  2. Package manifests (`package.json`, `requirements.txt`)
  3. Application source code

### Build Cache Optimization
```dockerfile
# BAD — busts cache on every source change
COPY . .
RUN npm ci

# GOOD — deps layer cached until package.json changes
COPY package*.json ./
RUN npm ci
COPY . .
```

---

## Docker Compose

### Full-Stack Application (App + DB + Cache + Proxy)
```yaml
# docker-compose.yml
name: myapp

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
      target: production
    restart: unless-stopped
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://appuser:${DB_PASSWORD}@db:5432/appdb
      - REDIS_URL=redis://cache:6379
    ports:
      - "3000:3000"
    depends_on:
      db:
        condition: service_healthy
      cache:
        condition: service_started
    networks:
      - backend
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M

  db:
    image: postgres:16-alpine
    restart: unless-stopped
    environment:
      POSTGRES_DB: appdb
      POSTGRES_USER: appuser
      POSTGRES_PASSWORD: ${DB_PASSWORD}   # set in .env file — never hardcode
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./scripts/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U appuser -d appdb"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - backend

  cache:
    image: redis:7-alpine
    restart: unless-stopped
    command: redis-server --requirepass ${REDIS_PASSWORD} --maxmemory 256mb --maxmemory-policy allkeys-lru
    volumes:
      - redis_data:/data
    networks:
      - backend

  proxy:
    image: nginx:1.25-alpine
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/certs:/etc/nginx/certs:ro
    depends_on:
      - app
    networks:
      - backend

volumes:
  postgres_data:
  redis_data:

networks:
  backend:
    driver: bridge
```

### .env Template (always accompany Compose files)
```bash
# .env.example — copy to .env and fill in values; never commit .env
DB_PASSWORD=change_me_in_production
REDIS_PASSWORD=change_me_in_production
```

```gitignore
# .gitignore additions
.env
*.env.local
```

---

## Security Hardening

### Non-Root User (always apply)
```dockerfile
RUN addgroup -S app && adduser -S app -G app
USER app
```

### Read-Only Filesystem
```yaml
# docker-compose.yml
services:
  app:
    read_only: true
    tmpfs:
      - /tmp           # allow writes only to tmpfs
      - /var/cache/app
```

### Drop Capabilities
```yaml
services:
  app:
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE   # only if binding port < 1024
    security_opt:
      - no-new-privileges:true
```

---

## Registry & Image Management

### Tagging Strategy
```bash
# Semantic versioning
docker tag myapp:build-123 myregistry.io/myapp:1.4.2
docker tag myapp:build-123 myregistry.io/myapp:1.4
docker tag myapp:build-123 myregistry.io/myapp:latest  # only on stable releases

# Git SHA (recommended for traceability)
IMAGE_TAG=$(git rev-parse --short HEAD)
docker build -t myregistry.io/myapp:${IMAGE_TAG} .
```

### Image Scanning (run before push)
```bash
# Trivy
trivy image --severity HIGH,CRITICAL --exit-code 1 myapp:latest

# Grype
grype myapp:latest --fail-on high
```
