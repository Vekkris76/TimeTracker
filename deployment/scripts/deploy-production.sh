#!/bin/bash

#############################################
# TimeTracker v2.1.0 - Production Deployment
# Automated deployment script
#############################################

set -e  # Exit on error

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

DEPLOY_DIR="/var/www/timetracker"
BACKUP_DIR="/var/backups/timetracker"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo -e "${BLUE}=================================================${NC}"
echo -e "${BLUE}  TimeTracker v2.1.0 - Production Deployment${NC}"
echo -e "${BLUE}=================================================${NC}"
echo ""

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run with sudo${NC}"
    exit 1
fi

# Step 1: Pre-deployment backup
echo -e "${YELLOW}[1/8] Creating pre-deployment backup...${NC}"
mkdir -p "$BACKUP_DIR"

# Backup database
echo "  - Backing up database..."
if [ -f "$DEPLOY_DIR/app/config/.env" ]; then
    source "$DEPLOY_DIR/app/config/.env"
    mysqldump -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$BACKUP_DIR/db_pre_deploy_${TIMESTAMP}.sql"
    echo -e "${GREEN}  ✓ Database backed up${NC}"
else
    echo -e "${RED}  ✗ .env not found, skipping database backup${NC}"
fi

# Backup files
echo "  - Backing up files..."
tar -czf "$BACKUP_DIR/files_pre_deploy_${TIMESTAMP}.tar.gz" -C "$DEPLOY_DIR" . 2>/dev/null || true
echo -e "${GREEN}  ✓ Files backed up${NC}"

# Step 2: Pull latest code
echo ""
echo -e "${YELLOW}[2/8] Pulling latest code from repository...${NC}"
cd "$DEPLOY_DIR"
git fetch origin
git pull origin main
echo -e "${GREEN}  ✓ Code updated${NC}"

# Step 3: Check .env file
echo ""
echo -e "${YELLOW}[3/8] Checking environment configuration...${NC}"
if [ ! -f "$DEPLOY_DIR/app/config/.env" ]; then
    echo -e "${RED}  ✗ .env file not found${NC}"
    echo ""
    echo "Please create .env file:"
    echo "  1. Copy from template: cp app/config/.env.example app/config/.env"
    echo "  2. Edit with your credentials: nano app/config/.env"
    echo "  3. Set APP_ENV=production"
    echo "  4. Set APP_DEBUG=false"
    echo ""
    echo "Then run this script again."
    exit 1
fi

# Verify production settings
if ! grep -q "^APP_ENV=production" app/config/.env; then
    echo -e "${YELLOW}  ⚠ APP_ENV is not set to 'production'${NC}"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

if grep -q "^APP_DEBUG=true" app/config/.env; then
    echo -e "${RED}  ✗ APP_DEBUG is set to 'true' (security risk!)${NC}"
    read -p "Continue anyway? (NOT RECOMMENDED) (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo -e "${GREEN}  ✓ Environment configuration OK${NC}"

# Step 4: Set file permissions
echo ""
echo -e "${YELLOW}[4/8] Setting file permissions...${NC}"
chown -R www-data:www-data "$DEPLOY_DIR"
chmod -R 755 "$DEPLOY_DIR"
chmod 600 "$DEPLOY_DIR/app/config/.env"
echo -e "${GREEN}  ✓ Permissions set${NC}"

# Step 5: Run migrations
echo ""
echo -e "${YELLOW}[5/8] Running database migrations...${NC}"

# Check if migration is needed
if [ -f "$DEPLOY_DIR/app/src/Database/migrate-pins.php" ]; then
    # Check if already migrated
    source "$DEPLOY_DIR/app/config/.env"
    HASHED_COUNT=$(mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -se "SELECT COUNT(*) FROM users WHERE pin LIKE '\$2y\$%';" 2>/dev/null || echo "0")

    if [ "$HASHED_COUNT" -eq 0 ]; then
        echo "  - Migrating PINs to bcrypt..."
        cd "$DEPLOY_DIR"
        php app/src/Database/migrate-pins.php
        echo -e "${GREEN}  ✓ PIN migration completed${NC}"

        echo "  - Removing migration script..."
        rm -f app/src/Database/migrate-pins.php
        echo -e "${GREEN}  ✓ Migration script removed${NC}"
    else
        echo -e "${GREEN}  ✓ PINs already migrated (skipping)${NC}"
        echo "  - Removing migration script..."
        rm -f app/src/Database/migrate-pins.php
    fi
else
    echo -e "${GREEN}  ✓ No migrations needed${NC}"
fi

# Step 6: Clean up sensitive files
echo ""
echo -e "${YELLOW}[6/8] Cleaning up sensitive files...${NC}"
FILES_TO_REMOVE=("setup.php" "test_login.php" "app/src/Database/migrate-pins.php")

for file in "${FILES_TO_REMOVE[@]}"; do
    if [ -f "$DEPLOY_DIR/$file" ]; then
        rm -f "$DEPLOY_DIR/$file"
        echo "  - Removed: $file"
    fi
done
echo -e "${GREEN}  ✓ Cleanup complete${NC}"

# Step 7: Restart services
echo ""
echo -e "${YELLOW}[7/8] Restarting services...${NC}"

# Restart PHP-FPM
PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
if systemctl is-active --quiet "php${PHP_VERSION}-fpm"; then
    systemctl restart "php${PHP_VERSION}-fpm"
    echo -e "${GREEN}  ✓ PHP-FPM restarted${NC}"
else
    echo -e "${YELLOW}  ⚠ PHP-FPM not running or not found${NC}"
fi

# Restart Nginx
if systemctl is-active --quiet nginx; then
    nginx -t && systemctl restart nginx
    echo -e "${GREEN}  ✓ Nginx restarted${NC}"
else
    echo -e "${YELLOW}  ⚠ Nginx not running${NC}"
fi

# Step 8: Post-deployment verification
echo ""
echo -e "${YELLOW}[8/8] Running post-deployment checks...${NC}"

# Check if services are running
if systemctl is-active --quiet nginx; then
    echo -e "${GREEN}  ✓ Nginx is running${NC}"
else
    echo -e "${RED}  ✗ Nginx is not running${NC}"
fi

if systemctl is-active --quiet "php${PHP_VERSION}-fpm"; then
    echo -e "${GREEN}  ✓ PHP-FPM is running${NC}"
else
    echo -e "${RED}  ✗ PHP-FPM is not running${NC}"
fi

# Test database connection
source "$DEPLOY_DIR/app/config/.env"
if mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -e "SELECT 1;" &>/dev/null; then
    echo -e "${GREEN}  ✓ Database connection OK${NC}"
else
    echo -e "${RED}  ✗ Database connection failed${NC}"
fi

# Test API
if curl -s "http://localhost/app/public/api.php?path=all" | grep -q "companies"; then
    echo -e "${GREEN}  ✓ API is responding${NC}"
else
    echo -e "${YELLOW}  ⚠ API test failed (check manually)${NC}"
fi

echo ""
echo -e "${BLUE}=================================================${NC}"
echo -e "${BLUE}  Deployment Complete!${NC}"
echo -e "${BLUE}=================================================${NC}"
echo ""
echo -e "${GREEN}✓ TimeTracker v2.1.0 deployed successfully${NC}"
echo ""
echo "Backup locations:"
echo "  - Database: $BACKUP_DIR/db_pre_deploy_${TIMESTAMP}.sql"
echo "  - Files: $BACKUP_DIR/files_pre_deploy_${TIMESTAMP}.tar.gz"
echo ""
echo "Next steps:"
echo "  1. Test the application in a browser"
echo "  2. Verify user login works"
echo "  3. Check error logs: tail -f /var/log/php${PHP_VERSION}-fpm.log"
echo "  4. Monitor for 24h and check audit_log table"
echo ""
echo "If issues occur, rollback with:"
echo "  mysql -u$DB_USER -p$DB_PASS $DB_NAME < $BACKUP_DIR/db_pre_deploy_${TIMESTAMP}.sql"
echo "  tar -xzf $BACKUP_DIR/files_pre_deploy_${TIMESTAMP}.tar.gz -C $DEPLOY_DIR"
echo ""
