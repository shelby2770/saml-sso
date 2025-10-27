/**
 * Two-Step Registration with WebAuthn Encryption
 * 
 * Flow:
 * 1. User fills registration form
 * 2. User clicks "Register" button
 * 3. If encryption checkbox is checked:
 *    - Prevent form submit (preventDefault)
 *    - Hold form data in memory
 *    - Create WebAuthn credential (user touches key)
 *    - Encrypt sensitive fields with credential-derived key
 *    - Add encrypted data to hidden fields
 *    - Submit form
 * 4. If checkbox unchecked: normal registration
 */

(function() {
    'use strict';

    // Fields to encrypt
    const SENSITIVE_FIELDS = ['user.attributes.phone', 'user.attributes.address'];

    /**
     * Check if WebAuthn is supported
     */
    function isWebAuthnSupported() {
        return window.PublicKeyCredential !== undefined &&
               navigator.credentials !== undefined &&
               navigator.credentials.create !== undefined;
    }

    /**
     * Show status message to user
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
     * Hide status message
     */
    function hideStatus() {
        const statusDiv = document.getElementById('webauthn-status');
        if (statusDiv) {
            statusDiv.style.display = 'none';
        }
    }

    /**
     * Register WebAuthn credential
     */
    async function registerWebAuthnCredential(username) {
        showStatus('Please touch your security key...', 'info');

        try {
            // Generate random challenge
            const challenge = new Uint8Array(32);
            window.crypto.getRandomValues(challenge);

            // Generate random user ID
            const userId = new Uint8Array(16);
            window.crypto.getRandomValues(userId);

            console.log('Creating WebAuthn credential for user:', username);

            // Create credential
            const credential = await navigator.credentials.create({
                publicKey: {
                    challenge: challenge,
                    rp: {
                        name: window.location.hostname,
                        id: window.location.hostname.replace(/:\d+$/, '') // Remove port if present
                    },
                    user: {
                        id: userId,
                        name: username,
                        displayName: username
                    },
                    pubKeyCredParams: [
                        { alg: -7, type: "public-key" },   // ES256 (Elliptic Curve)
                        { alg: -257, type: "public-key" }  // RS256 (RSA)
                    ],
                    authenticatorSelection: {
                        authenticatorAttachment: "cross-platform", // External security key
                        userVerification: "preferred",
                        requireResidentKey: false
                    },
                    timeout: 60000,
                    attestation: "none"
                }
            });

            console.log('✅ WebAuthn credential created successfully');
            console.log('Credential ID length:', credential.rawId.byteLength, 'bytes');
            
            showStatus('Security key registered successfully!', 'success');
            return credential;

        } catch (error) {
            console.error('❌ WebAuthn credential creation failed:', error);
            
            let errorMessage = 'Failed to register security key: ';
            
            if (error.name === 'NotAllowedError') {
                errorMessage += 'User cancelled or timeout. Please try again.';
            } else if (error.name === 'InvalidStateError') {
                errorMessage += 'This credential is already registered for this device.';
            } else if (error.name === 'NotSupportedError') {
                errorMessage += 'Your browser or device does not support this security key.';
            } else if (error.name === 'SecurityError') {
                errorMessage += 'Security error. Make sure you are using HTTPS or localhost.';
            } else {
                errorMessage += error.message || 'Unknown error';
            }
            
            showStatus(errorMessage, 'error');
            throw new Error(errorMessage);
        }
    }

    /**
     * Derive encryption key from WebAuthn credential ID
     */
    async function deriveEncryptionKey(credentialRawId, salt) {
        try {
            console.log('Deriving encryption key from credential...');
            
            // Import credential ID as key material
            const keyMaterial = await window.crypto.subtle.importKey(
                'raw',
                credentialRawId,
                { name: 'PBKDF2' },
                false,
                ['deriveBits', 'deriveKey']
            );

            // Derive AES-GCM-256 key using PBKDF2
            const encryptionKey = await window.crypto.subtle.deriveKey(
                {
                    name: 'PBKDF2',
                    salt: salt,
                    iterations: 100000,  // High iteration count for security
                    hash: 'SHA-256'
                },
                keyMaterial,
                { 
                    name: 'AES-GCM', 
                    length: 256 
                },
                false, // Not extractable
                ['encrypt', 'decrypt']
            );

            console.log('✅ Encryption key derived successfully');
            return encryptionKey;

        } catch (error) {
            console.error('❌ Key derivation failed:', error);
            throw new Error('Failed to derive encryption key: ' + error.message);
        }
    }

    /**
     * Encrypt data with AES-GCM
     */
    async function encryptData(plaintext, key) {
        try {
            // Generate random IV (Initialization Vector)
            const iv = new Uint8Array(12);
            window.crypto.getRandomValues(iv);

            // Convert plaintext to bytes
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
            throw new Error('Failed to encrypt data: ' + error.message);
        }
    }

    /**
     * Main encryption workflow
     */
    async function encryptSensitiveFields(formData, username) {
        try {
            console.log('🔐 Starting encryption workflow...');
            
            // Step 1: Create WebAuthn credential
            showStatus('Creating WebAuthn credential...', 'info');
            const credential = await registerWebAuthnCredential(username);
            const credentialId = credential.rawId;

            // Step 2: Generate random salt
            const salt = new Uint8Array(16);
            window.crypto.getRandomValues(salt);
            console.log('Generated random salt');

            // Step 3: Derive encryption key
            showStatus('Deriving encryption key...', 'info');
            const encryptionKey = await deriveEncryptionKey(credentialId, salt);

            // Step 4: Encrypt sensitive fields
            showStatus('Encrypting sensitive data...', 'info');
            const encryptedFields = {};
            let encryptedCount = 0;

            for (const fieldName of SENSITIVE_FIELDS) {
                const value = formData.get(fieldName);
                if (value && value.trim()) {
                    encryptedFields[fieldName] = await encryptData(value, encryptionKey);
                    encryptedCount++;
                    console.log(`✅ Encrypted field: ${fieldName}`);
                }
            }

            if (encryptedCount === 0) {
                showStatus('No sensitive data to encrypt', 'warning');
            }

            // Step 5: Create encrypted payload (compact format to fit in 255 char limit)
            // Store each field separately instead of as one JSON to avoid size limits
            const payload = {
                v: '1.0', // version (shortened key)
                a: 'AES-GCM-256', // algorithm (shortened key)
                f: encryptedFields // fields
            };

            const payloadString = JSON.stringify(payload);
            console.log(`📦 Encrypted payload size: ${payloadString.length} characters`);

            // Keycloak user attributes have 255 char limit, so chunk if needed
            const CHUNK_SIZE = 250; // Leave room for safety
            const chunks = [];
            
            if (payloadString.length > CHUNK_SIZE) {
                console.log('⚠️  Payload too large, splitting into chunks...');
                for (let i = 0; i < payloadString.length; i += CHUNK_SIZE) {
                    chunks.push(payloadString.substring(i, i + CHUNK_SIZE));
                }
                console.log(`📦 Split into ${chunks.length} chunks`);
            } else {
                chunks.push(payloadString);
            }

            showStatus(`Data encrypted successfully! (${encryptedCount} fields)`, 'success');

            return {
                credentialId: arrayBufferToBase64(credentialId),
                salt: arrayBufferToBase64(salt.buffer),
                encryptedPayload: chunks[0], // Main chunk
                encryptedPayloadChunks: chunks.length, // Number of chunks
                encryptedPayloadChunk1: chunks[1] || '', // Additional chunks if needed
                encryptedPayloadChunk2: chunks[2] || '',
                encryptedPayloadChunk3: chunks[3] || ''
            };

        } catch (error) {
            console.error('❌ Encryption workflow failed:', error);
            throw error;
        }
    }

    /**
     * Handle form submission
     */
    async function handleFormSubmit(event) {
        const useEncryption = document.getElementById('use-webauthn-encryption');
        
        // If encryption not requested, allow normal submit
        if (!useEncryption || !useEncryption.checked) {
            console.log('ℹ️ Proceeding with normal registration (no encryption)');
            hideStatus();
            return true;
        }

        // Check WebAuthn support
        if (!isWebAuthnSupported()) {
            alert('WebAuthn is not supported in this browser.\n\nRegistration will proceed without encryption.');
            useEncryption.checked = false;
            return true;
        }

        // Prevent default form submission
        event.preventDefault();
        console.log('🛑 Form submission intercepted for encryption');

        try {
            const form = event.target;
            const submitBtn = document.getElementById('kc-register-btn');
            const originalBtnText = submitBtn.textContent;

            // Disable form
            submitBtn.disabled = true;
            submitBtn.textContent = '🔐 Securing your data...';
            submitBtn.style.opacity = '0.7';

            // Get form data (holds ALL fields in memory)
            const formData = new FormData(form);
            const username = formData.get('username');
            const password = formData.get('password');
            const passwordConfirm = formData.get('password-confirm');

            // Validate required fields
            if (!username || !username.trim()) {
                throw new Error('Username is required');
            }

            if (!password) {
                throw new Error('Password is required');
            }

            if (password !== passwordConfirm) {
                throw new Error('Passwords do not match');
            }

            // Check if there are sensitive fields to encrypt
            const hasSensitiveData = SENSITIVE_FIELDS.some(field => {
                const value = formData.get(field);
                return value && value.trim();
            });

            if (!hasSensitiveData) {
                showStatus('No sensitive data to encrypt. Proceeding with normal registration.', 'warning');
                setTimeout(() => {
                    form.submit();
                }, 1000);
                return;
            }

            // Encrypt sensitive fields
            console.log('📝 Form data captured in memory');
            const encrypted = await encryptSensitiveFields(formData, username);

            // Add encrypted data to hidden fields (including chunks if payload is large)
            document.getElementById('encrypted-payload').value = encrypted.encryptedPayload;
            document.getElementById('encrypted-payload-chunks').value = encrypted.encryptedPayloadChunks || '1';
            document.getElementById('encrypted-payload-chunk1').value = encrypted.encryptedPayloadChunk1 || '';
            document.getElementById('encrypted-payload-chunk2').value = encrypted.encryptedPayloadChunk2 || '';
            document.getElementById('encrypted-payload-chunk3').value = encrypted.encryptedPayloadChunk3 || '';
            document.getElementById('webauthn-credential-id').value = encrypted.credentialId;
            document.getElementById('encryption-salt').value = encrypted.salt;

            console.log('✅ Encrypted data added to hidden fields');
            console.log('📝 Chunks: ' + (encrypted.encryptedPayloadChunks || 1));
            console.log('📝 Credential ID:', encrypted.credentialId.substring(0, 30) + '...');

            // CRITICAL: Clear original sensitive fields so they DON'T get stored as plain text
            console.log('🗑️  Clearing plain text sensitive fields...');
            SENSITIVE_FIELDS.forEach(fieldName => {
                const field = document.getElementById(fieldName);
                if (field && field.value) {
                    console.log(`   Clearing ${fieldName}: ${field.value.substring(0, 10)}...`);
                    field.value = ''; // CLEAR the plain text value
                    field.disabled = true; // Disable so it won't be submitted
                    field.setAttribute('data-encrypted', 'true');
                }
            });
            console.log('✅ Plain text fields cleared - only encrypted data will be stored!');

            // Submit form
            submitBtn.textContent = '✅ Submitting encrypted data...';
            console.log('📤 Submitting form with encrypted data');
            
            setTimeout(() => {
                form.submit();
            }, 500);

        } catch (error) {
            console.error('❌ Encryption process failed:', error);
            
            showStatus(error.message, 'error');
            
            // Ask user if they want to proceed without encryption
            setTimeout(() => {
                const proceedWithout = confirm(
                    '⚠️ Encryption failed:\n\n' + error.message + '\n\n' +
                    'Would you like to register WITHOUT encryption?\n\n' +
                    '• Click OK to proceed without encryption\n' +
                    '• Click Cancel to fix the issue and try again'
                );

                if (proceedWithout) {
                    console.log('ℹ️ User chose to proceed without encryption');
                    // Uncheck encryption checkbox
                    document.getElementById('use-webauthn-encryption').checked = false;
                    // Clear hidden fields
                    document.getElementById('encrypted-payload').value = '';
                    document.getElementById('webauthn-credential-id').value = '';
                    document.getElementById('encryption-salt').value = '';
                    // Submit form normally
                    event.target.submit();
                } else {
                    // Re-enable form for retry
                    const submitBtn = document.getElementById('kc-register-btn');
                    submitBtn.disabled = false;
                    submitBtn.textContent = 'Register';
                    submitBtn.style.opacity = '1';
                    hideStatus();
                }
            }, 500);
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
        console.log('🚀 Registration with WebAuthn encryption - Initializing...');
        
        const form = document.getElementById('kc-register-form');
        if (!form) {
            console.warn('⚠️ Registration form not found');
            return;
        }

        // Check WebAuthn support
        const isSupported = isWebAuthnSupported();
        console.log('WebAuthn supported:', isSupported);

        if (!isSupported) {
            const checkbox = document.getElementById('use-webauthn-encryption');
            if (checkbox) {
                checkbox.disabled = true;
                checkbox.parentElement.style.opacity = '0.5';
                checkbox.parentElement.title = 'WebAuthn not supported in this browser';
                
                const label = checkbox.parentElement.querySelector('small');
                if (label) {
                    label.textContent = '⚠️ Security key encryption is not available in this browser.';
                    label.style.color = '#ff6b6b';
                }
            }
            console.warn('⚠️ WebAuthn not supported in this browser');
        }

        // Attach form submit handler
        form.addEventListener('submit', handleFormSubmit);
        
        console.log('✅ Registration encryption initialized');
        console.log('📋 Sensitive fields to encrypt:', SENSITIVE_FIELDS);
    }

    // Initialize when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }

})();
