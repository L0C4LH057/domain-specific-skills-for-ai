# Observability Reference — Prometheus, Grafana, ELK, Alerting

## Table of Contents
1. [Prometheus](#prometheus)
2. [Grafana](#grafana)
3. [Alerting](#alerting)
4. [ELK / Loki](#elk--loki)
5. [SLOs & Error Budgets](#slos--error-budgets)

---

## Prometheus

### prometheus.yml (core config)
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']

rule_files:
  - "rules/*.yml"

scrape_configs:
  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: "true"
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']
```

### Key PromQL Queries
```promql
# Request rate (per second, 5m window)
rate(http_requests_total[5m])

# Error rate percentage
100 * rate(http_requests_total{status=~"5.."}[5m])
  / rate(http_requests_total[5m])

# P95 latency
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Memory usage percentage
100 * (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes))

# CPU usage
100 - (avg by(instance)(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Pod restarts in last 15m
increase(kube_pod_container_status_restarts_total[15m]) > 0
```

---

## Alerting

### Alertmanager Rules
```yaml
# rules/app-alerts.yml
groups:
  - name: app
    rules:
      - alert: HighErrorRate
        expr: |
          (
            rate(http_requests_total{status=~"5.."}[5m])
            / rate(http_requests_total[5m])
          ) > 0.05
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate on {{ $labels.job }}"
          description: "Error rate is {{ $value | humanizePercentage }} (threshold: 5%)"
          runbook: "https://wiki.example.com/runbooks/high-error-rate"

      - alert: PodCrashLooping
        expr: increase(kube_pod_container_status_restarts_total[15m]) > 3
        for: 0m
        labels:
          severity: warning
        annotations:
          summary: "Pod {{ $labels.pod }} is crash looping"

      - alert: HighMemoryUsage
        expr: |
          container_memory_working_set_bytes
            / container_spec_memory_limit_bytes > 0.85
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Container {{ $labels.container }} memory > 85%"
```

### Alertmanager Config (Slack + PagerDuty)
```yaml
# alertmanager.yml
global:
  slack_api_url: '${SLACK_WEBHOOK_URL}'

route:
  group_by: ['alertname', 'job']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  receiver: slack-warnings
  routes:
    - match:
        severity: critical
      receiver: pagerduty-critical

receivers:
  - name: slack-warnings
    slack_configs:
      - channel: '#alerts'
        send_resolved: true
        title: '{{ .Status | toUpper }} | {{ .CommonLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'

  - name: pagerduty-critical
    pagerduty_configs:
      - service_key: '${PAGERDUTY_KEY}'
        send_resolved: true
```

---

## ELK / Loki

### Filebeat Config (ship logs to Elasticsearch)
```yaml
# filebeat.yml
filebeat.inputs:
  - type: container
    paths:
      - /var/lib/docker/containers/*/*.log
    processors:
      - add_kubernetes_metadata:
          host: ${NODE_NAME}
          matchers:
            - logs_path:
                logs_path: "/var/lib/docker/containers/"

output.elasticsearch:
  hosts: ["elasticsearch:9200"]
  index: "filebeat-%{+yyyy.MM.dd}"

setup.kibana:
  host: "kibana:5601"
```

### Loki + Promtail (lightweight alternative)
```yaml
# promtail-config.yml
server:
  http_listen_port: 9080

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  - job_name: kubernetes-pods
    kubernetes_sd_configs:
      - role: pod
    pipeline_stages:
      - docker: {}
      - json:
          expressions:
            level: level
            msg: message
      - labels:
          level:
```

---

## SLOs & Error Budgets

### SLO Definition Template
```yaml
# slo.yml — document your SLO commitments here
service: payment-api
owner: team-payments

slos:
  - name: availability
    description: "99.9% of requests succeed (non-5xx)"
    sli:
      good_events: 'rate(http_requests_total{status!~"5.."}[28d])'
      total_events: 'rate(http_requests_total[28d])'
    target: 0.999             # 99.9%
    error_budget_minutes: 43  # 43.8 min/month

  - name: latency
    description: "95% of requests complete in < 300ms"
    sli:
      good_events: 'rate(http_request_duration_seconds_bucket{le="0.3"}[28d])'
      total_events: 'rate(http_request_duration_seconds_count[28d])'
    target: 0.95
```

### Error Budget Burn Rate Alert
```promql
# Fast burn: 2% budget in 1 hour = 14.4x burn rate
(
  rate(http_requests_total{status=~"5.."}[1h])
  / rate(http_requests_total[1h])
) / (1 - 0.999) > 14.4
```
