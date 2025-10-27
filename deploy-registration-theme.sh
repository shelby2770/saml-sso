#!/bin/bash

echo "🚀 Deploying Custom Registration Theme with WebAuthn Encryption"
echo "================================================================"
echo ""

# Check if Keycloak is running
if ! docker ps | grep -q keycloak-sso; then
    echo "❌ Keycloak is not running!"
    echo "   Please start Keycloak first: bash start-keycloak.sh"
    exit 1
fi

echo "✅ Keycloak is running"
echo ""

# Copy theme to Keycloak container
echo "📦 Copying theme to Keycloak container..."
docker cp custom-registration-theme keycloak-sso:/opt/keycloak/themes/

if [ $? -eq 0 ]; then
    echo "✅ Theme copied successfully"
else
    echo "❌ Failed to copy theme"
    exit 1
fi

echo ""

# Verify theme files
echo "🔍 Verifying theme files in container..."
docker exec keycloak-sso ls -la /opt/keycloak/themes/custom-registration-theme/

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Theme deployed successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 NEXT STEPS:"
echo ""
echo "1. Open Keycloak Admin Console:"
echo "   👉 http://localhost:8080"
echo "   Login: admin / admin"
echo ""
echo "2. Select 'demo' realm (top-left dropdown)"
echo ""
echo "3. Go to: Realm settings → Themes tab"
echo ""
echo "4. Set Login theme to: custom-registration-theme"
echo ""
echo "5. Click 'Save'"
echo ""
echo "6. Enable user registration:"
echo "   - Go to: Realm settings → Login tab"
echo "   - Check: ✅ User registration"
echo "   - Click 'Save'"
echo ""
echo "7. Test registration page:"
echo "   👉 http://localhost:8080/realms/demo/protocol/openid-connect/registrations?client_id=account&response_type=code"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
