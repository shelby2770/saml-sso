# 🚀 Building SSO + WebAuthn with Django (No Docker, No Keycloak)

## Why This Approach is Better for You

You already know Django, so this will be **3-4x faster** than learning Docker + Keycloak + Java.

---

## 📦 Required Django Packages

```bash
# SSO / Authentication
pip install django-allauth              # Social authentication & SSO
pip install python-social-auth[django]  # Alternative SSO solution
pip install django-oauth-toolkit        # OAuth2 provider/consumer

# WebAuthn (Passwordless)
pip install webauthn                    # WebAuthn server library
pip install django-webauthn             # Django integration for WebAuthn

# SAML (if still needed)
pip install python3-saml                # You already have this
pip install djangosaml2                 # Alternative SAML integration
```

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                 Your Django Application                  │
├─────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │   WebAuthn   │  │   OAuth2/    │  │    SAML      │ │
│  │ (Biometric)  │  │   OpenID     │  │  (Optional)  │ │
│  │   Login      │  │   Connect    │  │              │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │         Single Sign-On (SSO) Manager               │ │
│  │   - Google, Microsoft, GitHub, etc.               │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │              User Management                       │ │
│  │   - Registration, Profile, Sessions               │ │
│  └────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

---

## 🔐 Implementation: WebAuthn (Biometric Login)

### Step 1: Install Package

```bash
pip install webauthn django-webauthn
```

### Step 2: Add to `settings.py`

```python
INSTALLED_APPS = [
    # ... existing apps
    'django_webauthn',
]

# WebAuthn Configuration
WEBAUTHN_RP_ID = 'localhost'  # Your domain
WEBAUTHN_RP_NAME = 'My Django SSO App'
WEBAUTHN_ORIGIN = 'http://localhost:8000'
WEBAUTHN_CHALLENGE_TIMEOUT = 60000  # 60 seconds
```

### Step 3: Create Models

```python
# myapp/models.py
from django.db import models
from django.contrib.auth.models import User
import json

class WebAuthnCredential(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='webauthn_credentials')
    credential_id = models.BinaryField(unique=True)
    public_key = models.BinaryField()
    sign_count = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    last_used = models.DateTimeField(null=True, blank=True)
    device_name = models.CharField(max_length=255, default='Unknown Device')
    
    def __str__(self):
        return f"{self.user.username} - {self.device_name}"
```

### Step 4: Registration View

```python
# myapp/views.py
from django.shortcuts import render
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from webauthn import (
    generate_registration_options,
    verify_registration_response,
    options_to_json
)
from webauthn.helpers.structs import (
    AuthenticatorSelectionCriteria,
    UserVerificationRequirement,
)
import json

def webauthn_register_begin(request):
    """Start WebAuthn registration process"""
    user = request.user
    
    # Generate registration options
    options = generate_registration_options(
        rp_id=settings.WEBAUTHN_RP_ID,
        rp_name=settings.WEBAUTHN_RP_NAME,
        user_id=str(user.id).encode('utf-8'),
        user_name=user.username,
        user_display_name=user.get_full_name() or user.username,
        authenticator_selection=AuthenticatorSelectionCriteria(
            user_verification=UserVerificationRequirement.REQUIRED
        ),
    )
    
    # Store challenge in session
    request.session['webauthn_challenge'] = options.challenge.decode('utf-8')
    
    return JsonResponse(options_to_json(options))


@csrf_exempt
def webauthn_register_complete(request):
    """Complete WebAuthn registration"""
    if request.method != 'POST':
        return JsonResponse({'error': 'Method not allowed'}, status=405)
    
    user = request.user
    data = json.loads(request.body)
    challenge = request.session.get('webauthn_challenge').encode('utf-8')
    
    try:
        # Verify registration response
        verification = verify_registration_response(
            credential=data,
            expected_challenge=challenge,
            expected_origin=settings.WEBAUTHN_ORIGIN,
            expected_rp_id=settings.WEBAUTHN_RP_ID,
        )
        
        # Save credential
        WebAuthnCredential.objects.create(
            user=user,
            credential_id=verification.credential_id,
            public_key=verification.credential_public_key,
            sign_count=verification.sign_count,
            device_name=data.get('device_name', 'Unknown Device')
        )
        
        return JsonResponse({'success': True})
        
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=400)
```

### Step 5: Authentication View

```python
from webauthn import (
    generate_authentication_options,
    verify_authentication_response,
)
from django.contrib.auth import login

def webauthn_login_begin(request):
    """Start WebAuthn login process"""
    username = request.POST.get('username')
    
    try:
        user = User.objects.get(username=username)
        credentials = user.webauthn_credentials.all()
        
        options = generate_authentication_options(
            rp_id=settings.WEBAUTHN_RP_ID,
            allow_credentials=[
                {"type": "public-key", "id": cred.credential_id}
                for cred in credentials
            ],
        )
        
        request.session['webauthn_challenge'] = options.challenge.decode('utf-8')
        request.session['webauthn_user_id'] = user.id
        
        return JsonResponse(options_to_json(options))
        
    except User.DoesNotExist:
        return JsonResponse({'error': 'User not found'}, status=404)


@csrf_exempt
def webauthn_login_complete(request):
    """Complete WebAuthn login"""
    data = json.loads(request.body)
    challenge = request.session.get('webauthn_challenge').encode('utf-8')
    user_id = request.session.get('webauthn_user_id')
    
    try:
        user = User.objects.get(id=user_id)
        credential = user.webauthn_credentials.get(
            credential_id=data['credential_id']
        )
        
        # Verify authentication
        verification = verify_authentication_response(
            credential=data,
            expected_challenge=challenge,
            expected_origin=settings.WEBAUTHN_ORIGIN,
            expected_rp_id=settings.WEBAUTHN_RP_ID,
            credential_public_key=credential.public_key,
            credential_current_sign_count=credential.sign_count,
        )
        
        # Update sign count
        credential.sign_count = verification.new_sign_count
        credential.last_used = timezone.now()
        credential.save()
        
        # Log user in
        login(request, user)
        
        return JsonResponse({'success': True})
        
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=400)
```

### Step 6: Frontend (JavaScript)

```html
<!-- templates/webauthn_register.html -->
<button onclick="registerWebAuthn()">Register Biometric Login</button>

<script>
async function registerWebAuthn() {
    // Get registration options from server
    const optionsRes = await fetch('/webauthn/register/begin/');
    const options = await optionsRes.json();
    
    // Convert challenge from base64
    options.challenge = base64ToBuffer(options.challenge);
    options.user.id = base64ToBuffer(options.user.id);
    
    // Create credential
    const credential = await navigator.credentials.create({
        publicKey: options
    });
    
    // Send to server
    const response = await fetch('/webauthn/register/complete/', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({
            id: credential.id,
            rawId: bufferToBase64(credential.rawId),
            response: {
                clientDataJSON: bufferToBase64(credential.response.clientDataJSON),
                attestationObject: bufferToBase64(credential.response.attestationObject),
            },
            type: credential.type,
        })
    });
    
    if (response.ok) {
        alert('Biometric login registered!');
    }
}

function base64ToBuffer(base64) {
    const binary = atob(base64.replace(/-/g, '+').replace(/_/g, '/'));
    const bytes = new Uint8Array(binary.length);
    for (let i = 0; i < binary.length; i++) {
        bytes[i] = binary.charCodeAt(i);
    }
    return bytes.buffer;
}

function bufferToBase64(buffer) {
    const bytes = new Uint8Array(buffer);
    let binary = '';
    for (let i = 0; i < bytes.length; i++) {
        binary += String.fromCharCode(bytes[i]);
    }
    return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
}
</script>
```

---

## 🔑 Implementation: SSO with OAuth2/OpenID

### Using django-allauth (Easiest)

```bash
pip install django-allauth
```

```python
# settings.py
INSTALLED_APPS = [
    # ... existing
    'django.contrib.sites',
    'allauth',
    'allauth.account',
    'allauth.socialaccount',
    'allauth.socialaccount.providers.google',
    'allauth.socialaccount.providers.github',
    'allauth.socialaccount.providers.microsoft',
]

SITE_ID = 1

AUTHENTICATION_BACKENDS = [
    'django.contrib.auth.backends.ModelBackend',
    'allauth.account.auth_backends.AuthenticationBackend',
]

# Social Auth Settings
SOCIALACCOUNT_PROVIDERS = {
    'google': {
        'SCOPE': [
            'profile',
            'email',
        ],
        'AUTH_PARAMS': {
            'access_type': 'online',
        }
    },
    'github': {
        'SCOPE': [
            'user',
            'email',
        ],
    }
}
```

```python
# urls.py
urlpatterns = [
    path('accounts/', include('allauth.urls')),
]
```

**That's it!** django-allauth gives you:
- ✅ Google SSO
- ✅ Microsoft SSO
- ✅ GitHub SSO
- ✅ 50+ other providers
- ✅ Email verification
- ✅ Password reset
- ✅ All with ~10 lines of config!

---

## 🎯 Complete Example: Unified Auth System

```python
# views.py - Unified login page
def unified_login(request):
    """Single login page with multiple options"""
    context = {
        'show_password': True,      # Traditional password login
        'show_webauthn': True,      # Biometric login
        'show_google': True,        # Google SSO
        'show_github': True,        # GitHub SSO
        'show_saml': True,          # SAML (existing setup)
    }
    return render(request, 'login.html', context)
```

```html
<!-- templates/login.html -->
<h2>Login to My App</h2>

<!-- Option 1: Biometric (WebAuthn) -->
<button onclick="loginWithBiometric()">
    🔐 Login with Fingerprint/Face ID
</button>

<!-- Option 2: Social SSO -->
<a href="{% provider_login_url 'google' %}">
    Login with Google
</a>
<a href="{% provider_login_url 'github' %}">
    Login with GitHub
</a>

<!-- Option 3: SAML (Your existing setup) -->
<a href="/saml/login/">
    Login with Corporate SSO
</a>

<!-- Option 4: Traditional Password -->
<form method="post">
    <input type="text" name="username" placeholder="Username">
    <input type="password" name="password" placeholder="Password">
    <button type="submit">Login</button>
</form>
```

---

## ⚡ Time Comparison

| Task | Django Approach | Keycloak + Docker |
|------|----------------|-------------------|
| Setup | 1-2 hours | 1-2 days |
| WebAuthn | 4-6 hours | 2-3 days |
| SSO (OAuth) | 2-3 hours | 3-5 days |
| Customization | Immediate | 1-2 weeks |
| **Total** | **1-2 weeks** | **4-6 weeks** |

---

## 🎓 Learning Resources

### For Django SSO:
- django-allauth docs: https://django-allauth.readthedocs.io/
- WebAuthn guide: https://webauthn.guide/

### Pre-built Solutions:
```bash
pip install django-rest-framework-simplejwt  # JWT auth
pip install dj-rest-auth                      # REST API auth
pip install django-guardian                   # Object-level permissions
```

---

## ✅ Final Recommendation

**Build it with Django** because:

1. ✅ You already know Python/Django
2. ✅ 3-4x faster development
3. ✅ Full control and easier debugging
4. ✅ Can still use your existing SAML setup
5. ✅ Add WebAuthn + OAuth SSO easily
6. ✅ No need to learn Docker, Java, or Keycloak

**Only use Keycloak if:**
- ❌ Your company requires it
- ❌ You need to manage 1000+ enterprise applications
- ❌ You have time to learn 3 new technologies

---

## 🚀 Quick Start Command

```bash
# Create new Django app for auth
python manage.py startapp sso_auth

# Install required packages
pip install django-allauth webauthn django-webauthn

# You're ready to code!
```

---

**Bottom Line:** Stick with Django. You'll be done in 1-2 weeks instead of 1-2 months! 🎯
