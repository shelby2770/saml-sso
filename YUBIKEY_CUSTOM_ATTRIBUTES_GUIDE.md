# 🔐 YubiKey + Custom Attributes SAML Setup Guide

## Overview

This guide implements:
- **Custom User Attributes**: username, age, email, mobile, address, profession
- **YubiKey Authentication**: WebAuthn/FIDO2 based authentication
- **SAML Attribute Mapping**: Forward attributes from IdP to SP in SAML assertions
- **SP Display**: Django SPs will display received attributes

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         AUTHENTICATION FLOW                         │
└─────────────────────────────────────────────────────────────────────┘

1. User Registration (IdP):
   ┌──────────┐
   │  User    │ Provides: username, age, email, mobile, address, 
   │ Sign-up  │          profession + Registers YubiKey
   └────┬─────┘
        │
        ▼
   ┌──────────────────────────────────────┐
   │ Keycloak IdP                         │
   │ ✓ Stores user attributes             │
   │ ✓ Stores YubiKey public key          │
   │   (WebAuthn credential)              │
   └──────────────────────────────────────┘

2. User Authentication (SP → IdP):
   ┌──────────┐       SAML Request        ┌──────────────┐
   │   SP1    │ ────────────────────────→  │ Keycloak IdP │
   │  (8001)  │                            │              │
   └──────────┘                            └──────┬───────┘
                                                  │
                                                  ▼
                                          ┌──────────────┐
                                          │ User inserts │
                                          │   YubiKey    │
                                          │ & touches it │
                                          └──────┬───────┘
                                                 │
                                                 ▼
                                          ┌──────────────┐
                                          │ Verify using │
                                          │ stored public│
                                          │     key      │
                                          └──────┬───────┘
                                                 │
                                                 ▼
                                          ┌──────────────┐
                                          │Build SAML    │
                                          │Response with:│
                                          │- username    │
                                          │- age         │
                                          │- email       │
                                          │- mobile      │
                                          │- address     │
                                          │- profession  │
                                          └──────┬───────┘
                                                 │
   ┌──────────┐      SAML Response        ┌─────▼────────┐
   │   SP1    │ ◀─────────────────────────│ Keycloak IdP │
   │  (8001)  │                            │              │
   └────┬─────┘                            └──────────────┘
        │
        ▼
   ┌──────────────────────────────┐
   │ Display Attributes:          │
   │ • Username: john_doe         │
   │ • Age: 30                    │
   │ • Email: john@example.com    │
   │ • Mobile: +1-555-0100        │
   │ • Address: 123 Main St       │
   │ • Profession: Software Dev   │
   └──────────────────────────────┘
```

---

## Part 1: Configure Custom User Attributes in Keycloak

### Step 1.1: Login to Keycloak Admin Console
```
URL: http://localhost:8080
Username: admin
Password: admin
```

### Step 1.2: Add Custom Attributes to User Profile

1. Select **"demo"** realm (top-left dropdown)
2. Click **"Realm settings"** (left sidebar)
3. Click **"User profile"** tab
4. Click **"Create attribute"** button

Add these attributes one by one:

#### Attribute 1: Age
- **Attribute name**: `age`
- **Display name**: `Age`
- **Required**: Yes (or No, your choice)
- **Permissions**: Check "User can edit"
- **Validators**: Add "integer" validator (optional)
- Click **"Create"**

#### Attribute 2: Mobile
- **Attribute name**: `mobile`
- **Display name**: `Mobile Number`
- **Required**: Yes
- **Permissions**: Check "User can edit"
- **Validators**: Add "length" validator (min: 10, max: 15) (optional)
- Click **"Create"**

#### Attribute 3: Address
- **Attribute name**: `address`
- **Display name**: `Address`
- **Required**: No
- **Permissions**: Check "User can edit"
- Click **"Create"**

#### Attribute 4: Profession
- **Attribute name**: `profession`
- **Display name**: `Profession`
- **Required**: No
- **Permissions**: Check "User can edit"
- Click **"Create"**

**Note**: `username` and `email` are already built-in attributes in Keycloak.

---

## Part 2: Set Up YubiKey WebAuthn Authentication

### Step 2.1: Enable WebAuthn Passwordless

1. In **"demo"** realm, click **"Authentication"** (left sidebar)
2. Click **"Required actions"** tab
3. Find **"Webauthn Register Passwordless"** → Click **"Enabled"**
4. Also find **"Webauthn Register"** → Click **"Enabled"**

### Step 2.2: Create WebAuthn Authentication Flow

1. Click **"Flows"** tab
2. Click **"Create flow"** button
3. **Name**: `YubiKey Browser Flow`
4. **Flow type**: `Basic flow`
5. Click **"Create"**

6. In the new flow, click **"Add step"**
7. Select **"Cookie"** → Click **"Add"**
8. Click **"Add step"** again
9. Select **"WebAuthn Passwordless Authenticator"** → Click **"Add"**
10. Set **WebAuthn Passwordless** to **"ALTERNATIVE"** (click the dropdown)

11. Click **"Add sub-flow"**
12. **Name**: `Forms`
13. **Flow type**: `Basic flow`
14. Click **"Add"**

15. In the **Forms** sub-flow, click **"Add step"**
16. Select **"Username Password Form"** → Click **"Add"**
17. Click **"Add step"** again
18. Select **"WebAuthn Authenticator"** → Click **"Add"**
19. Set both to **"REQUIRED"**

### Step 2.3: Bind the Flow

1. Go to **"Authentication"** → **"Flows"** tab
2. At the top, find **"Browser flow"** dropdown
3. Select your **"YubiKey Browser Flow"**
4. Click **"Action"** → **"Bind flow"**
5. Select **"Browser flow"**
6. Click **"Save"**

---

## Part 3: Configure SAML Attribute Mappers

### Step 3.1: Configure SP1 (saml-sp-1)

1. In **"demo"** realm, click **"Clients"** (left sidebar)
2. Click on **"saml-sp-1"**
3. Click **"Client scopes"** tab
4. Click on **"saml-sp-1-dedicated"** (or the dedicated scope)
5. Click **"Add mapper"** → **"By configuration"**
6. Select **"User Property"**

Add these mappers:

#### Mapper 1: Username
- **Name**: `username-mapper`
- **Property**: `username`
- **SAML Attribute Name**: `username`
- **SAML Attribute NameFormat**: `Basic`
- Click **"Save"**

#### Mapper 2: Email
- **Name**: `email-mapper`
- **Property**: `email`
- **SAML Attribute Name**: `email`
- **SAML Attribute NameFormat**: `Basic`
- Click **"Save"**

#### Mapper 3: Age
- **Name**: `age-mapper`
- **Mapper Type**: `User Attribute`
- **User Attribute**: `age`
- **SAML Attribute Name**: `age`
- **SAML Attribute NameFormat**: `Basic`
- Click **"Save"**

#### Mapper 4: Mobile
- **Name**: `mobile-mapper`
- **Mapper Type**: `User Attribute`
- **User Attribute**: `mobile`
- **SAML Attribute Name**: `mobile`
- **SAML Attribute NameFormat**: `Basic`
- Click **"Save"**

#### Mapper 5: Address
- **Name**: `address-mapper`
- **Mapper Type**: `User Attribute`
- **User Attribute**: `address`
- **SAML Attribute Name**: `address`
- **SAML Attribute NameFormat**: `Basic`
- Click **"Save"**

#### Mapper 6: Profession
- **Name**: `profession-mapper`
- **Mapper Type**: `User Attribute`
- **User Attribute**: `profession`
- **SAML Attribute Name**: `profession`
- **SAML Attribute NameFormat**: `Basic`
- Click **"Save"**

### Step 3.2: Repeat for SP2 (saml-sp-2)

Repeat the exact same steps for the **"saml-sp-2"** client.

---

## Part 4: Create Test User with Attributes

### Step 4.1: Update Existing User

1. In **"demo"** realm, click **"Users"** (left sidebar)
2. Find and click on **"testuser"**
3. Click **"Attributes"** tab
4. Add the custom attributes:
   - **age**: `30`
   - **mobile**: `+1-555-0100`
   - **address**: `123 Main Street, New York, NY 10001`
   - **profession**: `Software Developer`
5. Click **"Save"**

### Step 4.2: Register YubiKey for User

**Option A: Self-Registration (Recommended)**
1. Logout from admin console
2. Open: http://localhost:8080/realms/demo/account
3. Login as **testuser** / **password123**
4. Click **"Account security"** → **"Signing in"**
5. Find **"Passwordless"** section
6. Click **"Set up Security Key"**
7. Insert YubiKey and touch it when prompted
8. Give it a name (e.g., "My YubiKey")
9. Click **"Save"**

**Option B: Admin Registration**
1. In admin console, go to **Users** → **testuser**
2. Click **"Credentials"** tab
3. Click **"Set password"** (if not already set)
4. Password: `password123`
5. Temporary: **OFF**
6. Click **"Save"**

Then user must register YubiKey via Account Console (Option A).

---

## Part 5: Update Django Service Providers

### Step 5.1: Update SP1 Views

The SP1 needs to parse SAML attributes and display them.

File: `/home/shelby70/Projects/Django-SAML (2)/django_saml_Auth/views.py`

We'll update the login callback to extract and display attributes.

### Step 5.2: Update SP2 Views

File: `/home/shelby70/Projects/Django-SAML (2)/SAML_DJNAGO_2/django_saml_Auth/views.py`

Same changes as SP1.

---

## Part 6: Testing the Complete Flow

### Test Steps:

1. **Open SP1 in browser**:
   ```
   http://127.0.0.1:8001/saml/login/
   ```

2. **You'll be redirected to Keycloak login page**

3. **Enter credentials**:
   - Username: `testuser`
   - Password: `password123`

4. **YubiKey Challenge**:
   - Insert YubiKey
   - Touch it when LED blinks

5. **After successful authentication**:
   - Redirected back to SP1
   - Success page shows all attributes:
     ```
     ✅ Successfully authenticated!
     
     User Attributes:
     • Username: testuser
     • Email: testuser@example.com
     • Age: 30
     • Mobile: +1-555-0100
     • Address: 123 Main Street, New York, NY 10001
     • Profession: Software Developer
     ```

6. **Test SSO with SP2**:
   ```
   http://127.0.0.1:8002/saml/login/
   ```
   - Should auto-login without YubiKey (session already exists)
   - Shows same attributes

---

## Important Notes

### YubiKey Support

- **Browser Compatibility**: WebAuthn works in Chrome, Firefox, Edge, Safari
- **YubiKey Models**: YubiKey 5 series, Security Key series
- **USB/NFC**: Both supported (NFC on mobile browsers)

### Security Considerations

1. **Public Key Storage**: Keycloak stores YubiKey's public key, never private key
2. **Challenge-Response**: Each authentication uses unique challenge
3. **Phishing Protection**: YubiKey validates the origin (localhost:8080)
4. **Replay Protection**: Nonce-based, prevents replay attacks

### Attribute Privacy

- Attributes are sent in **encrypted SAML assertion** (signed by IdP)
- SP verifies signature before trusting attributes
- Use HTTPS in production!

### Debugging

**Check SAML Response**:
```bash
# In Django, enable SAML debug logging
# Add to settings.py:
LOGGING = {
    'version': 1,
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
        },
    },
    'loggers': {
        'djangosaml2': {
            'handlers': ['console'],
            'level': 'DEBUG',
        },
    },
}
```

**View SAML Response in Browser**:
- Install browser extension: "SAML-tracer" (Firefox/Chrome)
- Capture SAML response during login
- Verify attributes are present in `<saml:Attribute>` elements

---

## Troubleshooting

### YubiKey Not Recognized
- Check browser supports WebAuthn: https://caniuse.com/webauthn
- Try different USB port
- Update YubiKey firmware: https://www.yubico.com/support/download/yubikey-manager/

### Attributes Not Showing in SP
- Verify attribute mappers are configured in Keycloak client
- Check user has attributes set in Keycloak
- Enable SAML debug logging in Django
- Use SAML-tracer to inspect SAML response

### Authentication Flow Not Using YubiKey
- Verify authentication flow is bound to "Browser flow"
- Check WebAuthn is enabled in Required Actions
- User must register YubiKey first via Account Console

---

## Next Steps

1. ✅ Configure custom attributes (this guide)
2. ✅ Set up YubiKey authentication (this guide)
3. ✅ Update Django SPs to display attributes (code coming next)
4. 🔜 Test with real YubiKey
5. 🔜 Add more attributes as needed
6. 🔜 Deploy to production with HTTPS

---

## Quick Command Reference

**Restart Keycloak** (after config changes):
```bash
cd "/home/shelby70/Projects/Django-SAML (2)"
bash stop-keycloak.sh
bash start-keycloak.sh
```

**Check SP1 Status**:
```bash
ps aux | grep "runserver.*8001"
```

**View SP1 Logs**:
```bash
tail -f sp1.log
```

**View Keycloak Logs**:
```bash
docker logs -f keycloak-sso
```

---

## File Structure

```
Django-SAML (2)/
├── django_saml_Auth/
│   └── views.py                    # SP1 - Updated to show attributes
├── SAML_DJNAGO_2/
│   └── django_saml_Auth/
│       └── views.py                # SP2 - Updated to show attributes
├── templates/
│   └── success.html               # Shows user attributes
└── YUBIKEY_CUSTOM_ATTRIBUTES_GUIDE.md  # This file
```

---

**Let's implement this! 🚀**
