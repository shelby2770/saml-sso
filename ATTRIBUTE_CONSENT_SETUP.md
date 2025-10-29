# Manual Configuration for Attribute Selection in Keycloak

Since the Java extension approach has compilation complexities, we'll configure Keycloak manually through the Admin UI.

## ✅ Completed Steps

1. ✅ **Attribute Consent Page Created** (`attribute-consent.ftl`)
2. ✅ **JavaScript Handler Created** (`attribute-consent.js`)
3. ✅ **Files Deployed to Keycloak Container**

## 🔧 Manual Configuration Steps

### Step 1: Configure SAML Mappers for Encrypted Attributes

1. Login to Keycloak Admin Console: http://localhost:8080
2. Go to **Clients** → **django-saml-app**
3. Click on **Client scopes** tab
4. Select the dedicated scope or create a new one
5. Go to **Mappers** tab
6. Click **Add mapper** → **By configuration**
7. Select **User Attribute**

#### Create Mapper for Each Encrypted Attribute:

**Mapper 1: encrypted_firstName**
- Name: `Encrypted First Name`
- Mapper Type: `User Attribute`
- User Attribute: `encrypted_firstName`
- SAML Attribute Name: `encrypted_firstName`
- SAML Attribute NameFormat: `Basic`
- Click **Save**

**Mapper 2: encrypted_lastName**
- Name: `Encrypted Last Name`
- Mapper Type: `User Attribute`
- User Attribute: `encrypted_lastName`
- SAML Attribute Name: `encrypted_lastName`
- SAML Attribute NameFormat: `Basic`
- Click **Save**

**Mapper 3: encrypted_email**
- Name: `Encrypted Email`
- Mapper Type: `User Attribute`
- User Attribute: `encrypted_email`
- SAML Attribute Name: `encrypted_email`
- SAML Attribute NameFormat: `Basic`
- Click **Save**

**Mapper 4: encrypted_age**
- Name: `Encrypted Age`
- Mapper Type: `User Attribute`
- User Attribute: `encrypted_age`
- SAML Attribute Name: `encrypted_age`
- SAML Attribute NameFormat: `Basic`
- Click **Save**

**Mapper 5: encrypted_mobile**
- Name: `Encrypted Mobile`
- Mapper Type: `User Attribute`
- User Attribute: `encrypted_mobile`
- SAML Attribute Name: `encrypted_mobile`
- SAML Attribute NameFormat: `Basic`
- Click **Save**

**Mapper 6: encrypted_address**
- Name: `Encrypted Address`
- Mapper Type: `User Attribute`
- User Attribute: `encrypted_address`
- SAML Attribute Name: `encrypted_address`
- SAML Attribute NameFormat: `Basic`
- Click **Save**

**Mapper 7: encrypted_profession**
- Name: `Encrypted Profession`
- Mapper Type: `User Attribute`
- User Attribute: `encrypted_profession`
- SAML Attribute Name: `encrypted_profession`
- SAML Attribute NameFormat: `Basic`
- Click **Save**

#### Create Mappers for Encryption Metadata:

**Mapper 8: wrapped_key**
- Name: `Wrapped Key`
- Mapper Type: `User Attribute`
- User Attribute: `wrapped_key`
- SAML Attribute Name: `wrapped_key`
- SAML Attribute NameFormat: `Basic`
- Click **Save**

**Mapper 9: webauthn_credential_id**
- Name: `WebAuthn Credential ID`
- Mapper Type: `User Attribute`
- User Attribute: `webauthn_credential_id`
- SAML Attribute Name: `webauthn_credential_id`
- SAML Attribute NameFormat: `Basic`
- Click **Save**

**Mapper 10: encryption_salt**
- Name: `Encryption Salt`
- Mapper Type: `User Attribute`
- User Attribute: `encryption_salt`
- SAML Attribute Name: `encryption_salt`
- SAML Attribute NameFormat: `Basic`
- Click **Save**

**Mapper 11: public_key**
- Name: `Public Key`
- Mapper Type: `User Attribute`
- User Attribute: `public_key`
- SAML Attribute Name: `public_key`
- SAML Attribute NameFormat: `Basic`
- Click **Save**

**Mapper 12: encryption_iv**
- Name: `Encryption IV`
- Mapper Type: `User Attribute`
- User Attribute: `encryption_iv`
- SAML Attribute Name: `encryption_iv`
- SAML Attribute NameFormat: `Basic`
- Click **Save**

**Mapper 13: wrapping_iv**
- Name: `Wrapping IV`
- Mapper Type: `User Attribute`
- User Attribute: `wrapping_iv`
- SAML Attribute Name: `wrapping_iv`
- SAML Attribute NameFormat: `Basic`
- Click **Save**

### Step 2: Enable Consent Screen (Attribute Selection)

1. Go to **Clients** → **django-saml-app**
2. Go to **Settings** tab
3. Scroll to **Login settings** section
4. Enable **Consent Required**: Toggle **ON**
5. Click **Save**

### Step 3: Configure Consent Screen Text

1. Go to **Clients** → **django-saml-app**
2. Go to **Client scopes** tab
3. For each scope containing your mappers:
   - Click on the scope name
   - Go to **Mappers** tab
   - For each mapper, edit and add:
     - **Consent Text**: e.g., "Share encrypted first name"
     - Check **Display on consent screen**
     - Click **Save**

### Step 4: Test the Flow

1. Clear browser cache/cookies
2. Navigate to SP: `http://localhost:8001`
3. Click "Login with SAML"
4. Login to Keycloak
5. **Consent screen should appear** showing:
   - List of attributes to share
   - Checkboxes for selection
   - "Accept" and "Decline" buttons
6. Select desired attributes
7. Click "Accept"
8. SAML assertion should contain only selected encrypted attributes

## 🔍 Verification

### Check SAML Assertion Content:

1. Login to SP with SAML
2. View page source on success page
3. Look for raw SAML assertion
4. Verify only selected encrypted attributes are present
5. Verify encryption metadata (wrapped_key, credential_id, etc.) is present
6. Verify username is present (plain text)

### Expected SAML Attributes:

```xml
<saml:Attribute Name="encrypted_firstName">
    <saml:AttributeValue>V3NbJC4j...</saml:AttributeValue>
</saml:Attribute>
<saml:Attribute Name="encrypted_email">
    <saml:AttributeValue>dzl8YwlLv...</saml:AttributeValue>
</saml:Attribute>
<saml:Attribute Name="wrapped_key">
    <saml:AttributeValue>3ds32hf...</saml:AttributeValue>
</saml:Attribute>
<saml:Attribute Name="webauthn_credential_id">
    <saml:AttributeValue>P3USfgsM7...</saml:AttributeValue>
</saml:Attribute>
<!-- Other encryption metadata -->
<saml:Attribute Name="username">
    <saml:AttributeValue>adnanistaque6969</saml:AttributeValue>
</saml:Attribute>
```

## ⚙️ Alternative: Custom Consent Page

If you want to use the custom `attribute-consent.ftl` page instead of Keycloak's default:

### Option A: Override Default Consent Page

1. Rename `attribute-consent.ftl` to `oauth-grant.ftl` (Keycloak's consent page name)
2. Copy to theme:
   ```bash
   docker cp custom-registration-theme/login/attribute-consent.ftl \
       keycloak-sso:/opt/keycloak/themes/custom-registration-theme/login/oauth-grant.ftl
   ```
3. Restart Keycloak:
   ```bash
   docker restart keycloak-sso
   ```

### Option B: Use Required Action (Requires Java Extension)

This would need the Java extension to work, which we attempted but has compilation issues.

## 📝 Notes

- **Consent screen approach** is simpler and doesn't require Java extensions
- **All encryption metadata** is always included (needed for decryption)
- **Username** is always included (not encrypted, needed for identification)
- **Only selected encrypted attributes** are included in SAML assertion
- User can choose which attributes to share per SP per login

## 🎯 Next Steps

After configuration:
1. ✅ Test attribute selection flow
2. ✅ Verify SAML assertion contains only selected attributes
3. 🔄 Add decryption UI to SP success page
4. 🔄 Test end-to-end: register → login → select → decrypt

