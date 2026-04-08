#!/bin/bash
# ============================================
# SIT Test Script — PO Request Management
# Automated API testing via curl
# ============================================
# Usage:
#   cd Day3-Extensibility/po-project-sit
#   chmod +x sit-test-curl.sh
#   ./sit-test-curl.sh
#
# Prerequisite: cds watch running on localhost:4004
# ============================================

BASE_URL="http://localhost:4004/po"
PASS=0
FAIL=0
SKIP=0

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo ""
    echo "============================================"
    echo -e "${CYAN}$1${NC}"
    echo "============================================"
}

assert_contains() {
    local test_name="$1"
    local response="$2"
    local expected="$3"

    if echo "$response" | grep -q "$expected"; then
        echo -e "  ${GREEN}✅ PASS${NC} — $test_name"
        PASS=$((PASS + 1))
    else
        echo -e "  ${RED}❌ FAIL${NC} — $test_name (expected: '$expected')"
        FAIL=$((FAIL + 1))
    fi
}

assert_http_code() {
    local test_name="$1"
    local actual_code="$2"
    local expected_code="$3"

    if [ "$actual_code" = "$expected_code" ]; then
        echo -e "  ${GREEN}✅ PASS${NC} — $test_name (HTTP $actual_code)"
        PASS=$((PASS + 1))
    else
        echo -e "  ${RED}❌ FAIL${NC} — $test_name (expected HTTP $expected_code, got $actual_code)"
        FAIL=$((FAIL + 1))
    fi
}

assert_count() {
    local test_name="$1"
    local response="$2"
    local expected_count="$3"

    local actual_count=$(echo "$response" | python3 -c "import sys,json; data=json.load(sys.stdin); print(len(data.get('value',[])))" 2>/dev/null)
    if [ "$actual_count" = "$expected_count" ]; then
        echo -e "  ${GREEN}✅ PASS${NC} — $test_name (count=$actual_count)"
        PASS=$((PASS + 1))
    else
        echo -e "  ${RED}❌ FAIL${NC} — $test_name (expected $expected_count records, got $actual_count)"
        FAIL=$((FAIL + 1))
    fi
}

# ============================================
# Check server is running
# ============================================
print_header "Pre-check: Server Running?"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$BASE_URL/PORequests" 2>/dev/null)
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "  ${GREEN}✅ Server running at $BASE_URL${NC}"
else
    echo -e "  ${RED}❌ Server NOT running (HTTP $HTTP_CODE)${NC}"
    echo -e "  ${YELLOW}→ Jalankan 'cds watch' dulu di po-project directory${NC}"
    exit 1
fi

# ============================================
# SIT-01: OData Service Tests
# ============================================
print_header "SIT-01: OData Service Metadata"

RESPONSE=$(curl -s --max-time 10 "$BASE_URL/\$metadata" 2>/dev/null)
assert_contains "Metadata accessible" "$RESPONSE" "edmx:Edmx"
assert_contains "Entity PORequests" "$RESPONSE" "PORequests"
assert_contains "Entity PORequestItems" "$RESPONSE" "PORequestItems"
assert_contains "Action postToSAP" "$RESPONSE" "postToSAP"
assert_contains "Function getSAPSuppliers" "$RESPONSE" "getSAPSuppliers"
assert_contains "Function testSAPConnection" "$RESPONSE" "testSAPConnection"

# ============================================
print_header "SIT-01: Read PO Requests"

RESPONSE=$(curl -s --max-time 10 "$BASE_URL/PORequests" 2>/dev/null)
assert_count "3 seed records" "$RESPONSE" "3"
assert_contains "REQ-260001 exists" "$RESPONSE" "REQ-260001"
assert_contains "REQ-260002 exists" "$RESPONSE" "REQ-260002"
assert_contains "REQ-260003 exists" "$RESPONSE" "REQ-260003"
assert_contains "Laptop description" "$RESPONSE" "Pengadaan Laptop Kantor Jakarta"

# ============================================
print_header "SIT-01: Read Items (\$expand)"

RESPONSE=$(curl -s --max-time 10 "$BASE_URL/PORequests(b1c2d3e4-f5a6-7890-bcde-f12345670001)?\$expand=items" 2>/dev/null)
assert_contains "REQ-260001 loaded" "$RESPONSE" "REQ-260001"
assert_contains "Item EWMS4-01" "$RESPONSE" "EWMS4-01"

RESPONSE=$(curl -s --max-time 10 "$BASE_URL/PORequests(b1c2d3e4-f5a6-7890-bcde-f12345670002)?\$expand=items" 2>/dev/null)
assert_contains "REQ-260002 has EWMS4-02" "$RESPONSE" "EWMS4-02"
assert_contains "REQ-260002 has EWMS4-01" "$RESPONSE" "EWMS4-01"

# ============================================
print_header "SIT-01: OData Query Options"

# Filter
RESPONSE=$(curl -s --max-time 10 "$BASE_URL/PORequests?\$filter=status%20eq%20'D'" 2>/dev/null)
DRAFT_COUNT=$(echo "$RESPONSE" | python3 -c "import sys,json; data=json.load(sys.stdin); print(len(data.get('value',[])))" 2>/dev/null)
if [ "$DRAFT_COUNT" -ge "2" ] 2>/dev/null; then
    echo -e "  ${GREEN}✅ PASS${NC} — \$filter status=D ($DRAFT_COUNT drafts)"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC} — \$filter status=D (expected >=2, got $DRAFT_COUNT)"
    FAIL=$((FAIL + 1))
fi

# Select
RESPONSE=$(curl -s --max-time 10 "$BASE_URL/PORequests?\$select=requestNo,status" 2>/dev/null)
assert_contains "\$select works" "$RESPONSE" "requestNo"

# Count
COUNT=$(curl -s --max-time 10 "$BASE_URL/PORequests/\$count" 2>/dev/null)
if [ "$COUNT" -ge "3" ] 2>/dev/null; then
    echo -e "  ${GREEN}✅ PASS${NC} — \$count = $COUNT (>=3)"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC} — \$count (expected >=3, got '$COUNT')"
    FAIL=$((FAIL + 1))
fi

# ============================================
print_header "SIT-01: Create PO Request"

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/PORequests" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "SIT Auto Test PO",
    "companyCode": "1710",
    "purchasingOrg": "1710",
    "purchasingGroup": "001",
    "supplier": "17300001",
    "supplierName": "SIT Test Supplier",
    "deliveryDate": "2026-08-01",
    "currency": "USD"
  }' 2>/dev/null)

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | sed '$d')

assert_http_code "POST /PORequests → 201" "$HTTP_CODE" "201"
assert_contains "requestNo auto-generated" "$BODY" "REQ-26"
assert_contains "status = D" "$BODY" '"D"'

# Extract ID for next tests
NEW_PO_ID=$(echo "$BODY" | python3 -c "import sys,json; print(json.load(sys.stdin).get('ID',''))" 2>/dev/null)

if [ -n "$NEW_PO_ID" ]; then
    echo -e "  ${CYAN}→ Created PO ID: $NEW_PO_ID${NC}"

    # Create item
    ITEM_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/PORequests($NEW_PO_ID)/items" \
      -H "Content-Type: application/json" \
      -d '{
        "materialNo": "EWMS4-01",
        "description": "SIT Test Item",
        "quantity": 5,
        "uom": "PC",
        "unitPrice": 200.00,
        "plant": "1710",
        "materialGroup": "L001"
      }' 2>/dev/null)

    ITEM_CODE=$(echo "$ITEM_RESPONSE" | tail -1)
    ITEM_BODY=$(echo "$ITEM_RESPONSE" | sed '$d')

    assert_http_code "POST item → 201" "$ITEM_CODE" "201"
    assert_contains "netAmount auto-calc 1000" "$ITEM_BODY" "1000"
    assert_contains "itemNo auto-generated" "$ITEM_BODY" '"itemNo":10'

    # Verify totalAmount updated
    PARENT=$(curl -s --max-time 10 "$BASE_URL/PORequests($NEW_PO_ID)" 2>/dev/null)
    assert_contains "totalAmount = 1000" "$PARENT" "1000"
fi

# ============================================
print_header "SIT-01: Validation Tests"

# Delivery date before order date
VAL_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/PORequests" \
  -H "Content-Type: application/json" \
  -d '{"description":"Validation Test","orderDate":"2026-05-01","deliveryDate":"2026-04-01","supplier":"17300001"}' 2>/dev/null)
VAL_CODE=$(echo "$VAL_RESPONSE" | tail -1)
assert_http_code "Delivery < Order → 400" "$VAL_CODE" "400"

# Block edit Posted PO
EDIT_RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/PORequests(b1c2d3e4-f5a6-7890-bcde-f12345670003)" \
  -H "Content-Type: application/json" \
  -d '{"description":"Should fail"}' 2>/dev/null)
EDIT_CODE=$(echo "$EDIT_RESPONSE" | tail -1)
assert_http_code "Edit Posted PO → 400" "$EDIT_CODE" "400"

# ============================================
print_header "SIT-03: SAP Connection Test"

SAP_RESPONSE=$(curl -s --max-time 15 "$BASE_URL/testSAPConnection()" 2>/dev/null)
if echo "$SAP_RESPONSE" | grep -q '"ok":true'; then
    echo -e "  ${GREEN}✅ PASS${NC} — SAP Connection OK"
    PASS=$((PASS + 1))
    assert_contains "SAP host in message" "$SAP_RESPONSE" "sap.ilmuprogram.com"
else
    echo -e "  ${YELLOW}⏭️ SKIP${NC} — SAP Connection failed (SAP might be down)"
    SKIP=$((SKIP + 1))
fi

# Get Suppliers
SUPP_RESPONSE=$(curl -s --max-time 15 "$BASE_URL/getSAPSuppliers()" 2>/dev/null)
if echo "$SUPP_RESPONSE" | grep -q "Supplier"; then
    echo -e "  ${GREEN}✅ PASS${NC} — getSAPSuppliers() returned data"
    PASS=$((PASS + 1))
else
    echo -e "  ${YELLOW}⏭️ SKIP${NC} — getSAPSuppliers() no data (SAP might be down)"
    SKIP=$((SKIP + 1))
fi

# ============================================
print_header "SIT-03: Post Validations (NO actual SAP post)"

# Post without supplier
NO_SUPP_ID=$(curl -s -X POST "$BASE_URL/PORequests" \
  -H "Content-Type: application/json" \
  -d '{"description":"No Supplier Test"}' 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin).get('ID',''))" 2>/dev/null)

if [ -n "$NO_SUPP_ID" ]; then
    POST_RESP=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/PORequests($NO_SUPP_ID)/PurchaseOrderService.postToSAP" \
      -H "Content-Type: application/json" -d '{}' 2>/dev/null)
    POST_CODE=$(echo "$POST_RESP" | tail -1)
    assert_http_code "Post without supplier → 400" "$POST_CODE" "400"
fi

# Post already posted
ALREADY_RESP=$(curl -s -w "\n%{http_code}" -X POST \
  "$BASE_URL/PORequests(b1c2d3e4-f5a6-7890-bcde-f12345670003)/PurchaseOrderService.postToSAP" \
  -H "Content-Type: application/json" -d '{}' 2>/dev/null)
ALREADY_CODE=$(echo "$ALREADY_RESP" | tail -1)
assert_http_code "Post already-posted PO → 400" "$ALREADY_CODE" "400"

# ============================================
# SUMMARY
# ============================================
echo ""
echo "============================================"
echo -e "${CYAN}SIT TEST SUMMARY${NC}"
echo "============================================"
TOTAL=$((PASS + FAIL + SKIP))
echo -e "  Total Tests: $TOTAL"
echo -e "  ${GREEN}✅ PASS: $PASS${NC}"
echo -e "  ${RED}❌ FAIL: $FAIL${NC}"
echo -e "  ${YELLOW}⏭️ SKIP: $SKIP${NC}"
echo ""

if [ "$FAIL" -eq "0" ]; then
    echo -e "  ${GREEN}=============================${NC}"
    echo -e "  ${GREEN}  ALL TESTS PASSED!  ${NC}"
    echo -e "  ${GREEN}=============================${NC}"
    exit 0
else
    echo -e "  ${RED}=============================${NC}"
    echo -e "  ${RED}  $FAIL TEST(S) FAILED  ${NC}"
    echo -e "  ${RED}=============================${NC}"
    exit 1
fi
