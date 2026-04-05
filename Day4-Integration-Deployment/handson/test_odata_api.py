#!/usr/bin/env python3
"""
=============================================================
  Test Script — OData API on SAP BTP Cloud Foundry
  Workshop: Hands-On TEC Rise — Day 4
  Deployed App: CAP Bookshop + HANA Cloud + XSUAA
  Author: Wahyu Amaldi — Technical Lead SAP & Full Stack Development
=============================================================

Usage:
  python3 test_odata_api.py

Sebelum menjalankan, set environment variables:
  export XSUAA_CLIENT_ID='sb-bookshop-...'
  export XSUAA_CLIENT_SECRET='...'
  export XSUAA_TOKEN_URL='https://<subdomain>.authentication.<region>.hana.ondemand.com/oauth/token'
  export APP_URL='https://<app-route>.cfapps.<region>.hana.ondemand.com'

Atau edit bagian CONFIG di bawah.
"""

import os
import sys
import json
import urllib.request
import urllib.parse
import urllib.error
import ssl
import time

# ============================================================
# CONFIG — edit sesuai deployment kamu, atau pakai env vars
# ============================================================
APP_URL = os.environ.get(
    "APP_URL",
    "https://3220086dtrial-dev-bookshop-srv.cfapps.ap21.hana.ondemand.com"
)
XSUAA_CLIENT_ID = os.environ.get(
    "XSUAA_CLIENT_ID",
    "sb-bookshop-3220086dtrial-dev!t116032"
)
XSUAA_CLIENT_SECRET = os.environ.get("XSUAA_CLIENT_SECRET", "")
XSUAA_TOKEN_URL = os.environ.get(
    "XSUAA_TOKEN_URL",
    "https://3220086dtrial.authentication.ap21.hana.ondemand.com/oauth/token"
)

# ============================================================
# HELPERS
# ============================================================
PASS = "\033[92m✅ PASS\033[0m"
FAIL = "\033[91m❌ FAIL\033[0m"
WARN = "\033[93m⚠️  WARN\033[0m"
BOLD = "\033[1m"
RESET = "\033[0m"

ctx = ssl.create_default_context()
# macOS Python sering tidak punya root CA certificates yang lengkap.
# Jika ada error SSL, gunakan certifi atau fallback ke unverified (hanya untuk testing).
try:
    import certifi
    ctx.load_verify_locations(certifi.where())
except ImportError:
    # Fallback: skip SSL verification (hanya untuk workshop/testing)
    ctx = ssl._create_unverified_context()

results = []


def header(title):
    print(f"\n{'='*60}")
    print(f"  {BOLD}{title}{RESET}")
    print(f"{'='*60}")


def get_oauth_token():
    """Get OAuth2 access token via client_credentials grant."""
    data = urllib.parse.urlencode({
        "grant_type": "client_credentials",
        "client_id": XSUAA_CLIENT_ID,
        "client_secret": XSUAA_CLIENT_SECRET,
    }).encode()
    req = urllib.request.Request(XSUAA_TOKEN_URL, data=data, method="POST")
    req.add_header("Content-Type", "application/x-www-form-urlencoded")
    with urllib.request.urlopen(req, context=ctx) as resp:
        body = json.loads(resp.read())
    return body["access_token"]


def api_call(path, token=None, expect_status=200):
    """Call an OData endpoint and return (status_code, body_text)."""
    url = f"{APP_URL}{path}"
    req = urllib.request.Request(url)
    if token:
        req.add_header("Authorization", f"Bearer {token}")
    try:
        with urllib.request.urlopen(req, context=ctx) as resp:
            return resp.status, resp.read().decode()
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()


def test(name, status, body, expect_status=200, check_fn=None):
    """Evaluate a test case and print result."""
    ok = status == expect_status
    if ok and check_fn:
        ok = check_fn(body)
    tag = PASS if ok else FAIL
    results.append(ok)
    print(f"  {tag}  {name}  (HTTP {status})")
    return ok


# ============================================================
# TESTS
# ============================================================
def main():
    header("SAP BTP OData API Test Suite")
    print(f"  App URL:  {APP_URL}")
    print(f"  Token URL: {XSUAA_TOKEN_URL}")
    print(f"  Client ID: {XSUAA_CLIENT_ID[:30]}...")

    # ----------------------------------------------------------
    # 0) Pre-check: client secret
    # ----------------------------------------------------------
    if not XSUAA_CLIENT_SECRET:
        print(f"\n  {FAIL}  XSUAA_CLIENT_SECRET tidak di-set!")
        print("  Set via: export XSUAA_CLIENT_SECRET='...'")
        sys.exit(1)

    # ----------------------------------------------------------
    # Test 1: Unauthorized access (tanpa token)
    # ----------------------------------------------------------
    header("Test 1: Unauthorized Access (tanpa token)")
    status, body = api_call("/odata/v4/catalog/Books")
    test("GET /catalog/Books tanpa token → 401", status, body, expect_status=401)

    # ----------------------------------------------------------
    # Test 2: Get OAuth Token
    # ----------------------------------------------------------
    header("Test 2: OAuth Token (client_credentials)")
    try:
        t0 = time.time()
        token = get_oauth_token()
        elapsed = time.time() - t0
        print(f"  {PASS}  Token diperoleh ({len(token)} chars, {elapsed:.2f}s)")
        results.append(True)
    except Exception as e:
        print(f"  {FAIL}  Gagal mendapat token: {e}")
        results.append(False)
        sys.exit(1)

    # ----------------------------------------------------------
    # Test 3: GET /odata/v4/catalog/Books
    # ----------------------------------------------------------
    header("Test 3: GET /odata/v4/catalog/Books")
    status, body = api_call("/odata/v4/catalog/Books", token)
    test("Status 200 OK", status, body)

    data = json.loads(body)
    books = data.get("value", [])
    test(
        f"Response contains books (found {len(books)})",
        status, body,
        check_fn=lambda b: len(json.loads(b).get("value", [])) > 0,
    )

    print(f"\n  📚 Books dari HANA Cloud:")
    for b in books:
        print(f"     {b['ID']:>3}  {b['title']:<25} {b.get('author',''):<20} {b.get('price','')} {b.get('currency_code','')}")

    # ----------------------------------------------------------
    # Test 4: GET /odata/v4/catalog/Books/$count
    # ----------------------------------------------------------
    header("Test 4: GET /odata/v4/catalog/Books/$count")
    status, body = api_call("/odata/v4/catalog/Books/$count", token)
    test("Status 200 OK", status, body)
    test(
        f"Count = {body.strip()}",
        status, body,
        check_fn=lambda b: b.strip().isdigit() and int(b.strip()) > 0,
    )

    # ----------------------------------------------------------
    # Test 5: OData $filter
    # ----------------------------------------------------------
    header("Test 5: OData $filter (price gt 13)")
    path = "/odata/v4/catalog/Books?$filter=" + urllib.parse.quote("price gt 13")
    status, body = api_call(path, token)
    test("Status 200 OK", status, body)

    filtered = json.loads(body).get("value", [])
    test(
        f"Filtered books count = {len(filtered)} (expected 3)",
        status, body,
        check_fn=lambda b: len(json.loads(b).get("value", [])) == 3,
    )
    for b in filtered:
        print(f"     → {b['title']:<25} price: {b['price']}")

    # ----------------------------------------------------------
    # Test 6: OData $select
    # ----------------------------------------------------------
    header("Test 6: OData $select (title, author)")
    status, body = api_call("/odata/v4/catalog/Books?$select=title,author", token)
    test("Status 200 OK", status, body)

    item = json.loads(body).get("value", [{}])[0]
    has_title = "title" in item
    has_no_stock = "stock" not in item
    test(
        f"Response has 'title' but no 'stock'",
        status, body,
        check_fn=lambda b: has_title and has_no_stock,
    )

    # ----------------------------------------------------------
    # Test 7: OData $top & $skip
    # ----------------------------------------------------------
    header("Test 7: OData $top=2&$skip=1")
    status, body = api_call("/odata/v4/catalog/Books?$top=2&$skip=1", token)
    test("Status 200 OK", status, body)

    paged = json.loads(body).get("value", [])
    test(
        f"Returned {len(paged)} books (expected 2)",
        status, body,
        check_fn=lambda b: len(json.loads(b).get("value", [])) == 2,
    )

    # ----------------------------------------------------------
    # Test 8: OData $orderby
    # ----------------------------------------------------------
    header("Test 8: OData $orderby=price desc")
    path = "/odata/v4/catalog/Books?$orderby=" + urllib.parse.quote("price desc") + "&$select=title,price"
    status, body = api_call(path, token)
    test("Status 200 OK", status, body)

    ordered = json.loads(body).get("value", [])
    if ordered:
        prices = [float(b["price"]) for b in ordered]
        test(
            f"Prices descending: {prices}",
            status, body,
            check_fn=lambda b: prices == sorted(prices, reverse=True),
        )
        for b in ordered:
            print(f"     → {b['title']:<25} price: {b['price']}")

    # ----------------------------------------------------------
    # Test 9: OData $metadata
    # ----------------------------------------------------------
    header("Test 9: GET /odata/v4/catalog/$metadata")
    status, body = api_call("/odata/v4/catalog/$metadata", token)
    test("Status 200 OK", status, body)
    test(
        "Contains EntityType 'Books'",
        status, body,
        check_fn=lambda b: "Books" in b and "EntityType" in b,
    )

    # ----------------------------------------------------------
    # Test 10: Service root
    # ----------------------------------------------------------
    header("Test 10: GET /odata/v4/catalog/")
    status, body = api_call("/odata/v4/catalog/", token)
    test("Status 200 OK", status, body)

    svc = json.loads(body)
    entities = [e["name"] for e in svc.get("value", [])]
    test(
        f"Service entities: {entities}",
        status, body,
        check_fn=lambda b: len(json.loads(b).get("value", [])) > 0,
    )

    # ----------------------------------------------------------
    # SUMMARY
    # ----------------------------------------------------------
    header("TEST SUMMARY")
    passed = sum(results)
    total = len(results)
    pct = (passed / total * 100) if total else 0

    for i, r in enumerate(results, 1):
        tag = PASS if r else FAIL
        print(f"  {tag}  Test assertion #{i}")

    print(f"\n  {BOLD}Result: {passed}/{total} passed ({pct:.0f}%){RESET}")

    if passed == total:
        print(f"\n  🎉 ALL TESTS PASSED — App berjalan sempurna di BTP Cloud!")
    else:
        print(f"\n  ⚠️  {total - passed} test(s) failed")

    return 0 if passed == total else 1


if __name__ == "__main__":
    sys.exit(main())
