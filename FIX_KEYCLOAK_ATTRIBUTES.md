# Fix Keycloak SAML Attribute Mapping

## Problem
Keycloak is NOT sending custom user attributes (phone, address, encrypted_payload, etc.) in the SAML response to the Service Provider.

**Evidence:**
- Browser console shows: `Raw Attributes Object: {}`
- User attributes are empty
- Encrypted attributes are empty

## Root Cause
The custom user attributes stored in Keycloak are not mapped to SAML assertion attributes. We need to configure SAML attribute mappers in Keycloak.

---

## Solution: Add SAML Attribute Mappers in Keycloak

### Step 1: Open Keycloak Admin Console
1. Go to: http://localhost:8080
2. Login with: admin/admin
3. Select realm: **demo**

### Step 2: Navigate to SAML Client
1. Click **Clients** in left menu
2. Find and click your SAML client (probably `http://127.0.0.1:8001/api/saml/metadata/`)

### Step 3: Add Attribute Mappers

Click **"Client scopes"** tab (or **"Mappers"** tab depending on Keycloak version)

Then click **"Add mapper"** or **"Create"** button.

Add the following mappers **one by one**:

---

#### Mapper 1: Email
- **Name:** email
- **Mapper Type:** User Property
- **Property:** email
- **Friendly Name:** email
- **SAML Attribute Name:** email
- **SAML Attribute NameFormat:** Basic
- Click **Save**

---

#### Mapper 2: Username
- **Name:** username
- **Mapper Type:** User Property
- **Property:** username
- **Friendly Name:** username
- **SAML Attribute Name:** username
- **SAML Attribute NameFormat:** Basic
- Click **Save**

---

#### Mapper 3: Phone (Custom Attribute)
- **Name:** phone
- **Mapper Type:** User Attribute
- **User Attribute:** phone
- **Friendly Name:** phone
- **SAML Attribute Name:** phone
- **SAML Attribute NameFormat:** Basic
- Click **Save**

---

#### Mapper 4: Address (Custom Attribute)
- **Name:** address
- **Mapper Type:** User Attribute
- **User Attribute:** address
- **Friendly Name:** address
- **SAML Attribute Name:** address
- **SAML Attribute NameFormat:** Basic
- Click **Save**

---

#### Mapper 5: Age (Custom Attribute)
- **Name:** age
- **Mapper Type:** User Attribute
- **User Attribute:** age
- **Friendly Name:** age
- **SAML Attribute Name:** age
- **SAML Attribute NameFormat:** Basic
- Click **Save**

---

#### Mapper 6: Mobile (Custom Attribute)
- **Name:** mobile
- **Mapper Type:** User Attribute
- **User Attribute:** mobile
- **Friendly Name:** mobile
- **SAML Attribute Name:** mobile
- **SAML Attribute NameFormat:** Basic
- Click **Save**

---

#### Mapper 7: Profession (Custom Attribute)
- **Name:** profession
- **Mapper Type:** User Attribute
- **User Attribute:** profession
- **Friendly Name:** profession
- **SAML Attribute Name:** profession
- **SAML Attribute NameFormat:** Basic
- Click **Save**

---

#### Mapper 8: Encrypted Payload
- **Name:** encrypted_payload
- **Mapper Type:** User Attribute
- **User Attribute:** encrypted_payload
- **Friendly Name:** encrypted_payload
- **SAML Attribute Name:** encrypted_payload
- **SAML Attribute NameFormat:** Basic
- Click **Save**

---

#### Mapper 9: Encrypted Payload Chunks
- **Name:** encrypted_payload_chunks
- **Mapper Type:** User Attribute
- **User Attribute:** encrypted_payload_chunks
- **Friendly Name:** encrypted_payload_chunks
- **SAML Attribute Name:** encrypted_payload_chunks
- **SAML Attribute NameFormat:** Basic
- Click **Save**

---

#### Mapper 10: Encrypted Payload Chunk 1
- **Name:** encrypted_payload_chunk1
- **Mapper Type:** User Attribute
- **User Attribute:** encrypted_payload_chunk1
- **Friendly Name:** encrypted_payload_chunk1
- **SAML Attribute Name:** encrypted_payload_chunk1
- **SAML Attribute NameFormat:** Basic
- Click **Save**

---

#### Mapper 11: Encrypted Payload Chunk 2
- **Name:** encrypted_payload_chunk2
- **Mapper Type:** User Attribute
- **User Attribute:** encrypted_payload_chunk2
- **Friendly Name:** encrypted_payload_chunk2
- **SAML Attribute Name:** encrypted_payload_chunk2
- **SAML Attribute NameFormat:** Basic
- Click **Save**

---

#### Mapper 12: Encrypted Payload Chunk 3
- **Name:** encrypted_payload_chunk3
- **Mapper Type:** User Attribute
- **User Attribute:** encrypted_payload_chunk3
- **Friendly Name:** encrypted_payload_chunk3
- **SAML Attribute Name:** encrypted_payload_chunk3
- **SAML Attribute NameFormat:** Basic
- Click **Save**

---

#### Mapper 13: WebAuthn Credential ID
- **Name:** webauthn_credential_id
- **Mapper Type:** User Attribute
- **User Attribute:** webauthn_credential_id
- **Friendly Name:** webauthn_credential_id
- **SAML Attribute Name:** webauthn_credential_id
- **SAML Attribute NameFormat:** Basic
- Click **Save**

---

#### Mapper 14: Encryption Salt
- **Name:** encryption_salt
- **Mapper Type:** User Attribute
- **User Attribute:** encryption_salt
- **Friendly Name:** encryption_salt
- **SAML Attribute Name:** encryption_salt
- **SAML Attribute NameFormat:** Basic
- Click **Save**

---

### Step 4: Verify User Has Attributes

1. Click **Users** in left menu
2. Find your test user (e.g., `dev_user`)
3. Click on the user
4. Go to **"Attributes"** tab
5. Make sure the custom attributes exist (phone, address, encrypted_payload, etc.)
6. If not, add them manually for testing:
   - Click **"Add attribute"**
   - Key: `phone`, Value: `+8801234567890`
   - Key: `address`, Value: `123 Test Street`
   - Click **Save**

---

### Step 5: Test Again

1. Logout from SP1 if logged in
2. Go to: http://127.0.0.1:8001
3. Click "Login with SAML"
4. Login with dev_user
5. Check browser console (F12 → Console tab)
6. You should now see attributes in the console output!

---

## Quick Check: Are Mappers Working?

After adding mappers, you can verify by:

1. Go to Clients → Your SAML Client
2. Click "Client scopes" or "Mappers" tab
3. You should see all 14+ mappers listed
4. Each mapper should show "User Attribute" or "User Property" as type

---

## Alternative: Use Keycloak API to Add Mappers

If you prefer, I can create a script to add all these mappers automatically using Keycloak's REST API.

---

## Why This Was Missing

When we created the custom registration theme with WebAuthn encryption, the user attributes were stored in Keycloak's database, but Keycloak wasn't configured to **include them in SAML assertions** sent to service providers.

SAML attribute mappers tell Keycloak: "When this SP authenticates, send these user attributes in the SAML response."

---

## After Fixing

Once mappers are added, the browser console will show:

```
📦 Raw Attributes Object: {
  email: "dev@example.com",
  username: "dev_user",
  phone: "+8801234567890",
  address: "123 Test Street",
  encrypted_payload: "...",
  webauthn_credential_id: "...",
  encryption_salt: "...",
  ...
}
```

And the success page will display all user attributes and encrypted attributes properly!
