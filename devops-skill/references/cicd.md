# CI/CD Pipelines Reference

## Table of Contents
1. [GitHub Actions](#github-actions)
2. [GitLab CI/CD](#gitlab-cicd)
3. [Jenkins](#jenkins)
4. [Pipeline Design Principles](#pipeline-design-principles)
5. [Common Pipeline Patterns](#common-pipeline-patterns)

---

## GitHub Actions

### Complete Node.js Pipeline (Build → Test → Docker → Deploy)
```yaml
# .github/workflows/ci-cd.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  test:
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run linter
        run: npm run lint

      - name: Run tests
        run: npm test -- --coverage

      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          token: ${{ secrets.CODECOV_TOKEN }}

  build-and-push:
    needs: test
    runs-on: ubuntu-22.04
    if: github.ref == 'refs/heads/main'
    permissions:
      contents: read
      packages: write

    steps:
      - uses: actions/checkout@v4

      - name: Login to registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=sha,prefix=,suffix=,format=short
            type=ref,event=branch
            type=semver,pattern={{version}}

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  deploy:
    needs: build-and-push
    runs-on: ubuntu-22.04
    environment: production

    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Update kubeconfig
        run: aws eks update-kubeconfig --name my-cluster --region us-east-1

      - name: Deploy to Kubernetes
        run: |
          kubectl set image deployment/myapp \
            app=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }} \
            --namespace=production
          kubectl rollout status deployment/myapp --namespace=production --timeout=5m
```

### Reusable Workflow (caller/callee pattern)
```yaml
# .github/workflows/reusable-deploy.yml
name: Reusable Deploy

on:
  workflow_call:
    inputs:
      environment:
        required: true
        type: string
      image_tag:
        required: true
        type: string
    secrets:
      KUBE_CONFIG:
        required: true

jobs:
  deploy:
    runs-on: ubuntu-22.04
    environment: ${{ inputs.environment }}
    steps:
      - name: Deploy
        run: |
          echo "${{ secrets.KUBE_CONFIG }}" | base64 -d > kubeconfig.yaml
          export KUBECONFIG=kubeconfig.yaml
          kubectl set image deployment/myapp app=myimage:${{ inputs.image_tag }}
```

### Matrix Build (multi-version testing)
```yaml
jobs:
  test:
    strategy:
      matrix:
        node: ['18', '20', '22']
        os: [ubuntu-22.04, windows-latest]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node }}
      - run: npm ci && npm test
```

---

## GitLab CI/CD

### Complete Pipeline
```yaml
# .gitlab-ci.yml
stages:
  - lint
  - test
  - build
  - scan
  - deploy

variables:
  DOCKER_DRIVER: overlay2
  IMAGE_TAG: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA

default:
  image: node:20-alpine
  cache:
    paths:
      - node_modules/

lint:
  stage: lint
  script:
    - npm ci
    - npm run lint

test:
  stage: test
  script:
    - npm ci
    - npm test -- --coverage
  coverage: '/Lines\s*:\s*(\d+(?:\.\d+)?)%/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml

build:
  stage: build
  image: docker:24
  services:
    - docker:24-dind
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - docker build -t $IMAGE_TAG .
    - docker push $IMAGE_TAG
  only:
    - main

scan:
  stage: scan
  image:
    name: aquasec/trivy:latest
    entrypoint: [""]
  script:
    - trivy image --exit-code 1 --severity HIGH,CRITICAL $IMAGE_TAG
  needs: [build]

deploy_staging:
  stage: deploy
  environment:
    name: staging
    url: https://staging.example.com
  script:
    - kubectl set image deployment/myapp app=$IMAGE_TAG --namespace=staging
  only:
    - main

deploy_prod:
  stage: deploy
  environment:
    name: production
    url: https://example.com
  script:
    - kubectl set image deployment/myapp app=$IMAGE_TAG --namespace=production
  when: manual
  only:
    - main
```

---

## Jenkins

### Declarative Pipeline (Jenkinsfile)
```groovy
// Jenkinsfile
pipeline {
    agent {
        kubernetes {
            yaml '''
                apiVersion: v1
                kind: Pod
                spec:
                  containers:
                  - name: docker
                    image: docker:24-dind
                    securityContext:
                      privileged: true
                  - name: kubectl
                    image: bitnami/kubectl:1.29
                    command: [sleep, infinity]
            '''
        }
    }

    environment {
        REGISTRY = 'registry.example.com'
        IMAGE    = "${REGISTRY}/myapp:${GIT_COMMIT[0..7]}"
    }

    options {
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {
        stage('Test') {
            steps {
                sh 'npm ci && npm test'
            }
            post {
                always {
                    junit 'test-results/**/*.xml'
                }
            }
        }

        stage('Build & Push') {
            when { branch 'main' }
            steps {
                container('docker') {
                    withCredentials([usernamePassword(
                        credentialsId: 'registry-creds',
                        usernameVariable: 'USER',
                        passwordVariable: 'PASS'
                    )]) {
                        sh '''
                            docker login -u $USER -p $PASS $REGISTRY
                            docker build -t $IMAGE .
                            docker push $IMAGE
                        '''
                    }
                }
            }
        }

        stage('Deploy') {
            when { branch 'main' }
            steps {
                container('kubectl') {
                    withKubeConfig([credentialsId: 'kube-config']) {
                        sh "kubectl set image deployment/myapp app=$IMAGE -n production"
                        sh "kubectl rollout status deployment/myapp -n production"
                    }
                }
            }
        }
    }

    post {
        failure {
            slackSend channel: '#alerts', color: 'danger',
                      message: "Pipeline FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
        }
    }
}
```

---

## Pipeline Design Principles

### Stage Order (Non-negotiable)
```
commit → lint → unit-test → build → integration-test → security-scan → staging-deploy → smoke-test → prod-deploy
```

### Release Strategies
| Strategy | How | When to Use |
|---|---|---|
| Rolling | Replace pods one by one | Default; zero downtime for stateless apps |
| Blue/Green | Run two identical envs; swap traffic | Instant rollback; needs 2x resources |
| Canary | Send % of traffic to new version | Risk mitigation; needs service mesh |
| Feature Flags | Toggle in code, no redeploy | Fine-grained control; LaunchDarkly/Flagsmith |

### Environment Variable Naming Convention
```
APP_NAME           # application identifier
APP_ENV            # dev | staging | prod
DATABASE_URL       # full connection string (from secret)
LOG_LEVEL          # debug | info | warn | error
PORT               # application port
```
