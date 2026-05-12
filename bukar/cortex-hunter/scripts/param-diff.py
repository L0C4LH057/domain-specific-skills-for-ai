#!/usr/bin/env python3
"""
param-diff.py — Phase 5 Parameter Archaeology helper.

Performs the 3-request diff test from AGENT.md §10:
  A: baseline (no new param)
  B: param with empty value
  C: param with plausible value

Compares response length, JSON structure (new keys), error messages, status,
and timing. Flags suspicious behavior for human review.

Usage:
  ./param-diff.py --url "https://app.example.com/api/v1/user/profile" \\
                  --param debug \\
                  --value true \\
                  --header "Cookie: session=abc123" \\
                  [--method GET|POST] \\
                  [--body '{"x":1}']

Output: JSON diff report to stdout.

⚠️ Cortex rule: only run against in-scope endpoints with the human's session.
"""

import argparse
import json
import sys
import time
from urllib.parse import urlparse, urlencode, parse_qsl, urlunparse

try:
    import requests
except ImportError:
    print("[FAIL] Install requests: pip install requests", file=sys.stderr)
    sys.exit(1)


def make_request(url, method, headers, body, params_extra=None):
    """Send one request, capture key response attributes."""
    parsed = urlparse(url)
    existing_params = dict(parse_qsl(parsed.query))
    if params_extra:
        existing_params.update(params_extra)
    new_query = urlencode(existing_params)
    final_url = urlunparse(parsed._replace(query=new_query))

    t0 = time.monotonic()
    try:
        r = requests.request(
            method=method,
            url=final_url,
            headers=headers,
            data=body,
            timeout=20,
            allow_redirects=False,
        )
        elapsed = time.monotonic() - t0

        body_text = r.text[:10000]  # cap for sanity
        try:
            body_json = r.json() if 'application/json' in r.headers.get('Content-Type', '') else None
        except Exception:
            body_json = None

        return {
            'url': final_url,
            'status': r.status_code,
            'length': len(r.content),
            'elapsed_ms': round(elapsed * 1000, 1),
            'content_type': r.headers.get('Content-Type', ''),
            'body_text': body_text,
            'body_json': body_json,
            'json_keys': sorted(body_json.keys()) if isinstance(body_json, dict) else None,
        }
    except requests.RequestException as e:
        return {'url': final_url, 'error': str(e)}


def diff_responses(base, mod, label):
    """Compare baseline vs modified, surface deltas."""
    deltas = []

    if 'error' in base or 'error' in mod:
        deltas.append(f"network error in {label}")
        return deltas

    if base['status'] != mod['status']:
        deltas.append(f"status: {base['status']} → {mod['status']}")

    len_delta = mod['length'] - base['length']
    if abs(len_delta) > 50:
        deltas.append(f"length: {base['length']} → {mod['length']} ({len_delta:+d} bytes)")

    if base.get('json_keys') and mod.get('json_keys'):
        new_keys = set(mod['json_keys']) - set(base['json_keys'])
        removed_keys = set(base['json_keys']) - set(mod['json_keys'])
        if new_keys:
            deltas.append(f"JSON: new keys appeared: {sorted(new_keys)}")
        if removed_keys:
            deltas.append(f"JSON: keys removed: {sorted(removed_keys)}")

    time_delta = mod['elapsed_ms'] - base['elapsed_ms']
    if abs(time_delta) > 500:
        deltas.append(f"timing: {base['elapsed_ms']}ms → {mod['elapsed_ms']}ms ({time_delta:+.0f}ms)")

    # Error message hints
    error_hints = ['stack trace', 'exception', 'traceback', 'internal server', 'sql', 'syntax error']
    for hint in error_hints:
        if hint in mod.get('body_text', '').lower() and hint not in base.get('body_text', '').lower():
            deltas.append(f"new error indicator: '{hint}' in modified response")

    return deltas


def main():
    ap = argparse.ArgumentParser(description='Cortex Phase 5 — 3-request param diff')
    ap.add_argument('--url', required=True, help='target URL')
    ap.add_argument('--param', required=True, help='parameter name to test')
    ap.add_argument('--value', default='true', help='plausible value (default: true)')
    ap.add_argument('--method', default='GET', choices=['GET', 'POST', 'PUT', 'PATCH', 'DELETE'])
    ap.add_argument('--header', action='append', default=[], help='HTTP header, repeatable')
    ap.add_argument('--body', default=None, help='request body for non-GET')
    ap.add_argument('--json-out', action='store_true', help='emit machine-readable JSON only')
    args = ap.parse_args()

    headers = {}
    for h in args.header:
        if ':' in h:
            k, v = h.split(':', 1)
            headers[k.strip()] = v.strip()

    if not args.json_out:
        print(f"[CORTEX] Param diff — {args.param} on {args.url}")
        print(f"[CORTEX] Sending 3 requests...")

    A = make_request(args.url, args.method, headers, args.body)
    B = make_request(args.url, args.method, headers, args.body, {args.param: ''})
    C = make_request(args.url, args.method, headers, args.body, {args.param: args.value})

    diff_B = diff_responses(A, B, 'B (empty)')
    diff_C = diff_responses(A, C, f'C ({args.value})')

    report = {
        'parameter': args.param,
        'baseline': {k: v for k, v in A.items() if k not in ('body_text', 'body_json')},
        'with_empty': {k: v for k, v in B.items() if k not in ('body_text', 'body_json')},
        'with_value': {k: v for k, v in C.items() if k not in ('body_text', 'body_json')},
        'deltas_empty_vs_baseline': diff_B,
        'deltas_value_vs_baseline': diff_C,
        'verdict': 'SUSPICIOUS' if (diff_B or diff_C) else 'NO CHANGE OBSERVED',
    }

    if args.json_out:
        print(json.dumps(report, indent=2))
    else:
        print()
        print(f"[A] baseline:        status={A.get('status')} length={A.get('length')} ms={A.get('elapsed_ms')}")
        print(f"[B] {args.param}=:    status={B.get('status')} length={B.get('length')} ms={B.get('elapsed_ms')}")
        print(f"[C] {args.param}={args.value}: status={C.get('status')} length={C.get('length')} ms={C.get('elapsed_ms')}")
        print()
        if diff_B:
            print(f"[CORTEX] B vs A deltas:")
            for d in diff_B:
                print(f"  - {d}")
        if diff_C:
            print(f"[CORTEX] C vs A deltas:")
            for d in diff_C:
                print(f"  - {d}")
        if not (diff_B or diff_C):
            print("[CORTEX] No significant deltas. Parameter likely not accepted.")
        else:
            print()
            print("[CORTEX] ⚠️  Parameter shows behavior change. Investigate as suspicious.")


if __name__ == '__main__':
    main()
