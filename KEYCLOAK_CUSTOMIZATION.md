# 🎨 Keycloak Customization Guide

This guide explains how to customize Keycloak running in Docker, including adding custom login pages and modifying data before storing in the database.

## 📋 Table of Contents

1. [Understanding Keycloak Architecture](#understanding-keycloak-architecture)
2. [Custom Themes (Frontend/Login Pages)](#custom-themes-frontendlogin-pages)
3. [Custom Providers (Database Logic)](#custom-providers-database-logic)
4. [Development Workflow](#development-workflow)

---

## 🏗️ Understanding Keycloak Architecture

When running Keycloak in Docker, you **cannot directly edit the codebase** inside the container. Instead, you need to:

1. **Create custom themes** - for UI/frontend changes
2. **Develop custom providers (SPIs)** - for backend logic changes
3. **Mount them as volumes** - to make them available to the container

**Key Directories in Keycloak:**
```
/opt/keycloak/
├── themes/              # Custom themes go here
├── providers/           # Custom JAR files (SPIs) go here
├── data/               # Database and runtime data
└── conf/               # Configuration files
```

---

## 🎨 Custom Themes (Frontend/Login Pages)

### Step 1: Create Your Theme Directory Structure

Create a custom theme directory in your project:

```bash
mkdir -p keycloak/themes/mytheme/{login,account,email}
mkdir -p keycloak/themes/mytheme/login/resources/{css,js,img}
```

### Step 2: Create Theme Configuration

Create `keycloak/themes/mytheme/theme.properties`:

```properties
parent=keycloak
import=common/keycloak

# Styles
styles=css/login.css css/custom.css

# Scripts  
scripts=js/custom.js
```

### Step 3: Create Custom Login Page

Create `keycloak/themes/mytheme/login/login.ftl`:

```html
<#import "template.ftl" as layout>
<@layout.registrationLayout displayMessage=!messagesPerField.existsError('username','password') displayInfo=realm.password && realm.registrationAllowed && !registrationDisabled??; section>
    <#if section = "header">
        ${msg("loginAccountTitle")}
    <#elseif section = "form">
    <div id="kc-form">
      <div id="kc-form-wrapper">
        
        <!-- Custom Header -->
        <div class="custom-header">
            <h1>Welcome to My Custom Login</h1>
            <p>Please sign in to continue</p>
        </div>

        <#if realm.password>
            <form id="kc-form-login" onsubmit="login.disabled = true; return true;" action="${url.loginAction}" method="post">
                <div class="${properties.kcFormGroupClass!}">
                    <label for="username" class="${properties.kcLabelClass!}">
                        <#if !realm.loginWithEmailAllowed>${msg("username")}<#elseif !realm.registrationEmailAsUsername>${msg("usernameOrEmail")}<#else>${msg("email")}</#if>
                    </label>

                    <input tabindex="1" id="username" class="${properties.kcInputClass!}" name="username" 
                           value="${(login.username!'')}"  type="text" autofocus autocomplete="off"
                           aria-invalid="<#if messagesPerField.existsError('username','password')>true</#if>"
                    />

                    <#if messagesPerField.existsError('username','password')>
                        <span id="input-error" class="${properties.kcInputErrorMessageClass!}" aria-live="polite">
                            ${kcSanitize(messagesPerField.getFirstError('username','password'))?no_esc}
                        </span>
                    </#if>
                </div>

                <div class="${properties.kcFormGroupClass!}">
                    <label for="password" class="${properties.kcLabelClass!}">${msg("password")}</label>

                    <input tabindex="2" id="password" class="${properties.kcInputClass!}" name="password"
                           type="password" autocomplete="off"
                           aria-invalid="<#if messagesPerField.existsError('username','password')>true</#if>"
                    />
                </div>

                <div class="${properties.kcFormGroupClass!} ${properties.kcFormSettingClass!}">
                    <div id="kc-form-options">
                        <#if realm.rememberMe && !usernameEditDisabled??>
                            <div class="checkbox">
                                <label>
                                    <#if login.rememberMe??>
                                        <input tabindex="3" id="rememberMe" name="rememberMe" type="checkbox" checked> ${msg("rememberMe")}
                                    <#else>
                                        <input tabindex="3" id="rememberMe" name="rememberMe" type="checkbox"> ${msg("rememberMe")}
                                    </#if>
                                </label>
                            </div>
                        </#if>
                        </div>
                        <div class="${properties.kcFormOptionsWrapperClass!}">
                            <#if realm.resetPasswordAllowed>
                                <span><a tabindex="5" href="${url.loginResetCredentialsUrl}">${msg("doForgotPassword")}</a></span>
                            </#if>
                        </div>

                  </div>

                  <div id="kc-form-buttons" class="${properties.kcFormGroupClass!}">
                      <input type="hidden" id="id-hidden-input" name="credentialId" <#if auth.selectedCredential?has_content>value="${auth.selectedCredential}"</#if>/>
                      <input tabindex="4" class="${properties.kcButtonClass!} ${properties.kcButtonPrimaryClass!} ${properties.kcButtonBlockClass!} ${properties.kcButtonLargeClass!}" name="login" id="kc-login" type="submit" value="${msg("doLogIn")}"/>
                  </div>
            </form>
        </#if>
        </div>
    </div>
    <#elseif section = "info" >
        <#if realm.password && realm.registrationAllowed && !registrationDisabled??>
            <div id="kc-registration-container">
                <div id="kc-registration">
                    <span>${msg("noAccount")} <a tabindex="6"
                                                 href="${url.registrationUrl}">${msg("doRegister")}</a></span>
                </div>
            </div>
        </#if>
    </#if>

</@layout.registrationLayout>
```

### Step 4: Add Custom CSS

Create `keycloak/themes/mytheme/login/resources/css/custom.css`:

```css
/* Custom Login Page Styles */
.custom-header {
    text-align: center;
    margin-bottom: 2rem;
    padding: 2rem;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    border-radius: 10px;
    color: white;
}

.custom-header h1 {
    margin: 0;
    font-size: 2rem;
    font-weight: 700;
}

.custom-header p {
    margin: 0.5rem 0 0 0;
    font-size: 1rem;
    opacity: 0.9;
}

#kc-form-wrapper {
    background: white;
    padding: 2rem;
    border-radius: 15px;
    box-shadow: 0 10px 40px rgba(0, 0, 0, 0.1);
}

.form-group input[type="text"],
.form-group input[type="password"] {
    border-radius: 8px;
    border: 2px solid #e2e8f0;
    padding: 12px 16px;
    transition: all 0.3s ease;
}

.form-group input[type="text"]:focus,
.form-group input[type="password"]:focus {
    border-color: #667eea;
    box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
}

#kc-login {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    border: none;
    border-radius: 8px;
    padding: 14px 24px;
    font-weight: 600;
    transition: transform 0.2s ease;
}

#kc-login:hover {
    transform: translateY(-2px);
    box-shadow: 0 5px 20px rgba(102, 126, 234, 0.4);
}
```

### Step 5: Add Custom JavaScript (Optional)

Create `keycloak/themes/mytheme/login/resources/js/custom.js`:

```javascript
// Custom login page behavior
document.addEventListener('DOMContentLoaded', function() {
    console.log('Custom Keycloak theme loaded!');
    
    // Add custom validation
    const loginForm = document.getElementById('kc-form-login');
    if (loginForm) {
        loginForm.addEventListener('submit', function(e) {
            const username = document.getElementById('username').value;
            const password = document.getElementById('password').value;
            
            if (!username || !password) {
                e.preventDefault();
                alert('Please fill in all fields');
                return false;
            }
            
            // You can add more custom logic here
            console.log('Form submitted with username:', username);
        });
    }
});
```

### Step 6: Update Docker Compose to Mount Theme

Edit `docker-compose.yml`:

```yaml
services:
  keycloak:
    image: quay.io/keycloak/keycloak:23.0
    container_name: keycloak-sso
    # ... existing config ...
    volumes:
      - ./demo-realm.json:/opt/keycloak/data/import/demo-realm.json
      - keycloak_data:/opt/keycloak/data
      - ./keycloak/themes/mytheme:/opt/keycloak/themes/mytheme  # Add this line
```

### Step 7: Apply Theme in Keycloak Admin Console

1. Restart Keycloak: `bash stop-keycloak.sh && bash start-keycloak.sh`
2. Login to Admin Console: http://localhost:8080
3. Go to: **Realm Settings** → **Themes** tab
4. Select your custom theme for:
   - **Login theme**: mytheme
   - **Account theme**: mytheme (optional)
   - **Email theme**: mytheme (optional)
5. Click **Save**

---

## ⚙️ Custom Providers (Database Logic)

To modify data before storing in the database, you need to create a **Custom SPI (Service Provider Interface)**.

### Step 1: Setup Java Development Environment

Create a Maven project structure:

```bash
mkdir -p keycloak-custom-provider/src/main/java/com/example/keycloak
mkdir -p keycloak-custom-provider/src/main/resources/META-INF/services
```

### Step 2: Create `pom.xml`

Create `keycloak-custom-provider/pom.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.example</groupId>
    <artifactId>keycloak-custom-provider</artifactId>
    <version>1.0.0</version>
    <packaging>jar</packaging>

    <properties>
        <maven.compiler.source>17</maven.compiler.source>
        <maven.compiler.target>17</maven.compiler.target>
        <keycloak.version>23.0.0</keycloak.version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.keycloak</groupId>
            <artifactId>keycloak-core</artifactId>
            <version>${keycloak.version}</version>
            <scope>provided</scope>
        </dependency>
        <dependency>
            <groupId>org.keycloak</groupId>
            <artifactId>keycloak-server-spi</artifactId>
            <version>${keycloak.version}</version>
            <scope>provided</scope>
        </dependency>
        <dependency>
            <groupId>org.keycloak</groupId>
            <artifactId>keycloak-server-spi-private</artifactId>
            <version>${keycloak.version}</version>
            <scope>provided</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>3.11.0</version>
            </plugin>
        </plugins>
    </build>
</project>
```

### Step 3: Create Custom Event Listener (Pre-Database Storage)

Create `keycloak-custom-provider/src/main/java/com/example/keycloak/CustomEventListenerProvider.java`:

```java
package com.example.keycloak;

import org.keycloak.events.Event;
import org.keycloak.events.EventListenerProvider;
import org.keycloak.events.EventType;
import org.keycloak.events.admin.AdminEvent;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.UserModel;

public class CustomEventListenerProvider implements EventListenerProvider {

    private final KeycloakSession session;

    public CustomEventListenerProvider(KeycloakSession session) {
        this.session = session;
    }

    @Override
    public void onEvent(Event event) {
        // Intercept events before they're stored
        if (EventType.REGISTER.equals(event.getType())) {
            System.out.println("🔔 User Registration Event Intercepted!");
            
            // Get the user that was just registered
            String userId = event.getUserId();
            if (userId != null) {
                UserModel user = session.users().getUserById(session.getContext().getRealm(), userId);
                
                if (user != null) {
                    // Modify user data before it's fully committed
                    System.out.println("📝 Modifying user: " + user.getUsername());
                    
                    // Example: Add custom attribute
                    user.setSingleAttribute("customField", "customValue");
                    user.setSingleAttribute("registrationTimestamp", String.valueOf(System.currentTimeMillis()));
                    
                    // Example: Normalize email
                    if (user.getEmail() != null) {
                        user.setEmail(user.getEmail().toLowerCase().trim());
                    }
                    
                    // Example: Set custom first name prefix
                    if (user.getFirstName() != null) {
                        user.setFirstName("Mr/Ms " + user.getFirstName());
                    }
                }
            }
        }
        
        // Intercept login events
        if (EventType.LOGIN.equals(event.getType())) {
            System.out.println("🔐 Login Event: " + event.getUserId());
            
            // Update last login timestamp
            String userId = event.getUserId();
            if (userId != null) {
                UserModel user = session.users().getUserById(session.getContext().getRealm(), userId);
                if (user != null) {
                    user.setSingleAttribute("lastLogin", String.valueOf(System.currentTimeMillis()));
                }
            }
        }
    }

    @Override
    public void onEvent(AdminEvent adminEvent, boolean includeRepresentation) {
        // Handle admin events if needed
        System.out.println("⚙️ Admin Event: " + adminEvent.getOperationType());
    }

    @Override
    public void close() {
        // Cleanup if needed
    }
}
```

### Step 4: Create Provider Factory

Create `keycloak-custom-provider/src/main/java/com/example/keycloak/CustomEventListenerProviderFactory.java`:

```java
package com.example.keycloak;

import org.keycloak.Config;
import org.keycloak.events.EventListenerProvider;
import org.keycloak.events.EventListenerProviderFactory;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.KeycloakSessionFactory;

public class CustomEventListenerProviderFactory implements EventListenerProviderFactory {

    private static final String PROVIDER_ID = "custom-event-listener";

    @Override
    public EventListenerProvider create(KeycloakSession session) {
        return new CustomEventListenerProvider(session);
    }

    @Override
    public void init(Config.Scope config) {
        System.out.println("🚀 Custom Event Listener Provider Initialized!");
    }

    @Override
    public void postInit(KeycloakSessionFactory factory) {
        // Post-initialization if needed
    }

    @Override
    public void close() {
        // Cleanup
    }

    @Override
    public String getId() {
        return PROVIDER_ID;
    }
}
```

### Step 5: Register the SPI

Create `keycloak-custom-provider/src/main/resources/META-INF/services/org.keycloak.events.EventListenerProviderFactory`:

```
com.example.keycloak.CustomEventListenerProviderFactory
```

### Step 6: Build the JAR

```bash
cd keycloak-custom-provider
mvn clean package
```

This creates: `target/keycloak-custom-provider-1.0.0.jar`

### Step 7: Mount Provider in Docker

Update `docker-compose.yml`:

```yaml
services:
  keycloak:
    image: quay.io/keycloak/keycloak:23.0
    container_name: keycloak-sso
    # ... existing config ...
    volumes:
      - ./demo-realm.json:/opt/keycloak/data/import/demo-realm.json
      - keycloak_data:/opt/keycloak/data
      - ./keycloak/themes/mytheme:/opt/keycloak/themes/mytheme
      - ./keycloak-custom-provider/target/keycloak-custom-provider-1.0.0.jar:/opt/keycloak/providers/keycloak-custom-provider.jar  # Add this
```

### Step 8: Enable the Provider

1. Restart Keycloak
2. Go to: **Events** → **Config** tab
3. Add `custom-event-listener` to **Event Listeners**
4. Click **Save**

---

## 🔄 Development Workflow

### For Theme Changes:

```bash
# 1. Edit your theme files in keycloak/themes/mytheme/
# 2. Restart Keycloak to reload themes
docker-compose restart keycloak

# 3. Clear browser cache and test
```

### For Provider Changes:

```bash
# 1. Edit Java code in keycloak-custom-provider/
# 2. Rebuild
cd keycloak-custom-provider && mvn clean package

# 3. Restart Keycloak
cd .. && docker-compose restart keycloak

# 4. Check logs
docker-compose logs -f keycloak
```

### Quick Development Setup Script

Create `keycloak/dev-reload.sh`:

```bash
#!/bin/bash
echo "🔄 Rebuilding custom provider..."
cd keycloak-custom-provider
mvn clean package

echo "🔄 Restarting Keycloak..."
cd ..
docker-compose restart keycloak

echo "📋 Tailing logs..."
docker-compose logs -f keycloak
```

---

## 📚 Additional Resources

### Common SPIs You Can Implement:

1. **UserStorageProvider** - Custom user database
2. **EventListenerProvider** - Intercept and modify events
3. **AuthenticatorFactory** - Custom authentication flows
4. **ProtocolMapper** - Modify SAML/OIDC tokens
5. **RequiredActionProvider** - Custom required actions

### Useful Keycloak Directories:

```
/opt/keycloak/
├── themes/              # Your custom themes
├── providers/           # Your custom JARs
├── data/
│   ├── h2/             # Database files (dev mode)
│   └── import/         # Realm import files
└── conf/
    └── keycloak.conf   # Main configuration
```

### Debug Mode:

To enable debug logging, add to `docker-compose.yml`:

```yaml
environment:
  KC_LOG_LEVEL: DEBUG
```

---

## 🎯 Quick Examples

### Example 1: Add Company Logo to Login Page

1. Add logo: `keycloak/themes/mytheme/login/resources/img/logo.png`
2. Edit `login.ftl` to include:
   ```html
   <img src="${url.resourcesPath}/img/logo.png" alt="Logo" class="logo">
   ```

### Example 2: Validate Email Domain on Registration

In `CustomEventListenerProvider.java`:

```java
if (EventType.REGISTER.equals(event.getType())) {
    UserModel user = session.users().getUserById(realm, event.getUserId());
    String email = user.getEmail();
    
    if (email != null && !email.endsWith("@company.com")) {
        // Reject or modify
        user.setEnabled(false);
        user.setSingleAttribute("pending_approval", "true");
    }
}
```

---

## ⚠️ Important Notes

1. **JAR Changes**: Always rebuild and restart Keycloak after code changes
2. **Theme Caching**: Clear browser cache to see theme changes
3. **Database**: Data modifications happen at runtime, not schema level
4. **Version Compatibility**: Match Keycloak version in pom.xml with Docker image
5. **Testing**: Always test in dev mode before production

---

## 🆘 Troubleshooting

**Provider not loading?**
```bash
# Check if JAR is mounted
docker exec keycloak-sso ls -la /opt/keycloak/providers/

# Check logs for errors
docker-compose logs keycloak | grep -i error
```

**Theme not appearing?**
```bash
# Verify mount
docker exec keycloak-sso ls -la /opt/keycloak/themes/

# Check theme.properties syntax
cat keycloak/themes/mytheme/theme.properties
```

**Need to access Keycloak shell?**
```bash
docker exec -it keycloak-sso /bin/bash
```

---

Happy Customizing! 🚀
