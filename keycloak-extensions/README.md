# Keycloak Attribute Consent Extension

This extension adds attribute selection functionality to Keycloak for SAML SSO with encrypted attributes.

## Components

### 1. Required Action: AttributeConsentRequiredAction
- Triggers after authentication for SAML protocol
- Shows attribute selection page (`attribute-consent.ftl`)
- Stores selected attributes in authentication session

### 2. Protocol Mapper: EncryptedAttributeMapper
- Custom SAML mapper for encrypted attributes
- Includes only selected attributes in SAML assertion
- Always includes encryption metadata (wrapped_key, credential_id, etc.)
- Always includes username (not encrypted)

## Build and Deploy

```bash
chmod +x build-and-deploy.sh
./build-and-deploy.sh
```

This will:
1. Build the JAR file with Maven
2. Copy to Keycloak's `/opt/keycloak/providers/` directory
3. Restart Keycloak to load the extension

## Manual Configuration (After Deployment)

### 1. Enable Required Action
1. Login to Keycloak Admin Console
2. Go to **Authentication** → **Required Actions**
3. Enable **"Attribute Consent for SAML"**
4. Set as **Default Action** (optional)

### 2. Add Protocol Mapper to Client
1. Go to **Clients** → **django-saml-app**
2. Go to **Mappers** tab
3. Click **Add Builtin**
4. Select **"Encrypted Attribute Mapper"**
5. Save

## How It Works

### Registration Flow:
1. User registers with encrypted attributes (YubiKey)
2. Attributes stored in Keycloak as `encrypted_*` user attributes

### Login Flow:
1. User authenticates to Keycloak
2. **Required Action triggers** (for SAML protocol)
3. Attribute consent page shown
4. User selects which attributes to share
5. Selected attributes stored in auth session
6. **Custom mapper** includes only selected attributes in SAML assertion
7. SP receives SAML with encrypted selected attributes

### SAML Assertion Contents:
- ✅ Selected encrypted attributes (encrypted_firstName, encrypted_age, etc.)
- ✅ Encryption metadata (wrapped_key, credential_id, salt, IVs)
- ✅ Username (plain text)
- ❌ Non-selected attributes (excluded)

## Files Created

```
keycloak-extensions/
├── pom.xml                                    # Maven build configuration
├── build-and-deploy.sh                        # Build and deployment script
├── README.md                                  # This file
└── src/main/
    ├── java/com/saml/keycloak/
    │   ├── consent/
    │   │   ├── AttributeConsentRequiredAction.java        # Required action implementation
    │   │   └── AttributeConsentRequiredActionFactory.java # Factory
    │   └── mapper/
    │       ├── EncryptedAttributeMapper.java              # SAML mapper implementation
    │       └── EncryptedAttributeMapperFactory.java       # Factory
    └── resources/META-INF/services/
        ├── org.keycloak.authentication.RequiredActionFactory  # SPI descriptor
        └── org.keycloak.protocol.ProtocolMapper              # SPI descriptor
```

## Requirements

- Java 17+
- Maven 3.6+
- Keycloak 23.0.7
- Custom theme with `attribute-consent.ftl` page

## Theme Files Required

```
custom-registration-theme/login/
├── attribute-consent.ftl                      # Attribute selection page
└── resources/js/
    └── attribute-consent.js                   # Selection logic
```
