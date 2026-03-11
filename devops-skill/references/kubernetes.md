# Kubernetes Reference — Manifests, Helm & Operations

## Table of Contents
1. [Core Manifests](#core-manifests)
2. [Networking](#networking)
3. [RBAC](#rbac)
4. [Helm](#helm)
5. [Autoscaling](#autoscaling)
6. [Common kubectl Commands](#common-kubectl-commands)

---

## Core Manifests

### Deployment (Production Template)
```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: production
  labels:
    app: myapp
    version: "1.4.2"
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0       # zero-downtime: never kill a pod before a new one is ready
  template:
    metadata:
      labels:
        app: myapp
        version: "1.4.2"
    spec:
      serviceAccountName: myapp-sa
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 2000
      containers:
        - name: app
          image: registry.example.com/myapp:1.4.2   # always pin; never :latest
          ports:
            - containerPort: 3000
          env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: myapp-secrets
                  key: database_url
            - name: LOG_LEVEL
              valueFrom:
                configMapKeyRef:
                  name: myapp-config
                  key: log_level
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 512Mi
          livenessProbe:
            httpGet:
              path: /health/live
              port: 3000
            initialDelaySeconds: 15
            periodSeconds: 20
            failureThreshold: 3
          readinessProbe:
            httpGet:
              path: /health/ready
              port: 3000
            initialDelaySeconds: 5
            periodSeconds: 10
            failureThreshold: 3
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop: ["ALL"]
          volumeMounts:
            - name: tmp
              mountPath: /tmp
      volumes:
        - name: tmp
          emptyDir: {}
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: kubernetes.io/hostname
          whenUnsatisfiable: DoNotSchedule
          labelSelector:
            matchLabels:
              app: myapp
```

### Service
```yaml
# service.yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp
  namespace: production
spec:
  selector:
    app: myapp
  ports:
    - port: 80
      targetPort: 3000
      protocol: TCP
  type: ClusterIP    # use LoadBalancer or NodePort only at the edge; prefer Ingress
```

### ConfigMap & Secret
```yaml
# configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: myapp-config
  namespace: production
data:
  log_level: "info"
  max_connections: "100"
---
# secret.yaml — store actual values in Vault/SealedSecrets, not plain YAML
apiVersion: v1
kind: Secret
metadata:
  name: myapp-secrets
  namespace: production
type: Opaque
# Use SealedSecrets or External Secrets Operator for GitOps:
# kubectl create secret generic myapp-secrets --from-literal=database_url=... --dry-run=client -o yaml | kubeseal
```

### PodDisruptionBudget (always add for production)
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: myapp-pdb
  namespace: production
spec:
  minAvailable: 2     # or maxUnavailable: 1
  selector:
    matchLabels:
      app: myapp
```

---

## Networking

### Ingress (NGINX)
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp
  namespace: production
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - myapp.example.com
      secretName: myapp-tls
  rules:
    - host: myapp.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: myapp
                port:
                  number: 80
```

### NetworkPolicy (default-deny + allow)
```yaml
# deny all ingress by default
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: production
spec:
  podSelector: {}
  policyTypes: [Ingress]
---
# allow only from ingress controller
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-controller
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: myapp
  policyTypes: [Ingress]
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: ingress-nginx
```

---

## RBAC

### ServiceAccount + Role + Binding
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: myapp-sa
  namespace: production
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/myapp-role  # IRSA for AWS
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: myapp-role
  namespace: production
rules:
  - apiGroups: [""]
    resources: ["configmaps", "secrets"]
    verbs: ["get", "list"]    # least privilege: only what the app needs
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: myapp-rolebinding
  namespace: production
subjects:
  - kind: ServiceAccount
    name: myapp-sa
    namespace: production
roleRef:
  kind: Role
  name: myapp-role
  apiGroup: rbac.authorization.k8s.io
```

---

## Helm

### Chart Structure
```
mychart/
├── Chart.yaml
├── values.yaml
├── values-staging.yaml
├── values-production.yaml
└── templates/
    ├── _helpers.tpl
    ├── deployment.yaml
    ├── service.yaml
    ├── ingress.yaml
    ├── configmap.yaml
    ├── hpa.yaml
    └── NOTES.txt
```

### values.yaml Pattern
```yaml
# values.yaml — defaults; override per environment
replicaCount: 2
image:
  repository: registry.example.com/myapp
  tag: ""        # set at deploy time: helm upgrade --set image.tag=1.4.2
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: true
  className: nginx
  host: myapp.example.com

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi

autoscaling:
  enabled: false
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
```

### Common Helm Commands
```bash
# Install / upgrade (always use --atomic for safe rollbacks)
helm upgrade --install myapp ./mychart \
  --namespace production \
  --create-namespace \
  --values values-production.yaml \
  --set image.tag=$IMAGE_TAG \
  --atomic \
  --timeout 5m

# Rollback
helm rollback myapp 1 --namespace production

# Diff (requires helm-diff plugin)
helm diff upgrade myapp ./mychart -f values-production.yaml
```

---

## Autoscaling

### HPA (CPU/Memory)
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: myapp-hpa
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  minReplicas: 2
  maxReplicas: 20
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300   # prevent flapping
      policies:
        - type: Pods
          value: 1
          periodSeconds: 60
```

---

## Common kubectl Commands

```bash
# Context & namespace
kubectl config get-contexts
kubectl config use-context my-cluster
kubectl config set-context --current --namespace=production

# Debugging
kubectl get pods -n production -o wide
kubectl describe pod <pod-name> -n production
kubectl logs <pod-name> -n production --previous   # crashed container logs
kubectl exec -it <pod-name> -n production -- sh

# Rollout management
kubectl rollout status deployment/myapp -n production
kubectl rollout history deployment/myapp -n production
kubectl rollout undo deployment/myapp -n production

# Resource usage
kubectl top pods -n production
kubectl top nodes

# Port forward for local debugging
kubectl port-forward svc/myapp 8080:80 -n production
```
