#!/bin/bash

# Automatic Server Setup Script for Hello World App
# This script installs and configures everything needed for the Node.js application

set -e  # Exit on any error

echo "=================================================="
echo "  Starting Automated Server Setup"
echo "=================================================="
echo ""

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DEPLOY_PATH="/var/www/hello-world"
APP_NAME="hello-world-app"
APP_PORT="3000"
REPO_URL="https://github.com/eduardkolberg/test.git"

echo -e "${BLUE}[1/8] Updating system packages...${NC}"
apt-get update -qq
apt-get upgrade -y -qq
echo -e "${GREEN}✓ System updated${NC}"
echo ""

echo -e "${BLUE}[2/8] Installing Node.js 18.x LTS...${NC}"
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs
else
    echo "Node.js already installed"
fi
node --version
npm --version
echo -e "${GREEN}✓ Node.js installed${NC}"
echo ""

echo -e "${BLUE}[3/8] Installing Git...${NC}"
if ! command -v git &> /dev/null; then
    apt-get install -y git
else
    echo "Git already installed"
fi
git --version
echo -e "${GREEN}✓ Git installed${NC}"
echo ""

echo -e "${BLUE}[4/8] Installing PM2 process manager...${NC}"
if ! command -v pm2 &> /dev/null; then
    npm install -g pm2
else
    echo "PM2 already installed"
fi
pm2 --version
echo -e "${GREEN}✓ PM2 installed${NC}"
echo ""

echo -e "${BLUE}[5/8] Cloning repository to ${DEPLOY_PATH}...${NC}"
if [ -d "$DEPLOY_PATH" ]; then
    echo "Directory exists, pulling latest changes..."
    cd $DEPLOY_PATH
    git pull origin main || git pull origin master || echo "No remote branch to pull"
else
    mkdir -p $DEPLOY_PATH
    git clone $REPO_URL $DEPLOY_PATH
    cd $DEPLOY_PATH
fi
echo -e "${GREEN}✓ Repository ready${NC}"
echo ""

echo -e "${BLUE}[6/8] Installing application dependencies...${NC}"
cd $DEPLOY_PATH
npm install --production
echo -e "${GREEN}✓ Dependencies installed${NC}"
echo ""

echo -e "${BLUE}[7/8] Starting application with PM2...${NC}"
# Stop existing process if running
pm2 stop $APP_NAME 2>/dev/null || true
pm2 delete $APP_NAME 2>/dev/null || true

# Start the application
pm2 start server.js --name $APP_NAME
pm2 save
echo -e "${GREEN}✓ Application started${NC}"
echo ""

echo -e "${BLUE}[8/8] Configuring PM2 to start on boot...${NC}"
env PATH=$PATH:/usr/bin pm2 startup systemd -u root --hp /root | tail -n 1 | bash
pm2 save
echo -e "${GREEN}✓ PM2 configured for auto-start${NC}"
echo ""

echo -e "${BLUE}[BONUS] Installing and configuring Nginx...${NC}"
if ! command -v nginx &> /dev/null; then
    apt-get install -y nginx
fi

# Create Nginx configuration
cat > /etc/nginx/sites-available/$APP_NAME << 'NGINX_EOF'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /health {
        proxy_pass http://localhost:3000/health;
        access_log off;
    }
}
NGINX_EOF

# Enable the site
ln -sf /etc/nginx/sites-available/$APP_NAME /etc/nginx/sites-enabled/$APP_NAME
rm -f /etc/nginx/sites-enabled/default

# Test and restart Nginx
nginx -t
systemctl restart nginx
systemctl enable nginx
echo -e "${GREEN}✓ Nginx configured${NC}"
echo ""

echo -e "${BLUE}[BONUS] Configuring firewall...${NC}"
if command -v ufw &> /dev/null; then
    ufw --force enable
    ufw allow OpenSSH
    ufw allow 'Nginx Full'
    ufw allow 3000/tcp
    echo -e "${GREEN}✓ Firewall configured${NC}"
else
    echo "UFW not installed, skipping firewall configuration"
fi
echo ""

echo "=================================================="
echo -e "${GREEN}  ✓ Setup Complete!${NC}"
echo "=================================================="
echo ""
echo "Application Status:"
pm2 status
echo ""
echo "Application URLs:"
echo "  - Direct access: http://91.99.120.72:3000"
echo "  - Via Nginx:     http://91.99.120.72"
echo "  - Health check:  http://91.99.120.72/health"
echo ""
echo "Useful commands:"
echo "  pm2 status              - Check application status"
echo "  pm2 logs $APP_NAME      - View application logs"
echo "  pm2 restart $APP_NAME   - Restart application"
echo "  pm2 stop $APP_NAME      - Stop application"
echo "  systemctl status nginx  - Check Nginx status"
echo ""
echo "Next steps:"
echo "1. Test the application: curl http://localhost:3000"
echo "2. Open in browser: http://91.99.120.72"
echo "3. Set up GitHub Secrets (see SETUP.md)"
echo ""
