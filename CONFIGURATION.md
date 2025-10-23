# Django SAML Configuration Guide

## Current Configuration Status ✅

Your Django SAML application has been configured with the following settings:

### 🔧 Application Endpoints

- **Home**: `http://127.0.0.1:8001/`
- **SAML Login**: `http://127.0.0.1:8001/api/saml/login/`
- **SAML Callback**: `http://127.0.0.1:8001/api/saml/callback/`
- **SAML Logout**: `http://127.0.0.1:8001/api/saml/logout/`
- **SAML Metadata**: `http://127.0.0.1:8001/api/saml/metadata/`

### 🎯 SAML Configuration

The application is pre-configured with default Keycloak settings:

- **IdP Entity ID**: `http://localhost:8080/realms/demo`
- **SSO URL**: `http://localhost:8080/realms/demo/protocol/saml`
- **SP Entity ID**: `django-saml-app`

### 🚀 Quick Start

1. **Test the Application**:
   ```bash
   # Visit the home page to see current status
   curl http://127.0.0.1:8001/
   ```

2. **Get SP Metadata**:
   ```bash
   # Get the metadata to configure in Keycloak
   curl http://127.0.0.1:8001/api/saml/metadata/
   ```

### 🔑 Keycloak Setup Required

To complete the SAML integration, you need to:

1. **Install and Start Keycloak**:
   ```bash
   # Download Keycloak from https://www.keycloak.org/downloads
   # Or use Docker:
   docker run -p 8080:8080 -e KEYCLOAK_ADMIN=admin -e KEYCLOAK_ADMIN_PASSWORD=admin quay.io/keycloak/keycloak:latest start-dev
   ```

2. **Create a Realm**:
   - Login to Keycloak admin console: `http://localhost:8080`
   - Create a new realm called `demo`

3. **Configure SAML Client**:
   - Client ID: `django-saml-app`
   - Client Protocol: `saml`
   - Root URL: `http://127.0.0.1:8001`
   - Valid Redirect URIs: `http://127.0.0.1:8001/api/saml/callback/`

4. **Update Certificate**:
   - Get the realm certificate from Keycloak
   - Update the `x509cert` field in `settings.py`

### 🔄 Session Management

The application now includes:
- ✅ Session-based authentication tracking
- ✅ Single Logout (SLO) support
- ✅ Proper error handling
- ✅ User attribute extraction

### 📝 Testing Without Keycloak

You can test the basic functionality by visiting:
- `http://127.0.0.1:8001/` - Home page with current auth status
- `http://127.0.0.1:8001/api/saml/metadata/` - SP metadata (for IdP configuration)

### 🛠️ Customization

To customize the SAML settings, edit the `SAML_SETTINGS` in `/SAML_DJNAGO/settings.py`:

- Change realm names
- Update URLs for production
- Modify attribute mappings
- Configure certificates

### 🔍 Troubleshooting

1. **Check server is running**: `http://127.0.0.1:8001/`
2. **View logs**: Check the terminal for Django server logs
3. **SAML debugging**: Set `"debug": True` in SAML_SETTINGS
4. **Validate metadata**: Visit the metadata endpoint

Your Django SAML application is now properly configured! 🎉
