#!/bin/bash

# MomentumOS - Quick Deployment Script
# Automates deployment setup for production

set -e  # Exit on error

echo "🚀 MomentumOS Deployment Setup"
echo "================================"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

# Check Node.js
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js not found. Install from https://nodejs.org/${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Node.js $(node --version)${NC}"

# Check npm
if ! command -v npm &> /dev/null; then
    echo -e "${RED}❌ npm not found${NC}"
    exit 1
fi
echo -e "${GREEN}✅ npm $(npm --version)${NC}"

# Check PostgreSQL
if ! command -v psql &> /dev/null; then
    echo -e "${RED}❌ PostgreSQL not found. Install from https://www.postgresql.org/${NC}"
    exit 1
fi
echo -e "${GREEN}✅ PostgreSQL installed${NC}"

# Setup backend
echo -e "\n${YELLOW}Setting up backend...${NC}"

cd backend

# Install dependencies
echo "Installing dependencies..."
npm install

# Create environment file
if [ ! -f .env ]; then
    echo "Creating .env file from template..."
    cp .env.example .env
    echo -e "${YELLOW}⚠️  Please update .env with your configuration${NC}"
else
    echo -e "${GREEN}✅ .env file exists${NC}"
fi

# Setup database
echo -e "\n${YELLOW}Setting up database...${NC}"

# Check if database exists
DB_NAME="momentumos"
if psql -lqt | cut -d \| -f 1 | grep -qw $DB_NAME; then
    echo -e "${GREEN}✅ Database 'momentumos' already exists${NC}"
else
    echo "Creating database..."
    createdb $DB_NAME
    echo -e "${GREEN}✅ Database created${NC}"
fi

# Run migrations
echo "Running database migrations..."
psql -d $DB_NAME -f database.sql
echo -e "${GREEN}✅ Database schema created${NC}"

# Test database connection
echo "Testing database connection..."
psql -d $DB_NAME -c "SELECT version();" > /dev/null
echo -e "${GREEN}✅ Database connection successful${NC}"

cd ..

# Summary
echo -e "\n${GREEN}================================${NC}"
echo -e "${GREEN}✅ Setup Complete!${NC}"
echo -e "${GREEN}================================${NC}"

echo -e "\nNext steps:"
echo "1. Update .env file with your configuration:"
echo "   - JWT_SECRET: Generate with: node -e \"console.log(require('crypto').randomBytes(32).toString('hex'))\""
echo "   - DATABASE_URL: Already configured if using local PostgreSQL"
echo "   - Add any external service keys (SendGrid, Stripe, etc.)"
echo ""
echo "2. Start the server:"
echo "   cd backend"
echo "   npm start"
echo ""
echo "3. Update iOS app:"
echo "   - Open MomentumOS.swift"
echo "   - Update BackendAPIService baseURL to your server"
echo ""
echo "4. Test API:"
echo "   curl http://localhost:3000/v1/health"
echo ""
echo "5. Deploy backend:"
echo "   - Heroku:      heroku create momentumos-api && git push heroku main"
echo "   - AWS:         Follow DEPLOYMENT_GUIDE.md"
echo "   - DigitalOcean: Follow DEPLOYMENT_GUIDE.md"
echo ""
echo "📚 For detailed instructions, see: DEPLOYMENT_GUIDE.md"
echo -e "\n${GREEN}Ready for deployment!${NC}"
