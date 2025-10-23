# 🎯 Step-by-Step Keycloak Configuration Guide

Let's configure Keycloak together! I'll guide you through each step.

---

## ✅ Pre-Check: Services Running

Before we start, verify these are all running:
- ✅ Keycloak: http://localhost:8080
- ✅ SP1: http://127.0.0.1:8001
- ✅ SP2: http://127.0.0.1:8002

---

## 📋 STEP 1: Add Custom User Attributes (5 minutes)

### Open Keycloak Admin Console

1. **Open your browser** and go to: http://localhost:8080
2. **Click "Administration Console"**
3. **Login** with:
   - Username: `admin`
   - Password: `admin`

### Navigate to User Profile

4. **Select the "demo" realm**
   - Look at the **top-left corner**
   - You should see a dropdown (might say "master" or "demo")
   - Click it and select **"demo"**

5. **Click "Realm settings"** in the left sidebar

6. **Click "User profile"** tab at the top

### Add Attribute 1: Age

7. **Click "Create attribute"** button (top right)

8. **Fill in the form**:
   ```
   Attribute name:     age
   Display name:       Age
   Required:           ✓ (check this box)
   ```

9. **Scroll down to "Permissions"**:
   - Check the box: **"User can edit"**

10. **Click "Create"** button at the bottom

✅ **Checkpoint**: You should see "age" in the attributes list

### Add Attribute 2: Mobile

11. **Click "Create attribute"** button again

12. **Fill in**:
   ```
   Attribute name:     mobile
   Display name:       Mobile Number
   Required:           ✓ (check this)
   ```

13. **Permissions**: Check **"User can edit"**

14. **Click "Create"**

✅ **Checkpoint**: You should see "mobile" in the list

### Add Attribute 3: Address

15. **Click "Create attribute"** again

16. **Fill in**:
   ```
   Attribute name:     address
   Display name:       Address
   Required:           (leave unchecked - NOT required)
   ```

17. **Permissions**: Check **"User can edit"**

18. **Click "Create"**

✅ **Checkpoint**: You should see "address" in the list

### Add Attribute 4: Profession

19. **Click "Create attribute"** again

20. **Fill in**:
   ```
   Attribute name:     profession
   Display name:       Profession
   Required:           (leave unchecked - NOT required)
   ```

21. **Permissions**: Check **"User can edit"**

22. **Click "Create"**

✅ **STEP 1 COMPLETE!** You should now see 4 custom attributes:
   - age
   - mobile
   - address
   - profession

**Screenshot checkpoint**: The User profile attributes list should show these 4 attributes.

---

## 🔐 STEP 2: Enable WebAuthn for YubiKey (3 minutes)

### Navigate to Authentication

1. **Click "Authentication"** in the left sidebar

2. **Click "Required actions"** tab at the top

### Enable WebAuthn Options

3. Find **"Webauthn Register Passwordless"** in the list
   - Click the toggle or checkbox to **Enable** it

4. Find **"Webauthn Register"** in the list
   - Click the toggle or checkbox to **Enable** it

✅ **STEP 2 COMPLETE!** Both WebAuthn options should now be enabled.

---

## 🔑 STEP 3: Create YubiKey Authentication Flow (8 minutes)

### Create a New Flow

1. **Click "Flows"** tab (should still be in Authentication section)

2. **Click "Create flow"** button (top right)

3. **Fill in**:
   ```
   Name:        YubiKey Browser Flow
   Description: (optional) Browser flow with YubiKey support
   Flow type:   Basic flow
   ```

4. **Click "Create"**

### Add Cookie Step

5. You should now see the flow builder screen with "YubiKey Browser Flow"

6. **Click "Add step"** button

7. **Select "Cookie"** from the list

8. **Click "Add"**

9. The Cookie step should appear - leave it as is (usually ALTERNATIVE)

### Add WebAuthn Passwordless Step

10. **Click "Add step"** button again

11. **Select "WebAuthn Passwordless Authenticator"**

12. **Click "Add"**

13. Find the dropdown next to "WebAuthn Passwordless Authenticator"
    - Change it to **"ALTERNATIVE"**

### Add Forms Sub-flow

14. **Click "Add sub-flow"** button (different from "Add step")

15. **Fill in**:
    ```
    Name:        Forms
    Description: (optional)
    Flow type:   Basic flow
    ```

16. **Click "Add"**

### Add Steps to Forms Sub-flow

17. You should see a "Forms" sub-flow. **Click "Add step"** inside the Forms section

18. **Select "Username Password Form"**

19. **Click "Add"**

20. Change the dropdown next to "Username Password Form" to **"REQUIRED"**

21. **Click "Add step"** again (inside Forms sub-flow)

22. **Select "WebAuthn Authenticator"**

23. **Click "Add"**

24. Change the dropdown next to "WebAuthn Authenticator" to **"REQUIRED"**

### Bind the Flow

25. **Look at the top of the page** - you should see an "Action" dropdown

26. **Click "Action" → "Bind flow"**

27. **Select "Browser flow"** from the dropdown

28. **Click "Save"**

✅ **STEP 3 COMPLETE!** The YubiKey Browser Flow is now bound.

---

## 📤 STEP 4: Add SAML Attribute Mappers for SP1 (8 minutes)

### Navigate to SP1 Client

1. **Click "Clients"** in the left sidebar

2. **Find and click "saml-sp-1"** in the list

3. **Click "Client scopes"** tab at the top

4. **Click "saml-sp-1-dedicated"** (or similar dedicated scope)

### Add Mapper 1: Username

5. **Click "Add mapper"** button → **"By configuration"**

6. **Select "User Property"**

7. **Fill in**:
   ```
   Name:                    username-mapper
   Property:                username
   SAML Attribute Name:     username
   SAML Attribute NameFormat: Basic
   ```

8. **Click "Save"**

### Add Mapper 2: Email

9. **Click "Add mapper"** → **"By configuration"** → **"User Property"**

10. **Fill in**:
    ```
    Name:                    email-mapper
    Property:                email
    SAML Attribute Name:     email
    SAML Attribute NameFormat: Basic
    ```

11. **Click "Save"**

### Add Mapper 3: Age

12. **Click "Add mapper"** → **"By configuration"** → **"User Attribute"**

13. **Fill in**:
    ```
    Name:                    age-mapper
    User Attribute:          age
    SAML Attribute Name:     age
    SAML Attribute NameFormat: Basic
    ```

14. **Click "Save"**

### Add Mapper 4: Mobile

15. **Click "Add mapper"** → **"By configuration"** → **"User Attribute"**

16. **Fill in**:
    ```
    Name:                    mobile-mapper
    User Attribute:          mobile
    SAML Attribute Name:     mobile
    SAML Attribute NameFormat: Basic
    ```

17. **Click "Save"**

### Add Mapper 5: Address

18. **Click "Add mapper"** → **"By configuration"** → **"User Attribute"**

19. **Fill in**:
    ```
    Name:                    address-mapper
    User Attribute:          address
    SAML Attribute Name:     address
    SAML Attribute NameFormat: Basic
    ```

20. **Click "Save"**

### Add Mapper 6: Profession

21. **Click "Add mapper"** → **"By configuration"** → **"User Attribute"**

22. **Fill in**:
    ```
    Name:                    profession-mapper
    User Attribute:          profession
    SAML Attribute Name:     profession
    SAML Attribute NameFormat: Basic
    ```

23. **Click "Save"**

✅ **STEP 4 COMPLETE!** SP1 now has 6 attribute mappers.

---

## 📤 STEP 5: Add SAML Attribute Mappers for SP2 (8 minutes)

### Navigate to SP2 Client

1. **Click "Clients"** in the left sidebar

2. **Find and click "saml-sp-2"** in the list

3. **Click "Client scopes"** tab

4. **Click "saml-sp-2-dedicated"** scope

### Repeat All 6 Mappers

Now repeat the EXACT same steps as Step 4 for SP2:

- **Mapper 1**: username-mapper (User Property)
- **Mapper 2**: email-mapper (User Property)
- **Mapper 3**: age-mapper (User Attribute)
- **Mapper 4**: mobile-mapper (User Attribute)
- **Mapper 5**: address-mapper (User Attribute)
- **Mapper 6**: profession-mapper (User Attribute)

✅ **STEP 5 COMPLETE!** SP2 now has 6 attribute mappers.

---

## 👤 STEP 6: Update Test User with Attributes (2 minutes)

### Navigate to Users

1. **Click "Users"** in the left sidebar

2. **Find "testuser"** in the list (you might need to click "View all users")

3. **Click on "testuser"**

### Add Custom Attributes

4. **Click "Attributes"** tab

5. **Add the following attributes**:

   Click "Add an attribute" for each one:

   ```
   Key: age          Value: 30
   Key: mobile       Value: +1-555-0100
   Key: address      Value: 123 Main Street, New York, NY 10001
   Key: profession   Value: Software Developer
   ```

6. **Click "Save"** at the bottom

✅ **STEP 6 COMPLETE!** Test user now has all custom attributes.

---

## 🔑 STEP 7 (Optional): Register YubiKey (3 minutes)

**Note**: You can skip this if you don't have a YubiKey. Attribute mapping will still work!

### If You Have a YubiKey:

1. **Logout from admin console** (top right corner)

2. **Open a new tab**: http://localhost:8080/realms/demo/account

3. **Login** as:
   - Username: `testuser`
   - Password: `password123`

4. **Click "Account security"** → **"Signing in"**

5. **Find "Passwordless"** section

6. **Click "Set up Security Key"**

7. **Insert your YubiKey** into USB port

8. **Touch the YubiKey** when the LED blinks

9. **Give it a name**: "My YubiKey"

10. **Click "Save"**

✅ **STEP 7 COMPLETE!** YubiKey is registered (or skipped).

---

## ✅ CONFIGURATION COMPLETE!

All Keycloak configuration is done! Now let's test it.

**Next**: Tell me when you're ready, and I'll help you restart the Django services and test the login flow!

---

## 📊 Progress Tracker

Mark off each step as you complete it:

- [ ] Step 1: Added 4 custom attributes (age, mobile, address, profession)
- [ ] Step 2: Enabled WebAuthn
- [ ] Step 3: Created YubiKey Browser Flow
- [ ] Step 4: Added 6 mappers to SP1
- [ ] Step 5: Added 6 mappers to SP2
- [ ] Step 6: Updated testuser attributes
- [ ] Step 7: Registered YubiKey (optional)

---

**Take your time with each step. Let me know which step you're on, and I can help if you get stuck!**
