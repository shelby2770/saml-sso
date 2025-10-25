#!/bin/bash

echo "🔍 Analyzing demo-realm.json..."
echo ""

# Check if file exists
if [ ! -f "demo-realm.json" ]; then
    echo "❌ demo-realm.json NOT FOUND!"
    echo ""
    echo "💡 Export your realm first:"
    echo "   ./export-keycloak-config.sh"
    echo ""
    echo "   OR use Admin Console:"
    echo "   1. Visit http://localhost:8080"
    echo "   2. Realm settings → Action → Partial export"
    exit 1
fi

echo "✅ demo-realm.json found"
echo "📊 File size: $(du -h demo-realm.json | cut -f1)"
echo "📝 Lines: $(wc -l < demo-realm.json)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Content Analysis:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check for realm
if grep -q '"realm": "demo"' demo-realm.json; then
    echo "✅ Realm: demo"
else
    echo "❌ Realm 'demo' NOT found"
fi

# Check for users
USER_COUNT=$(grep -c '"username"' demo-realm.json || echo "0")
echo "👤 Users: $USER_COUNT"
if [ "$USER_COUNT" -gt 0 ]; then
    echo "   Found:"
    grep '"username"' demo-realm.json | sed 's/.*"username": "\(.*\)".*/     - \1/' | head -5
fi
echo ""

# Check for clients
CLIENT_COUNT=$(grep -c '"clientId"' demo-realm.json || echo "0")
echo "🔐 Clients: $CLIENT_COUNT"
if [ "$CLIENT_COUNT" -gt 0 ]; then
    echo "   Found:"
    grep '"clientId"' demo-realm.json | sed 's/.*"clientId": "\(.*\)".*/     - \1/' | head -5
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎨 Custom Attributes Check:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

ATTRS_FOUND=0

if grep -q '"age"' demo-realm.json 2>/dev/null; then
    echo "✅ Custom attribute 'age' found"
    ATTRS_FOUND=$((ATTRS_FOUND + 1))
else
    echo "⚠️  Custom attribute 'age' NOT found"
fi

if grep -q '"mobile"' demo-realm.json 2>/dev/null; then
    echo "✅ Custom attribute 'mobile' found"
    ATTRS_FOUND=$((ATTRS_FOUND + 1))
else
    echo "⚠️  Custom attribute 'mobile' NOT found"
fi

if grep -q '"address"' demo-realm.json 2>/dev/null; then
    echo "✅ Custom attribute 'address' found"
    ATTRS_FOUND=$((ATTRS_FOUND + 1))
else
    echo "⚠️  Custom attribute 'address' NOT found"
fi

if grep -q '"profession"' demo-realm.json 2>/dev/null; then
    echo "✅ Custom attribute 'profession' found"
    ATTRS_FOUND=$((ATTRS_FOUND + 1))
else
    echo "⚠️  Custom attribute 'profession' NOT found"
fi

if grep -q '"email"' demo-realm.json 2>/dev/null; then
    echo "✅ Custom attribute 'email' found"
    ATTRS_FOUND=$((ATTRS_FOUND + 1))
fi

if grep -q '"username"' demo-realm.json 2>/dev/null; then
    echo "✅ Custom attribute 'username' found"
    ATTRS_FOUND=$((ATTRS_FOUND + 1))
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Summary:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "   Users: $USER_COUNT"
echo "   Clients: $CLIENT_COUNT"
echo "   Custom Attributes: $ATTRS_FOUND"
echo ""

if [ "$USER_COUNT" -eq 0 ] || [ "$CLIENT_COUNT" -eq 0 ]; then
    echo "⚠️  WARNING: Export seems incomplete!"
    echo ""
    echo "💡 Re-export using Admin Console:"
    echo "   1. Visit: http://localhost:8080"
    echo "   2. Login: admin / admin"
    echo "   3. Select 'demo' realm"
    echo "   4. Realm settings → Action → Partial export"
    echo "   5. ✅ Check 'Include groups and roles'"
    echo "   6. ✅ Check 'Include clients'"
    echo "   7. ✅ Check 'Include users'"
    echo "   8. Click 'Export'"
    echo "   9. mv ~/Downloads/realm-export.json ./demo-realm.json"
    echo ""
else
    echo "✅ Export looks good! Ready to commit."
    echo ""
    echo "💡 To share with team:"
    echo "   git add demo-realm.json"
    echo "   git commit -m 'Update Keycloak realm configuration'"
    echo "   git push"
    echo ""
fi
