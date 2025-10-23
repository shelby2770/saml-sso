#!/bin/bash

# Django SAML Project - Status Check Script
# This script checks the status of all services

echo "🔍 Django SAML Project Status Check"
echo "===================================="
echo ""

# Check Keycloak
echo "🏛️  Keycloak IdP Status:"
if curl -s http://localhost:8080/realms/demo > /dev/null 2>&1; then
    echo "   ✅ Keycloak is running on http://localhost:8080"
    echo "   ✅ Demo realm is accessible"
else
    echo "   ❌ Keycloak is not running or not accessible"
    echo "   💡 Run: ./start-keycloak.sh"
fi

echo ""

# Check Django SP1
echo "🐍 Django Service Provider 1:"
if curl -s http://127.0.0.1:8001 > /dev/null 2>&1; then
    echo "   ✅ SP1 is running on http://127.0.0.1:8001"
else
    echo "   ❌ SP1 is not running"
    echo "   💡 Run: source venv/bin/activate && python3 manage.py runserver 127.0.0.1:8001"
fi

echo ""

# Check Django SP2
echo "🐍 Django Service Provider 2:"
if curl -s http://127.0.0.1:8002 > /dev/null 2>&1; then
    echo "   ✅ SP2 is running on http://127.0.0.1:8002"
else
    echo "   ❌ SP2 is not running"
    echo "   💡 Run: source venv/bin/activate && cd SAML_DJNAGO_2 && python3 manage.py runserver 127.0.0.1:8002"
fi

echo ""

# Check if everything is running
if curl -s http://localhost:8080/realms/demo > /dev/null 2>&1 && \
   curl -s http://127.0.0.1:8001 > /dev/null 2>&1 && \
   curl -s http://127.0.0.1:8002 > /dev/null 2>&1; then
    
    echo "🎉 All services are running! You can now test SAML SSO:"
    echo ""
    echo "🔗 Quick Links:"
    echo "   • Keycloak Admin: http://localhost:8080 (admin/admin)"
    echo "   • SP1 Home: http://127.0.0.1:8001"
    echo "   • SP2 Home: http://127.0.0.1:8002"
    echo ""
    echo "👤 Test User:"
    echo "   • Username: testuser"
    echo "   • Password: password123"
    echo ""
    echo "🧪 Test SAML SSO Flow:"
    echo "   1. Visit http://127.0.0.1:8001"
    echo "   2. Click 'Login with SAML'"
    echo "   3. Login with testuser/password123"
    echo "   4. Visit http://127.0.0.1:8002 (should be auto-logged in)"
else
    echo "⚠️  Some services are not running. Please start them first."
fi

echo ""
