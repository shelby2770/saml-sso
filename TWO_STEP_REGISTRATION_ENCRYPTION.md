# 🔐 Two-Step Registration: Encrypt User Attributes with WebAuthn

## 🎯 Your Scenario

```
STEP 1: User fills registration form
├─ Username
├─ Email  
├─ Phone (sensitive!)
├─ Address (sensitive!)
└─ Password

STEP 2: Register WebAuthn credential
├─ User touches security key
└─ Credential createdrst and webauthn in the second step. BU

PROBLEM: How to encrypt STEP 1 data using STEP 2 credential?
```

---

## 💡 Solution: Reverse the Flow or Use Temporary Storage

### **Approach 1: WebAuthn FIRST, Then Registration Form (Recommended)**

**Flow:**
```
1. User clicks "Register"
        ↓
2. Prompt: "Please register your security key first"
        ↓
3. User touches security key → WebAuthn credential created
        ↓
4. Store credential ID in browser (sessionStorage/memory)
        ↓
5. Show registration form (username, email, phone, etc.)
        ↓
6. User fills form
        ↓
7. On submit: Encrypt sensitive fields with credential-derived key
        ↓
8. Submit encrypted data to Keycloak
```

**Pros:**
- ✅ Credential exists before form submission
- ✅ Can encrypt data immediately
- ✅ Clean flow

**Cons:**
- ❌ Unusual UX (security key before registration)
- ❌ What if WebAuthn fails? User can't register at all

---

### **Approach 2: Form FIRST, WebAuthn SECOND, Encrypt Before Final Submit (Your Case)**

**Flow:**
```
1. User fills registration form
   Username: john_doe
   Email: john@example.com
   Phone: +1-555-1234
   Password: myPassword123
        ↓
2. User clicks "Register"
        ↓
3. JavaScript intercepts submit (e.preventDefault())
        ↓
4. Store form data temporarily (in memory)
        ↓
5. Prompt: "Register your security key to encrypt sensitive data"
        ↓
6. User touches security key → WebAuthn credential created
        ↓
7. Derive encryption key from credential ID
        ↓
8. Encrypt sensitive fields (phone, address, etc.)
        ↓
9. Add encrypted data + credential ID to form
        ↓
10. Submit form to Keycloak
```

**Pros:**
- ✅ Normal registration UX (form first)
- ✅ WebAuthn is optional (can skip encryption)
- ✅ Encrypts before submission

**Cons:**
- ❌ Slightly complex JavaScript
- ❌ Form data held in memory temporarily

---

### **Approach 3: Hybrid - Generate Temporary Key, Then Wrap with WebAuthn**

**Flow:**
```
1. User fills registration form
        ↓
2. User clicks "Register"
        ↓
3. Generate temporary encryption key (Web Crypto API)
        ↓
4. Encrypt sensitive fields with temporary key
        ↓
5. Prompt: "Register security key to protect your encryption key"
        ↓
6. User touches security key → WebAuthn credential created
        ↓
7. Derive key-wrapping key from WebAuthn credential
        ↓
8. Encrypt the temporary key with key-wrapping key
        ↓
9. Submit:
   - Encrypted data (with temporary key)
   - Encrypted temporary key (with WebAuthn-derived key)
   - WebAuthn credential ID
        ↓
10. Keycloak stores all three
```

**To decrypt later:**
```
1. User logs in with WebAuthn
2. Derive key-wrapping key from credential
3. Decrypt temporary key
4. Use temporary key to decrypt sensitive data
```

**Pros:**
- ✅ Most secure (temporary key never stored plaintext)
- ✅ WebAuthn credential required for decryption
- ✅ Normal UX flow

**Cons:**
- ❌ Complex implementation
- ❌ Two-layer encryption

---

## 🚀 Recommended Implementation: Approach 2 (Form First, WebAuthn Second)

Let me create the complete implementation:

---

### **File: custom-login-theme/login/register.ftl**

```html
<#import "template.ftl" as layout>
<@layout.registrationLayout displayMessage=!messagesPerField.existsError('firstName','lastName','email','username','password','password-confirm'); section>
    <#if section = "header">
        ${msg("registerTitle")}
    <#elseif section = "form">
        
        <!-- Registration Form -->
        <form id="kc-register-form" class="${properties.kcFormClass!}" action="${url.registrationAction}" method="post">
            
            <!-- Username -->
            <div class="${properties.kcFormGroupClass!}">
                <label for="username" class="${properties.kcLabelClass!}">${msg("username")}</label>
                <input type="text" id="username" class="${properties.kcInputClass!}" 
                       name="username" value="${(register.formData.username!'')}" 
                       autocomplete="username" required />
            </div>

            <!-- Email -->
            <div class="${properties.kcFormGroupClass!}">
                <label for="email" class="${properties.kcLabelClass!}">${msg("email")}</label>
                <input type="email" id="email" class="${properties.kcInputClass!}" 
                       name="email" value="${(register.formData.email!'')}" 
                       autocomplete="email" required />
            </div>

            <!-- First Name -->
            <div class="${properties.kcFormGroupClass!}">
                <label for="firstName" class="${properties.kcLabelClass!}">${msg("firstName")}</label>
                <input type="text" id="firstName" class="${properties.kcInputClass!}" 
                       name="firstName" value="${(register.formData.firstName!'')}" />
            </div>

            <!-- Last Name -->
            <div class="${properties.kcFormGroupClass!}">
                <label for="lastName" class="${properties.kcLabelClass!}">${msg("lastName")}</label>
                <input type="text" id="lastName" class="${properties.kcInputClass!}" 
                       name="lastName" value="${(register.formData.lastName!'')}" />
            </div>

            <!-- Password -->
            <div class="${properties.kcFormGroupClass!}">
                <label for="password" class="${properties.kcLabelClass!}">${msg("password")}</label>
                <input type="password" id="password" class="${properties.kcInputClass!}" 
                       name="password" autocomplete="new-password" required />
            </div>

            <!-- Password Confirm -->
            <div class="${properties.kcFormGroupClass!}">
                <label for="password-confirm" class="${properties.kcLabelClass!}">${msg("passwordConfirm")}</label>
                <input type="password" id="password-confirm" class="${properties.kcInputClass!}" 
                       name="password-confirm" autocomplete="new-password" required />
            </div>

            <!-- Phone Number (Sensitive - will be encrypted) -->
            <div class="${properties.kcFormGroupClass!}">
                <label for="user.attributes.phone" class="${properties.kcLabelClass!}">
                    📱 Phone Number (Will be encrypted)
                </label>
                <input type="tel" id="user.attributes.phone" class="${properties.kcInputClass!}" 
                       name="user.attributes.phone" 
                       value="${(register.formData['user.attributes.phone']!'')}"
                       placeholder="+1-555-1234" />
            </div>

            <!-- Address (Sensitive - will be encrypted) -->
            <div class="${properties.kcFormGroupClass!}">
                <label for="user.attributes.address" class="${properties.kcLabelClass!}">
                    🏠 Address (Will be encrypted)
                </label>
                <textarea id="user.attributes.address" class="${properties.kcInputClass!}" 
                          name="user.attributes.address" 
                          rows="2">${(register.formData['user.attributes.address']!'')}</textarea>
            </div>

            <!-- Hidden fields for encrypted data -->
            <input type="hidden" id="encrypted-payload" name="user.attributes.encrypted_payload" value="" />
            <input type="hidden" id="webauthn-credential-id" name="user.attributes.webauthn_credential_id" value="" />
            <input type="hidden" id="encryption-salt" name="user.attributes.encryption_salt" value="" />

            <!-- WebAuthn Checkbox -->
            <div class="${properties.kcFormGroupClass!}" style="margin-top: 20px; padding: 15px; background: #f0f8ff; border-radius: 5px;">
                <label style="display: flex; align-items: center; cursor: pointer;">
                    <input type="checkbox" id="use-webauthn-encryption" 
                           style="margin-right: 10px; width: 20px; height: 20px;" />
                    <span>
                        <strong>🔐 Encrypt my sensitive data with security key</strong>
                        <br/>
                        <small style="color: #666;">
                            Your phone and address will be encrypted using your hardware security key.
                            You'll need to touch your key during registration.
                        </small>
                    </span>
                </label>
            </div>

            <!-- Submit Button -->
            <div class="${properties.kcFormGroupClass!}" style="margin-top: 30px;">
                <button type="submit" 
                        class="${properties.kcButtonClass!} ${properties.kcButtonPrimaryClass!} ${properties.kcButtonBlockClass!} ${properties.kcButtonLargeClass!}" 
                        id="kc-register-btn">
                    ${msg("doRegister")}
                </button>
            </div>

            <!-- Back to Login -->
            <div class="${properties.kcFormGroupClass!}" style="text-align: center; margin-top: 15px;">
                <a href="${url.loginUrl}">${msg("backToLogin")}</a>
            </div>
        </form>

        <!-- Load encryption script -->
        <script src="${url.resourcesPath}/js/registration-with-webauthn.js"></script>

        <!-- WebAuthn Status Indicator -->
        <div id="webauthn-status" style="margin-top: 20px; padding: 10px; border-radius: 5px; display: none;"></div>

    </#if>
</@layout.registrationLayout>
```

---

### **File: custom-login-theme/login/resources/js/registration-with-webauthn.js**

```javascript
/**
 * Two-Step Registration with WebAuthn Encryption
 * 
 * Flow:
 * 1. User fills form
 * 2. User clicks Register
 * 3. If encryption checkbox is checked:
 *    a. Prevent form submit
 *    b. Create WebAuthn credential
 *    c. Encrypt sensitive fields
 *    d. Add encrypted data to form
 *    e. Submit form
 * 4. If checkbox not checked: normal submit
 */

(function() {
    'use strict';

    const SENSITIVE_FIELDS = ['user.attributes.phone', 'user.attributes.address'];

    /**
     * Check WebAuthn support
     */
    function isWebAuthnSupported() {
        return window.PublicKeyCredential !== undefined &&
               navigator.credentials !== undefined;
    }

    /**
     * Show status message
     */
    function showStatus(message, type = 'info') {
        const statusDiv = document.getElementById('webauthn-status');
        if (!statusDiv) return;

        const colors = {
            info: '#0066cc',
            success: '#00aa00',
            error: '#cc0000',
            warning: '#ff8800'
        };

        const icons = {
            info: 'ℹ️',
            success: '✅',
            error: '❌',
            warning: '⚠️'
        };

        statusDiv.style.display = 'block';
        statusDiv.style.backgroundColor = colors[type] + '20';
        statusDiv.style.border = `2px solid ${colors[type]}`;
        statusDiv.style.color = colors[type];
        statusDiv.innerHTML = `<strong>${icons[type]} ${message}</strong>`;
    }

    /**
     * Create WebAuthn credential
     */
    async function registerWebAuthnCredential(username) {
        showStatus('Please touch your security key...', 'info');

        try {
            // Generate random challenge
            const challenge = new Uint8Array(32);
            window.crypto.getRandomValues(challenge);

            // Generate user ID
            const userId = new Uint8Array(16);
            window.crypto.getRandomValues(userId);

            // Request credential
            const credential = await navigator.credentials.create({
                publicKey: {
                    challenge: challenge,
                    rp: {
                        name: window.location.hostname,
                        id: window.location.hostname.replace(/:\d+$/, '') // Remove port
                    },
                    user: {
                        id: userId,
                        name: username,
                        displayName: username
                    },
                    pubKeyCredParams: [
                        { alg: -7, type: "public-key" },   // ES256
                        { alg: -257, type: "public-key" }  // RS256
                    ],
                    authenticatorSelection: {
                        authenticatorAttachment: "cross-platform", // External key
                        userVerification: "preferred",
                        requireResidentKey: false
                    },
                    timeout: 60000,
                    attestation: "none"
                }
            });

            showStatus('Security key registered successfully!', 'success');
            console.log('✅ WebAuthn credential created');
            return credential;

        } catch (error) {
            console.error('❌ WebAuthn registration failed:', error);
            
            let errorMessage = 'Failed to register security key: ';
            if (error.name === 'NotAllowedError') {
                errorMessage += 'User cancelled or timeout';
            } else if (error.name === 'InvalidStateError') {
                errorMessage += 'Credential already registered';
            } else {
                errorMessage += error.message;
            }
            
            showStatus(errorMessage, 'error');
            throw new Error(errorMessage);
        }
    }

    /**
     * Derive encryption key from WebAuthn credential
     */
    async function deriveEncryptionKey(credentialRawId, salt) {
        try {
            // Import credential ID as key material
            const keyMaterial = await window.crypto.subtle.importKey(
                'raw',
                credentialRawId,
                { name: 'PBKDF2' },
                false,
                ['deriveBits', 'deriveKey']
            );

            // Derive AES-GCM key
            const encryptionKey = await window.crypto.subtle.deriveKey(
                {
                    name: 'PBKDF2',
                    salt: salt,
                    iterations: 100000,
                    hash: 'SHA-256'
                },
                keyMaterial,
                { name: 'AES-GCM', length: 256 },
                false, // not extractable
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
    async function encryptData(plaintext, key) {
        try {
            // Generate random IV
            const iv = new Uint8Array(12);
            window.crypto.getRandomValues(iv);

            // Encode plaintext
            const encoder = new TextEncoder();
            const plaintextBuffer = encoder.encode(plaintext);

            // Encrypt
            const ciphertextBuffer = await window.crypto.subtle.encrypt(
                {
                    name: 'AES-GCM',
                    iv: iv
                },
                key,
                plaintextBuffer
            );

            // Combine IV + ciphertext
            const combined = new Uint8Array(iv.length + ciphertextBuffer.byteLength);
            combined.set(iv, 0);
            combined.set(new Uint8Array(ciphertextBuffer), iv.length);

            // Return as base64
            return arrayBufferToBase64(combined.buffer);

        } catch (error) {
            console.error('❌ Encryption failed:', error);
            throw error;
        }
    }

    /**
     * Main encryption workflow
     */
    async function encryptSensitiveFields(formData, username) {
        showStatus('Creating WebAuthn credential...', 'info');

        // Step 1: Register WebAuthn credential
        const credential = await registerWebAuthnCredential(username);
        const credentialId = credential.rawId;

        // Step 2: Generate salt
        const salt = new Uint8Array(16);
        window.crypto.getRandomValues(salt);

        // Step 3: Derive encryption key
        showStatus('Deriving encryption key...', 'info');
        const encryptionKey = await deriveEncryptionKey(credentialId, salt);

        // Step 4: Encrypt sensitive fields
        showStatus('Encrypting sensitive data...', 'info');
        const encryptedFields = {};

        for (const fieldName of SENSITIVE_FIELDS) {
            const value = formData.get(fieldName);
            if (value && value.trim()) {
                encryptedFields[fieldName] = await encryptData(value, encryptionKey);
                console.log(`✅ Encrypted field: ${fieldName}`);
            }
        }

        // Step 5: Create payload
        const payload = {
            version: '1.0',
            algorithm: 'AES-GCM-256',
            timestamp: new Date().toISOString(),
            fields: encryptedFields
        };

        showStatus('Data encrypted successfully!', 'success');

        return {
            credentialId: arrayBufferToBase64(credentialId),
            salt: arrayBufferToBase64(salt.buffer),
            encryptedPayload: JSON.stringify(payload)
        };
    }

    /**
     * Handle form submission
     */
    async function handleFormSubmit(event) {
        const useEncryption = document.getElementById('use-webauthn-encryption');
        
        // If encryption not requested, allow normal submit
        if (!useEncryption || !useEncryption.checked) {
            console.log('ℹ️ Proceeding without encryption');
            return true;
        }

        // Check WebAuthn support
        if (!isWebAuthnSupported()) {
            alert('WebAuthn is not supported in this browser.\n\nRegistration will proceed without encryption.');
            return true;
        }

        // Prevent default submission
        event.preventDefault();

        try {
            const form = event.target;
            const submitBtn = document.getElementById('kc-register-btn');
            const originalBtnText = submitBtn.textContent;

            // Disable form
            submitBtn.disabled = true;
            submitBtn.textContent = '🔐 Securing your data...';

            // Get form data
            const formData = new FormData(form);
            const username = formData.get('username');

            if (!username) {
                throw new Error('Username is required');
            }

            // Validate password match
            const password = formData.get('password');
            const passwordConfirm = formData.get('password-confirm');
            if (password !== passwordConfirm) {
                throw new Error('Passwords do not match');
            }

            // Encrypt sensitive fields
            const encrypted = await encryptSensitiveFields(formData, username);

            // Add encrypted data to hidden fields
            document.getElementById('encrypted-payload').value = encrypted.encryptedPayload;
            document.getElementById('webauthn-credential-id').value = encrypted.credentialId;
            document.getElementById('encryption-salt').value = encrypted.salt;

            // Clear original sensitive fields (optional)
            SENSITIVE_FIELDS.forEach(fieldName => {
                const field = document.getElementById(fieldName);
                if (field) {
                    field.value = '[ENCRYPTED]';
                    field.setAttribute('data-original-value', formData.get(fieldName));
                }
            });

            console.log('✅ Form data encrypted and ready to submit');
            console.log('📝 Credential ID:', encrypted.credentialId.substring(0, 20) + '...');

            // Submit form
            submitBtn.textContent = '✅ Submitting...';
            setTimeout(() => {
                form.submit();
            }, 500);

        } catch (error) {
            console.error('❌ Encryption process failed:', error);
            
            showStatus(error.message, 'error');
            
            // Ask user if they want to proceed without encryption
            const proceedWithout = confirm(
                'Encryption failed: ' + error.message + '\n\n' +
                'Do you want to register without encryption?\n\n' +
                'Click OK to proceed, or Cancel to try again.'
            );

            if (proceedWithout) {
                // Uncheck encryption checkbox and submit normally
                document.getElementById('use-webauthn-encryption').checked = false;
                // Restore form
                const submitBtn = document.getElementById('kc-register-btn');
                submitBtn.disabled = false;
                submitBtn.textContent = originalBtnText || 'Register';
                // Submit
                event.target.submit();
            } else {
                // Re-enable form
                const submitBtn = document.getElementById('kc-register-btn');
                submitBtn.disabled = false;
                submitBtn.textContent = originalBtnText || 'Register';
            }
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
     * Initialize
     */
    function init() {
        const form = document.getElementById('kc-register-form');
        if (!form) {
            console.warn('⚠️ Registration form not found');
            return;
        }

        // Check WebAuthn support
        if (!isWebAuthnSupported()) {
            const checkbox = document.getElementById('use-webauthn-encryption');
            if (checkbox) {
                checkbox.disabled = true;
                checkbox.parentElement.style.opacity = '0.5';
                checkbox.parentElement.title = 'WebAuthn not supported in this browser';
            }
            console.warn('⚠️ WebAuthn not supported');
            return;
        }

        // Attach form submit handler
        form.addEventListener('submit', handleFormSubmit);
        
        console.log('✅ Registration with WebAuthn encryption initialized');
        console.log('📋 Sensitive fields:', SENSITIVE_FIELDS);
    }

    // Initialize when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }

})();
```

---

## 🎯 How This Solution Works

### **Timeline:**

```
T=0: User opens registration page
     └─ Form loads with all fields visible

T=1: User fills form
     ├─ username: john_doe
     ├─ email: john@example.com
     ├─ phone: +1-555-1234
     └─ address: 123 Main St

T=2: User checks "🔐 Encrypt with security key" checkbox

T=3: User clicks "Register" button

T=4: JavaScript intercepts submit (event.preventDefault())
     └─ Form data stored in memory (FormData object)

T=5: Prompt: "Please touch your security key"
     └─ User touches YubiKey/hardware key

T=6: WebAuthn credential created
     └─ credential.rawId obtained

T=7: Derive encryption key from credential.rawId + salt

T=8: Encrypt phone and address fields
     ├─ phone: "aBcD123...encrypted..."
     └─ address: "xYz456...encrypted..."

T=9: Add to hidden fields:
     ├─ encrypted_payload: {"phone": "...", "address": "..."}
     ├─ webauthn_credential_id: "dEf789..."
     └─ encryption_salt: "gHi012..."

T=10: Submit form to Keycloak
      └─ POST /realms/demo/registration

T=11: Keycloak stores user with encrypted attributes
```

---

## 📦 Deployment

```bash
# 1. Create theme directory structure
mkdir -p custom-login-theme/login/resources/js

# 2. Copy the files (register.ftl and registration-with-webauthn.js)

# 3. Copy theme to Keycloak
docker cp custom-login-theme keycloak-sso:/opt/keycloak/themes/

# 4. Restart Keycloak
docker restart keycloak-sso

# 5. Activate in Admin Console
# Visit: http://localhost:8080
# Realm settings → Themes → Login theme: custom-login-theme
# Save
```

---

## 🧪 Testing

```bash
# 1. Visit registration page
http://localhost:8080/realms/demo/protocol/openid-connect/registrations?client_id=account&response_type=code

# 2. Fill form with test data

# 3. Check the "Encrypt with security key" checkbox

# 4. Click Register

# 5. Touch your security key when prompted

# 6. Data is encrypted and submitted!
```

---

## 🔍 What Gets Stored in Keycloak

```json
{
  "username": "john_doe",
  "email": "john@example.com",
  "attributes": {
    "phone": "[ENCRYPTED]",
    "address": "[ENCRYPTED]",
    "encrypted_payload": "{\"version\":\"1.0\",\"fields\":{\"phone\":\"abc123...\",\"address\":\"xyz789...\"}}",
    "webauthn_credential_id": "dEfGhI...",
    "encryption_salt": "JkLmNo..."
  }
}
```

---

## ✅ Key Features

1. **✅ Normal UX** - User fills form first, encryption happens at submit
2. **✅ Optional encryption** - Checkbox to enable/disable
3. **✅ Graceful fallback** - If WebAuthn fails, can register without encryption
4. **✅ Visual feedback** - Status messages during encryption process
5. **✅ Secure** - Sensitive data encrypted before leaving browser

---

**This is the complete solution for your two-step flow! Want me to create the decryption function next?**
