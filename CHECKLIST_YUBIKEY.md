# ✅ YubiKey + Custom Attributes - Configuration Checklist

Use this checklist to track your progress as you configure Keycloak.

---

## Pre-Configuration

- [ ] Keycloak is running (`docker ps | grep keycloak-sso`)
- [ ] SP1 is running on port 8001
- [ ] SP2 is running on port 8002
- [ ] You can access http://localhost:8080 (Keycloak admin console)

---

## Part 1: Custom User Attributes (5 min)

**Location**: Realm Settings → User Profile

- [ ] Logged into Keycloak admin console (admin/admin)
- [ ] Selected "demo" realm (top-left dropdown)
- [ ] Navigated to "Realm settings" → "User profile" tab
- [ ] Added attribute: **age**
  - Display name: Age
  - Required: Yes
  - User can edit: ✓
- [ ] Added attribute: **mobile**
  - Display name: Mobile Number
  - Required: Yes
  - User can edit: ✓
- [ ] Added attribute: **address**
  - Display name: Address
  - Required: No
  - User can edit: ✓
- [ ] Added attribute: **profession**
  - Display name: Profession
  - Required: No
  - User can edit: ✓

---

## Part 2: YubiKey WebAuthn Setup (8 min)

### 2.1 Enable WebAuthn Required Actions

**Location**: Authentication → Required Actions

- [ ] Clicked "Authentication" in left sidebar
- [ ] Clicked "Required actions" tab
- [ ] Enabled "Webauthn Register Passwordless"
- [ ] Enabled "Webauthn Register"

### 2.2 Create YubiKey Authentication Flow

**Location**: Authentication → Flows

- [ ] Clicked "Flows" tab
- [ ] Clicked "Create flow"
- [ ] Created flow named "YubiKey Browser Flow" (Basic flow)
- [ ] Added step: **Cookie**
- [ ] Added step: **WebAuthn Passwordless Authenticator**
  - Set to: ALTERNATIVE
- [ ] Added sub-flow: **Forms** (Basic flow)
- [ ] In Forms sub-flow, added step: **Username Password Form**
  - Set to: REQUIRED
- [ ] In Forms sub-flow, added step: **WebAuthn Authenticator**
  - Set to: REQUIRED

### 2.3 Bind the Flow

**Location**: Authentication → Flows

- [ ] Found "Browser flow" dropdown at top of page
- [ ] Clicked "Action" → "Bind flow"
- [ ] Selected "Browser flow"
- [ ] Clicked "Save"

---

## Part 3: SAML Attribute Mappers - SP1 (8 min)

**Location**: Clients → saml-sp-1 → Client scopes → saml-sp-1-dedicated

- [ ] Navigated to "Clients" → "saml-sp-1"
- [ ] Clicked "Client scopes" tab
- [ ] Clicked "saml-sp-1-dedicated" scope
- [ ] Added mapper: **username-mapper**
  - Type: User Property
  - Property: username
  - SAML Attribute Name: username
  - SAML Attribute NameFormat: Basic
- [ ] Added mapper: **email-mapper**
  - Type: User Property
  - Property: email
  - SAML Attribute Name: email
  - SAML Attribute NameFormat: Basic
- [ ] Added mapper: **age-mapper**
  - Type: User Attribute
  - User Attribute: age
  - SAML Attribute Name: age
  - SAML Attribute NameFormat: Basic
- [ ] Added mapper: **mobile-mapper**
  - Type: User Attribute
  - User Attribute: mobile
  - SAML Attribute Name: mobile
  - SAML Attribute NameFormat: Basic
- [ ] Added mapper: **address-mapper**
  - Type: User Attribute
  - User Attribute: address
  - SAML Attribute Name: address
  - SAML Attribute NameFormat: Basic
- [ ] Added mapper: **profession-mapper**
  - Type: User Attribute
  - User Attribute: profession
  - SAML Attribute Name: profession
  - SAML Attribute NameFormat: Basic

---

## Part 4: SAML Attribute Mappers - SP2 (8 min)

**Location**: Clients → saml-sp-2 → Client scopes → saml-sp-2-dedicated

- [ ] Navigated to "Clients" → "saml-sp-2"
- [ ] Clicked "Client scopes" tab
- [ ] Clicked "saml-sp-2-dedicated" scope
- [ ] Added mapper: **username-mapper** (same as SP1)
- [ ] Added mapper: **email-mapper** (same as SP1)
- [ ] Added mapper: **age-mapper** (same as SP1)
- [ ] Added mapper: **mobile-mapper** (same as SP1)
- [ ] Added mapper: **address-mapper** (same as SP1)
- [ ] Added mapper: **profession-mapper** (same as SP1)

---

## Part 5: Update Test User (2 min)

**Location**: Users → testuser → Attributes

- [ ] Navigated to "Users"
- [ ] Found and clicked "testuser"
- [ ] Clicked "Attributes" tab
- [ ] Added attribute: age = `30`
- [ ] Added attribute: mobile = `+1-555-0100`
- [ ] Added attribute: address = `123 Main Street, New York, NY 10001`
- [ ] Added attribute: profession = `Software Developer`
- [ ] Clicked "Save"

---

## Part 6: Register YubiKey (Optional, 3 min)

**Location**: http://localhost:8080/realms/demo/account

### Option A: User Self-Registration (Recommended)

- [ ] Logged out from admin console
- [ ] Opened: http://localhost:8080/realms/demo/account
- [ ] Logged in as: testuser / password123
- [ ] Clicked "Account security" → "Signing in"
- [ ] Found "Passwordless" section
- [ ] Clicked "Set up Security Key"
- [ ] Inserted YubiKey
- [ ] Touched YubiKey when LED blinked
- [ ] Named it (e.g., "My YubiKey")
- [ ] Clicked "Save"

### Option B: Skip for Now

- [ ] Skipping YubiKey for now (can test attributes without it)

---

## Post-Configuration: Testing

### Restart Django Services

```bash
bash test-yubikey-attributes.sh
```

- [ ] Ran test script
- [ ] SP1 restarted successfully
- [ ] SP2 restarted successfully
- [ ] All services verified running

### Test Login

- [ ] Opened: http://127.0.0.1:8001/saml/login/
- [ ] Logged in: testuser / password123
- [ ] (If YubiKey registered) Touched YubiKey when prompted
- [ ] Redirected to success page
- [ ] Verified attributes displayed:
  - [ ] Username
  - [ ] Email
  - [ ] Age: 30
  - [ ] Mobile: +1-555-0100
  - [ ] Address: 123 Main Street, New York, NY 10001
  - [ ] Profession: Software Developer

### Check Console Logs

```bash
tail -f sp1.log
```

- [ ] Opened log file
- [ ] Saw authentication success message
- [ ] Saw all 6 attributes listed
- [ ] Attributes have correct values

### Test SP2

- [ ] Opened: http://127.0.0.1:8002/saml/login/
- [ ] Auto-logged in (SSO) OR logged in manually
- [ ] Verified same attributes displayed

---

## Troubleshooting (If Issues)

### Attributes Show "N/A"

- [ ] Verified mappers exist in Keycloak for both SPs
- [ ] Verified user has attributes set
- [ ] Restarted Django services
- [ ] Checked logs for errors

### YubiKey Not Prompted

- [ ] Verified WebAuthn flow is bound
- [ ] Verified user registered YubiKey
- [ ] Tried different browser
- [ ] Checked browser console for errors

### SAML Errors

- [ ] Installed SAML-tracer extension
- [ ] Captured SAML response
- [ ] Verified attributes in response XML
- [ ] Checked Keycloak logs: `docker logs keycloak-sso`

---

## ✅ Configuration Complete!

When all items above are checked:

- [ ] All 4 custom attributes added to Keycloak
- [ ] WebAuthn enabled and flow configured
- [ ] All 6 SAML mappers added for SP1
- [ ] All 6 SAML mappers added for SP2
- [ ] Test user updated with sample data
- [ ] (Optional) YubiKey registered
- [ ] Tested login flow successfully
- [ ] Verified attributes displayed correctly
- [ ] Checked console logs showing attributes

---

## Next Steps

1. **Customize Further**:
   - Add more custom attributes
   - Create additional mappers
   - Modify success page styling

2. **Production Deployment**:
   - Use HTTPS
   - Configure proper certificates
   - Update domain names
   - Set strong passwords

3. **Add More Users**:
   - Create additional test users
   - Register multiple YubiKeys
   - Test group-based attributes

---

## Quick Commands Reference

```bash
# Configuration wizard
bash configure-yubikey-attributes.sh

# Test and restart services
bash test-yubikey-attributes.sh

# View logs
tail -f sp1.log
tail -f sp2.log
docker logs -f keycloak-sso

# Check processes
ps aux | grep runserver
docker ps

# Stop services
pkill -f "runserver.*8001"
pkill -f "runserver.*8002"
docker stop keycloak-sso
```

---

**Time to complete**: ~36 minutes
**Difficulty**: Medium
**Prerequisites**: Keycloak admin access

**Documentation**:
- Full guide: `YUBIKEY_CUSTOM_ATTRIBUTES_GUIDE.md`
- Quick start: `QUICK_START_YUBIKEY.md`
