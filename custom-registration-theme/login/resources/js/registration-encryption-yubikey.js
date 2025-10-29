/**
 * Registration with YubiKey 5 Encryption
 * 
 * Architecture:
 * 1. User fills registration form
 * 2. Click "Encrypt & Register with YubiKey"
 * 3. Generate random AES-256-GCM symmetric key
 * 4. Encrypt attributes: firstName, lastName, email, age, mobile, address, profession
 * 5. Create WebAuthn credential on YubiKey (user touches key)
 * 6. Derive wrapping key from: CredentialID + PublicKey + Random salt
 * 7. Wrap (encrypt) the AES key with wrapping key
 * 8. Store: encrypted attributes + wrapped key + credential ID + public key + salt
 * 9. Submit form with encrypted data
 * 
 * Username stays PLAIN TEXT (not encrypted)
 */

(function() {
    'use strict';

    console.log('🔐 YubiKey Encryption Module Loaded');

    // Fields to encrypt (username is NOT in this list)
    const FIELDS_TO_ENCRYPT = [
        'firstName',
        'lastName', 
        'email',
        'user.attributes.age',
        'user.attributes.mobile',
        'user.attributes.address',
        'user.attributes.profession'
    ];

    /**
     * Check if WebAuthn is supported
     */
    function isWebAuthnSupported() {
        return window.PublicKeyCredential !== undefined &&
               navigator.credentials !== undefined &&
               navigator.credentials.create !== undefined;
    }

    /**
     * Show status message
     */
    function showStatus(message, type = 'info') {
        const statusDiv = document.getElementById('webauthn-status');
        if (!statusDiv) return;

        const colors = {
            info: { bg: '#e3f2fd', border: '#2196f3', text: '#1565c0' },
            success: { bg: '#e8f5e9', border: '#4caf50', text: '#2e7d32' },
            error: { bg: '#ffebee', border: '#f44336', text: '#c62828' },
            warning: { bg: '#fff3e0', border: '#ff9800', text: '#e65100' }
        };

        const icons = {
            info: '🔄',
            success: '✅',
            error: '❌',
            warning: '⚠️'
        };

        const style = colors[type] || colors.info;

        statusDiv.style.display = 'block';
        statusDiv.style.backgroundColor = style.bg;
        statusDiv.style.border = `2px solid ${style.border}`;
        statusDiv.style.color = style.text;
        statusDiv.innerHTML = `<strong>${icons[type]} ${message}</strong>`;

        console.log(`[${type.toUpperCase()}] ${message}`);
    }

    /**
     * Generate random AES-256-GCM key
     */
    async function generateSymmetricKey() {
        return await window.crypto.subtle.generateKey(
            {
                name: 'AES-GCM',
                length: 256
            },
            true, // extractable
            ['encrypt', 'decrypt']
        );
    }

    /**
     * Encrypt data with AES-256-GCM
     */
    async function encryptWithAES(data, key, iv) {
        const encoder = new TextEncoder();
        const encodedData = encoder.encode(data);

        const encryptedData = await window.crypto.subtle.encrypt(
            {
                name: 'AES-GCM',
                iv: iv
            },
            key,
            encodedData
        );

        return new Uint8Array(encryptedData);
    }

    /**
     * Register WebAuthn credential on YubiKey
     */
    async function registerYubiKey(username) {
        showStatus('Please touch your YubiKey...', 'info');

        try {
            // Generate random challenge
            const challenge = new Uint8Array(32);
            window.crypto.getRandomValues(challenge);

            // Generate random user ID
            const userId = new Uint8Array(16);
            window.crypto.getRandomValues(userId);

            console.log('Creating WebAuthn credential for:', username);

            // Create credential on YubiKey
            const credential = await navigator.credentials.create({
                publicKey: {
                    challenge: challenge,
                    rp: {
                        name: 'Keycloak SSO',
                        id: window.location.hostname.split(':')[0] // Remove port
                    },
                    user: {
                        id: userId,
                        name: username,
                        displayName: username
                    },
                    pubKeyCredParams: [
                        { type: 'public-key', alg: -7 },  // ES256
                        { type: 'public-key', alg: -257 } // RS256
                    ],
                    authenticatorSelection: {
                        authenticatorAttachment: 'cross-platform', // YubiKey is external
                        requireResidentKey: false,
                        userVerification: 'preferred'
                    },
                    timeout: 60000,
                    attestation: 'direct'
                }
            });

            if (!credential) {
                throw new Error('Failed to create WebAuthn credential');
            }

            console.log('✅ YubiKey credential created successfully');

            // Extract credential ID and public key
            const credentialId = arrayBufferToBase64(credential.rawId);
            const publicKey = arrayBufferToBase64(credential.response.getPublicKey());

            return {
                credentialId: credentialId,
                publicKey: publicKey,
                response: credential.response
            };

        } catch (error) {
            console.error('❌ YubiKey registration failed:', error);
            throw error;
        }
    }

    /**
     * Derive wrapping key from YubiKey data
     */
    async function deriveWrappingKey(credentialId, publicKey, salt) {
        // Combine credential ID + public key + salt for key derivation
        const combinedData = credentialId + publicKey + salt;
        
        const encoder = new TextEncoder();
        const data = encoder.encode(combinedData);

        // Hash the combined data
        const hashBuffer = await window.crypto.subtle.digest('SHA-256', data);

        // Import as key material
        const keyMaterial = await window.crypto.subtle.importKey(
            'raw',
            hashBuffer,
            'PBKDF2',
            false,
            ['deriveKey']
        );

        // Derive AES-GCM key for wrapping
        const wrappingKey = await window.crypto.subtle.deriveKey(
            {
                name: 'PBKDF2',
                salt: encoder.encode(salt),
                iterations: 100000,
                hash: 'SHA-256'
            },
            keyMaterial,
            {
                name: 'AES-GCM',
                length: 256
            },
            false,
            ['wrapKey', 'unwrapKey']
        );

        return wrappingKey;
    }

    /**
     * Wrap (encrypt) the symmetric key
     */
    async function wrapSymmetricKey(symmetricKey, wrappingKey, iv) {
        const wrappedKey = await window.crypto.subtle.wrapKey(
            'raw',
            symmetricKey,
            wrappingKey,
            {
                name: 'AES-GCM',
                iv: iv
            }
        );

        return new Uint8Array(wrappedKey);
    }

    /**
     * Convert ArrayBuffer to Base64
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
     * Generate random salt
     */
    function generateSalt() {
        const salt = new Uint8Array(16);
        window.crypto.getRandomValues(salt);
        return arrayBufferToBase64(salt);
    }

    /**
     * Main encryption function
     */
    async function encryptAndRegister(event) {
        event.preventDefault();

        showStatus('Starting encryption process...', 'info');

        try {
            // Step 1: Check WebAuthn support
            if (!isWebAuthnSupported()) {
                throw new Error('WebAuthn is not supported in this browser');
            }

            // Step 2: Get form data
            const form = document.getElementById('kc-register-form');
            const username = document.getElementById('username').value;

            if (!username) {
                throw new Error('Username is required');
            }

            console.log('📝 Collecting form data...');

            const formData = {};
            FIELDS_TO_ENCRYPT.forEach(fieldName => {
                const field = document.getElementById(fieldName);
                if (field && field.value) {
                    formData[fieldName] = field.value;
                }
            });

            console.log('📦 Data to encrypt:', Object.keys(formData));

            // Step 3: Generate symmetric key
            showStatus('Generating encryption key...', 'info');
            const symmetricKey = await generateSymmetricKey();
            console.log('✅ Symmetric key generated');

            // Step 4: Generate IV for encryption
            const encryptionIV = new Uint8Array(12);
            window.crypto.getRandomValues(encryptionIV);

            // Step 5: Encrypt each field
            showStatus('Encrypting your data...', 'info');
            const encryptedData = {};

            for (const [fieldName, value] of Object.entries(formData)) {
                const encrypted = await encryptWithAES(value, symmetricKey, encryptionIV);
                const fieldKey = fieldName.replace('user.attributes.', '');
                encryptedData[fieldKey] = arrayBufferToBase64(encrypted);
                console.log(`✅ Encrypted: ${fieldName}`);
            }

            // Step 6: Register YubiKey
            showStatus('Please touch your YubiKey now...', 'warning');
            const yubikey = await registerYubiKey(username);
            console.log('✅ YubiKey registered');

            // Step 7: Generate salt
            const salt = generateSalt();

            // Step 8: Derive wrapping key
            showStatus('Securing encryption key...', 'info');
            const wrappingKey = await deriveWrappingKey(yubikey.credentialId, yubikey.publicKey, salt);
            console.log('✅ Wrapping key derived');

            // Step 9: Wrap symmetric key
            const wrappingIV = new Uint8Array(12);
            window.crypto.getRandomValues(wrappingIV);
            const wrappedKey = await wrapSymmetricKey(symmetricKey, wrappingKey, wrappingIV);
            console.log('✅ Symmetric key wrapped');

            // Step 10: Populate hidden fields
            showStatus('Preparing encrypted data for submission...', 'info');

            document.getElementById('encrypted-firstName').value = encryptedData['firstName'] || '';
            document.getElementById('encrypted-lastName').value = encryptedData['lastName'] || '';
            document.getElementById('encrypted-email').value = encryptedData['email'] || '';
            document.getElementById('encrypted-age').value = encryptedData['age'] || '';
            document.getElementById('encrypted-mobile').value = encryptedData['mobile'] || '';
            document.getElementById('encrypted-address').value = encryptedData['address'] || '';
            document.getElementById('encrypted-profession').value = encryptedData['profession'] || '';
            
            document.getElementById('wrapped-key').value = arrayBufferToBase64(wrappedKey);
            document.getElementById('webauthn-credential-id').value = yubikey.credentialId;
            document.getElementById('encryption-salt').value = salt;
            document.getElementById('public-key').value = yubikey.publicKey;

            // Also store encryption IV and wrapping IV (need these for decryption)
            const ivField = document.createElement('input');
            ivField.type = 'hidden';
            ivField.name = 'user.attributes.encryption_iv';
            ivField.value = arrayBufferToBase64(encryptionIV);
            form.appendChild(ivField);

            const wrappingIVField = document.createElement('input');
            wrappingIVField.type = 'hidden';
            wrappingIVField.name = 'user.attributes.wrapping_iv';
            wrappingIVField.value = arrayBufferToBase64(wrappingIV);
            form.appendChild(wrappingIVField);

            console.log('✅ All encrypted data populated');

            // Step 11: Disable plain text fields so they won't be submitted
            // Only encrypted versions will be sent to Keycloak
            showStatus('Removing plain text data...', 'info');
            
            // Remove 'name' attribute from all plain text fields to prevent submission
            document.querySelectorAll('.plaintext-field').forEach(field => {
                field.removeAttribute('name');
                console.log(`🔒 Disabled plain text field: ${field.id}`);
            });

            console.log('✅ Plain text fields disabled');

            // Step 12: Submit form
            showStatus('Registration complete! Submitting...', 'success');
            console.log('📤 Submitting encrypted registration form');

            setTimeout(() => {
                form.submit();
            }, 1000);

        } catch (error) {
            console.error('❌ Encryption failed:', error);
            showStatus(`Error: ${error.message}`, 'error');
        }
    }

    /**
     * Initialize on page load
     */
    document.addEventListener('DOMContentLoaded', function() {
        console.log('🚀 Initializing YubiKey encryption...');

        const encryptedButton = document.getElementById('kc-register-encrypted-btn');
        
        if (encryptedButton) {
            encryptedButton.addEventListener('click', encryptAndRegister);
            console.log('✅ Encrypted registration button initialized');
        }

        // Check WebAuthn support
        if (!isWebAuthnSupported()) {
            showStatus('WebAuthn not supported. Use normal registration.', 'warning');
            if (encryptedButton) {
                encryptedButton.disabled = true;
                encryptedButton.style.opacity = '0.5';
            }
        }
    });

})();
