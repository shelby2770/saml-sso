#!/bin/bash

# Django SAML Project - Keycloak Startup Script
# This script starts Keycloak using Docker Compose and waits for it to be ready

echo "🚀 Starting Keycloak SSO Server with Docker Compose..."
echo "=================================================="

# Check if Docker and Docker Compose are available
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! command -v docker &> /dev/null; then
    echo "❌ Docker Compose is not available. Please install Docker Compose first."
    exit 1
fi

# Start Keycloak using Docker Compose
echo "📦 Starting Keycloak container..."
docker-compose up -d keycloak

# Wait for Keycloak to be ready
echo "⏳ Waiting for Keycloak to start..."
echo "   This may take a few minutes on first run..."

# Function to check if Keycloak is ready
check_keycloak() {
    curl -s http://localhost:8080/realms/demo > /dev/null 2>&1
    return $?
}

# Wait up to 180 seconds for Keycloak to be ready
TIMEOUT=180
ELAPSED=0
INTERVAL=5

while [ $ELAPSED -lt $TIMEOUT ]; do
    if check_keycloak; then
        echo "✅ Keycloak is ready!"
        echo ""
        echo "🎯 Keycloak Admin Console: http://localhost:8080"
        echo "👤 Admin credentials: admin / admin"
        echo "🌐 Demo Realm: http://localhost:8080/realms/demo"
        echo ""
        echo "📋 Available test user:"
        echo "   Username: testuser"
        echo "   Password: password123"
        echo "   Email: testuser@example.com"
        echo ""
        echo "🔧 Both Django Service Providers are pre-configured:"
        echo "   SP1 (django-saml-app): http://127.0.0.1:8001"
        echo "   SP2 (django-saml-app-sp2): http://127.0.0.1:8002"
        echo ""
        echo "🚀 You can now start your Django applications:"
        echo "   Terminal 1: source venv/bin/activate && python3 manage.py runserver 127.0.0.1:8001"
        echo "   Terminal 2: source venv/bin/activate && cd SAML_DJNAGO_2 && python3 manage.py runserver 127.0.0.1:8002"
        exit 0
    fi
    
    echo "   Still waiting... ($ELAPSED/$TIMEOUT seconds)"
    sleep $INTERVAL
    ELAPSED=$((ELAPSED + INTERVAL))
done

echo "❌ Timeout waiting for Keycloak to start. Please check the logs:"
echo "   docker-compose logs keycloak"
exit 1
