#!/bin/bash

# Script to update all encrypted attribute mappers to require consent

echo "🔐 Updating SAML Mappers to require consent..."

# Login
docker exec keycloak-sso /opt/keycloak/bin/kcadm.sh config credentials \
    --server http://localhost:8080 --realm master --user admin --password admin

# Get all mapper IDs for encrypted attributes
MAPPER_NAMES=(
    "Encrypted First Name"
    "Encrypted Last Name"
    "Encrypted Email"
    "Encrypted Age"
    "Encrypted Mobile"
    "Encrypted Address"
    "Encrypted Profession"
)

echo ""
echo "📋 Updating encrypted attribute mappers..."

for mapper_name in "${MAPPER_NAMES[@]}"; do
    echo "  ✓ Updating: $mapper_name"
    
    # Get mapper ID
    MAPPER_ID=$(docker exec keycloak-sso /opt/keycloak/bin/kcadm.sh get \
        clients/django-saml-app/protocol-mappers/models -r demo \
        --fields id,name | grep -B1 "\"$mapper_name\"" | grep '"id"' | cut -d'"' -f4)
    
    if [ -n "$MAPPER_ID" ]; then
        # Update mapper to require consent
        docker exec keycloak-sso /opt/keycloak/bin/kcadm.sh update \
            "clients/django-saml-app/protocol-mappers/models/$MAPPER_ID" -r demo \
            -s consentRequired=true 2>/dev/null
        
        echo "    ✅ Updated $mapper_name (ID: $MAPPER_ID)"
    else
        echo "    ⚠️  Could not find $mapper_name"
    fi
done

echo ""
echo "✅ Done! All mappers updated."
echo ""
echo "🧪 Now test by logging in at: http://localhost:8001"
echo "   The consent screen should appear!"
