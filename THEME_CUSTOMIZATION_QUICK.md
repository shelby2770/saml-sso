# 🎨 Quick Keycloak Theme Customization

## Option A: Override with Docker Volume (No Java needed!)

### 1. Create your theme folder:
```bash
mkdir -p keycloak-themes/mytheme/login
cd keycloak-themes/mytheme/login
```

### 2. Create `theme.properties`:
```properties
parent=keycloak
import=common/keycloak
```

### 3. Create custom `login.ftl` (override login page):
```html
<#import "template.ftl" as layout>
<@layout.registrationLayout displayInfo=social.displayInfo; section>
    <#if section = "title">
        ${msg("loginTitle",(realm.displayName!''))}
    <#elseif section = "header">
        <!-- Your custom logo -->
        <img src="${url.resourcesPath}/img/mylogo.png" alt="Logo" />
        <h1>Welcome to My Custom Login!</h1>
    <#elseif section = "form">
        <!-- Login form -->
        <form action="${url.loginAction}" method="post">
            <input type="text" name="username" placeholder="Email" />
            <input type="password" name="password" placeholder="Password" />
            <button type="submit">Sign In</button>
        </form>
    </#if>
</@layout.registrationLayout>
```

### 4. Update `docker-compose.yml`:
```yaml
services:
  keycloak:
    volumes:
      - ./keycloak-themes:/opt/keycloak/themes/mytheme
```

### 5. Restart and activate:
```bash
bash stop-keycloak.sh
bash start-keycloak.sh

# In Keycloak Admin Console:
# Realm Settings → Themes → Login Theme → Select "mytheme"
```

## Files You Can Override:

**Login Pages:**
- `login.ftl` - Main login page
- `register.ftl` - Registration form
- `login-reset-password.ftl` - Password reset
- `login-otp.ftl` - 2FA page

**Email Templates:**
- `email/html/email-verification.ftl`
- `email/html/password-reset.ftl`

**Styles:**
- `resources/css/login.css` - Custom CSS
- `resources/img/` - Your images/logos

**Full example theme structure:**
```
keycloak-themes/
└── mytheme/
    ├── login/
    │   ├── theme.properties
    │   ├── login.ftl
    │   ├── register.ftl
    │   └── resources/
    │       ├── css/
    │       │   └── login.css
    │       └── img/
    │           └── logo.png
    └── email/
        └── html/
            └── email-verification.ftl
```

## Testing Your Theme:
1. Login to Admin Console: http://localhost:8080
2. Select your realm (demo)
3. Realm Settings → Themes
4. Select your theme from dropdowns
5. Save
6. Open SP1 and test login!
