#!/bin/bash

# Keycloak Development - Build and Reload Script
# Use this during development to rebuild and reload your custom providers

echo "🔄 Keycloak Custom Provider - Build & Reload"
echo "=============================================="

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Step 1: Build the custom provider
echo -e "${BLUE}📦 Building custom provider...${NC}"
cd keycloak-customization

mvn clean package

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Build failed! Fix errors and try again.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Build successful!${NC}"
cd ..

# Check if JAR was created
if [ ! -f "keycloak-customization/target/keycloak-custom-extensions.jar" ]; then
    echo -e "${RED}❌ JAR file not found in target directory${NC}"
    exit 1
fi

echo -e "${GREEN}✓ JAR file created: keycloak-customization/target/keycloak-custom-extensions.jar${NC}"

# Step 2: Check if Keycloak is running
echo ""
echo -e "${BLUE}🔍 Checking Keycloak status...${NC}"

if ! docker ps | grep -q keycloak-sso; then
    echo -e "${YELLOW}⚠️  Keycloak is not running. Starting...${NC}"
    docker-compose up -d keycloak
    
    echo -e "${BLUE}⏳ Waiting for Keycloak to start...${NC}"
    sleep 30
fi

# Step 3: Restart Keycloak to load new provider
echo ""
echo -e "${BLUE}🔄 Restarting Keycloak to load new provider...${NC}"
docker-compose restart keycloak

echo -e "${BLUE}⏳ Waiting for Keycloak to restart...${NC}"
sleep 15

# Step 4: Verify container is running
if docker ps | grep -q keycloak-sso; then
    echo -e "${GREEN}✅ Keycloak restarted successfully!${NC}"
else
    echo -e "${RED}❌ Keycloak failed to restart${NC}"
    exit 1
fi

# Step 5: Check if provider is loaded
echo ""
echo -e "${BLUE}📋 Checking if provider is loaded...${NC}"
docker exec keycloak-sso ls -la /opt/keycloak/providers/

echo ""
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}✅ Reload Complete!${NC}"
echo -e "${GREEN}=============================================${NC}"
echo ""
echo "Next steps:"
echo "1. Open Keycloak Admin Console: http://localhost:8080"
echo "2. Login with: admin / admin"
echo "3. Go to: Realm Settings → Events → Event Listeners"
echo "4. Add 'custom-event-listener' to the list"
echo "5. Test by creating a new user"
echo ""
echo "📊 View logs in real-time:"
echo "   docker-compose logs -f keycloak | grep 'com.mycompany'"
echo ""
echo "🐛 Debug mode logs:"
echo "   docker-compose logs -f keycloak"
echo ""
