# Networking Reference

## Table of Contents
1. [NGINX Configuration](#nginx-configuration)
2. [TLS & cert-manager](#tls--cert-manager)
3. [Service Mesh (Istio)](#service-mesh-istio)
4. [DNS Patterns](#dns-patterns)
5. [Firewall & Security Groups](#firewall--security-groups)

---

## NGINX Configuration

### Reverse Proxy (Production)
```nginx
# /etc/nginx/sites-available/my-app.conf
upstream app_backend {
    server 127.0.0.1:3000;
    server 127.0.0.1:3001;
    keepalive 32;
}

server {
    listen 80;
    server_name app.example.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name app.example.com;

    # TLS
    ssl_certificate     /etc/letsencrypt/live/app.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/app.example.com/privkey.pem;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
    ssl_prefer_server_ciphers off;
    ssl_session_cache   shared:SSL:10m;
    ssl_session_timeout 1d;

    # Security headers
    add_header Strict-Transport-Security "max-age=63072000" always;
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header Referrer-Policy "strict-origin-when-cross-origin";
    add_header Content-Security-Policy "default-src 'self'";

    # Proxy settings
    location / {
        proxy_pass         http://app_backend;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade $http_upgrade;
        proxy_set_header   Connection 'upgrade';
        proxy_set_header   Host $host;
        proxy_set_header   X-Real-IP $remote_addr;
        proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }

    # Static assets with caching
    location /static/ {
        alias /var/www/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Health check endpoint (skip logging)
    location /healthz {
        proxy_pass http://app_backend;
        access_log off;
    }

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;
    location /api/ {
        limit_req zone=api_limit burst=20 nodelay;
        proxy_pass http://app_backend;
    }
}
```

### NGINX Ingress Controller (Kubernetes Annotations)
```yaml
metadata:
  annotations:
    # SSL redirect
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    # Rate limiting
    nginx.ingress.kubernetes.io/limit-rps: "10"
    nginx.ingress.kubernetes.io/limit-connections: "5"
    # CORS
    nginx.ingress.kubernetes.io/enable-cors: "true"
    nginx.ingress.kubernetes.io/cors-allow-origin: "https://app.example.com"
    # Body size
    nginx.ingress.kubernetes.io/proxy-body-size: "10m"
    # Timeouts
    nginx.ingress.kubernetes.io/proxy-read-timeout: "300"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "300"
    # WebSocket support
    nginx.ingress.kubernetes.io/proxy-http-version: "1.1"
    nginx.ingress.kubernetes.io/configuration-snippet: |
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection "upgrade";
```

---

## TLS & cert-manager

### cert-manager Install
```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set installCRDs=true
```

### ClusterIssuer (Let's Encrypt)
```yaml
# letsencrypt-prod issuer
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-prod-key
    solvers:
      - http01:
          ingress:
            class: nginx
---
# Staging (for testing — no rate limits)
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-staging-key
    solvers:
      - http01:
          ingress:
            class: nginx
```

### Certificate Resource (Manual)
```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: app-tls
  namespace: production
spec:
  secretName: app-tls-secret
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
    - app.example.com
    - api.example.com
```

### Check Certificate Status
```bash
kubectl get certificates -n production
kubectl describe certificate app-tls -n production
kubectl get certificaterequest -n production
kubectl get orders -n production
```

---

## Service Mesh (Istio)

### Install Istio
```bash
curl -L https://istio.io/downloadIstio | sh -
istioctl install --set profile=default -y
kubectl label namespace production istio-injection=enabled
```

### Traffic Management — VirtualService + DestinationRule
```yaml
# VirtualService: Route 90% to v1, 10% to v2 (canary)
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: my-app
  namespace: production
spec:
  hosts:
    - my-app
  http:
    - match:
        - headers:
            x-canary:
              exact: "true"
      route:
        - destination:
            host: my-app
            subset: v2
    - route:
        - destination:
            host: my-app
            subset: v1
          weight: 90
        - destination:
            host: my-app
            subset: v2
          weight: 10
      retries:
        attempts: 3
        perTryTimeout: 10s
      timeout: 30s
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: my-app
  namespace: production
spec:
  host: my-app
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        http1MaxPendingRequests: 100
        http2MaxRequests: 1000
    outlierDetection:
      consecutiveGatewayErrors: 5
      interval: 30s
      baseEjectionTime: 30s
  subsets:
    - name: v1
      labels:
        version: v1
    - name: v2
      labels:
        version: v2
```

### mTLS (Peer Authentication)
```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: production
spec:
  mtls:
    mode: STRICT  # All communication must use mTLS
```

---

## DNS Patterns

### ExternalDNS (Auto-manage Route53 from K8s)
```bash
helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/
helm install external-dns external-dns/external-dns \
  --namespace kube-system \
  --set provider=aws \
  --set aws.zoneType=public \
  --set txtOwnerId=my-cluster \
  --set domainFilters[0]=example.com
```

### CoreDNS Custom Config (K8s)
```yaml
# Add to ConfigMap coredns in kube-system
.:53 {
    forward . /etc/resolv.conf
    cache 30
    loop
    reload
    loadbalance
}

internal.example.com:53 {
    forward . 10.0.0.53  # Internal DNS server
}
```

---

## Firewall & Security Groups

### AWS Security Group (Terraform)
```hcl
# ALB Security Group — public traffic
resource "aws_security_group" "alb" {
  name   = "${local.name_prefix}-alb-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = local.common_tags
}

# App Security Group — only from ALB
resource "aws_security_group" "app" {
  name   = "${local.name_prefix}-app-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]  # Only from ALB
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = local.common_tags
}

# RDS Security Group — only from app
resource "aws_security_group" "rds" {
  name   = "${local.name_prefix}-rds-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]  # Only from app
  }
  tags = local.common_tags
}
```

### UFW (Ubuntu Firewall)
```bash
# Default deny incoming
ufw default deny incoming
ufw default allow outgoing

# Allow specific ports
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS

# Allow from specific IP
ufw allow from 10.0.0.0/8 to any port 5432  # Postgres from VPC only

ufw enable
ufw status verbose
```
