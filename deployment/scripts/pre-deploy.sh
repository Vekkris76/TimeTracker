#!/bin/bash

#############################################
# TimeTracker v2.1.0 - Pre-Deployment Script
# Valida el entorno antes del despliegue
#############################################

set -e  # Exit on error

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=================================================${NC}"
echo -e "${BLUE}  TimeTracker v2.1.0 - Pre-Deployment Checks${NC}"
echo -e "${BLUE}=================================================${NC}"
echo ""

# Counter for issues
ISSUES=0
WARNINGS=0

# Function to check
check_pass() {
    echo -e "${GREEN}✓${NC} $1"
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
    ((ISSUES++))
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

echo -e "${YELLOW}[1/10] Checking System Requirements...${NC}"
# Check PHP version
if command -v php &> /dev/null; then
    PHP_VERSION=$(php -r "echo PHP_VERSION;")
    if [[ $(echo "$PHP_VERSION >= 8.1" | bc -l) -eq 1 ]]; then
        check_pass "PHP $PHP_VERSION installed"
    else
        check_fail "PHP version $PHP_VERSION < 8.1 (required: 8.1+)"
    fi
else
    check_fail "PHP not found in PATH"
fi

# Check required PHP extensions
for ext in pdo pdo_mysql json; do
    if php -m | grep -q "^$ext$"; then
        check_pass "PHP extension: $ext"
    else
        check_fail "Missing PHP extension: $ext"
    fi
done

echo ""
echo -e "${YELLOW}[2/10] Checking Web Server...${NC}"
# Check Nginx
if command -v nginx &> /dev/null; then
    NGINX_VERSION=$(nginx -v 2>&1 | grep -oP '\d+\.\d+\.\d+')
    check_pass "Nginx $NGINX_VERSION installed"
else
    check_fail "Nginx not found"
fi

# Check if nginx is running
if pgrep nginx > /dev/null; then
    check_pass "Nginx is running"
else
    check_warn "Nginx is not running"
fi

echo ""
echo -e "${YELLOW}[3/10] Checking Database...${NC}"
# Check MySQL/MariaDB
if command -v mysql &> /dev/null; then
    MYSQL_VERSION=$(mysql --version | grep -oP '\d+\.\d+\.\d+' | head -1)
    check_pass "MySQL/MariaDB $MYSQL_VERSION installed"
else
    check_fail "MySQL/MariaDB not found"
fi

# Test database connection
if [ -f .env ]; then
    source .env
    if mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" -e "USE $DB_NAME;" 2>/dev/null; then
        check_pass "Database connection successful"
    else
        check_fail "Cannot connect to database (check .env credentials)"
    fi
else
    check_fail ".env file not found"
fi

echo ""
echo -e "${YELLOW}[4/10] Checking Required Files...${NC}"
# Check critical files
REQUIRED_FILES=(
    "index.html"
    "api.php"
    "config.php"
    "env-loader.php"
    "rate-limiter.php"
    "audit-logger.php"
    "validators.php"
    ".env"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        check_pass "File exists: $file"
    else
        check_fail "Missing file: $file"
    fi
done

echo ""
echo -e "${YELLOW}[5/10] Checking .env Configuration...${NC}"
if [ -f .env ]; then
    # Check required env variables
    REQUIRED_VARS=(
        "DB_HOST"
        "DB_NAME"
        "DB_USER"
        "DB_PASS"
        "APP_ENV"
        "APP_DEBUG"
        "APP_DOMAIN"
    )

    for var in "${REQUIRED_VARS[@]}"; do
        if grep -q "^${var}=" .env; then
            check_pass "Environment variable: $var"
        else
            check_fail "Missing environment variable: $var"
        fi
    done

    # Check if APP_ENV is production
    if grep -q "^APP_ENV=production" .env; then
        check_pass "APP_ENV set to production"
    else
        check_warn "APP_ENV is not set to 'production'"
    fi

    # Check if APP_DEBUG is false
    if grep -q "^APP_DEBUG=false" .env; then
        check_pass "APP_DEBUG set to false"
    else
        check_warn "APP_DEBUG is not set to 'false' (security risk)"
    fi
fi

echo ""
echo -e "${YELLOW}[6/10] Checking File Permissions...${NC}"
# Check directory permissions
if [ -w "." ]; then
    check_pass "Current directory is writable"
else
    check_fail "Current directory is not writable"
fi

# Check .env permissions
if [ -f .env ]; then
    PERM=$(stat -c "%a" .env)
    if [ "$PERM" = "600" ] || [ "$PERM" = "400" ]; then
        check_pass ".env has secure permissions ($PERM)"
    else
        check_warn ".env permissions are $PERM (should be 600 or 400)"
    fi
fi

echo ""
echo -e "${YELLOW}[7/10] Checking Database Tables...${NC}"
if [ -f .env ]; then
    source .env
    TABLES=$(mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -e "SHOW TABLES;" 2>/dev/null | tail -n +2)

    REQUIRED_TABLES=(
        "companies"
        "depts"
        "projects"
        "tasks"
        "users"
        "entries"
        "rate_limits"
        "audit_log"
    )

    for table in "${REQUIRED_TABLES[@]}"; do
        if echo "$TABLES" | grep -q "^${table}$"; then
            check_pass "Table exists: $table"
        else
            check_warn "Table missing: $table (will be created automatically)"
        fi
    done
fi

echo ""
echo -e "${YELLOW}[8/10] Checking Backups...${NC}"
# Check if backup directory exists
if [ -d "backups" ]; then
    check_pass "Backup directory exists"
    BACKUP_COUNT=$(ls -1 backups/*.sql 2>/dev/null | wc -l)
    if [ "$BACKUP_COUNT" -gt 0 ]; then
        check_pass "Found $BACKUP_COUNT database backup(s)"
    else
        check_warn "No database backups found in backups/"
    fi
else
    check_warn "Backup directory not found (recommended to create one)"
fi

echo ""
echo -e "${YELLOW}[9/10] Checking Migration Scripts...${NC}"
# Check if app/src/Database/migrate-pins.php exists (should be deleted after use)
if [ -f "app/src/Database/migrate-pins.php" ]; then
    check_warn "app/src/Database/migrate-pins.php still exists (should be deleted after migration)"
else
    check_pass "app/src/Database/migrate-pins.php not found (good if migration already done)"
fi

# Check if setup.php exists (should be deleted)
if [ -f "setup.php" ]; then
    check_warn "setup.php still exists (security risk - delete it)"
else
    check_pass "setup.php not found (good)"
fi

echo ""
echo -e "${YELLOW}[10/10] Checking Security...${NC}"
# Check if config.php is in gitignore
if grep -q "^config.php$" .gitignore 2>/dev/null; then
    check_pass "config.php is in .gitignore"
else
    check_fail "config.php is NOT in .gitignore (security risk)"
fi

# Check if .env is in gitignore
if grep -q "^.env$" .gitignore 2>/dev/null; then
    check_pass ".env is in .gitignore"
else
    check_fail ".env is NOT in .gitignore (security risk)"
fi

# Check SSL/HTTPS
if curl -s -o /dev/null -w "%{http_code}" https://localhost 2>/dev/null | grep -q "200\|301\|302"; then
    check_pass "HTTPS is configured"
else
    check_warn "HTTPS not detected (recommended for production)"
fi

echo ""
echo -e "${BLUE}=================================================${NC}"
echo -e "${BLUE}  Pre-Deployment Check Summary${NC}"
echo -e "${BLUE}=================================================${NC}"
echo ""

if [ $ISSUES -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed! Ready for deployment.${NC}"
    exit 0
elif [ $ISSUES -eq 0 ]; then
    echo -e "${YELLOW}⚠ ${WARNINGS} warning(s) found.${NC}"
    echo -e "${YELLOW}Review warnings above. Deployment can proceed but recommended to fix them.${NC}"
    exit 0
else
    echo -e "${RED}✗ ${ISSUES} critical issue(s) found.${NC}"
    echo -e "${RED}Please fix the issues above before deploying.${NC}"
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}⚠ ${WARNINGS} warning(s) also found.${NC}"
    fi
    exit 1
fi
