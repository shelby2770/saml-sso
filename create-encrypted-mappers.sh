#!/bin/bash

# Script to create SAML mappers for encrypted attributes and metadata

echo "🔐 Creating SAML Mappers for Encrypted Attributes..."

# Login to Keycloak
docker exec keycloak-sso /opt/keycloak/bin/kcadm.sh config credentials \
    --server http://localhost:8080 --realm master --user admin --password admin

# Array of encrypted attributes
ENCRYPTED_ATTRS=(
    "encrypted_firstName:Encrypted First Name"
    "encrypted_lastName:Encrypted Last Name"
    "encrypted_email:Encrypted Email"
    "encrypted_age:Encrypted Age"
    "encrypted_mobile:Encrypted Mobile"
    "encrypted_address:Encrypted Address"
    "encrypted_profession:Encrypted Profession"
)

# Array of encryption metadata
METADATA_ATTRS=(
    "wrapped_key:Wrapped Encryption Key"
    "webauthn_credential_id:WebAuthn Credential ID"
    "encryption_salt:Encryption Salt"
    "public_key:Public Key"
    "encryption_iv:Encryption IV"
    "wrapping_iv:Wrapping IV"
)

# Create mappers for encrypted attributes
echo ""
echo "📋 Creating mappers for encrypted attributes..."
for item in "${ENCRYPTED_ATTRS[@]}"; do
    IFS=':' read -r attr_name display_name <<< "$item"
    echo "  ✓ Creating mapper: $display_name"
    
    docker exec keycloak-sso /opt/keycloak/bin/kcadm.sh create \
        clients/django-saml-app/protocol-mappers/models -r demo \
        -s name="$display_name" \
        -s protocol=saml \
        -s protocolMapper=saml-user-attribute-mapper \
        -s 'config."attribute.nameformat"=Basic' \
        -s "config.\"user.attribute\"=$attr_name" \
        -s "config.\"attribute.name\"=$attr_name" \
        -s 'config."consent.required"=true' \
        -s "config.\"consent.text\"=Share $display_name" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "    ✅ $display_name created"
    else
        echo "    ⚠️  $display_name might already exist or error occurred"
    fi
done

# Create mappers for encryption metadata
echo ""
echo "🔑 Creating mappers for encryption metadata..."
for item in "${METADATA_ATTRS[@]}"; do
    IFS=':' read -r attr_name display_name <<< "$item"
    echo "  ✓ Creating mapper: $display_name"
    
    docker exec keycloak-sso /opt/keycloak/bin/kcadm.sh create \
        clients/django-saml-app/protocol-mappers/models -r demo \
        -s name="$display_name" \
        -s protocol=saml \
        -s protocolMapper=saml-user-attribute-mapper \
        -s 'config."attribute.nameformat"=Basic' \
        -s "config.\"user.attribute\"=$attr_name" \
        -s "config.\"attribute.name\"=$attr_name" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "    ✅ $display_name created"
    else
        echo "    ⚠️  $display_name might already exist or error occurred"
    fi
done

echo ""
echo "✅ Done! All mappers created."
echo ""
echo "📊 Verifying mappers..."
docker exec keycloak-sso /opt/keycloak/bin/kcadm.sh get \
    clients/django-saml-app/protocol-mappers/models -r demo --fields name | grep "encrypted\|wrapped\|webauthn\|salt\|public_key\|_iv"

echo ""
echo "🎉 Configuration complete!"
echo "Now test by logging in at: http://localhost:8001"
