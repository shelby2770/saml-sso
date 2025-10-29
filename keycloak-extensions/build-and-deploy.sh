#!/bin/bash

# Build and deploy Keycloak extension

echo "🔨 Building Keycloak Extension..."

cd "$(dirname "$0")"

# Build with Maven
mvn clean package

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    
    # Copy JAR to Keycloak providers directory
    echo "📦 Deploying to Keycloak..."
    docker cp target/attribute-consent-extension.jar keycloak-sso:/opt/keycloak/providers/
    
    if [ $? -eq 0 ]; then
        echo "✅ Deployed to Keycloak container"
        echo "🔄 Restarting Keycloak..."
        docker restart keycloak-sso
        echo "✅ Done! Extension deployed."
    else
        echo "❌ Failed to copy JAR to Keycloak"
        exit 1
    fi
else
    echo "❌ Build failed"
    exit 1
fi
