#!/bin/bash

echo "🔄 Exporting Keycloak configuration..."
echo ""

# Check if Keycloak is running
if ! docker ps | grep -q keycloak-sso; then
    echo "❌ Keycloak is not running!"
    echo "   Start it first: bash start-keycloak.sh"
    exit 1
fi

echo "✅ Keycloak is running"
echo ""

# Export realm using Keycloak admin CLI
echo "📦 Exporting demo realm..."
docker exec keycloak-sso /opt/keycloak/bin/kc.sh export \
  --file /tmp/demo-realm-export.json \
  --realm demo \
  --users realm_file 2>/dev/null

# Check if export was successful
if [ $? -eq 0 ]; then
    echo "✅ Export successful inside container"
else
    echo "⚠️  Direct export failed, trying alternative method..."
    echo ""
    echo "Please use Admin Console method:"
    echo "1. Visit: http://localhost:8080"
    echo "2. Login: admin / admin"
    echo "3. Select 'demo' realm"
    echo "4. Realm settings → Action → Partial export"
    echo "5. Check all boxes and export"
    echo "6. Move downloaded file: mv ~/Downloads/realm-export.json ./demo-realm.json"
    exit 1
fi

echo ""

# Copy export file from container
echo "📋 Copying export file..."
docker cp keycloak-sso:/tmp/demo-realm-export.json ./demo-realm.json

if [ $? -eq 0 ]; then
    echo "✅ Export complete! File: demo-realm.json"
    echo "📊 File size: $(du -h demo-realm.json | cut -f1)"
else
    echo "❌ Failed to copy export file"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 Next steps to share with team:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "   git add demo-realm.json"
echo "   git commit -m 'Update Keycloak configuration'"
echo "   git push"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💡 Your team should run:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "   git pull"
echo "   docker-compose down -v"
echo "   bash start-keycloak.sh"
echo ""
