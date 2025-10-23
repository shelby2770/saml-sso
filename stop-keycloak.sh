#!/bin/bash

# Django SAML Project - Keycloak Shutdown Script
# This script stops the Keycloak container

echo "🛑 Stopping Keycloak SSO Server..."
echo "=================================="

# Stop Keycloak using Docker Compose
docker-compose down

echo "✅ Keycloak has been stopped."
echo ""
echo "💡 To completely remove Keycloak data, run:"
echo "   docker-compose down -v"
echo ""
echo "🔄 To restart Keycloak later, run:"
echo "   ./start-keycloak.sh"
