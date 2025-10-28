# Keycloak Not Sending Attributes - Root Cause & Solution

## 🔍 Problem Identified

The Django server logs show:
```
============================================================
🔍 RAW ATTRIBUTES FROM KEYCLOAK (Development Mode):
============================================================
============================================================
```

**The section is EMPTY!** This means:
- ✅ SAML authentication works
- ✅ Attribute mappers are configured in Keycloak
- ❌ **Keycloak is NOT including attributes in the SAML assertion**

## 🎯 Root Cause

Even though we added attribute mappers in the client scope, there are TWO possible issues:

### Issue 1: User Attributes Don't Exist
The mappers can only send attributes that **exist** in the user's profile.

### Issue 2: Client Scope Not Applied to Client
The `django-saml-app-dedicated` scope might not be properly assigned to the SAML client.

---

## ✅ Solution Steps

### Step 1: Verify User Has Attributes

1. Go to Keycloak Admin: http://localhost:8080
2. Login: admin/admin
3. Realm: demo
4. Click **"Users"** in left menu
5. Search for the username you're using to login
6. Click on the user
7. Go to **"Attributes"** tab
8. **CHECK** if these attributes exist:
   - mobile
   - address
   - age
   - profession
   - email
   - (and encrypted attributes if applicable)

**If attributes are MISSING**, add them:
- Click "Add attribute"
- Key: `mobile`, Value: `+8801234567890`
- Key: `address`, Value: `123 Test Street`
- Key: `age`, Value: `25`
- Key: `profession`, Value: `Developer`
- Click **Save**

### Step 2: Verify Client Scope Assignment

1. In Keycloak Admin, go to **"Clients"**
2. Find and click **"django-saml-app"**
3. Go to **"Client scopes"** tab
4. Look at **"Assigned client scopes"** section
5. **VERIFY** that `django-saml-app-dedicated` is listed with type "Default"

If it's NOT there or marked as "Optional":
- Click "Add client scope"
- Select `django-saml-app-dedicated`
- Choose **"Default"** (not Optional)
- Click "Add"

### Step 3: Check Mapper Configuration

1. While in the client, go to **"Client scopes"** tab
2. Click on **"django-saml-app-dedicated"** (the blue link)
3. Click **"Mappers"** tab
4. **VERIFY** all these mappers exist:
   - email (User Property)
   - username (User Property)
   - mobile (User Attribute)
   - address (User Attribute)
   - age (User Attribute)
   - profession (User Attribute)
   - encrypted_payload (User Attribute)
   - encrypted_payload_chunks (User Attribute)
   - encrypted_payload_chunk1 (User Attribute)
   - encrypted_payload_chunk2 (User Attribute)
   - encrypted_payload_chunk3 (User Attribute)
   - webauthn_credential_id (User Attribute)
   - encryption_salt (User Attribute)

### Step 4: Test with a Known Good User

Create a test user with attributes:

1. Go to **"Users"** → **"Add user"**
2. Username: `test_attributes`
3. Email: `test@example.com`
4. Click **Save**
5. Go to **"Credentials"** tab
6. Set password: `Test123!`
7. Disable "Temporary"
8. Click **Save password**
9. Go to **"Attributes"** tab
10. Add these attributes:
    - mobile: `+1234567890`
    - address: `123 Test St`
    - age: `30`
    - profession: `Engineer`
11. Click **Save**

Now login with `test_attributes / Test123!` and check if attributes appear!

---

## 🧪 Testing & Debugging

### Test 1: Check SAML Assertion XML

To see what Keycloak is actually sending:

1. In Keycloak Admin, go to **"Clients"** → **"django-saml-app"**
2. Go to **"Settings"** tab
3. Temporarily enable **"Include AuthnStatement"**
4. Click **Save**
5. Login to SP1 again
6. Check `sp1.log` for the debug output

### Test 2: Use Browser Network Tab

1. Open browser DevTools (F12)
2. Go to **"Network"** tab
3. Clear network log
4. Login to SP1
5. Find the POST request to `/api/saml/callback/`
6. Look at the **Form Data** → **SAMLResponse**
7. Copy the base64 string
8. Decode it at: https://www.samltool.com/decode.php
9. Look for `<saml:Attribute>` tags - do they exist?

---

## 💡 Common Issues & Fixes

### Issue: "Attributes still not showing"
**Solution**: Clear browser cache and cookies, then try again

### Issue: "Only some attributes showing"
**Solution**: Check that all attribute mappers use `nameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic"`

### Issue: "Attributes showing for some users but not others"
**Solution**: Check each user's "Attributes" tab - they must have the attributes stored

### Issue: "Getting signature validation errors"
**Solution**: This is expected in development mode. The code now extracts attributes even with signature errors.

---

## 📋 Quick Checklist

- [ ] User attributes exist in Keycloak user profile
- [ ] Client scope `django-saml-app-dedicated` is assigned as "Default"
- [ ] All attribute mappers are configured correctly
- [ ] Mappers use correct attribute names (case-sensitive!)
- [ ] Django server is running with updated code
- [ ] Tested with a fresh login

---

## 🎯 Expected Result

After fixing, the debug output should show:

```
============================================================
🔍 RAW ATTRIBUTES FROM KEYCLOAK (Development Mode):
============================================================
  Key: 'email' = Value: 'test@example.com'
  Key: 'mobile' = Value: '+1234567890'
  Key: 'address' = Value: '123 Test St'
  Key: 'age' = Value: '30'
  Key: 'profession' = Value: 'Engineer'
============================================================
```

And the success page will display all attributes!

---

## 🚀 Next Steps

1. Follow Steps 1-4 above
2. Create/use a test user with attributes
3. Login to SP1
4. Check `sp1.log` for debug output
5. Verify attributes appear on success page

If attributes still don't appear after following all steps, the issue might be with the SAML assertion format or Keycloak realm configuration.
