#!/bin/bash

#############################################
# TimeTracker v2.1.0 - Post-Deployment Check
# Comprehensive verification after deployment
#############################################

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DEPLOY_DIR="/var/www/timetracker"
PASSED=0
FAILED=0
WARNINGS=0

check_pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED++))
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED++))
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

echo -e "${BLUE}=================================================${NC}"
echo -e "${BLUE}  TimeTracker v2.1.0 - Post-Deployment Check${NC}"
echo -e "${BLUE}=================================================${NC}"
echo ""

# 1. Service Status
echo -e "${YELLOW}[1/10] Checking Services...${NC}"
if systemctl is-active --quiet nginx; then
    check_pass "Nginx is running"
else
    check_fail "Nginx is not running"
fi

PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
if systemctl is-active --quiet "php${PHP_VERSION}-fpm"; then
    check_pass "PHP-FPM is running"
else
    check_fail "PHP-FPM is not running"
fi

if systemctl is-active --quiet mysql || systemctl is-active --quiet mariadb; then
    check_pass "Database server is running"
else
    check_fail "Database server is not running"
fi

# 2. File Integrity
echo ""
echo -e "${YELLOW}[2/10] Checking File Integrity...${NC}"
cd "$DEPLOY_DIR"

CRITICAL_FILES=(
    "index.html"
    "api.php"
    "config.php"
    "env-loader.php"
    "rate-limiter.php"
    "audit-logger.php"
    "validators.php"
    ".env"
)

for file in "${CRITICAL_FILES[@]}"; do
    if [ -f "$file" ]; then
        check_pass "File exists: $file"
    else
        check_fail "Missing file: $file"
    fi
done

# Check if sensitive files were removed
if [ ! -f "migrate-pins.php" ]; then
    check_pass "migrate-pins.php removed"
else
    check_warn "migrate-pins.php still exists (should be deleted)"
fi

if [ ! -f "setup.php" ]; then
    check_pass "setup.php removed"
else
    check_warn "setup.php still exists (security risk!)"
fi

# 3. File Permissions
echo ""
echo -e "${YELLOW}[3/10] Checking File Permissions...${NC}"

ENV_PERM=$(stat -c "%a" .env 2>/dev/null)
if [ "$ENV_PERM" = "600" ] || [ "$ENV_PERM" = "400" ]; then
    check_pass ".env permissions: $ENV_PERM (secure)"
else
    check_warn ".env permissions: $ENV_PERM (should be 600)"
fi

OWNER=$(stat -c "%U" . 2>/dev/null)
if [ "$OWNER" = "www-data" ]; then
    check_pass "Directory owner: www-data"
else
    check_warn "Directory owner: $OWNER (should be www-data)"
fi

# 4. Environment Configuration
echo ""
echo -e "${YELLOW}[4/10] Checking Environment Configuration...${NC}"

if [ -f .env ]; then
    source .env

    if [ "$APP_ENV" = "production" ]; then
        check_pass "APP_ENV=production"
    else
        check_warn "APP_ENV=$APP_ENV (should be 'production')"
    fi

    if [ "$APP_DEBUG" = "false" ]; then
        check_pass "APP_DEBUG=false"
    else
        check_fail "APP_DEBUG=$APP_DEBUG (must be 'false' in production!)"
    fi

    if [ -n "$DB_HOST" ]; then
        check_pass "DB_HOST is set"
    else
        check_fail "DB_HOST is not set"
    fi
fi

# 5. Database Connection
echo ""
echo -e "${YELLOW}[5/10] Checking Database Connection...${NC}"

if mysql -u"$DB_USER" -p"$DB_PASS" -h"$DB_HOST" -D"$DB_NAME" -e "SELECT 1;" &>/dev/null; then
    check_pass "Database connection successful"

    # Check tables exist
    TABLES=$(mysql -u"$DB_USER" -p"$DB_PASS" -h"$DB_HOST" -D"$DB_NAME" -se "SHOW TABLES;" 2>/dev/null)

    REQUIRED_TABLES=("companies" "depts" "projects" "tasks" "users" "entries" "rate_limits" "audit_log")
    for table in "${REQUIRED_TABLES[@]}"; do
        if echo "$TABLES" | grep -q "^${table}$"; then
            check_pass "Table exists: $table"
        else
            check_fail "Table missing: $table"
        fi
    done
else
    check_fail "Database connection failed"
fi

# 6. PIN Migration
echo ""
echo -e "${YELLOW}[6/10] Checking PIN Migration...${NC}"

if [ -f .env ]; then
    TOTAL_USERS=$(mysql -u"$DB_USER" -p"$DB_PASS" -h"$DB_HOST" -D"$DB_NAME" -se "SELECT COUNT(*) FROM users;" 2>/dev/null)
    HASHED_USERS=$(mysql -u"$DB_USER" -p"$DB_PASS" -h"$DB_HOST" -D"$DB_NAME" -se "SELECT COUNT(*) FROM users WHERE pin LIKE '\$2y\$%';" 2>/dev/null)

    if [ "$TOTAL_USERS" -eq "$HASHED_USERS" ]; then
        check_pass "All $TOTAL_USERS user PINs are hashed"
    else
        check_fail "$HASHED_USERS/$TOTAL_USERS PINs are hashed (migration incomplete)"
    fi
fi

# 7. API Functionality
echo ""
echo -e "${YELLOW}[7/10] Checking API Functionality...${NC}"

# Test /api.php?path=all
API_RESPONSE=$(curl -s "http://localhost/api.php?path=all" 2>/dev/null)
if echo "$API_RESPONSE" | grep -q "companies"; then
    check_pass "API endpoint /all is responding"
else
    check_fail "API endpoint /all is not responding correctly"
fi

# Check if API returns valid JSON
if echo "$API_RESPONSE" | python3 -m json.tool &>/dev/null; then
    check_pass "API returns valid JSON"
else
    check_fail "API does not return valid JSON"
fi

# 8. Security Features
echo ""
echo -e "${YELLOW}[8/10] Checking Security Features...${NC}"

# Check rate_limits table
RATE_LIMIT_TABLE=$(mysql -u"$DB_USER" -p"$DB_PASS" -h"$DB_HOST" -D"$DB_NAME" -se "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$DB_NAME' AND table_name='rate_limits';" 2>/dev/null)
if [ "$RATE_LIMIT_TABLE" -eq 1 ]; then
    check_pass "Rate limiting table exists"
else
    check_fail "Rate limiting table missing"
fi

# Check audit_log table
AUDIT_TABLE=$(mysql -u"$DB_USER" -p"$DB_PASS" -h"$DB_HOST" -D"$DB_NAME" -se "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$DB_NAME' AND table_name='audit_log';" 2>/dev/null)
if [ "$AUDIT_TABLE" -eq 1 ]; then
    check_pass "Audit log table exists"
else
    check_fail "Audit log table missing"
fi

# Check CORS configuration
CORS_HEADER=$(curl -s -I "http://localhost/api.php?path=all" 2>/dev/null | grep -i "Access-Control-Allow-Origin")
if [ -n "$CORS_HEADER" ]; then
    check_pass "CORS headers configured"
else
    check_warn "CORS headers not detected"
fi

# 9. Error Logs
echo ""
echo -e "${YELLOW}[9/10] Checking Error Logs...${NC}"

# Check PHP-FPM log
PHP_LOG="/var/log/php${PHP_VERSION}-fpm.log"
if [ -f "$PHP_LOG" ]; then
    RECENT_ERRORS=$(tail -100 "$PHP_LOG" | grep -i "error" | wc -l)
    if [ "$RECENT_ERRORS" -eq 0 ]; then
        check_pass "No PHP errors in recent log"
    else
        check_warn "$RECENT_ERRORS PHP error(s) found in recent log"
    fi
else
    check_warn "PHP-FPM log not found at $PHP_LOG"
fi

# Check Nginx error log
NGINX_LOG="/var/log/nginx/error.log"
if [ -f "$NGINX_LOG" ]; then
    RECENT_NGINX_ERRORS=$(tail -100 "$NGINX_LOG" | grep -E "error|crit|alert|emerg" | wc -l)
    if [ "$RECENT_NGINX_ERRORS" -eq 0 ]; then
        check_pass "No Nginx errors in recent log"
    else
        check_warn "$RECENT_NGINX_ERRORS Nginx error(s) found in recent log"
    fi
else
    check_warn "Nginx error log not found at $NGINX_LOG"
fi

# 10. Performance Check
echo ""
echo -e "${YELLOW}[10/10] Checking Performance...${NC}"

# Test response time
START=$(date +%s%N)
curl -s "http://localhost/api.php?path=all" > /dev/null 2>&1
END=$(date +%s%N)
RESPONSE_TIME=$(( (END - START) / 1000000 ))

if [ "$RESPONSE_TIME" -lt 200 ]; then
    check_pass "API response time: ${RESPONSE_TIME}ms (excellent)"
elif [ "$RESPONSE_TIME" -lt 500 ]; then
    check_pass "API response time: ${RESPONSE_TIME}ms (good)"
elif [ "$RESPONSE_TIME" -lt 1000 ]; then
    check_warn "API response time: ${RESPONSE_TIME}ms (acceptable)"
else
    check_warn "API response time: ${RESPONSE_TIME}ms (slow)"
fi

# Summary
echo ""
echo -e "${BLUE}=================================================${NC}"
echo -e "${BLUE}  Post-Deployment Check Summary${NC}"
echo -e "${BLUE}=================================================${NC}"
echo ""
echo -e "  ${GREEN}Passed:${NC} $PASSED"
echo -e "  ${YELLOW}Warnings:${NC} $WARNINGS"
echo -e "  ${RED}Failed:${NC} $FAILED"
echo ""

if [ $FAILED -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed! Deployment is healthy.${NC}"
    exit 0
elif [ $FAILED -eq 0 ]; then
    echo -e "${YELLOW}⚠ Deployment successful but with ${WARNINGS} warning(s).${NC}"
    echo -e "${YELLOW}Review warnings above and address them.${NC}"
    exit 0
else
    echo -e "${RED}✗ Deployment has ${FAILED} critical issue(s)!${NC}"
    echo -e "${RED}Please fix the issues above immediately.${NC}"
    exit 1
fi
