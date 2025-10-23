# Keycloak SAML Setup Guide

## 🎯 Current Status
- ✅ Keycloak is running at `http://localhost:8080`
- ✅ Django SAML app is running at `http://127.0.0.1:8001`
- ❌ "demo" realm needs to be created
- ❌ SAML client needs to be configured

## 📋 Step-by-Step Setup

### Step 1: Access Keycloak Admin Console
1. Go to: `http://localhost:8080/admin/`
2. Login with admin credentials (usually admin/admin if using Docker)

### Step 2: Create the "demo" Realm
1. Click on "Master" dropdown (top-left corner)
2. Click "Create Realm"
3. Enter Realm name: `demo`
4. Click "Create"

### Step 3: Create SAML Client for SP1
1. In the "demo" realm, go to "Clients" in the left menu
2. Click "Create client"
3. Configure as follows:
   - **Client type**: SAML
   - **Client ID**: `http://127.0.0.1:8001/api/saml/metadata/`
   - **Name**: Django SAML Application SP1
   - Click "Next"

### Step 3b: Create SAML Client for SP2
1. Click "Create client" again
2. Configure as follows:
   - **Client type**: SAML
   - **Client ID**: `http://127.0.0.1:8002/api/saml/metadata/`
   - **Name**: Django SAML Application SP2
   - Click "Next"

### Step 4: Configure Client Settings for SP1
1. **General Settings**:
   - Root URL: `http://127.0.0.1:8001`
   - Home URL: `http://127.0.0.1:8001`

2. **SAML Settings**:
   - Valid redirect URIs: `http://127.0.0.1:8001/api/saml/callback/`
   - Base URL: `http://127.0.0.1:8001`
   - Master SAML Processing URL: `http://127.0.0.1:8001/api/saml/callback/`

3. **Advanced Settings**:
   - Assertion Consumer Service POST Binding URL: `http://127.0.0.1:8001/api/saml/callback/`
   - Logout Service POST Binding URL: `http://127.0.0.1:8001/api/saml/sls/`

4. Click "Save"

### Step 4b: Configure Client Settings for SP2
1. **General Settings**:
   - Root URL: `http://127.0.0.1:8002`
   - Home URL: `http://127.0.0.1:8002`

2. **SAML Settings**:
   - Valid redirect URIs: `http://127.0.0.1:8002/api/saml/callback/`
   - Base URL: `http://127.0.0.1:8002`
   - Master SAML Processing URL: `http://127.0.0.1:8002/api/saml/callback/`

3. **Advanced Settings**:
   - Assertion Consumer Service POST Binding URL: `http://127.0.0.1:8002/api/saml/callback/`
   - Logout Service POST Binding URL: `http://127.0.0.1:8002/api/saml/sls/`

4. Click "Save"

### Step 5: Configure Client Scopes and Mappers
1. Go to "Client scopes" tab
2. Add mappers for user attributes:
   - First Name → given_name
   - Last Name → family_name
   - Email → email

### Step 6: Get Realm Certificate
1. Go to "Realm settings" → "Keys" tab
2. Find the RSA256 key and click "Certificate"
3. Copy the certificate content

### Step 7: Update Django Configuration
1. Add the certificate to your Django settings.py
2. Update the x509cert field in SAML_SETTINGS

## 🚀 Quick Test Commands

After setup, test the integration:

```bash
# Test SAML login flow
curl -L "http://127.0.0.1:8001/api/saml/login/"

# Check metadata
curl "http://127.0.0.1:8001/api/saml/metadata/"
```

## 🔧 Alternative: Auto-Configuration Script

I can help you create a realm configuration file that can be imported into Keycloak for faster setup.
