# 🔥 Keycloak Internal Customization - Java Deep Dive

Complete guide to override and customize Keycloak internally using Java, SPIs, and providers.

---

## 📚 Table of Contents

1. [Learning Path & Prerequisites](#learning-path--prerequisites)
2. [Keycloak Architecture Deep Dive](#keycloak-architecture-deep-dive)
3. [Development Environment Setup](#development-environment-setup)
4. [Custom Login Page (Theme + Backend)](#custom-login-page-theme--backend)
5. [Custom Database Logic (SPIs)](#custom-database-logic-spis)
6. [Advanced Customizations](#advanced-customizations)
7. [Real-World Examples](#real-world-examples)
8. [Testing & Debugging](#testing--debugging)
9. [Production Deployment](#production-deployment)

---

## 🎓 Learning Path & Prerequisites

### Phase 1: Java Fundamentals (1-2 weeks if new)

**Essential Java Topics:**
1. Java 17+ basics (syntax, OOP, classes, interfaces)
2. Maven/Gradle build tools
3. Dependency injection concepts
4. Java annotations
5. JAR file creation and management

**Quick Learning Resources:**
- Java Tutorial: https://dev.java/learn/
- Maven in 5 Minutes: https://maven.apache.org/guides/getting-started/

### Phase 2: Keycloak-Specific Concepts (1 week)

**Must Understand:**
1. **SPIs (Service Provider Interfaces)** - Keycloak's plugin system
2. **Realms** - Isolated security domains
3. **Clients** - Applications that use Keycloak
4. **Users, Roles, Groups** - Identity management
5. **Authentication Flows** - How login works
6. **Events** - Lifecycle hooks for customization

**Official Docs:**
- Keycloak SPI Documentation: https://www.keycloak.org/docs/latest/server_development/
- Server Developer Guide: https://www.keycloak.org/docs/latest/server_development/

### Phase 3: Docker Basics (2-3 days)

**Docker Concepts You Need:**
1. Images vs Containers
2. Volumes (mounting files)
3. docker-compose.yml syntax
4. Container restart and logs
5. Exec into running containers

**Quick Docker Tutorial:**
```bash
# Essential Docker commands
docker ps                           # List running containers
docker logs keycloak-sso           # View container logs
docker exec -it keycloak-sso bash  # Enter container shell
docker-compose restart keycloak    # Restart Keycloak
docker-compose down && docker-compose up -d  # Full restart
```

---

## 🏗️ Keycloak Architecture Deep Dive

### Understanding Keycloak's Plugin System

```
┌─────────────────────────────────────────────────────────────┐
│                    KEYCLOAK CORE                             │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              SPI Framework (Service Layer)             │ │
│  │  - Defines extension points                           │ │
│  │  - Loads custom providers at runtime                  │ │
│  └────────────────────────────────────────────────────────┘ │
│                           ↓                                  │
│  ┌─────────────┬─────────────┬─────────────┬─────────────┐ │
│  │   USER      │    AUTH     │   EVENT     │    THEME    │ │
│  │  STORAGE    │  FLOWS      │  LISTENER   │  PROVIDER   │ │
│  │    SPI      │    SPI      │    SPI      │    SPI      │ │
│  └─────────────┴─────────────┴─────────────┴─────────────┘ │
│         ↓              ↓             ↓             ↓         │
│  ┌─────────────┬─────────────┬─────────────┬─────────────┐ │
│  │   YOUR      │   YOUR      │   YOUR      │   YOUR      │ │
│  │  CUSTOM     │  CUSTOM     │  CUSTOM     │  CUSTOM     │ │
│  │ PROVIDER    │ PROVIDER    │ PROVIDER    │ PROVIDER    │ │
│  │  (.jar)     │  (.jar)     │  (.jar)     │  (.jar)     │ │
│  └─────────────┴─────────────┴─────────────┴─────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### Key SPI Types for Customization

| SPI Type | Use Case | Complexity |
|----------|----------|------------|
| **EventListenerProvider** | Modify data before/after DB operations | ⭐⭐ Medium |
| **UserStorageProvider** | Custom user database integration | ⭐⭐⭐ Advanced |
| **AuthenticatorFactory** | Custom authentication logic | ⭐⭐⭐ Advanced |
| **ProtocolMapper** | Modify SAML/OIDC tokens | ⭐⭐ Medium |
| **RequiredActionProvider** | Force user actions (change password, etc.) | ⭐⭐ Medium |
| **ThemeProvider** | Dynamic theme selection | ⭐ Easy |
| **FormAction** | Custom form validation | ⭐⭐ Medium |

---

## 💻 Development Environment Setup

### Step 1: Install Java Development Kit (JDK)

```bash
# Check if Java is installed
java -version

# If not, install JDK 17 (recommended for Keycloak 23+)
# On Ubuntu/Debian:
sudo apt update
sudo apt install openjdk-17-jdk openjdk-17-jdk-headless maven

# On macOS:
brew install openjdk@17 maven

# Verify installation
java -version   # Should show 17.x.x
mvn -version    # Should show Maven 3.x.x
```

### Step 2: IDE Setup (Choose One)

**Option A: IntelliJ IDEA (Recommended)**
```bash
# Download from: https://www.jetbrains.com/idea/download/
# Community Edition is free and sufficient
```

**Option B: VS Code**
```bash
# Install Java extensions
# 1. Extension Pack for Java
# 2. Maven for Java
# 3. Debugger for Java
```

### Step 3: Project Structure Setup

```bash
cd "/home/shelby70/Projects/Django-SAML (2)"

# Create custom provider project
mkdir -p keycloak-customization
cd keycloak-customization

# Create Maven project structure
mkdir -p src/main/java/com/mycompany/keycloak
mkdir -p src/main/resources/META-INF/services
mkdir -p src/test/java

# Create directory for themes
mkdir -p ../keycloak/themes/mytheme/login/resources/{css,js,img}
```

### Step 4: Create `pom.xml` (Maven Configuration)

Create `keycloak-customization/pom.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.mycompany</groupId>
    <artifactId>keycloak-custom-extensions</artifactId>
    <version>1.0.0-SNAPSHOT</version>
    <packaging>jar</packaging>

    <name>Keycloak Custom Extensions</name>
    <description>Custom Keycloak providers for authentication and data processing</description>

    <properties>
        <maven.compiler.source>17</maven.compiler.source>
        <maven.compiler.target>17</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        
        <!-- Match this with your Keycloak Docker image version -->
        <keycloak.version>23.0.0</keycloak.version>
    </properties>

    <dependencies>
        <!-- Keycloak Core Dependencies -->
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
        
        <dependency>
            <groupId>org.keycloak</groupId>
            <artifactId>keycloak-services</artifactId>
            <version>${keycloak.version}</version>
            <scope>provided</scope>
        </dependency>

        <!-- For logging -->
        <dependency>
            <groupId>org.jboss.logging</groupId>
            <artifactId>jboss-logging</artifactId>
            <version>3.5.3.Final</version>
            <scope>provided</scope>
        </dependency>

        <!-- For testing -->
        <dependency>
            <groupId>junit</groupId>
            <artifactId>junit</artifactId>
            <version>4.13.2</version>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <finalName>${project.artifactId}</finalName>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>3.11.0</version>
                <configuration>
                    <source>17</source>
                    <target>17</target>
                </configuration>
            </plugin>
            
            <!-- Create JAR with dependencies -->
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-shade-plugin</artifactId>
                <version>3.5.0</version>
                <executions>
                    <execution>
                        <phase>package</phase>
                        <goals>
                            <goal>shade</goal>
                        </goals>
                        <configuration>
                            <createDependencyReducedPom>false</createDependencyReducedPom>
                        </configuration>
                    </execution>
                </executions>
            </plugin>
        </plugins>
    </build>
</project>
```

### Step 5: Test Maven Setup

```bash
cd keycloak-customization
mvn clean compile

# Should see: BUILD SUCCESS
```

---

## 🎨 Custom Login Page (Theme + Backend)

### Part 1: Custom Theme with Dynamic Data

Create `keycloak/themes/mytheme/theme.properties`:

```properties
parent=keycloak
import=common/keycloak

# CSS files
styles=css/login.css css/custom.css

# JavaScript files
scripts=js/custom.js

# Localization
locales=en,es,fr
```

### Part 2: Advanced Login Template with Server Data

Create `keycloak/themes/mytheme/login/login.ftl`:

```html
<#import "template.ftl" as layout>
<@layout.registrationLayout displayMessage=!messagesPerField.existsError('username','password') displayInfo=realm.password && realm.registrationAllowed && !registrationDisabled??; section>
    <#if section = "header">
        ${msg("loginAccountTitle")}
        
    <#elseif section = "form">
    <div id="kc-form">
      <div id="kc-form-wrapper">
        
        <!-- Custom Dynamic Header -->
        <div class="custom-login-header">
            <img src="${url.resourcesPath}/img/logo.png" alt="Logo" class="custom-logo">
            <h1>Welcome to ${realm.displayName!realm.name}</h1>
            <p class="login-subtitle">Secure Enterprise Authentication</p>
            
            <!-- Display custom realm attribute (set from backend) -->
            <#if realm.attributes?? && realm.attributes['customMessage']??>
                <div class="custom-message">
                    ${realm.attributes['customMessage']}
                </div>
            </#if>
        </div>

        <!-- Show login attempt count (from custom provider) -->
        <#if loginAttempts??>
            <div class="login-attempts-info">
                Remaining attempts: ${3 - loginAttempts}
            </div>
        </#if>

        <#if realm.password>
            <form id="kc-form-login" onsubmit="return validateLogin();" action="${url.loginAction}" method="post">
                
                <!-- Hidden field for custom data -->
                <input type="hidden" name="clientIpAddress" id="clientIpAddress" value="">
                <input type="hidden" name="browserFingerprint" id="browserFingerprint" value="">
                
                <!-- Username Field -->
                <div class="form-group ${properties.kcFormGroupClass!}">
                    <label for="username" class="control-label ${properties.kcLabelClass!}">
                        <#if !realm.loginWithEmailAllowed>${msg("username")}
                        <#elseif !realm.registrationEmailAsUsername>${msg("usernameOrEmail")}
                        <#else>${msg("email")}</#if>
                    </label>

                    <div class="input-wrapper">
                        <span class="input-icon">👤</span>
                        <input tabindex="1" 
                               id="username" 
                               class="form-control ${properties.kcInputClass!}" 
                               name="username" 
                               value="${(login.username!'')}" 
                               type="text" 
                               autofocus 
                               autocomplete="username"
                               placeholder="Enter your username or email"
                               aria-invalid="<#if messagesPerField.existsError('username','password')>true</#if>"
                        />
                    </div>

                    <#if messagesPerField.existsError('username','password')>
                        <span class="error-message ${properties.kcInputErrorMessageClass!}">
                            ${kcSanitize(messagesPerField.getFirstError('username','password'))?no_esc}
                        </span>
                    </#if>
                </div>

                <!-- Password Field -->
                <div class="form-group ${properties.kcFormGroupClass!}">
                    <label for="password" class="control-label ${properties.kcLabelClass!}">
                        ${msg("password")}
                    </label>

                    <div class="input-wrapper">
                        <span class="input-icon">🔒</span>
                        <input tabindex="2" 
                               id="password" 
                               class="form-control ${properties.kcInputClass!}" 
                               name="password"
                               type="password" 
                               autocomplete="current-password"
                               placeholder="Enter your password"
                               aria-invalid="<#if messagesPerField.existsError('username','password')>true</#if>"
                        />
                        <span class="toggle-password" onclick="togglePassword()">👁️</span>
                    </div>
                </div>

                <!-- Remember Me & Forgot Password -->
                <div class="form-options ${properties.kcFormGroupClass!} ${properties.kcFormSettingClass!}">
                    <div class="checkbox-wrapper">
                        <#if realm.rememberMe && !usernameEditDisabled??>
                            <label class="checkbox-label">
                                <input tabindex="3" 
                                       id="rememberMe" 
                                       name="rememberMe" 
                                       type="checkbox" 
                                       <#if login.rememberMe??>checked</#if>
                                />
                                <span>${msg("rememberMe")}</span>
                            </label>
                        </#if>
                    </div>
                    
                    <#if realm.resetPasswordAllowed>
                        <div class="forgot-password">
                            <a tabindex="5" href="${url.loginResetCredentialsUrl}">
                                ${msg("doForgotPassword")}
                            </a>
                        </div>
                    </#if>
                </div>

                <!-- Login Button -->
                <div class="form-actions ${properties.kcFormGroupClass!}">
                    <input type="hidden" 
                           id="id-hidden-input" 
                           name="credentialId" 
                           <#if auth.selectedCredential?has_content>value="${auth.selectedCredential}"</#if>
                    />
                    <button tabindex="4" 
                            class="btn-login ${properties.kcButtonClass!} ${properties.kcButtonPrimaryClass!}" 
                            name="login" 
                            id="kc-login" 
                            type="submit">
                        <span class="btn-text">${msg("doLogIn")}</span>
                        <span class="btn-icon">→</span>
                    </button>
                </div>

                <!-- Social Login Options -->
                <#if realm.password && social.providers??>
                    <div class="social-login-divider">
                        <span>or continue with</span>
                    </div>
                    
                    <div class="social-login-buttons">
                        <#list social.providers as p>
                            <a href="${p.loginUrl}" class="social-btn social-${p.alias}">
                                <img src="${url.resourcesPath}/img/social/${p.alias}.svg" alt="${p.displayName}">
                                ${p.displayName}
                            </a>
                        </#list>
                    </div>
                </#if>
            </form>
        </#if>
      </div>
    </div>
    
    <#elseif section = "info" >
        <#if realm.password && realm.registrationAllowed && !registrationDisabled??>
            <div id="kc-registration-container">
                <div id="kc-registration">
                    <span>${msg("noAccount")} 
                        <a tabindex="6" href="${url.registrationUrl}" class="register-link">
                            ${msg("doRegister")}
                        </a>
                    </span>
                </div>
            </div>
        </#if>
        
        <!-- Custom footer info -->
        <div class="login-footer">
            <p>🔒 Secured by Advanced Authentication</p>
            <p class="small-text">Protected connection · Privacy Policy · Terms of Service</p>
        </div>
    </#if>

</@layout.registrationLayout>
```

### Part 3: Advanced Custom CSS

Create `keycloak/themes/mytheme/login/resources/css/custom.css`:

```css
/* Modern Login Page Styling */
:root {
    --primary-color: #667eea;
    --primary-dark: #5568d3;
    --secondary-color: #764ba2;
    --success-color: #48bb78;
    --error-color: #f56565;
    --text-primary: #2d3748;
    --text-secondary: #718096;
    --bg-light: #f7fafc;
    --border-color: #e2e8f0;
    --shadow: 0 10px 40px rgba(0, 0, 0, 0.1);
}

body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
}

#kc-form-wrapper {
    background: white;
    padding: 3rem;
    border-radius: 20px;
    box-shadow: var(--shadow);
    max-width: 480px;
    width: 100%;
    animation: slideIn 0.4s ease-out;
}

@keyframes slideIn {
    from {
        opacity: 0;
        transform: translateY(-20px);
    }
    to {
        opacity: 1;
        transform: translateY(0);
    }
}

/* Custom Header */
.custom-login-header {
    text-align: center;
    margin-bottom: 2.5rem;
}

.custom-logo {
    width: 80px;
    height: 80px;
    margin-bottom: 1rem;
    object-fit: contain;
}

.custom-login-header h1 {
    font-size: 1.875rem;
    font-weight: 700;
    color: var(--text-primary);
    margin: 0 0 0.5rem 0;
}

.login-subtitle {
    color: var(--text-secondary);
    font-size: 1rem;
    margin: 0;
}

.custom-message {
    background: linear-gradient(135deg, #667eea15 0%, #764ba215 100%);
    border-left: 4px solid var(--primary-color);
    padding: 1rem;
    margin-top: 1rem;
    border-radius: 8px;
    color: var(--text-primary);
}

/* Login Attempts Info */
.login-attempts-info {
    background: #fff5f5;
    border: 1px solid #feb2b2;
    color: #c53030;
    padding: 0.75rem 1rem;
    border-radius: 8px;
    margin-bottom: 1.5rem;
    text-align: center;
    font-weight: 500;
}

/* Form Groups */
.form-group {
    margin-bottom: 1.5rem;
}

.control-label {
    display: block;
    font-weight: 600;
    color: var(--text-primary);
    margin-bottom: 0.5rem;
    font-size: 0.875rem;
}

/* Input Wrapper */
.input-wrapper {
    position: relative;
    display: flex;
    align-items: center;
}

.input-icon {
    position: absolute;
    left: 1rem;
    font-size: 1.25rem;
    pointer-events: none;
}

.form-control {
    width: 100%;
    padding: 0.875rem 1rem 0.875rem 3rem;
    border: 2px solid var(--border-color);
    border-radius: 10px;
    font-size: 1rem;
    transition: all 0.3s ease;
    background: var(--bg-light);
}

.form-control:focus {
    outline: none;
    border-color: var(--primary-color);
    background: white;
    box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
}

.form-control::placeholder {
    color: #a0aec0;
}

/* Toggle Password */
.toggle-password {
    position: absolute;
    right: 1rem;
    cursor: pointer;
    font-size: 1.25rem;
    user-select: none;
    opacity: 0.6;
    transition: opacity 0.2s;
}

.toggle-password:hover {
    opacity: 1;
}

/* Error Messages */
.error-message {
    display: block;
    color: var(--error-color);
    font-size: 0.875rem;
    margin-top: 0.5rem;
    animation: shake 0.3s;
}

@keyframes shake {
    0%, 100% { transform: translateX(0); }
    25% { transform: translateX(-5px); }
    75% { transform: translateX(5px); }
}

/* Form Options */
.form-options {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 1.5rem;
}

.checkbox-wrapper {
    display: flex;
    align-items: center;
}

.checkbox-label {
    display: flex;
    align-items: center;
    cursor: pointer;
    user-select: none;
    color: var(--text-secondary);
    font-size: 0.875rem;
}

.checkbox-label input[type="checkbox"] {
    margin-right: 0.5rem;
    cursor: pointer;
}

.forgot-password a {
    color: var(--primary-color);
    text-decoration: none;
    font-size: 0.875rem;
    font-weight: 500;
    transition: color 0.2s;
}

.forgot-password a:hover {
    color: var(--primary-dark);
    text-decoration: underline;
}

/* Login Button */
.btn-login {
    width: 100%;
    padding: 1rem 1.5rem;
    background: linear-gradient(135deg, var(--primary-color) 0%, var(--secondary-color) 100%);
    border: none;
    border-radius: 10px;
    color: white;
    font-size: 1rem;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.3s ease;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
}

.btn-login:hover {
    transform: translateY(-2px);
    box-shadow: 0 10px 25px rgba(102, 126, 234, 0.4);
}

.btn-login:active {
    transform: translateY(0);
}

.btn-login:disabled {
    opacity: 0.6;
    cursor: not-allowed;
}

.btn-icon {
    font-size: 1.25rem;
    transition: transform 0.3s;
}

.btn-login:hover .btn-icon {
    transform: translateX(4px);
}

/* Social Login */
.social-login-divider {
    margin: 2rem 0 1.5rem;
    text-align: center;
    position: relative;
}

.social-login-divider::before {
    content: '';
    position: absolute;
    top: 50%;
    left: 0;
    right: 0;
    height: 1px;
    background: var(--border-color);
    z-index: 0;
}

.social-login-divider span {
    background: white;
    padding: 0 1rem;
    position: relative;
    z-index: 1;
    color: var(--text-secondary);
    font-size: 0.875rem;
}

.social-login-buttons {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
    gap: 1rem;
}

.social-btn {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
    padding: 0.75rem 1rem;
    border: 2px solid var(--border-color);
    border-radius: 8px;
    text-decoration: none;
    color: var(--text-primary);
    font-weight: 500;
    font-size: 0.875rem;
    transition: all 0.2s;
    background: white;
}

.social-btn:hover {
    border-color: var(--primary-color);
    background: var(--bg-light);
    transform: translateY(-1px);
}

.social-btn img {
    width: 20px;
    height: 20px;
}

/* Registration */
#kc-registration-container {
    margin-top: 2rem;
    text-align: center;
    padding-top: 2rem;
    border-top: 1px solid var(--border-color);
}

.register-link {
    color: var(--primary-color);
    text-decoration: none;
    font-weight: 600;
    transition: color 0.2s;
}

.register-link:hover {
    color: var(--primary-dark);
    text-decoration: underline;
}

/* Footer */
.login-footer {
    margin-top: 2rem;
    text-align: center;
    color: var(--text-secondary);
    font-size: 0.875rem;
}

.small-text {
    font-size: 0.75rem;
    margin-top: 0.5rem;
}

/* Responsive */
@media (max-width: 480px) {
    #kc-form-wrapper {
        padding: 2rem 1.5rem;
    }
    
    .custom-login-header h1 {
        font-size: 1.5rem;
    }
}
```

### Part 4: Custom JavaScript with Client Data Collection

Create `keycloak/themes/mytheme/login/resources/js/custom.js`:

```javascript
/**
 * Custom Keycloak Login Page JavaScript
 * Handles client-side validation, fingerprinting, and UX enhancements
 */

document.addEventListener('DOMContentLoaded', function() {
    console.log('🔐 Custom Keycloak Login Page Loaded');
    
    // Collect browser fingerprint
    collectBrowserFingerprint();
    
    // Setup form enhancements
    setupFormValidation();
    setupPasswordToggle();
    setupAutoFocus();
    trackLoginAttempts();
});

/**
 * Collect browser fingerprint for security
 */
function collectBrowserFingerprint() {
    const fingerprint = {
        userAgent: navigator.userAgent,
        language: navigator.language,
        platform: navigator.platform,
        screenResolution: `${screen.width}x${screen.height}`,
        timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
        timestamp: new Date().toISOString()
    };
    
    // Hash the fingerprint
    const fingerprintString = JSON.stringify(fingerprint);
    const hash = simpleHash(fingerprintString);
    
    // Set in hidden field
    const fingerprintField = document.getElementById('browserFingerprint');
    if (fingerprintField) {
        fingerprintField.value = hash;
    }
    
    console.log('Browser fingerprint collected:', hash);
}

/**
 * Simple hash function
 */
function simpleHash(str) {
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
        const char = str.charCodeAt(i);
        hash = ((hash << 5) - hash) + char;
        hash = hash & hash; // Convert to 32-bit integer
    }
    return Math.abs(hash).toString(36);
}

/**
 * Setup form validation
 */
function setupFormValidation() {
    const form = document.getElementById('kc-form-login');
    if (!form) return;
    
    const usernameInput = document.getElementById('username');
    const passwordInput = document.getElementById('password');
    
    // Real-time validation
    usernameInput?.addEventListener('blur', function() {
        validateUsername(this.value);
    });
    
    passwordInput?.addEventListener('blur', function() {
        validatePassword(this.value);
    });
}

/**
 * Validate username
 */
function validateUsername(username) {
    if (!username || username.trim() === '') {
        showFieldError('username', 'Username is required');
        return false;
    }
    
    clearFieldError('username');
    return true;
}

/**
 * Validate password
 */
function validatePassword(password) {
    if (!password || password.trim() === '') {
        showFieldError('password', 'Password is required');
        return false;
    }
    
    if (password.length < 6) {
        showFieldError('password', 'Password must be at least 6 characters');
        return false;
    }
    
    clearFieldError('password');
    return true;
}

/**
 * Show field error
 */
function showFieldError(fieldName, message) {
    const field = document.getElementById(fieldName);
    if (!field) return;
    
    const wrapper = field.closest('.form-group');
    if (!wrapper) return;
    
    // Remove existing error
    const existingError = wrapper.querySelector('.custom-error');
    if (existingError) {
        existingError.remove();
    }
    
    // Add error message
    const errorDiv = document.createElement('div');
    errorDiv.className = 'custom-error error-message';
    errorDiv.textContent = message;
    wrapper.appendChild(errorDiv);
    
    // Add error styling
    field.style.borderColor = 'var(--error-color)';
}

/**
 * Clear field error
 */
function clearFieldError(fieldName) {
    const field = document.getElementById(fieldName);
    if (!field) return;
    
    const wrapper = field.closest('.form-group');
    if (!wrapper) return;
    
    const error = wrapper.querySelector('.custom-error');
    if (error) {
        error.remove();
    }
    
    field.style.borderColor = '';
}

/**
 * Validate login form before submission
 */
function validateLogin() {
    const username = document.getElementById('username')?.value;
    const password = document.getElementById('password')?.value;
    
    const isUsernameValid = validateUsername(username);
    const isPasswordValid = validatePassword(password);
    
    if (!isUsernameValid || !isPasswordValid) {
        showNotification('Please fix the errors before continuing', 'error');
        return false;
    }
    
    // Disable submit button to prevent double submission
    const submitBtn = document.getElementById('kc-login');
    if (submitBtn) {
        submitBtn.disabled = true;
        submitBtn.innerHTML = '<span class="btn-text">Logging in...</span> <span class="loader"></span>';
    }
    
    return true;
}

/**
 * Setup password toggle
 */
function setupPasswordToggle() {
    const passwordField = document.getElementById('password');
    const toggleBtn = document.querySelector('.toggle-password');
    
    if (passwordField && toggleBtn) {
        toggleBtn.addEventListener('click', function() {
            const type = passwordField.type === 'password' ? 'text' : 'password';
            passwordField.type = type;
            this.textContent = type === 'password' ? '👁️' : '🙈';
        });
    }
}

/**
 * Toggle password visibility
 */
function togglePassword() {
    const passwordField = document.getElementById('password');
    const toggleBtn = document.querySelector('.toggle-password');
    
    if (passwordField) {
        const type = passwordField.type === 'password' ? 'text' : 'password';
        passwordField.type = type;
        if (toggleBtn) {
            toggleBtn.textContent = type === 'password' ? '👁️' : '🙈';
        }
    }
}

/**
 * Setup auto-focus
 */
function setupAutoFocus() {
    // Focus on first empty field
    const usernameField = document.getElementById('username');
    const passwordField = document.getElementById('password');
    
    if (usernameField && !usernameField.value) {
        usernameField.focus();
    } else if (passwordField) {
        passwordField.focus();
    }
}

/**
 * Track login attempts
 */
function trackLoginAttempts() {
    const currentAttempts = parseInt(localStorage.getItem('loginAttempts') || '0');
    
    // Show warning if multiple failed attempts
    if (currentAttempts >= 2) {
        showNotification(
            `Warning: ${currentAttempts} failed login attempt(s). Account will be locked after 5 attempts.`,
            'warning'
        );
    }
    
    // Increment on form submission
    const form = document.getElementById('kc-form-login');
    if (form) {
        form.addEventListener('submit', function() {
            const newAttempts = currentAttempts + 1;
            localStorage.setItem('loginAttempts', newAttempts.toString());
        });
    }
}

/**
 * Show notification
 */
function showNotification(message, type = 'info') {
    const notification = document.createElement('div');
    notification.className = `notification notification-${type}`;
    notification.textContent = message;
    notification.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        padding: 1rem 1.5rem;
        background: ${type === 'error' ? '#f56565' : type === 'warning' ? '#ed8936' : '#4299e1'};
        color: white;
        border-radius: 8px;
        box-shadow: 0 10px 25px rgba(0,0,0,0.2);
        z-index: 9999;
        animation: slideInRight 0.3s ease-out;
    `;
    
    document.body.appendChild(notification);
    
    setTimeout(() => {
        notification.style.animation = 'slideOutRight 0.3s ease-out';
        setTimeout(() => notification.remove(), 300);
    }, 5000);
}

// Add animation styles
const style = document.createElement('style');
style.textContent = `
    @keyframes slideInRight {
        from { transform: translateX(400px); opacity: 0; }
        to { transform: translateX(0); opacity: 1; }
    }
    @keyframes slideOutRight {
        from { transform: translateX(0); opacity: 1; }
        to { transform: translateX(400px); opacity: 0; }
    }
    .loader {
        display: inline-block;
        width: 16px;
        height: 16px;
        border: 2px solid #ffffff50;
        border-top-color: white;
        border-radius: 50%;
        animation: spin 0.6s linear infinite;
    }
    @keyframes spin {
        to { transform: rotate(360deg); }
    }
`;
document.head.appendChild(style);
```

---

## ⚙️ Custom Database Logic (SPIs)

### Example 1: Event Listener - Modify Data Before DB Storage

Create `keycloak-customization/src/main/java/com/mycompany/keycloak/CustomEventListenerProvider.java`:

```java
package com.mycompany.keycloak;

import org.jboss.logging.Logger;
import org.keycloak.events.Event;
import org.keycloak.events.EventListenerProvider;
import org.keycloak.events.EventType;
import org.keycloak.events.admin.AdminEvent;
import org.keycloak.events.admin.OperationType;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.RealmModel;
import org.keycloak.models.UserModel;

import java.time.Instant;
import java.util.Map;

/**
 * Custom Event Listener to intercept and modify user data before database storage
 */
public class CustomEventListenerProvider implements EventListenerProvider {

    private static final Logger logger = Logger.getLogger(CustomEventListenerProvider.class);
    
    private final KeycloakSession session;

    public CustomEventListenerProvider(KeycloakSession session) {
        this.session = session;
    }

    @Override
    public void onEvent(Event event) {
        // Get realm and user
        RealmModel realm = session.realms().getRealm(event.getRealmId());
        
        if (realm == null) {
            logger.warn("Realm not found: " + event.getRealmId());
            return;
        }

        // Handle different event types
        switch (event.getType()) {
            case REGISTER:
                handleUserRegistration(event, realm);
                break;
            case LOGIN:
                handleUserLogin(event, realm);
                break;
            case LOGIN_ERROR:
                handleLoginError(event, realm);
                break;
            case UPDATE_PROFILE:
                handleProfileUpdate(event, realm);
                break;
            default:
                logger.debug("Unhandled event type: " + event.getType());
        }
    }

    /**
     * Handle user registration - modify data before final storage
     */
    private void handleUserRegistration(Event event, RealmModel realm) {
        logger.info("🎉 New user registration detected!");
        
        String userId = event.getUserId();
        if (userId == null) return;
        
        UserModel user = session.users().getUserById(realm, userId);
        if (user == null) {
            logger.warn("User not found: " + userId);
            return;
        }
        
        logger.info("📝 Modifying user data for: " + user.getUsername());
        
        // 1. Normalize email to lowercase
        if (user.getEmail() != null) {
            String normalizedEmail = user.getEmail().toLowerCase().trim();
            user.setEmail(normalizedEmail);
            logger.info("✓ Email normalized: " + normalizedEmail);
        }
        
        // 2. Add registration timestamp
        String registrationTime = Instant.now().toString();
        user.setSingleAttribute("registrationTimestamp", registrationTime);
        logger.info("✓ Registration timestamp added: " + registrationTime);
        
        // 3. Add custom welcome message
        user.setSingleAttribute("welcomeMessage", "Welcome to our platform!");
        
        // 4. Set default role based on email domain
        String email = user.getEmail();
        if (email != null && email.endsWith("@admin.com")) {
            user.setSingleAttribute("accountType", "ADMIN");
            logger.info("✓ Admin account type assigned");
        } else {
            user.setSingleAttribute("accountType", "STANDARD");
            logger.info("✓ Standard account type assigned");
        }
        
        // 5. Generate user reference ID
        String referenceId = "USR-" + System.currentTimeMillis();
        user.setSingleAttribute("referenceId", referenceId);
        logger.info("✓ Reference ID generated: " + referenceId);
        
        // 6. Set account status
        user.setSingleAttribute("accountStatus", "ACTIVE");
        user.setSingleAttribute("emailVerified", "false");
        
        // 7. Initialize counters
        user.setSingleAttribute("loginCount", "0");
        user.setSingleAttribute("failedLoginAttempts", "0");
        
        logger.info("✅ User registration data processed successfully");
    }

    /**
     * Handle user login - track login activity
     */
    private void handleUserLogin(Event event, RealmModel realm) {
        logger.info("🔐 User login detected");
        
        String userId = event.getUserId();
        if (userId == null) return;
        
        UserModel user = session.users().getUserById(realm, userId);
        if (user == null) return;
        
        logger.info("User logged in: " + user.getUsername());
        
        // Update last login timestamp
        String loginTime = Instant.now().toString();
        user.setSingleAttribute("lastLoginTimestamp", loginTime);
        
        // Increment login count
        String currentCount = user.getFirstAttribute("loginCount");
        int loginCount = currentCount != null ? Integer.parseInt(currentCount) : 0;
        user.setSingleAttribute("loginCount", String.valueOf(loginCount + 1));
        
        // Reset failed login attempts
        user.setSingleAttribute("failedLoginAttempts", "0");
        
        // Store IP address if available
        if (event.getIpAddress() != null) {
            user.setSingleAttribute("lastLoginIp", event.getIpAddress());
        }
        
        // Store client information
        Map<String, String> details = event.getDetails();
        if (details != null) {
            String clientId = details.get("client_id");
            if (clientId != null) {
                user.setSingleAttribute("lastLoginClient", clientId);
            }
        }
        
        logger.info("✅ Login tracking updated for: " + user.getUsername());
    }

    /**
     * Handle login errors - track failed attempts
     */
    private void handleLoginError(Event event, RealmModel realm) {
        logger.warn("❌ Login error detected");
        
        String userId = event.getUserId();
        if (userId == null) return;
        
        UserModel user = session.users().getUserById(realm, userId);
        if (user == null) return;
        
        // Increment failed login attempts
        String currentAttempts = user.getFirstAttribute("failedLoginAttempts");
        int attempts = currentAttempts != null ? Integer.parseInt(currentAttempts) : 0;
        attempts++;
        
        user.setSingleAttribute("failedLoginAttempts", String.valueOf(attempts));
        user.setSingleAttribute("lastFailedLoginTimestamp", Instant.now().toString());
        
        // Lock account after 5 failed attempts
        if (attempts >= 5) {
            user.setEnabled(false);
            user.setSingleAttribute("accountStatus", "LOCKED");
            user.setSingleAttribute("lockReason", "Too many failed login attempts");
            logger.warn("🔒 Account locked for user: " + user.getUsername());
        } else {
            logger.warn("Failed login attempt " + attempts + " for user: " + user.getUsername());
        }
    }

    /**
     * Handle profile updates
     */
    private void handleProfileUpdate(Event event, RealmModel realm) {
        logger.info("👤 Profile update detected");
        
        String userId = event.getUserId();
        if (userId == null) return;
        
        UserModel user = session.users().getUserById(realm, userId);
        if (user == null) return;
        
        // Track last profile update
        user.setSingleAttribute("lastProfileUpdate", Instant.now().toString());
        
        // Validate and normalize data
        if (user.getFirstName() != null) {
            String normalized = capitalizeFirst(user.getFirstName());
            user.setFirstName(normalized);
        }
        
        if (user.getLastName() != null) {
            String normalized = capitalizeFirst(user.getLastName());
            user.setLastName(normalized);
        }
        
        logger.info("✅ Profile update processed for: " + user.getUsername());
    }

    @Override
    public void onEvent(AdminEvent adminEvent, boolean includeRepresentation) {
        // Handle admin events
        logger.info("⚙️ Admin event: " + adminEvent.getOperationType());
        
        if (adminEvent.getOperationType() == OperationType.CREATE) {
            logger.info("Admin created new resource: " + adminEvent.getResourceType());
        } else if (adminEvent.getOperationType() == OperationType.UPDATE) {
            logger.info("Admin updated resource: " + adminEvent.getResourceType());
        } else if (adminEvent.getOperationType() == OperationType.DELETE) {
            logger.warn("Admin deleted resource: " + adminEvent.getResourceType());
        }
    }

    @Override
    public void close() {
        // Cleanup if needed
        logger.debug("Event listener provider closed");
    }

    /**
     * Utility: Capitalize first letter
     */
    private String capitalizeFirst(String input) {
        if (input == null || input.isEmpty()) {
            return input;
        }
        return input.substring(0, 1).toUpperCase() + input.substring(1).toLowerCase();
    }
}
```

Create the factory: `keycloak-customization/src/main/java/com/mycompany/keycloak/CustomEventListenerProviderFactory.java`:

```java
package com.mycompany.keycloak;

import org.jboss.logging.Logger;
import org.keycloak.Config;
import org.keycloak.events.EventListenerProvider;
import org.keycloak.events.EventListenerProviderFactory;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.KeycloakSessionFactory;

/**
 * Factory for Custom Event Listener Provider
 */
public class CustomEventListenerProviderFactory implements EventListenerProviderFactory {

    private static final Logger logger = Logger.getLogger(CustomEventListenerProviderFactory.class);
    
    // This ID is used to register the provider in Keycloak Admin Console
    private static final String PROVIDER_ID = "custom-event-listener";

    @Override
    public EventListenerProvider create(KeycloakSession session) {
        logger.debug("Creating Custom Event Listener Provider instance");
        return new CustomEventListenerProvider(session);
    }

    @Override
    public void init(Config.Scope config) {
        logger.info("🚀 Custom Event Listener Provider initialized!");
        logger.info("Provider ID: " + PROVIDER_ID);
        
        // You can read configuration here if needed
        // String customConfig = config.get("customProperty");
    }

    @Override
    public void postInit(KeycloakSessionFactory factory) {
        logger.info("Post-initialization complete for Custom Event Listener");
    }

    @Override
    public void close() {
        logger.info("Shutting down Custom Event Listener Provider");
    }

    @Override
    public String getId() {
        return PROVIDER_ID;
    }
}
```

Register the SPI - Create `keycloak-customization/src/main/resources/META-INF/services/org.keycloak.events.EventListenerProviderFactory`:

```
com.mycompany.keycloak.CustomEventListenerProviderFactory
```

---

## 🔨 Build and Deploy

### Step 1: Build the JAR

```bash
cd keycloak-customization
mvn clean package

# Should create: target/keycloak-custom-extensions.jar
```

### Step 2: Update docker-compose.yml

Edit `/home/shelby70/Projects/Django-SAML (2)/docker-compose.yml`:

```yaml
services:
  keycloak:
    image: quay.io/keycloak/keycloak:23.0
    container_name: keycloak-sso
    environment:
      KEYCLOAK_ADMIN: admin
      KEYCLOAK_ADMIN_PASSWORD: admin
      KC_DB: dev-file
      KC_HOSTNAME_STRICT: "false"
      KC_HOSTNAME_STRICT_HTTPS: "false"
      KC_HTTP_ENABLED: "true"
      KC_HOSTNAME: localhost
      KC_HOSTNAME_PORT: 8080
      KC_LOG_LEVEL: INFO,com.mycompany.keycloak:DEBUG  # Enable debug for your provider
    ports:
      - "8080:8080"
    command:
      - start-dev
      - --import-realm
    volumes:
      - ./demo-realm.json:/opt/keycloak/data/import/demo-realm.json
      - keycloak_data:/opt/keycloak/data
      # Mount custom theme
      - ./keycloak/themes/mytheme:/opt/keycloak/themes/mytheme
      # Mount custom provider JAR
      - ./keycloak-customization/target/keycloak-custom-extensions.jar:/opt/keycloak/providers/keycloak-custom-extensions.jar
    networks:
      - saml-network
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:8080/realms/demo || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 60s

networks:
  saml-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16

volumes:
  keycloak_data:
```

### Step 3: Restart Keycloak

```bash
cd "/home/shelby70/Projects/Django-SAML (2)"
bash stop-keycloak.sh
bash start-keycloak.sh
```

### Step 4: Enable Custom Provider in Admin Console

1. Open http://localhost:8080
2. Login with `admin` / `admin`
3. Select **demo** realm
4. Go to **Realm Settings** → **Events** tab
5. Click **Event Listeners**
6. Add `custom-event-listener` to the list
7. Click **Save**

### Step 5: Apply Custom Theme

1. In Admin Console, go to **Realm Settings** → **Themes** tab
2. Set **Login theme**: mytheme
3. Click **Save**

---

## 🧪 Testing

Test user registration to see custom data processing:

```bash
# Test via Admin Console:
# 1. Go to Users → Add User
# 2. Create a user with:
#    - Username: testuser2
#    - Email: testuser2@example.com
#    - First Name: john
#    - Last Name: doe
# 3. Check user attributes - you should see:
#    - registrationTimestamp
#    - accountType: STANDARD
#    - referenceId: USR-xxxxx
#    - emailVerified: false

# Check Keycloak logs:
docker-compose logs -f keycloak | grep "com.mycompany"
```

---

## 📚 Next Steps

Continue to **Part 2** for:
- Advanced custom authenticators
- Custom user storage providers
- Token customization
- API endpoints
- Production deployment

This is your complete foundation for Keycloak Java customization! 🚀
