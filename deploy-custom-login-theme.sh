#!/bin/bash

# Deploy Custom Login Theme to Keycloak

echo "🎨 Deploying Custom Login Theme with Alerts to Keycloak..."
echo ""

# Configuration
THEME_NAME="custom-login-theme"
THEME_DIR="$(pwd)/${THEME_NAME}"
KEYCLOAK_CONTAINER="keycloak-sso"

# Check if theme directory exists
if [ ! -d "$THEME_DIR" ]; then
    echo "❌ Error: Theme directory not found at $THEME_DIR"
    exit 1
fi

# Check if Keycloak container is running
if ! docker ps | grep -q "$KEYCLOAK_CONTAINER"; then
    echo "❌ Error: Keycloak container '$KEYCLOAK_CONTAINER' is not running"
    echo "Please start Keycloak first: ./start-keycloak.sh"
    exit 1
fi

echo "📦 Copying theme files to Keycloak container..."
docker cp "$THEME_DIR" "$KEYCLOAK_CONTAINER":/opt/keycloak/themes/

if [ $? -eq 0 ]; then
    echo "✅ Theme files copied successfully!"
else
    echo "❌ Failed to copy theme files"
    exit 1
fi

echo ""
echo "🔄 Restarting Keycloak to apply theme..."
docker restart "$KEYCLOAK_CONTAINER"

echo ""
echo "⏳ Waiting for Keycloak to restart (30 seconds)..."
sleep 30

echo ""
echo "✅ Theme deployed successfully!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 NEXT STEPS:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Open Keycloak Admin Console: http://localhost:8080"
echo "   Login: admin / admin"
echo ""
echo "2. Select 'demo' realm (top-left dropdown)"
echo ""
echo "3. Go to: Realm settings → Themes tab"
echo ""
echo "4. Set 'Login theme' to: custom-login-theme"
echo ""
echo "5. Click 'Save'"
echo ""
echo "6. Test the login page at: http://127.0.0.1:8001/api/saml/login/"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✨ FEATURES:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "• 🎉 Beautiful animated success alert"
echo "• ❌ Custom error alert for failed login"
echo "• 🔄 Processing alert during authentication"
echo "• 🎨 Gradient design with smooth animations"
echo "• ⌨️  Press ESC to close alerts"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
