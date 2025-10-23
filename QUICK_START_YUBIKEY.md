# 🎯 Quick Start: YubiKey + Custom Attributes

## What's Been Done

✅ **Django Service Providers Updated**:
- SP1 and SP2 views now extract SAML attributes
- Success pages display user attributes beautifully
- Console logging shows received attributes

✅ **Templates Enhanced**:
- Added animated attribute cards with icons
- Responsive grid layout
- Professional styling with gradients

## What You Need to Do in Keycloak

### 📋 Checklist

Run this to see the complete guide:
```bash
bash configure-yubikey-attributes.sh
```

Or follow manually:

#### 1. Add Custom Attributes (5 min)
- Go to: Realm Settings → User Profile
- Add: `age`, `mobile`, `address`, `profession`

#### 2. Enable WebAuthn (3 min)
- Go to: Authentication → Required Actions
- Enable: "Webauthn Register" and "Webauthn Register Passwordless"

#### 3. Create YubiKey Flow (5 min)
- Go to: Authentication → Flows
- Create flow: "YubiKey Browser Flow"
- Add: Cookie, WebAuthn Passwordless, Username/Password Form, WebAuthn
- Bind to Browser flow

#### 4. Add SAML Mappers for SP1 (8 min)
- Go to: Clients → saml-sp-1 → Client scopes → saml-sp-1-dedicated
- Add 6 mappers: username, email, age, mobile, address, profession

#### 5. Add SAML Mappers for SP2 (8 min)
- Go to: Clients → saml-sp-2 → Client scopes → saml-sp-2-dedicated
- Add same 6 mappers

#### 6. Update Test User (2 min)
- Go to: Users → testuser → Attributes
- Add values:
  - age: `30`
  - mobile: `+1-555-0100`
  - address: `123 Main Street, New York, NY 10001`
  - profession: `Software Developer`

#### 7. Register YubiKey (Optional, 3 min)
- Go to: http://localhost:8080/realms/demo/account
- Login as testuser
- Account Security → Signing In → Set up Security Key

---

## Testing

### Quick Test
```bash
bash test-yubikey-attributes.sh
```

This will:
1. Restart SP1 and SP2
2. Verify all services are running
3. Give you test instructions

### Manual Test

1. **Open SP1**:
   ```
   http://127.0.0.1:8001/saml/login/
   ```

2. **Login**:
   - Username: `testuser`
   - Password: `password123`
   - (Touch YubiKey if registered)

3. **Expected Result**:
   Success page shows:
   - ✅ Username: testuser
   - ✅ Email: (your email)
   - ✅ Age: 30
   - ✅ Mobile: +1-555-0100
   - ✅ Address: 123 Main Street, New York, NY 10001
   - ✅ Profession: Software Developer

4. **Check Console Logs**:
   ```bash
   tail -f sp1.log
   ```
   
   Should show:
   ```
   ============================================================
   🎉 SAML AUTHENTICATION SUCCESSFUL
   ============================================================
   NameID: testuser
   
   📋 User Attributes Received:
     • Username: testuser
     • Email: testuser@example.com
     • Age: 30
     • Mobile: +1-555-0100
     • Address: 123 Main Street, New York, NY 10001
     • Profession: Software Developer
   ============================================================
   ```

---

## Files Modified

### SP1
- `/django_saml_Auth/views.py` - Extract and log attributes
- `/templates/success.html` - Display attributes with styling

### SP2
- `/SAML_DJNAGO_2/django_saml_Auth/views.py` - Extract and log attributes
- `/SAML_DJNAGO_2/templates/success.html` - Display attributes with styling

---

## Architecture Flow

```
User → SP1/SP2 → Keycloak IdP → YubiKey Auth → SAML Response with Attributes → SP displays them
```

**SAML Response includes**:
```xml
<saml:Attribute Name="username">
  <saml:AttributeValue>testuser</saml:AttributeValue>
</saml:Attribute>
<saml:Attribute Name="age">
  <saml:AttributeValue>30</saml:AttributeValue>
</saml:Attribute>
<saml:Attribute Name="mobile">
  <saml:AttributeValue>+1-555-0100</saml:AttributeValue>
</saml:Attribute>
<!-- ... and more ... -->
```

---

## YubiKey Details

### How It Works

1. **Registration Phase** (one-time):
   - User inserts YubiKey
   - Browser generates key pair
   - **Private key** stored in YubiKey (never leaves device)
   - **Public key** sent to Keycloak for storage

2. **Authentication Phase** (every login):
   - Keycloak sends challenge
   - YubiKey signs challenge with private key
   - Keycloak verifies signature with stored public key
   - ✅ Authentication successful

### Security Benefits

- 🔒 **Phishing Protection**: YubiKey validates domain
- 🔐 **No Shared Secrets**: Public key cryptography
- 🚫 **Replay Protection**: Unique challenge each time
- 💪 **Physical Presence**: Requires touch

### Without YubiKey

If you don't have a YubiKey or skip registration:
- ✅ Attribute mapping still works perfectly
- ✅ Use username/password authentication
- ✅ All SAML attributes will be displayed
- ❌ Just missing the extra security layer

---

## Troubleshooting

### Attributes Show "N/A"

**Problem**: Attributes display as "N/A" on success page

**Solutions**:
1. ✅ Verify mappers added in Keycloak for both SP1 and SP2
2. ✅ Verify user has attributes set in Keycloak (Users → testuser → Attributes)
3. ✅ Restart Django servers: `bash test-yubikey-attributes.sh`
4. ✅ Check logs: `tail -f sp1.log` - should show received attributes

### YubiKey Not Prompted

**Problem**: Login doesn't ask for YubiKey

**Solutions**:
1. ✅ Verify WebAuthn flow is bound to Browser flow
2. ✅ Verify user has registered YubiKey (Account Console)
3. ✅ Try different browser (Chrome/Firefox/Edge)
4. ✅ Check browser console for WebAuthn errors

### SAML Attribute Not Received

**Problem**: Some attributes missing in SAML response

**Solutions**:
1. ✅ Install SAML-tracer browser extension
2. ✅ Capture SAML response during login
3. ✅ Verify `<saml:Attribute Name="...">` present
4. ✅ Check mapper configuration (exact attribute names)

---

## Next Steps

### 1. Test Basic Flow (No YubiKey)
```bash
bash test-yubikey-attributes.sh
# Open http://127.0.0.1:8001/saml/login/
# Login: testuser / password123
```

### 2. Configure Keycloak
```bash
bash configure-yubikey-attributes.sh
# Follow interactive prompts
```

### 3. Test with YubiKey
- Register YubiKey via Account Console
- Login and touch YubiKey when prompted
- Verify attributes displayed

### 4. Customize
- Add more attributes in Keycloak
- Update mappers to include new attributes
- Modify `views.py` to extract new attributes
- Update `success.html` to display them

---

## Documentation

📚 **Complete Guide**: `YUBIKEY_CUSTOM_ATTRIBUTES_GUIDE.md`
🔧 **Configuration**: `configure-yubikey-attributes.sh`
🧪 **Testing**: `test-yubikey-attributes.sh`

---

## Summary

**What's Working**:
- ✅ Django SPs ready to display attributes
- ✅ Templates styled and animated
- ✅ Console logging configured
- ✅ Scripts ready for testing

**What You Do**:
- ⏳ Configure Keycloak (30 min)
- ⏳ Add user attributes
- ⏳ Create SAML mappers
- ⏳ (Optional) Register YubiKey
- ⏳ Test!

**Time Estimate**: 30-40 minutes total

---

🚀 **Ready to start? Run:**
```bash
bash configure-yubikey-attributes.sh
```
