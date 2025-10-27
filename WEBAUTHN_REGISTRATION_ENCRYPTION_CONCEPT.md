# 🔐 WebAuthn Security Key + Registration Page Encryption

## 🎯 Your Goal

**Override Keycloak's registration page to:**
1. Capture user registration data (username, email, password, etc.)
2. Use WebAuthn security key to encrypt sensitive fields
3. Submit encrypted data to Keycloak
4. Store encrypted data or decrypt server-side

---

## 💡 Conceptual Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                    REGISTRATION WITH ENCRYPTION FLOW                 │
└─────────────────────────────────────────────────────────────────────┘

User fills registration form
        ↓
┌─────────────────────────────────────────────────────────────────────┐
│ 1. User provides data:                                               │
│    - Username: john_doe                                              │
│    - Password: mySecurePassword123                                   │
│    - Email: john@example.com                                         │
│    - Phone: +1-555-1234 (sensitive!)                                 │
└─────────────────────────────────────────────────────────────────────┘
        ↓
┌─────────────────────────────────────────────────────────────────────┐
│ 2. User clicks "Register"                                            │
│    JavaScript intercepts form submit                                 │
└─────────────────────────────────────────────────────────────────────┘
        ↓
┌─────────────────────────────────────────────────────────────────────┐
│ 3. Prompt user to insert/touch security key                         │
│    "Please touch your security key to secure your data"             │
└─────────────────────────────────────────────────────────────────────┘
        ↓
┌─────────────────────────────────────────────────────────────────────┐
│ 4. WebAuthn API generates/derives encryption key                    │
│    navigator.credentials.create() or get()                          │
│    Extract public key from authenticator                            │
└─────────────────────────────────────────────────────────────────────┘
        ↓
┌─────────────────────────────────────────────────────────────────────┐
│ 5. Encrypt sensitive fields with derived key                        │
│    - Password: encrypted_blob_1                                      │
│    - Phone: encrypted_blob_2                                         │
│    - Keep username, email unencrypted (for login/recovery)          │
└─────────────────────────────────────────────────────────────────────┘
        ↓
┌─────────────────────────────────────────────────────────────────────┐
│ 6. Submit form to Keycloak                                           │
│    POST /realms/demo/registration                                    │
│    Data: {                                                           │
│      username: "john_doe",                                           │
│      email: "john@example.com",                                      │
│      password: "encrypted_blob_1",                                   │
│      phone: "encrypted_blob_2"                                       │
│    }                                                                 │
└─────────────────────────────────────────────────────────────────────┘
        ↓
┌─────────────────────────────────────────────────────────────────────┐
│ 7. Keycloak stores encrypted data                                    │
│    OR                                                                │
│    Custom SPI decrypts and stores plain data                        │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🤔 Important Considerations

### Challenge #1: WebAuthn is for Authentication, Not Encryption

**WebAuthn's primary purpose:**
- Generate key pairs (private key on device, public key to server)
- Sign challenges to prove identity
- **NOT designed for data encryption/decryption**

**The Problem:**
```javascript
// This is what WebAuthn does well:
const credential = await navigator.credentials.create({
    publicKey: {
        challenge: new Uint8Array([...]),
        rp: { name: "My App" },
        user: { id: userId, name: "john", displayName: "John Doe" },
        pubKeyCredParams: [{ alg: -7, type: "public-key" }],
        authenticatorSelection: { userVerification: "required" }
    }
});
// Result: credential.response.attestationObject
// Contains: public key, authenticator data, signature
// DOES NOT provide: encryption/decryption functions!
```

**WebAuthn gives you:**
- ✅ Digital signatures (for authentication)
- ✅ Public/private key pairs
- ❌ Direct encryption APIs
- ❌ Access to private key (it stays in hardware!)

---

## 💡 Solution Approaches

### Approach 1: Use WebAuthn for Key Derivation (Recommended)

**Concept:** Derive an encryption key from WebAuthn credential ID

```javascript
// 1. Register WebAuthn credential during registration
const credential = await navigator.credentials.create({...});

// 2. Use credential.rawId as seed for encryption key
const credentialId = new Uint8Array(credential.rawId);

// 3. Derive encryption key using HKDF or PBKDF2
const encryptionKey = await deriveEncryptionKey(credentialId);

// 4. Encrypt sensitive data
const encryptedData = await encryptWithKey(encryptionKey, sensitiveData);

// 5. Store credential ID (for later decryption)
```

**Pros:**
- ✅ Ties encryption to hardware security key
- ✅ Unique per user
- ✅ Can be derived deterministically

**Cons:**
- ❌ Credential ID is not secret (public information)
- ❌ Need additional entropy/salt for true security
- ❌ Not truly hardware-backed encryption

---

### Approach 2: Hybrid - WebAuthn + Web Crypto API (Better)

**Concept:** Use WebAuthn for authentication, Web Crypto API for encryption

```javascript
// 1. Generate encryption key pair using Web Crypto API
const keyPair = await window.crypto.subtle.generateKey(
    {
        name: "RSA-OAEP",
        modulusLength: 2048,
        publicExponent: new Uint8Array([1, 0, 1]),
        hash: "SHA-256"
    },
    true, // extractable
    ["encrypt", "decrypt"]
);

// 2. Export public key
const publicKey = await window.crypto.subtle.exportKey("spki", keyPair.publicKey);

// 3. Encrypt sensitive data with public key
const encryptedData = await window.crypto.subtle.encrypt(
    { name: "RSA-OAEP" },
    keyPair.publicKey,
    dataToEncrypt
);

// 4. Store private key encrypted with WebAuthn-derived key
const webAuthnKey = await deriveKeyFromWebAuthn();
const encryptedPrivateKey = await encryptPrivateKey(keyPair.privateKey, webAuthnKey);

// 5. Store encryptedPrivateKey in browser (IndexedDB)
```

**Pros:**
- ✅ True encryption with Web Crypto API
- ✅ WebAuthn provides authentication layer
- ✅ Private key protected by hardware key

**Cons:**
- ❌ Complex implementation
- ❌ Private key still accessible in browser memory
- ❌ Need secure storage (IndexedDB)

---

### Approach 3: Server-Side Encryption with WebAuthn Auth (Most Practical)

**Concept:** Use WebAuthn to authenticate, encrypt server-side

```javascript
// CLIENT SIDE:
// 1. User fills registration form
const formData = {
    username: "john_doe",
    password: "mySecurePassword123",
    phone: "+1-555-1234"
};

// 2. Authenticate with WebAuthn
const assertion = await navigator.credentials.get({
    publicKey: {
        challenge: serverChallenge,
        allowCredentials: [{ id: credentialId, type: "public-key" }],
        userVerification: "required"
    }
});

// 3. Send data + WebAuthn assertion to server
fetch('/api/register-secure', {
    method: 'POST',
    body: JSON.stringify({
        formData: formData,
        webauthnAssertion: {
            id: assertion.id,
            response: {
                authenticatorData: btoa(assertion.response.authenticatorData),
                signature: btoa(assertion.response.signature),
                clientDataJSON: btoa(assertion.response.clientDataJSON)
            }
        }
    })
});


// SERVER SIDE (Keycloak Custom SPI):
public class SecureRegistrationProvider implements FormActionFactory {
    @Override
    public void validate(ValidationContext context) {
        // 1. Verify WebAuthn assertion
        WebAuthnAssertion assertion = parseAssertion(context.getHttpRequest());
        boolean valid = verifyWebAuthnSignature(assertion);
        
        if (!valid) {
            context.error("Invalid authentication");
            return;
        }
        
        // 2. Get user's encryption key (derived from credential ID)
        String credentialId = assertion.getCredentialId();
        byte[] encryptionKey = deriveServerEncryptionKey(credentialId);
        
        // 3. Encrypt sensitive fields
        String phone = context.getHttpRequest().getParameter("phone");
        String encryptedPhone = encrypt(phone, encryptionKey);
        
        // 4. Store encrypted data
        UserModel user = context.getSession().users().addUser(context.getRealm(), username);
        user.setSingleAttribute("phone_encrypted", encryptedPhone);
    }
}
```

**Pros:**
- ✅ Most secure (server controls encryption)
- ✅ Hardware key proves user identity
- ✅ Encryption keys never leave server
- ✅ Easier to audit and manage

**Cons:**
- ❌ Requires custom Keycloak SPI
- ❌ More server-side code

---

## 🚀 Recommended Implementation

### Step 1: Override Registration Page

Create custom registration theme:

```bash
mkdir -p custom-login-theme/login
```

**File: custom-login-theme/login/register.ftl**

```html
<#import "template.ftl" as layout>
<@layout.registrationLayout displayMessage=!messagesPerField.existsError('firstName','lastName','email','username','password','password-confirm'); section>
    <#if section = "header">
        ${msg("registerTitle")}
    <#elseif section = "form">
        <form id="kc-register-form" class="${properties.kcFormClass!}" action="${url.registrationAction}" method="post">
            
            <!-- Username -->
            <div class="${properties.kcFormGroupClass!}">
                <label for="username" class="${properties.kcLabelClass!}">${msg("username")}</label>
                <input type="text" id="username" class="${properties.kcInputClass!}" 
                       name="username" value="${(register.formData.username!'')}" 
                       autocomplete="username" />
            </div>

            <!-- Email -->
            <div class="${properties.kcFormGroupClass!}">
                <label for="email" class="${properties.kcLabelClass!}">${msg("email")}</label>
                <input type="email" id="email" class="${properties.kcInputClass!}" 
                       name="email" value="${(register.formData.email!'')}" 
                       autocomplete="email" />
            </div>

            <!-- Password -->
            <div class="${properties.kcFormGroupClass!}">
                <label for="password" class="${properties.kcLabelClass!}">${msg("password")}</label>
                <input type="password" id="password" class="${properties.kcInputClass!}" 
                       name="password" autocomplete="new-password" />
            </div>

            <!-- Password Confirm -->
            <div class="${properties.kcFormGroupClass!}">
                <label for="password-confirm" class="${properties.kcLabelClass!}">${msg("passwordConfirm")}</label>
                <input type="password" id="password-confirm" class="${properties.kcInputClass!}" 
                       name="password-confirm" autocomplete="new-password" />
            </div>

            <!-- Phone (Sensitive - will be encrypted) -->
            <div class="${properties.kcFormGroupClass!}">
                <label for="user.attributes.phone" class="${properties.kcLabelClass!}">Phone Number</label>
                <input type="tel" id="user.attributes.phone" class="${properties.kcInputClass!}" 
                       name="user.attributes.phone" value="${(register.formData['user.attributes.phone']!'')}" />
            </div>

            <!-- Hidden field for encrypted data -->
            <input type="hidden" id="encrypted-data" name="user.attributes.encrypted_fields" value="" />
            <input type="hidden" id="webauthn-credential-id" name="user.attributes.webauthn_cred_id" value="" />

            <div class="${properties.kcFormGroupClass!}">
                <button type="submit" class="${properties.kcButtonClass!} ${properties.kcButtonPrimaryClass!} ${properties.kcButtonBlockClass!} ${properties.kcButtonLargeClass!}" 
                        id="kc-register-btn">
                    ${msg("doRegister")}
                </button>
            </div>
        </form>

        <!-- Load encryption script -->
        <script src="${url.resourcesPath}/js/registration-encryption.js"></script>
    </#if>
</@layout.registrationLayout>
```

---

### Step 2: Create Encryption JavaScript

**File: custom-login-theme/login/resources/js/registration-encryption.js**

```javascript
/**
 * Registration Form Encryption with WebAuthn
 * 
 * This script encrypts sensitive registration data using a key derived
 * from WebAuthn security key credential.
 */

(function() {
    'use strict';

    /**
     * Check if WebAuthn is supported
     */
    function isWebAuthnSupported() {
        return window.PublicKeyCredential !== undefined &&
               navigator.credentials !== undefined;
    }

    /**
     * Generate a WebAuthn credential and derive encryption key
     */
    async function createWebAuthnCredentialForEncryption(username) {
        try {
            // Generate random challenge
            const challenge = new Uint8Array(32);
            window.crypto.getRandomValues(challenge);

            // Generate random user ID
            const userId = new Uint8Array(16);
            window.crypto.getRandomValues(userId);

            // Create WebAuthn credential
            const credential = await navigator.credentials.create({
                publicKey: {
                    challenge: challenge,
                    rp: {
                        name: window.location.hostname,
                        id: window.location.hostname
                    },
                    user: {
                        id: userId,
                        name: username,
                        displayName: username
                    },
                    pubKeyCredParams: [
                        { alg: -7, type: "public-key" },  // ES256
                        { alg: -257, type: "public-key" }  // RS256
                    ],
                    authenticatorSelection: {
                        authenticatorAttachment: "cross-platform", // External security key
                        userVerification: "required",
                        requireResidentKey: false
                    },
                    timeout: 60000,
                    attestation: "direct"
                }
            });

            console.log('✅ WebAuthn credential created:', credential.id);
            return credential;

        } catch (error) {
            console.error('❌ WebAuthn credential creation failed:', error);
            throw error;
        }
    }

    /**
     * Derive encryption key from WebAuthn credential ID
     */
    async function deriveEncryptionKeyFromCredential(credentialId, salt) {
        try {
            // Convert credential ID to ArrayBuffer if needed
            const credIdBuffer = typeof credentialId === 'string' 
                ? base64ToArrayBuffer(credentialId)
                : credentialId;

            // Import credential ID as key material
            const keyMaterial = await window.crypto.subtle.importKey(
                'raw',
                credIdBuffer,
                { name: 'PBKDF2' },
                false,
                ['deriveBits', 'deriveKey']
            );

            // Derive AES-GCM encryption key
            const encryptionKey = await window.crypto.subtle.deriveKey(
                {
                    name: 'PBKDF2',
                    salt: salt,
                    iterations: 100000,
                    hash: 'SHA-256'
                },
                keyMaterial,
                { name: 'AES-GCM', length: 256 },
                true, // extractable
                ['encrypt', 'decrypt']
            );

            console.log('✅ Encryption key derived');
            return encryptionKey;

        } catch (error) {
            console.error('❌ Key derivation failed:', error);
            throw error;
        }
    }

    /**
     * Encrypt data with AES-GCM
     */
    async function encryptData(data, key) {
        try {
            // Generate random IV
            const iv = new Uint8Array(12);
            window.crypto.getRandomValues(iv);

            // Convert data to ArrayBuffer
            const encoder = new TextEncoder();
            const dataBuffer = encoder.encode(data);

            // Encrypt
            const encryptedBuffer = await window.crypto.subtle.encrypt(
                {
                    name: 'AES-GCM',
                    iv: iv
                },
                key,
                dataBuffer
            );

            // Combine IV + encrypted data
            const combined = new Uint8Array(iv.length + encryptedBuffer.byteLength);
            combined.set(iv, 0);
            combined.set(new Uint8Array(encryptedBuffer), iv.length);

            // Return as base64
            return arrayBufferToBase64(combined);

        } catch (error) {
            console.error('❌ Encryption failed:', error);
            throw error;
        }
    }

    /**
     * Main encryption flow
     */
    async function encryptRegistrationData(formData) {
        try {
            console.log('🔐 Starting encryption process...');

            // 1. Get username
            const username = formData.get('username');
            if (!username) {
                throw new Error('Username is required');
            }

            // 2. Create WebAuthn credential
            const credential = await createWebAuthnCredentialForEncryption(username);
            const credentialId = arrayBufferToBase64(credential.rawId);

            // 3. Generate salt (store this with user!)
            const salt = new Uint8Array(16);
            window.crypto.getRandomValues(salt);
            const saltBase64 = arrayBufferToBase64(salt);

            // 4. Derive encryption key
            const encryptionKey = await deriveEncryptionKeyFromCredential(
                credential.rawId,
                salt
            );

            // 5. Encrypt sensitive fields
            const sensitiveFields = {};
            
            // Encrypt phone number
            const phone = formData.get('user.attributes.phone');
            if (phone) {
                sensitiveFields.phone = await encryptData(phone, encryptionKey);
                console.log('✅ Phone encrypted');
            }

            // Encrypt password (optional - Keycloak already hashes it)
            const password = formData.get('password');
            if (password) {
                sensitiveFields.password_backup = await encryptData(password, encryptionKey);
                console.log('✅ Password backup encrypted');
            }

            // 6. Create encrypted payload
            const encryptedPayload = {
                version: '1.0',
                algorithm: 'AES-GCM-256',
                salt: saltBase64,
                fields: sensitiveFields,
                timestamp: new Date().toISOString()
            };

            return {
                credentialId: credentialId,
                encryptedData: JSON.stringify(encryptedPayload),
                publicKey: arrayBufferToBase64(
                    new Uint8Array(credential.response.attestationObject)
                )
            };

        } catch (error) {
            console.error('❌ Encryption process failed:', error);
            throw error;
        }
    }

    /**
     * Handle form submission
     */
    async function handleFormSubmit(event) {
        // Check if WebAuthn is supported
        if (!isWebAuthnSupported()) {
            console.warn('⚠️ WebAuthn not supported, submitting without encryption');
            return true; // Allow normal form submission
        }

        // Check if user wants encryption
        const useEncryption = confirm(
            'Do you want to secure your registration data with a security key?\n\n' +
            'This will encrypt sensitive information using your hardware security key.\n\n' +
            'Click OK to use security key, or Cancel to skip encryption.'
        );

        if (!useEncryption) {
            console.log('ℹ️ User chose to skip encryption');
            return true; // Allow normal submission
        }

        // Prevent default submission
        event.preventDefault();

        try {
            // Show loading indicator
            const submitBtn = document.getElementById('kc-register-btn');
            const originalText = submitBtn.textContent;
            submitBtn.disabled = true;
            submitBtn.textContent = '🔐 Securing your data...';

            // Get form data
            const form = event.target;
            const formData = new FormData(form);

            // Encrypt sensitive data
            const encrypted = await encryptRegistrationData(formData);

            // Set encrypted data in hidden fields
            document.getElementById('encrypted-data').value = encrypted.encryptedData;
            document.getElementById('webauthn-credential-id').value = encrypted.credentialId;

            // Clear original sensitive fields (optional)
            // document.getElementById('user.attributes.phone').value = '[ENCRYPTED]';

            console.log('✅ Data encrypted successfully');
            console.log('📝 Credential ID:', encrypted.credentialId);

            // Submit form
            submitBtn.textContent = '✅ Submitting...';
            form.submit();

        } catch (error) {
            console.error('❌ Encryption failed:', error);
            alert('Encryption failed: ' + error.message + '\n\nForm will be submitted without encryption.');
            
            // Re-enable button
            const submitBtn = document.getElementById('kc-register-btn');
            submitBtn.disabled = false;
            submitBtn.textContent = originalText;
            
            // Submit anyway
            event.target.submit();
        }
    }

    /**
     * Utility: ArrayBuffer to Base64
     */
    function arrayBufferToBase64(buffer) {
        const bytes = new Uint8Array(buffer);
        let binary = '';
        for (let i = 0; i < bytes.byteLength; i++) {
            binary += String.fromCharCode(bytes[i]);
        }
        return window.btoa(binary);
    }

    /**
     * Utility: Base64 to ArrayBuffer
     */
    function base64ToArrayBuffer(base64) {
        const binary = window.atob(base64);
        const bytes = new Uint8Array(binary.length);
        for (let i = 0; i < binary.length; i++) {
            bytes[i] = binary.charCodeAt(i);
        }
        return bytes.buffer;
    }

    /**
     * Initialize
     */
    document.addEventListener('DOMContentLoaded', function() {
        const form = document.getElementById('kc-register-form');
        if (form) {
            form.addEventListener('submit', handleFormSubmit);
            console.log('✅ Registration encryption initialized');
            
            if (!isWebAuthnSupported()) {
                console.warn('⚠️ WebAuthn not supported in this browser');
            }
        }
    });

})();
```

---

### Step 3: Deploy Custom Theme

```bash
# Copy theme to Keycloak
cp -r custom-login-theme /opt/keycloak/themes/

# Or with Docker
docker cp custom-login-theme keycloak-sso:/opt/keycloak/themes/

# Restart Keycloak
docker restart keycloak-sso
```

---

### Step 4: Activate Theme in Keycloak

1. Go to: http://localhost:8080
2. Login: admin/admin
3. Select "demo" realm
4. Realm settings → Themes
5. Login theme: `custom-login-theme`
6. Save

---

## 🎯 How It Works

```
User visits registration page
        ↓
Fills form (username, email, password, phone)
        ↓
Clicks "Register"
        ↓
Prompt: "Do you want to secure with security key?"
        ↓
User clicks OK
        ↓
Prompt: "Touch your security key"
        ↓
User touches YubiKey/hardware key
        ↓
WebAuthn creates credential
        ↓
Derive encryption key from credential ID
        ↓
Encrypt phone number with AES-GCM
        ↓
Store encrypted data + credential ID in form
        ↓
Submit to Keycloak
        ↓
Keycloak stores:
  - user.attributes.encrypted_fields: {encrypted phone}
  - user.attributes.webauthn_cred_id: {credential ID}
        ↓
Registration complete!
```

---

## 📋 Next Steps

1. **Test the registration flow**
2. **Create decryption function** (for reading encrypted data)
3. **Build custom Keycloak SPI** (for server-side decryption)
4. **Add more sophisticated key management**

---

## ⚠️ Security Considerations

1. **Credential ID is public** - Don't rely solely on it for encryption
2. **Add server-side salt** - Store salt per user, combine with credential ID
3. **Implement key rotation** - Allow users to re-encrypt with new keys
4. **Audit logging** - Log all encryption/decryption operations
5. **Backup mechanism** - What if user loses security key?

---

**Want me to create the full implementation with custom Keycloak SPI for server-side decryption?**
